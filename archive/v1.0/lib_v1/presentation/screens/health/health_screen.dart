import 'package:flutter/cupertino.dart';
import 'package:focus_life/core/themes/app_theme.dart';

/// 健康管理页面 - 睡眠、饮水、运动等健康数据
class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('健康'),
        backgroundColor: AppTheme.cardColor,
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.heart_fill,
                size: 80,
                color: AppTheme.secondaryTextColor,
              ),
              const SizedBox(height: AppTheme.spacingL),
              const Text(
                '健康管理',
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
}
