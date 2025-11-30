import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

/// Empty state widget to show when there's no data
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? iconColor;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.iconColor,
    this.iconSize = 80,
  });

  const EmptyState.noData({
    super.key,
    this.title = '暂无数据',
    this.subtitle,
    this.actionText,
    this.onAction,
  })  : icon = Icons.inbox,
        iconColor = AppColors.textHint,
        iconSize = AppSpacing.iconXXLarge * 2;

  const EmptyState.noTasks({
    super.key,
    this.title = '还没有任务',
    this.subtitle = '点击下方按钮创建第一个任务吧！',
    this.actionText,
    this.onAction,
  })  : icon = Icons.task_alt,
        iconColor = AppColors.textHint,
        iconSize = AppSpacing.iconXXLarge * 2;

  const EmptyState.noStudyRooms({
    super.key,
    this.title = '暂无自习室',
    this.subtitle = '创建一个自习室开始学习吧！',
    this.actionText,
    this.onAction,
  })  : icon = Icons.meeting_room,
        iconColor = AppColors.textHint,
        iconSize = AppSpacing.iconXXLarge * 2;

  const EmptyState.noResults({
    super.key,
    this.title = '未找到结果',
    this.subtitle = '尝试调整搜索条件',
    this.actionText,
    this.onAction,
  })  : icon = Icons.search_off,
        iconColor = AppColors.textHint,
        iconSize = AppSpacing.iconXXLarge * 2;

  const EmptyState.networkError({
    super.key,
    this.title = '网络连接失败',
    this.subtitle = '请检查网络连接后重试',
    this.actionText = '重试',
    this.onAction,
  })  : icon = Icons.wifi_off,
        iconColor = AppColors.error,
        iconSize = AppSpacing.iconXXLarge * 2;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              title,
              style: AppTextStyles.headingSmall,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxxl,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
                  ),
                ),
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state widget for showing errors
class ErrorState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData icon;
  final Color iconColor;

  const ErrorState({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.icon = Icons.error_outline,
    this.iconColor = Colors.red,
  });

  const ErrorState.generic({
    super.key,
    this.subtitle,
    this.actionText = '重试',
    this.onAction,
  })  : title = '出错了',
        icon = Icons.error_outline,
        iconColor = AppColors.error;

  const ErrorState.network({
    super.key,
    this.subtitle = '请检查网络连接后重试',
    this.actionText = '重试',
    this.onAction,
  })  : title = '网络连接失败',
        icon = Icons.wifi_off,
        iconColor = AppColors.error;

  const ErrorState.notFound({
    super.key,
    this.subtitle = '请求的内容不存在',
    this.actionText = '返回',
    this.onAction,
  })  : title = '未找到',
        icon = Icons.search_off,
        iconColor = AppColors.warning;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppSpacing.iconXXLarge * 2,
              color: iconColor,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              title,
              style: AppTextStyles.headingSmall,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxxl,
                    vertical: AppSpacing.md,
                  ),
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
                  ),
                ),
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
