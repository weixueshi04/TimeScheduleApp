import 'package:flutter/cupertino.dart';
import 'package:focus_life/core/themes/app_theme.dart';

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
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            _showComingSoon();
          },
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.list_bullet,
                size: 80,
                color: AppTheme.secondaryTextColor,
              ),
              const SizedBox(height: AppTheme.spacingL),
              const Text(
                '任务管理',
                style: AppTheme.titleStyle,
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                '功能开发中...',
                style: AppTheme.captionStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: const Text('功能正在开发中，敬请期待！'),
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
