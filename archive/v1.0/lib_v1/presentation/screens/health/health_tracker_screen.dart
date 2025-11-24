import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:focus_life/core/themes/app_theme.dart';
import 'package:focus_life/business/providers/health_record_provider.dart';
import 'package:focus_life/data/models/health_record_model.dart';

/// 健康追踪页面 - 记录和管理健康数据
class HealthTrackerScreen extends StatefulWidget {
  const HealthTrackerScreen({super.key});

  @override
  State<HealthTrackerScreen> createState() => _HealthTrackerScreenState();
}

class _HealthTrackerScreenState extends State<HealthTrackerScreen> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('健康'),
        backgroundColor: AppTheme.cardColor,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showSettings,
          child: const Icon(CupertinoIcons.settings),
        ),
      ),
      child: SafeArea(
        child: Consumer<HealthRecordProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            }

            return CustomScrollView(
              slivers: [
                // 健康分数卡片
                SliverToBoxAdapter(
                  child: _buildHealthScoreCard(provider),
                ),

                // 今日目标进度
                SliverToBoxAdapter(
                  child: _buildTodayGoals(provider),
                ),

                // 健康指标卡片
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSleepCard(provider),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildWaterCard(provider),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildExerciseCard(provider),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildMealsCard(provider),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildWeightCard(provider),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildMoodCard(provider),
                      const SizedBox(height: AppTheme.spacingXXL),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 构建健康分数卡片
  Widget _buildHealthScoreCard(HealthRecordProvider provider) {
    final score = provider.todayHealthScore;
    final color = _getScoreColor(score);

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingL),
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.8),
            color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '今日健康分数',
            style: TextStyle(
              fontSize: AppTheme.fontSizeBody,
              color: CupertinoColors.white,
              fontWeight: AppTheme.fontWeightMedium,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            score.toString(),
            style: const TextStyle(
              fontSize: 64,
              fontWeight: AppTheme.fontWeightBold,
              color: CupertinoColors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            _getScoreLabel(score),
            style: const TextStyle(
              fontSize: AppTheme.fontSizeSubtitle,
              color: CupertinoColors.white,
              fontWeight: AppTheme.fontWeightMedium,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildScoreBreakdown(provider),
        ],
      ),
    );
  }

  /// 构建分数分解
  Widget _buildScoreBreakdown(HealthRecordProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildScoreItem(
          icon: CupertinoIcons.moon_fill,
          label: '睡眠',
          value: provider.todaySleepMinutes >= provider.sleepGoalMinutes ? '✓' : '○',
        ),
        _buildScoreItem(
          icon: CupertinoIcons.drop_fill,
          label: '饮水',
          value: provider.todayWaterCount >= provider.waterGoalCount ? '✓' : '○',
        ),
        _buildScoreItem(
          icon: CupertinoIcons.flame_fill,
          label: '运动',
          value: provider.todayExerciseMinutes >= provider.exerciseGoalMinutes ? '✓' : '○',
        ),
        _buildScoreItem(
          icon: CupertinoIcons.square_grid_3x2_fill,
          label: '用餐',
          value: provider.todayMealCount >= 3 ? '✓' : '○',
        ),
      ],
    );
  }

  /// 构建分数项
  Widget _buildScoreItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: CupertinoColors.white, size: 20),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          value,
          style: const TextStyle(
            fontSize: AppTheme.fontSizeSubtitle,
            fontWeight: AppTheme.fontWeightBold,
            color: CupertinoColors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            color: CupertinoColors.white,
          ),
        ),
      ],
    );
  }

  /// 构建今日目标
  Widget _buildTodayGoals(HealthRecordProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日目标',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSubtitle,
              fontWeight: AppTheme.fontWeightBold,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildGoalProgress(
            label: '睡眠',
            current: provider.todaySleepMinutes,
            goal: provider.sleepGoalMinutes,
            unit: '分钟',
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildGoalProgress(
            label: '饮水',
            current: provider.todayWaterCount,
            goal: provider.waterGoalCount,
            unit: '杯',
            color: AppTheme.secondaryColor,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildGoalProgress(
            label: '运动',
            current: provider.todayExerciseMinutes,
            goal: provider.exerciseGoalMinutes,
            unit: '分钟',
            color: AppTheme.warningColor,
          ),
        ],
      ),
    );
  }

  /// 构建目标进度
  Widget _buildGoalProgress({
    required String label,
    required int current,
    required int goal,
    required String unit,
    required Color color,
  }) {
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeBody,
                color: AppTheme.primaryTextColor,
              ),
            ),
            Text(
              '$current / $goal $unit',
              style: TextStyle(
                fontSize: AppTheme.fontSizeBody,
                color: color,
                fontWeight: AppTheme.fontWeightMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingS),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: CupertinoColors.systemGrey5,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  /// 构建睡眠卡片
  Widget _buildSleepCard(HealthRecordProvider provider) {
    return _buildMetricCard(
      icon: CupertinoIcons.moon_fill,
      title: '睡眠',
      value: '${provider.todaySleepHours.toStringAsFixed(1)}小时',
      subtitle: provider.todayRecord?.bedTime != null
          ? '${_formatTime(provider.todayRecord!.bedTime!)} - ${_formatTime(provider.todayRecord!.wakeTime ?? DateTime.now())}'
          : '未记录',
      color: AppTheme.primaryColor,
      onTap: () => _showSleepInput(provider),
    );
  }

  /// 构建饮水卡片
  Widget _buildWaterCard(HealthRecordProvider provider) {
    return _buildMetricCard(
      icon: CupertinoIcons.drop_fill,
      title: '饮水',
      value: '${provider.todayWaterCount}杯',
      subtitle: '目标 ${provider.waterGoalCount} 杯',
      color: AppTheme.secondaryColor,
      onTap: () => _showWaterInput(provider),
      actions: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => provider.removeWater(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.minus,
              color: AppTheme.secondaryColor,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => provider.addWater(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.plus,
              color: AppTheme.secondaryColor,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建运动卡片
  Widget _buildExerciseCard(HealthRecordProvider provider) {
    return _buildMetricCard(
      icon: CupertinoIcons.flame_fill,
      title: '运动',
      value: '${provider.todayExerciseMinutes}分钟',
      subtitle: provider.todayRecord?.exerciseType ?? '未记录',
      color: AppTheme.warningColor,
      onTap: () => _showExerciseInput(provider),
    );
  }

  /// 构建用餐卡片
  Widget _buildMealsCard(HealthRecordProvider provider) {
    return _buildMetricCard(
      icon: CupertinoIcons.square_grid_3x2_fill,
      title: '用餐',
      value: '${provider.todayMealCount}餐',
      subtitle: '目标 3 餐',
      color: AppTheme.successColor,
      onTap: () => _showMealsInput(provider),
    );
  }

  /// 构建体重卡片
  Widget _buildWeightCard(HealthRecordProvider provider) {
    return _buildMetricCard(
      icon: CupertinoIcons.chart_bar_alt_fill,
      title: '体重',
      value: provider.todayWeight != null
          ? '${provider.todayWeight!.toStringAsFixed(1)}kg'
          : '未记录',
      subtitle: '点击记录',
      color: AppTheme.accentColor,
      onTap: () => _showWeightInput(provider),
    );
  }

  /// 构建心情卡片
  Widget _buildMoodCard(HealthRecordProvider provider) {
    final mood = provider.todayRecord?.mood;
    return _buildMetricCard(
      icon: CupertinoIcons.smiley_fill,
      title: '心情',
      value: mood != null ? _getMoodEmoji(mood) : '未记录',
      subtitle: mood != null ? _getMoodLabel(mood) : '点击记录',
      color: AppTheme.primaryColor,
      onTap: () => _showMoodInput(provider),
    );
  }

  /// 通用指标卡片
  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    List<Widget>? actions,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: [AppTheme.cardShadow],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeBody,
                      fontWeight: AppTheme.fontWeightMedium,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeTitle,
                      fontWeight: AppTheme.fontWeightBold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.captionStyle,
                  ),
                ],
              ),
            ),
            if (actions != null) ...actions,
            if (actions == null)
              const Icon(
                CupertinoIcons.chevron_right,
                color: AppTheme.secondaryTextColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // ==================== 辅助方法 ====================

  /// 获取分数颜色
  Color _getScoreColor(int score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  /// 获取分数标签
  String _getScoreLabel(int score) {
    if (score >= 90) return '优秀';
    if (score >= 80) return '良好';
    if (score >= 70) return '中等';
    if (score >= 60) return '及格';
    return '需要改善';
  }

  /// 获取心情表情
  String _getMoodEmoji(int mood) {
    switch (mood) {
      case 1:
        return '😞';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }

  /// 获取心情标签
  String _getMoodLabel(int mood) {
    switch (mood) {
      case 1:
        return '很差';
      case 2:
        return '较差';
      case 3:
        return '一般';
      case 4:
        return '良好';
      case 5:
        return '很好';
      default:
        return '一般';
    }
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // ==================== 输入对话框 ====================

  /// 显示睡眠输入
  void _showSleepInput(HealthRecordProvider provider) {
    DateTime? selectedBedTime = provider.todayRecord?.bedTime ?? DateTime.now();
    DateTime? selectedWakeTime = provider.todayRecord?.wakeTime ?? DateTime.now();

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 400,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const Text(
                    '睡眠时间',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSubtitle,
                      fontWeight: AppTheme.fontWeightBold,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      if (selectedBedTime != null && selectedWakeTime != null) {
                        provider.setBedTime(selectedBedTime!);
                        provider.setWakeUpTime(selectedWakeTime!);
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('完成'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('就寝时间', style: AppTheme.captionStyle),
                        Expanded(
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.time,
                            initialDateTime: selectedBedTime,
                            onDateTimeChanged: (time) {
                              selectedBedTime = time;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('起床时间', style: AppTheme.captionStyle),
                        Expanded(
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.time,
                            initialDateTime: selectedWakeTime,
                            onDateTimeChanged: (time) {
                              selectedWakeTime = time;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示饮水输入
  void _showWaterInput(HealthRecordProvider provider) {
    int selectedCount = provider.todayWaterCount;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('饮水记录'),
        content: SizedBox(
          height: 150,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem: selectedCount,
            ),
            itemExtent: 32,
            onSelectedItemChanged: (index) {
              selectedCount = index;
            },
            children: List.generate(
              21,
              (index) => Center(child: Text('$index 杯')),
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
              provider.setWaterCount(selectedCount);
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示运动输入
  void _showExerciseInput(HealthRecordProvider provider) {
    int selectedMinutes = provider.todayExerciseMinutes;
    String selectedType = provider.todayRecord?.exerciseType ?? '跑步';

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('运动记录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: (selectedMinutes / 10).round(),
                ),
                itemExtent: 32,
                onSelectedItemChanged: (index) {
                  selectedMinutes = index * 10;
                },
                children: List.generate(
                  13,
                  (index) => Center(child: Text('${index * 10} 分钟')),
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            onPressed: () {
              provider.updateExercise(
                minutes: selectedMinutes,
                type: selectedType,
              );
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示用餐输入
  void _showMealsInput(HealthRecordProvider provider) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('添加用餐记录'),
        content: const Text('选择用餐类型'),
        actions: [
          CupertinoDialogAction(
            child: const Text('早餐'),
            onPressed: () {
              provider.addMeal(MealRecord(
                type: MealType.breakfast,
                time: DateTime.now(),
              ));
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            child: const Text('午餐'),
            onPressed: () {
              provider.addMeal(MealRecord(
                type: MealType.lunch,
                time: DateTime.now(),
              ));
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            child: const Text('晚餐'),
            onPressed: () {
              provider.addMeal(MealRecord(
                type: MealType.dinner,
                time: DateTime.now(),
              ));
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// 显示体重输入
  void _showWeightInput(HealthRecordProvider provider) {
    double selectedWeight = provider.todayWeight ?? 60.0;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('体重记录'),
        content: SizedBox(
          height: 150,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem: ((selectedWeight - 40) * 2).round(),
            ),
            itemExtent: 32,
            onSelectedItemChanged: (index) {
              selectedWeight = 40 + (index * 0.5);
            },
            children: List.generate(
              121,
              (index) => Center(
                child: Text('${(40 + index * 0.5).toStringAsFixed(1)} kg'),
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
              provider.updateWeight(selectedWeight);
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示心情输入
  void _showMoodInput(HealthRecordProvider provider) {
    int selectedMood = provider.todayRecord?.mood ?? 3;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('今天心情如何？'),
        content: SizedBox(
          height: 150,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem: selectedMood - 1,
            ),
            itemExtent: 32,
            onSelectedItemChanged: (index) {
              selectedMood = index + 1;
            },
            children: [
              Center(child: Text('${_getMoodEmoji(1)} 很差')),
              Center(child: Text('${_getMoodEmoji(2)} 较差')),
              Center(child: Text('${_getMoodEmoji(3)} 一般')),
              Center(child: Text('${_getMoodEmoji(4)} 良好')),
              Center(child: Text('${_getMoodEmoji(5)} 很好')),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            onPressed: () {
              provider.updateMood(selectedMood);
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示设置
  void _showSettings() {
    // TODO: 实现设置页面
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('设置'),
        content: const Text('健康目标设置功能即将推出'),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
