import 'package:flutter/cupertino.dart';
import 'package:focus_life/core/themes/app_theme.dart';
import 'package:focus_life/data/models/task_model.dart';
import 'package:intl/intl.dart';

/// 任务列表项组件
///
/// 显示单个任务的信息，支持点击、切换完成状态、删除等操作
class TaskItemWidget extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const TaskItemWidget({
    super.key,
    required this.task,
    this.onTap,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoContextMenu(
      actions: _buildContextMenuActions(),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: _getBorderColor(),
            width: 1,
          ),
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                // 完成状态复选框
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted
                            ? task.category.color
                            : AppTheme.secondaryTextColor,
                        width: 2,
                      ),
                      color: task.isCompleted
                          ? task.category.color
                          : CupertinoColors.transparent,
                    ),
                    child: task.isCompleted
                        ? const Icon(
                            CupertinoIcons.checkmark,
                            size: 16,
                            color: CupertinoColors.white,
                          )
                        : null,
                  ),
                ),

                const SizedBox(width: AppTheme.spacingM),

                // 任务信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeBody,
                          fontWeight: AppTheme.fontWeightMedium,
                          color: task.isCompleted
                              ? AppTheme.secondaryTextColor
                              : AppTheme.primaryTextColor,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),

                      // 描述（如果有）
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          task.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.captionStyle.copyWith(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ],

                      const SizedBox(height: AppTheme.spacingS),

                      // 标签和信息
                      Wrap(
                        spacing: AppTheme.spacingS,
                        runSpacing: AppTheme.spacingXS,
                        children: [
                          // 分类标签
                          _buildTag(
                            icon: task.category.icon,
                            label: task.category.displayName,
                            color: task.category.color,
                          ),

                          // 优先级标签
                          if (task.priority == TaskPriority.high ||
                              task.priority == TaskPriority.urgent)
                            _buildTag(
                              icon: CupertinoIcons.flag_fill,
                              label: task.priority.displayName,
                              color: task.priority.color,
                            ),

                          // 截止日期
                          if (task.dueDate != null)
                            _buildTag(
                              icon: CupertinoIcons.calendar,
                              label: _formatDueDate(task.dueDate!),
                              color: task.isOverdue
                                  ? AppTheme.dangerColor
                                  : AppTheme.secondaryTextColor,
                            ),

                          // 预估时间
                          if (task.estimatedMinutes > 0)
                            _buildTag(
                              icon: CupertinoIcons.clock,
                              label: '${task.estimatedMinutes}分钟',
                              color: AppTheme.secondaryTextColor,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppTheme.spacingM),

                // 优先级指示器
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: task.priority.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建标签
  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: color,
              fontWeight: AppTheme.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取边框颜色
  Color _getBorderColor() {
    if (task.isOverdue) {
      return AppTheme.dangerColor.withOpacity(0.3);
    }
    if (task.isCompleted) {
      return AppTheme.successColor.withOpacity(0.3);
    }
    return CupertinoColors.separator;
  }

  /// 格式化截止日期
  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (taskDate == today) {
      return '今天';
    } else if (taskDate == tomorrow) {
      return '明天';
    } else if (taskDate.isBefore(today)) {
      final daysAgo = today.difference(taskDate).inDays;
      return '逾期$daysAgo天';
    } else {
      final daysLeft = taskDate.difference(today).inDays;
      if (daysLeft <= 7) {
        return '$daysLeft天后';
      } else {
        return DateFormat('MM-dd').format(dueDate);
      }
    }
  }

  /// 构建长按菜单
  List<Widget> _buildContextMenuActions() {
    return [
      CupertinoContextMenuAction(
        onPressed: () {
          Navigator.pop(CupertinoContextMenu.context);
          onToggle?.call();
        },
        trailingIcon: task.isCompleted
            ? CupertinoIcons.square
            : CupertinoIcons.checkmark_square,
        child: Text(task.isCompleted ? '标记未完成' : '标记完成'),
      ),
      CupertinoContextMenuAction(
        onPressed: () {
          Navigator.pop(CupertinoContextMenu.context);
          onTap?.call();
        },
        trailingIcon: CupertinoIcons.pencil,
        child: const Text('编辑'),
      ),
      CupertinoContextMenuAction(
        onPressed: () {
          Navigator.pop(CupertinoContextMenu.context);
          onDelete?.call();
        },
        isDestructiveAction: true,
        trailingIcon: CupertinoIcons.delete,
        child: const Text('删除'),
      ),
    ];
  }
}
