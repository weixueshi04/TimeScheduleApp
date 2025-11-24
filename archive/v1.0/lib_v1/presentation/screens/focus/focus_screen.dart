import 'package:flutter/cupertino.dart';
import 'package:focus_life/core/themes/app_theme.dart';

/// 专注页面 - 番茄钟和专注模式
class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('专注'),
        backgroundColor: AppTheme.cardColor,
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.timer,
                size: 80,
                color: AppTheme.secondaryTextColor,
              ),
              const SizedBox(height: AppTheme.spacingL),
              const Text(
                '专注模式',
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
