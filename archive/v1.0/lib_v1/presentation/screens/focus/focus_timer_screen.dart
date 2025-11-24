import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:focus_life/core/themes/app_theme.dart';
import 'package:focus_life/business/providers/focus_session_provider.dart';
import 'package:focus_life/business/providers/task_provider.dart';
import 'package:focus_life/data/models/focus_session_model.dart';
import 'package:focus_life/data/models/task_model.dart';

/// 专注计时器页面 - 番茄钟功能
class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('专注'),
        backgroundColor: AppTheme.cardColor,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showSettings,
          child: const Icon(CupertinoIcons.settings),
        ),
      ),
      child: SafeArea(
        child: Consumer<FocusSessionProvider>(
          builder: (context, provider, child) {
            return CustomScrollView(
              slivers: [
                // 今日统计
                SliverToBoxAdapter(
                  child: _buildTodayStats(provider),
                ),

                // 计时器主体
                SliverToBoxAdapter(
                  child: _buildTimerSection(provider),
                ),

                // 会话类型选择
                if (provider.isIdle)
                  SliverToBoxAdapter(
                    child: _buildSessionTypeSelector(provider),
                  ),

                // 控制按钮
                SliverToBoxAdapter(
                  child: _buildControls(provider),
                ),

                // 今日会话历史
                SliverToBoxAdapter(
                  child: _buildTodayHistory(provider),
                ),

                // 底部间距
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.spacingXXL),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 构建今日统计
  Widget _buildTodayStats(FocusSessionProvider provider) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingL),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: CupertinoIcons.timer,
            value: '${provider.todayFocusMinutes}分钟',
            label: '今日专注',
            color: AppTheme.primaryColor,
          ),
          _buildStatItem(
            icon: CupertinoIcons.checkmark_circle,
            value: '${provider.todaySessionsCount}次',
            label: '完成会话',
            color: AppTheme.successColor,
          ),
          _buildStatItem(
            icon: CupertinoIcons.star_fill,
            value: provider.todayAverageQuality.toStringAsFixed(0),
            label: '平均质量',
            color: AppTheme.warningColor,
          ),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTheme.fontSizeSubtitle,
            fontWeight: AppTheme.fontWeightBold,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          label,
          style: AppTheme.captionStyle,
        ),
      ],
    );
  }

  /// 构建计时器区域
  Widget _buildTimerSection(FocusSessionProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingXL,
      ),
      child: Column(
        children: [
          // 关联任务显示
          if (provider.associatedTask != null)
            Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
                vertical: AppTheme.spacingS,
              ),
              decoration: BoxDecoration(
                color: provider.associatedTask!.category.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    provider.associatedTask!.category.icon,
                    size: 16,
                    color: provider.associatedTask!.category.color,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Flexible(
                    child: Text(
                      provider.associatedTask!.title,
                      style: TextStyle(
                        color: provider.associatedTask!.category.color,
                        fontWeight: AppTheme.fontWeightMedium,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // 圆形计时器
          _buildCircularTimer(provider),

          const SizedBox(height: AppTheme.spacingXL),

          // 会话状态和中断计数
          if (!provider.isIdle)
            Column(
              children: [
                Text(
                  provider.currentSessionType.displayName,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeSubtitle,
                    fontWeight: AppTheme.fontWeightMedium,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
                if (provider.interruptionCount > 0) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        size: 16,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(width: AppTheme.spacingXS),
                      Text(
                        '${provider.interruptionCount} 次中断',
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  /// 构建圆形计时器
  Widget _buildCircularTimer(FocusSessionProvider provider) {
    final size = 280.0;
    final isRunning = provider.isRunning;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景圆环
          CustomPaint(
            size: Size(size, size),
            painter: _CircularTimerPainter(
              progress: provider.progress,
              backgroundColor: CupertinoColors.systemGrey5,
              progressColor: _getSessionColor(provider.currentSessionType),
              strokeWidth: 12,
            ),
          ),

          // 脉动效果 (运行时)
          if (isRunning)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: size * (0.85 + 0.05 * _pulseController.value),
                  height: size * (0.85 + 0.05 * _pulseController.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getSessionColor(provider.currentSessionType)
                        .withOpacity(0.1 * (1 - _pulseController.value)),
                  ),
                );
              },
            ),

          // 时间显示
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                provider.formattedTime,
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: AppTheme.fontWeightBold,
                  color: AppTheme.primaryTextColor,
                  fontFeatures: const [
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              if (provider.completedPomodoros > 0) ...[
                const SizedBox(height: AppTheme.spacingS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    math.min(provider.completedPomodoros, 4),
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 构建会话类型选择器
  Widget _buildSessionTypeSelector(FocusSessionProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择会话类型',
            style: TextStyle(
              fontSize: AppTheme.fontSizeCaption,
              fontWeight: AppTheme.fontWeightMedium,
              color: AppTheme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildSessionTypeCard(
                  sessionType: SessionType.focus,
                  icon: CupertinoIcons.timer,
                  title: '专注',
                  duration: '${provider.targetMinutes}分钟',
                  color: AppTheme.primaryColor,
                  onTap: () => _selectTask(provider),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildSessionTypeCard(
                  sessionType: SessionType.shortBreak,
                  icon: CupertinoIcons.pause_circle,
                  title: '短休息',
                  duration: '${provider.shortBreakMinutes}分钟',
                  color: AppTheme.successColor,
                  onTap: () => provider.startBreakSession(isLongBreak: false),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildSessionTypeCard(
                  sessionType: SessionType.longBreak,
                  icon: CupertinoIcons.moon_fill,
                  title: '长休息',
                  duration: '${provider.longBreakMinutes}分钟',
                  color: AppTheme.secondaryColor,
                  onTap: () => provider.startBreakSession(isLongBreak: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建会话类型卡片
  Widget _buildSessionTypeCard({
    required SessionType sessionType,
    required IconData icon,
    required String title,
    required String duration,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [AppTheme.cardShadow],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              title,
              style: TextStyle(
                fontSize: AppTheme.fontSizeBody,
                fontWeight: AppTheme.fontWeightMedium,
                color: AppTheme.primaryTextColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              duration,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建控制按钮
  Widget _buildControls(FocusSessionProvider provider) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 中断按钮 (运行或暂停时显示)
          if (!provider.isIdle && provider.currentSessionType == SessionType.focus) ...[
            CupertinoButton(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              onPressed: () {
                provider.recordInterruption();
                _showInterruptionDialog();
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  color: AppTheme.errorColor,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingL),
          ],

          // 主控制按钮
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _handleMainAction(provider),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getMainButtonColor(provider),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getMainButtonColor(provider).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _getMainButtonIcon(provider),
                color: CupertinoColors.white,
                size: 36,
              ),
            ),
          ),

          // 停止按钮 (运行或暂停时显示)
          if (!provider.isIdle) ...[
            const SizedBox(width: AppTheme.spacingL),
            CupertinoButton(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              onPressed: () => _confirmStop(provider),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryTextColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.stop_fill,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建今日历史
  Widget _buildTodayHistory(FocusSessionProvider provider) {
    if (provider.todaySessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日会话',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSubtitle,
              fontWeight: AppTheme.fontWeightBold,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          ...provider.todaySessions.reversed.take(5).map((session) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(
                  color: _getSessionColor(session.sessionType).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getSessionIcon(session.sessionType),
                    color: _getSessionColor(session.sessionType),
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.taskTitle ?? session.sessionType.displayName,
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeBody,
                            fontWeight: AppTheme.fontWeightMedium,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatTime(session.startTime)} · ${session.durationMinutes}分钟',
                          style: AppTheme.captionStyle,
                        ),
                      ],
                    ),
                  ),
                  if (session.sessionType == SessionType.focus)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingS,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getQualityColor(session.qualityScore)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Text(
                        '${session.qualityScore}分',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          fontWeight: AppTheme.fontWeightMedium,
                          color: _getQualityColor(session.qualityScore),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ==================== 辅助方法 ====================

  /// 获取会话颜色
  Color _getSessionColor(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return AppTheme.primaryColor;
      case SessionType.shortBreak:
        return AppTheme.successColor;
      case SessionType.longBreak:
        return AppTheme.secondaryColor;
    }
  }

  /// 获取会话图标
  IconData _getSessionIcon(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return CupertinoIcons.timer;
      case SessionType.shortBreak:
        return CupertinoIcons.pause_circle;
      case SessionType.longBreak:
        return CupertinoIcons.moon_fill;
    }
  }

  /// 获取质量分数颜色
  Color _getQualityColor(int score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  /// 获取主按钮颜色
  Color _getMainButtonColor(FocusSessionProvider provider) {
    if (provider.isRunning) {
      return AppTheme.warningColor;
    } else if (provider.isPaused) {
      return AppTheme.successColor;
    } else {
      return AppTheme.primaryColor;
    }
  }

  /// 获取主按钮图标
  IconData _getMainButtonIcon(FocusSessionProvider provider) {
    if (provider.isRunning) {
      return CupertinoIcons.pause_fill;
    } else if (provider.isPaused) {
      return CupertinoIcons.play_fill;
    } else {
      return CupertinoIcons.play_fill;
    }
  }

  /// 处理主按钮动作
  void _handleMainAction(FocusSessionProvider provider) {
    if (provider.isRunning) {
      provider.pauseSession();
    } else if (provider.isPaused) {
      provider.resumeSession();
    } else {
      // 空闲状态,不做任何操作(需要先选择会话类型)
    }
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // ==================== 交互方法 ====================

  /// 选择任务
  void _selectTask(FocusSessionProvider provider) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _TaskSelectorSheet(
        onTaskSelected: (task) {
          Navigator.pop(context);
          provider.startFocusSession(task: task);
        },
        onStartWithoutTask: () {
          Navigator.pop(context);
          provider.startFocusSession();
        },
      ),
    );
  }

  /// 确认停止
  void _confirmStop(FocusSessionProvider provider) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('停止会话'),
        content: const Text('确定要停止当前会话吗?进度将会被保存。'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              provider.stopSession();
              Navigator.pop(context);
            },
            child: const Text('停止'),
          ),
        ],
      ),
    );
  }

  /// 显示中断对话框
  void _showInterruptionDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('记录中断'),
        content: const Text('中断已记录,会影响本次会话的质量分数。'),
        actions: [
          CupertinoDialogAction(
            child: const Text('知道了'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// 显示设置
  void _showSettings() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _FocusSettingsSheet(),
    );
  }
}

// ==================== 自定义绘制器 ====================

/// 圆形计时器绘制器
class _CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _CircularTimerPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 背景圆环
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 进度圆环
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(center: center, radius: radius);
      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(_CircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ==================== 任务选择器 ====================

class _TaskSelectorSheet extends StatelessWidget {
  final Function(Task?) onTaskSelected;
  final VoidCallback onStartWithoutTask;

  const _TaskSelectorSheet({
    required this.onTaskSelected,
    required this.onStartWithoutTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      color: CupertinoColors.systemBackground,
      child: Column(
        children: [
          // 标题栏
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '选择任务',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSubtitle,
                    fontWeight: AppTheme.fontWeightBold,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onStartWithoutTask,
                  child: const Text('不关联'),
                ),
              ],
            ),
          ),

          // 任务列表
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, child) {
                final pendingTasks = provider.tasks
                    .where((task) => !task.isCompleted)
                    .take(20)
                    .toList();

                if (pendingTasks.isEmpty) {
                  return const Center(
                    child: Text(
                      '暂无未完成任务',
                      style: AppTheme.captionStyle,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: pendingTasks.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final task = pendingTasks[index];
                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      onPressed: () => onTaskSelected(task),
                      child: Row(
                        children: [
                          Icon(
                            task.category.icon,
                            color: task.category.color,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: const TextStyle(
                                    color: AppTheme.primaryTextColor,
                                    fontSize: AppTheme.fontSizeBody,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  task.priority.displayName,
                                  style: TextStyle(
                                    color: task.priority.color,
                                    fontSize: AppTheme.fontSizeSmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 设置面板 ====================

class _FocusSettingsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      color: CupertinoColors.systemBackground,
      child: Column(
        children: [
          // 标题栏
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '专注设置',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSubtitle,
                    fontWeight: AppTheme.fontWeightBold,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Text('完成'),
                ),
              ],
            ),
          ),

          // 设置列表
          Expanded(
            child: Consumer<FocusSessionProvider>(
              builder: (context, provider, child) {
                return ListView(
                  children: [
                    _buildSettingItem(
                      context,
                      title: '专注时长',
                      value: '${provider.targetMinutes}分钟',
                      onTap: () => _showDurationPicker(
                        context,
                        title: '专注时长',
                        initialValue: provider.targetMinutes,
                        onChanged: provider.setFocusDuration,
                      ),
                    ),
                    _buildSettingItem(
                      context,
                      title: '短休息时长',
                      value: '${provider.shortBreakMinutes}分钟',
                      onTap: () => _showDurationPicker(
                        context,
                        title: '短休息时长',
                        initialValue: provider.shortBreakMinutes,
                        onChanged: provider.setShortBreakDuration,
                      ),
                    ),
                    _buildSettingItem(
                      context,
                      title: '长休息时长',
                      value: '${provider.longBreakMinutes}分钟',
                      onTap: () => _showDurationPicker(
                        context,
                        title: '长休息时长',
                        initialValue: provider.longBreakMinutes,
                        onChanged: provider.setLongBreakDuration,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.primaryTextColor,
              fontSize: AppTheme.fontSizeBody,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.secondaryTextColor,
                  fontSize: AppTheme.fontSizeBody,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: AppTheme.secondaryTextColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDurationPicker(
    BuildContext context, {
    required String title,
    required int initialValue,
    required Function(int) onChanged,
  }) {
    int selectedMinutes = initialValue;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: SizedBox(
          height: 150,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem: (initialValue / 5 - 1).round(),
            ),
            itemExtent: 32,
            onSelectedItemChanged: (index) {
              selectedMinutes = (index + 1) * 5;
            },
            children: List.generate(
              24,
              (index) => Center(
                child: Text('${(index + 1) * 5}分钟'),
              ),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            onPressed: () {
              onChanged(selectedMinutes);
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
