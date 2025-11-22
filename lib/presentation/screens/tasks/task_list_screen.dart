import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:focus_life/core/themes/app_theme.dart';
import 'package:focus_life/business/providers/task_provider.dart';
import 'package:focus_life/data/models/task_model.dart';
import 'package:focus_life/presentation/widgets/task_item_widget.dart';
import 'package:focus_life/presentation/screens/tasks/add_task_screen.dart';

/// 任务列表页面 - 显示和管理所有任务
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('任务'),
        backgroundColor: AppTheme.cardColor,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showFilterSheet,
          child: const Icon(CupertinoIcons.slider_horizontal_3),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _navigateToAddTask,
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: Consumer<TaskProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            }

            final tasks = provider.filteredTasks;

            if (tasks.isEmpty) {
              return _buildEmptyState(provider);
            }

            return Column(
              children: [
                // 统计信息栏
                _buildStatsBar(provider),

                // 当前筛选条件显示
                if (provider.currentFilter != TaskFilter.all)
                  _buildFilterChip(provider),

                // 任务列表
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      CupertinoSliverRefreshControl(
                        onRefresh: provider.refresh,
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final task = tasks[index];
                            return TaskItemWidget(
                              task: task,
                              onTap: () => _navigateToTaskDetail(task),
                              onToggle: () =>
                                  provider.toggleTaskCompletion(task.id),
                              onDelete: () => _confirmDelete(task),
                            );
                          },
                          childCount: tasks.length,
                        ),
                      ),
                      // 底部间距
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppTheme.spacingXXL),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(TaskProvider provider) {
    String message;
    IconData icon;

    switch (provider.currentFilter) {
      case TaskFilter.all:
        message = '还没有任务\n点击右上角添加第一个任务';
        icon = CupertinoIcons.list_bullet;
        break;
      case TaskFilter.pending:
        message = '太棒了！\n所有任务都已完成';
        icon = CupertinoIcons.check_mark_circled;
        break;
      case TaskFilter.completed:
        message = '还没有完成任何任务';
        icon = CupertinoIcons.checkmark_alt;
        break;
      case TaskFilter.today:
        message = '今天没有任务';
        icon = CupertinoIcons.calendar_today;
        break;
      default:
        message = '没有符合条件的任务';
        icon = CupertinoIcons.search;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppTheme.secondaryTextColor,
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.captionStyle.copyWith(
              fontSize: AppTheme.fontSizeBody,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计信息栏
  Widget _buildStatsBar(TaskProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingM,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.separatorColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: '全部',
            value: provider.totalCount.toString(),
            color: AppTheme.primaryColor,
          ),
          _buildStatItem(
            label: '未完成',
            value: provider.pendingCount.toString(),
            color: AppTheme.warningColor,
          ),
          _buildStatItem(
            label: '已完成',
            value: provider.completedCount.toString(),
            color: AppTheme.successColor,
          ),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: AppTheme.fontSizeTitle,
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

  /// 构建筛选条件芯片
  Widget _buildFilterChip(TaskProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
                vertical: AppTheme.spacingS,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.line_horizontal_3_decrease,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Text(
                    provider.currentFilter.displayName,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: AppTheme.fontWeightMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => provider.setFilter(TaskFilter.all),
            child: const Icon(
              CupertinoIcons.clear_circled,
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 显示筛选选项
  void _showFilterSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('筛选任务'),
        actions: [
          for (var filter in TaskFilter.values)
            CupertinoActionSheetAction(
              onPressed: () {
                context.read<TaskProvider>().setFilter(filter);
                Navigator.pop(context);
              },
              child: Text(filter.displayName),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  /// 导航到添加任务页面
  void _navigateToAddTask() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const AddTaskScreen(),
      ),
    );
  }

  /// 导航到任务详情页面
  void _navigateToTaskDetail(Task task) {
    // TODO: 实现任务详情页面
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(task.title),
        content: Text(task.description ?? '无描述'),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// 确认删除任务
  void _confirmDelete(Task task) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('删除任务'),
        content: Text('确定要删除"${task.title}"吗？'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              context.read<TaskProvider>().deleteTask(task.id);
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
