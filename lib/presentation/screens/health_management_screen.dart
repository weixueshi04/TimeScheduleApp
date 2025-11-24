import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/health_repository.dart';
import '../../data/models/health_record.dart';

class HealthManagementScreen extends StatefulWidget {
  const HealthManagementScreen({super.key});

  @override
  State<HealthManagementScreen> createState() => _HealthManagementScreenState();
}

class _HealthManagementScreenState extends State<HealthManagementScreen> {
  HealthRecord? _todayRecord;
  List<HealthRecord> _recentRecords = [];
  HealthStats? _stats;
  bool _isLoading = false;

  // Form fields
  double _sleepHours = 7.0;
  int _waterIntake = 2000;
  int _exerciseMinutes = 30;
  String _mood = 'normal';

  final Map<String, String> _moodOptions = {
    'great': '😄 非常好',
    'good': '🙂 不错',
    'normal': '😐 一般',
    'bad': '😔 不太好',
    'terrible': '😢 很差',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final repository = context.read<HealthRepository>();

    try {
      final results = await Future.wait([
        repository.getTodayRecord(),
        repository.getHealthRecords(days: 7),
        repository.getHealthStats(days: 30),
      ]);

      setState(() {
        _todayRecord = results[0] as HealthRecord?;
        _recentRecords = results[1] as List<HealthRecord>;
        _stats = results[2] as HealthStats;

        // Load today's values if exists
        if (_todayRecord != null) {
          _sleepHours = _todayRecord!.sleepHours ?? 7.0;
          _waterIntake = _todayRecord!.waterIntake ?? 2000;
          _exerciseMinutes = _todayRecord!.exerciseMinutes ?? 30;
          _mood = _todayRecord!.mood ?? 'normal';
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRecord() async {
    final repository = context.read<HealthRepository>();

    setState(() => _isLoading = true);

    try {
      final request = HealthRecordRequest(
        sleepHours: _sleepHours,
        waterIntake: _waterIntake,
        exerciseMinutes: _exerciseMinutes,
        mood: _mood,
      );

      final record = await repository.saveHealthRecord(request);

      setState(() {
        _todayRecord = record;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功！')),
      );

      await _loadData(); // Refresh data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('健康管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Show history
            },
          ),
        ],
      ),
      body: _isLoading && _todayRecord == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Health score card
                    if (_todayRecord != null) _buildHealthScoreCard(),
                    if (_todayRecord != null) const SizedBox(height: 16),

                    // Today's record form
                    _buildTodayRecordCard(),
                    const SizedBox(height: 16),

                    // Stats
                    if (_stats != null) _buildStatsCard(),
                    const SizedBox(height: 16),

                    // Recent records
                    if (_recentRecords.isNotEmpty) _buildRecentRecords(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHealthScoreCard() {
    final score = _todayRecord!.healthScore;
    final color = _getScoreColor(score);

    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text(
              '今日健康分数',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$score',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getScoreLevel(score),
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayRecordCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '今日记录 - ${DateFormat('MM月dd日').format(DateTime.now())}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_todayRecord != null)
                  const Chip(
                    label: Text('已记录'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                  ),
              ],
            ),
            const Divider(height: 24),

            // Sleep hours
            _buildSectionLabel('睡眠时长', Icons.bedtime),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _sleepHours,
                    min: 0,
                    max: 12,
                    divisions: 24,
                    label: '$_sleepHours 小时',
                    onChanged: (value) => setState(() => _sleepHours = value),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '${_sleepHours.toStringAsFixed(1)} 小时',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Water intake
            _buildSectionLabel('饮水量', Icons.water_drop),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _waterIntake.toDouble(),
                    min: 0,
                    max: 4000,
                    divisions: 40,
                    label: '$_waterIntake ml',
                    onChanged: (value) => setState(() => _waterIntake = value.toInt()),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '$_waterIntake ml',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Quick buttons
            Wrap(
              spacing: 8,
              children: [250, 500, 1000, 1500, 2000, 2500].map((ml) {
                return ChoiceChip(
                  label: Text('${ml}ml'),
                  selected: _waterIntake == ml,
                  onSelected: (selected) {
                    if (selected) setState(() => _waterIntake = ml);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Exercise minutes
            _buildSectionLabel('运动时长', Icons.fitness_center),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _exerciseMinutes.toDouble(),
                    min: 0,
                    max: 180,
                    divisions: 36,
                    label: '$_exerciseMinutes 分钟',
                    onChanged: (value) => setState(() => _exerciseMinutes = value.toInt()),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '$_exerciseMinutes 分钟',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Quick buttons
            Wrap(
              spacing: 8,
              children: [0, 15, 30, 60, 90, 120].map((min) {
                return ChoiceChip(
                  label: Text('${min}分'),
                  selected: _exerciseMinutes == min,
                  onSelected: (selected) {
                    if (selected) setState(() => _exerciseMinutes = min);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Mood
            _buildSectionLabel('心情', Icons.mood),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _moodOptions.entries.map((entry) {
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: _mood == entry.key,
                  onSelected: (selected) {
                    if (selected) setState(() => _mood = entry.key);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveRecord,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('保存今日记录', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '30天平均数据',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '睡眠',
                  '${_stats!.avgSleepHours.toStringAsFixed(1)}h',
                  Icons.bedtime,
                  Colors.purple,
                ),
                _buildStatItem(
                  '饮水',
                  '${_stats!.avgWaterIntake}ml',
                  Icons.water_drop,
                  Colors.blue,
                ),
                _buildStatItem(
                  '运动',
                  '${_stats!.avgExerciseMinutes}min',
                  Icons.fitness_center,
                  Colors.orange,
                ),
                _buildStatItem(
                  '分数',
                  _stats!.avgHealthScore.toInt().toString(),
                  Icons.stars,
                  Colors.green,
                ),
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
            fontSize: 18,
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

  Widget _buildRecentRecords() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '最近7天',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._recentRecords.map((record) => _buildRecordItem(record)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordItem(HealthRecord record) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Date
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MM-dd').format(record.recordDate),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  DateFormat('EEE', 'zh_CN').format(record.recordDate),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Health score
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getScoreColor(record.healthScore).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getScoreColor(record.healthScore),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '${record.healthScore}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(record.healthScore),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (record.sleepHours != null)
                  _buildMiniStat(Icons.bedtime, '${record.sleepHours!.toStringAsFixed(1)}h'),
                if (record.waterIntake != null)
                  _buildMiniStat(Icons.water_drop, '${record.waterIntake}ml'),
                if (record.exerciseMinutes != null)
                  _buildMiniStat(Icons.fitness_center, '${record.exerciseMinutes}m'),
                if (record.mood != null)
                  Text(
                    _getMoodEmoji(record.mood!),
                    style: const TextStyle(fontSize: 20),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLevel(int score) {
    if (score >= 90) return '优秀';
    if (score >= 80) return '良好';
    if (score >= 60) return '一般';
    if (score >= 40) return '较差';
    return '很差';
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'great':
        return '😄';
      case 'good':
        return '🙂';
      case 'normal':
        return '😐';
      case 'bad':
        return '😔';
      case 'terrible':
        return '😢';
      default:
        return '😐';
    }
  }
}
