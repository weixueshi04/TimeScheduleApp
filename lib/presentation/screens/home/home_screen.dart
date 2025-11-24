import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:focus_life/core/themes/app_theme.dart';
import 'package:focus_life/core/constants/app_constants.dart';
import 'package:focus_life/business/providers/task_provider.dart';
import 'package:focus_life/business/providers/focus_session_provider.dart';
import 'package:focus_life/business/providers/health_record_provider.dart';
import 'package:focus_life/presentation/screens/tasks/add_task_screen.dart';

/// 首页 - 展示今日概览和快速操作
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text(AppConstants.appNameCN),
        backgroundColor: AppTheme.cardColor,
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 顶部间距
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacingXL),
            ),

            // 欢迎区域
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: AppTheme.captionStyle,
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    const Text(
                      '准备好开始高效的一天了吗？',
                      style: AppTheme.titleStyle,
                    ),
                  ],
                ),
              ),
            ),

            // 间距
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacingXL),
            ),

            // 今日数据概览卡片
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                ),
                child: _buildTodayOverview(),
              ),
            ),

            // 间距
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacingXL),
            ),

            // 今日任务预览
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                ),
                child: _buildTodayTasks(),
              ),
            ),

            // 间距
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacingXL),
            ),

            // 快速操作区域
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '快速操作',
                      style: AppTheme.subtitleStyle,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),

            // 底部间距
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacingXXL),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取问候语
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) {
      return '夜深了';
    } else if (hour < 12) {
      return '早上好';
    } else if (hour < 14) {
      return '中午好';
    } else if (hour < 18) {
      return '下午好';
    } else {
      return '晚上好';
    }
  }

  /// 构建今日概览
  Widget _buildTodayOverview() {
    return Consumer3<TaskProvider, FocusSessionProvider, HealthRecordProvider>(
      builder: (context, taskProvider, focusProvider, healthProvider, child) {
        final completedTasks = taskProvider.completedCount;
        final focusMinutes = focusProvider.todayFocusMinutes;
        final healthScore = healthProvider.todayHealthScore;

        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                AppTheme.secondaryColor.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            boxShadow: [AppTheme.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '今日概览',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSubtitle,
                      fontWeight: AppTheme.fontWeightBold,
                      color: AppTheme.primaryTextColor,
                    ),
                  ),
                  Text(
                    _formatDate(DateTime.now()),
                    style: AppTheme.captionStyle,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildOverviewItem(
                    icon: CupertinoIcons.checkmark_circle_fill,
                    label: '已完成',
                    value: '$completedTasks',
                    color: AppTheme.successColor,
                  ),
                  _buildOverviewItem(
                    icon: CupertinoIcons.timer_fill,
                    label: '专注时长',
                    value: '${focusMinutes}分',
                    color: AppTheme.primaryColor,
                  ),
                  _buildOverviewItem(
                    icon: CupertinoIcons.heart_fill,
                    label: '健康分',
                    value: '$healthScore',
                    color: _getHealthScoreColor(healthScore),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建概览项
  Widget _buildOverviewItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: color,
        ),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTheme.fontSizeSubtitle,
            fontWeight: AppTheme.fontWeightBold,
            color: color,
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

  /// 构建今日任务预览
  Widget _buildTodayTasks() {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final todayTasks = provider.todayTasks.take(3).toList();

        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            boxShadow: [AppTheme.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '今日任务',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSubtitle,
                      fontWeight: AppTheme.fontWeightBold,
                      color: AppTheme.primaryTextColor,
                    ),
                  ),
                  Text(
                    '${provider.todayTasks.length} 个',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeBody,
                      color: AppTheme.primaryColor,
                      fontWeight: AppTheme.fontWeightMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              if (todayTasks.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingL),
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.checkmark_alt_circle,
                          size: 48,
                          color: AppTheme.secondaryTextColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        const Text(
                          '今天还没有任务',
                          style: AppTheme.captionStyle,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...todayTasks.map((task) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: task.category.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color: task.category.color.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          task.isCompleted
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.circle,
                          color: task.isCompleted
                              ? AppTheme.successColor
                              : task.category.color,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeBody,
                              color: task.isCompleted
                                  ? AppTheme.secondaryTextColor
                                  : AppTheme.primaryTextColor,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingS,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: task.priority.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          ),
                          child: Text(
                            task.priority.displayName,
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeSmall,
                              color: task.priority.color,
                              fontWeight: AppTheme.fontWeightMedium,
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
      },
    );
  }

  /// 构建快速操作
  Widget _buildQuickActions() {
    return Column(
      children: [
        _buildActionButton(
          icon: CupertinoIcons.add_circled_solid,
          title: '添加任务',
          subtitle: '快速创建新任务',
          color: AppTheme.primaryColor,
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const AddTaskScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: AppTheme.spacingM),
        _buildActionButton(
          icon: CupertinoIcons.timer_fill,
          title: '开始专注',
          subtitle: '启动番茄钟计时',
          color: AppTheme.warningColor,
          onTap: () {
            // 切换到专注页面
            DefaultTabController.of(context).animateTo(2);
          },
        ),
        const SizedBox(height: AppTheme.spacingM),
        _buildActionButton(
          icon: CupertinoIcons.heart_fill,
          title: '健康记录',
          subtitle: '记录今日健康数据',
          color: AppTheme.successColor,
          onTap: () {
            // 切换到健康页面
            DefaultTabController.of(context).animateTo(3);
          },
        ),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
          boxShadow: [AppTheme.cardShadow],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Icon(
                icon,
                size: 28,
                color: color,
              ),
            ),
            const SizedBox(width: AppTheme.spacingL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeBody,
                      fontWeight: AppTheme.fontWeightSemibold,
                      color: AppTheme.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    subtitle,
                    style: AppTheme.captionStyle,
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: AppTheme.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 辅助方法 ====================

  /// 获取健康分数颜色
  Color _getHealthScoreColor(int score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.month}月${date.day}日';
  }
}
