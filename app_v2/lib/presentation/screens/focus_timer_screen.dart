import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/focus_repository.dart';
import '../../data/models/focus_session.dart';
import '../../data/models/task.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> with TickerProviderStateMixin {
  // Timer state
  Timer? _timer;
  int _remainingSeconds = 0;
  int _totalSeconds = 25 * 60; // Default: 25 minutes
  bool _isRunning = false;
  bool _isPaused = false;
  int _interruptionCount = 0;

  // Session state
  FocusSession? _activeSession;
  Task? _selectedTask;
  String _mode = 'pomodoro'; // pomodoro, custom, deep_work

  // Mode presets
  final Map<String, int> _modePresets = {
    'pomodoro': 25,
    'short_break': 5,
    'long_break': 15,
    'deep_work': 90,
  };

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _loadActiveSession();
    _loadTasks();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveSession() async {
    final repository = context.read<FocusRepository>();
    try {
      final session = await repository.getActiveSession();
      if (session != null) {
        setState(() {
          _activeSession = session;
          _totalSeconds = session.durationMinutes * 60;
          _remainingSeconds = (session.remainingMinutes ?? 0) * 60;
          _interruptionCount = session.interruptionCount;
          _isRunning = true;
        });
        _startTimer();
      }
    } catch (e) {
      // No active session
    }
  }

  Future<void> _loadTasks() async {
    // Load tasks for selection (optional)
  }

  void _startTimer() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _completeSession();
      }
    });
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = true;
      _isRunning = false;
      _interruptionCount++;
    });
    _timer?.cancel();

    // Record interruption
    if (_activeSession != null) {
      context.read<FocusRepository>().interruptFocusSession(_activeSession!.id);
    }
  }

  void _resumeTimer() {
    _startTimer();
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
    });
  }

  Future<void> _startNewSession() async {
    if (_activeSession != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已有活跃会话，请先完成或放弃')),
      );
      return;
    }

    final repository = context.read<FocusRepository>();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final request = StartFocusRequest(
        taskId: _selectedTask?.id,
        durationMinutes: _totalSeconds ~/ 60,
        mode: _mode,
      );

      final session = await repository.startFocusSession(request);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      setState(() {
        _activeSession = session;
        _remainingSeconds = _totalSeconds;
        _interruptionCount = 0;
      });

      _startTimer();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('启动失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _completeSession() async {
    _stopTimer();

    if (_activeSession == null) return;

    final repository = context.read<FocusRepository>();
    final actualMinutes = (_totalSeconds - _remainingSeconds) ~/ 60;

    try {
      final request = CompleteFocusRequest(
        actualDurationMinutes: actualMinutes,
        interruptionCount: _interruptionCount,
      );

      await repository.completeFocusSession(_activeSession!.id, request);

      if (!mounted) return;

      // Show completion dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🎉 完成专注！'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('专注时长: $actualMinutes 分钟'),
              if (_interruptionCount > 0) Text('中断次数: $_interruptionCount 次'),
              const SizedBox(height: 16),
              const Text('继续保持专注！'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetSession();
              },
              child: const Text('确定'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('完成失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _abandonSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃会话'),
        content: const Text('确定要放弃当前专注会话吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('放弃'),
          ),
        ],
      ),
    );

    if (confirm != true || _activeSession == null) return;

    final repository = context.read<FocusRepository>();

    try {
      await repository.abandonFocusSession(_activeSession!.id);
      _resetSession();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已放弃会话')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _resetSession() {
    _stopTimer();
    setState(() {
      _activeSession = null;
      _remainingSeconds = _totalSeconds;
      _interruptionCount = 0;
      _selectedTask = null;
    });
  }

  void _setMode(String mode) {
    if (_isRunning) return;

    setState(() {
      _mode = mode;
      _totalSeconds = (_modePresets[mode] ?? 25) * 60;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _setCustomTime(int minutes) {
    if (_isRunning) return;

    setState(() {
      _mode = 'custom';
      _totalSeconds = minutes * 60;
      _remainingSeconds = _totalSeconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('专注计时'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Show focus history
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Mode selection
            if (!_isRunning) _buildModeSelection(),
            if (!_isRunning) const SizedBox(height: 24),

            // Timer display
            _buildTimerDisplay(),
            const SizedBox(height: 32),

            // Controls
            _buildControls(),
            const SizedBox(height: 32),

            // Task selection
            if (!_isRunning) _buildTaskSelection(),
            if (!_isRunning) const SizedBox(height: 32),

            // Stats
            _buildStatsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择模式',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildModeChip('番茄钟 (25分)', 'pomodoro'),
                _buildModeChip('短休息 (5分)', 'short_break'),
                _buildModeChip('长休息 (15分)', 'long_break'),
                _buildModeChip('深度工作 (90分)', 'deep_work'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('自定义时长:'),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: (_totalSeconds / 60).toDouble(),
                    min: 1,
                    max: 120,
                    divisions: 119,
                    label: '${_totalSeconds ~/ 60} 分钟',
                    onChanged: (value) => _setCustomTime(value.toInt()),
                  ),
                ),
                Text('${_totalSeconds ~/ 60}分'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip(String label, String mode) {
    final isSelected = _mode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _setMode(mode);
      },
    );
  }

  Widget _buildTimerDisplay() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final progress = _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0.0;

    return ScaleTransition(
      scale: _isRunning ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: _isRunning
                ? [Colors.green.shade400, Colors.green.shade600]
                : [Colors.blue.shade400, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress ring
            SizedBox(
              width: 260,
              height: 260,
              child: CircularProgressIndicator(
                value: 1 - progress,
                strokeWidth: 8,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            // Time display
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getStatusText(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                if (_interruptionCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '中断 $_interruptionCount 次',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    if (_isRunning) return '专注中...';
    if (_isPaused) return '已暂停';
    if (_activeSession != null) return '准备就绪';
    return '点击开始';
  }

  Widget _buildControls() {
    if (_activeSession == null) {
      // Not started
      return ElevatedButton.icon(
        onPressed: _startNewSession,
        icon: const Icon(Icons.play_arrow, size: 32),
        label: const Text('开始专注', style: TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isRunning)
          ElevatedButton.icon(
            onPressed: _pauseTimer,
            icon: const Icon(Icons.pause),
            label: const Text('暂停'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _resumeTimer,
            icon: const Icon(Icons.play_arrow),
            label: const Text('继续'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: _abandonSession,
          icon: const Icon(Icons.stop),
          label: const Text('放弃'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '关联任务（可选）',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                // TODO: Show task picker
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.task_alt, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedTask?.title ?? '选择任务',
                        style: TextStyle(
                          color: _selectedTask == null ? Colors.grey : null,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '今日统计',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('完成会话', '0', Icons.check_circle, Colors.green),
                _buildStatItem('专注时长', '0分', Icons.timer, Colors.blue),
                _buildStatItem('完成率', '0%', Icons.trending_up, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
