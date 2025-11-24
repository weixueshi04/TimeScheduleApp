import 'package:flutter/cupertino.dart';
import 'package:focus_life/core/themes/app_theme.dart';

/// 统计页面 - 数据分析和智能建议
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('统计'),
        backgroundColor: AppTheme.cardColor,
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.chart_bar,
                size: 80,
                color: AppTheme.secondaryTextColor,
              ),
              const SizedBox(height: AppTheme.spacingL),
              const Text(
                '数据统计',
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
