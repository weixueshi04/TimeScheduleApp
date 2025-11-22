import 'package:flutter/cupertino.dart';
import 'package:focus_life/core/themes/app_theme.dart';
import 'package:focus_life/core/constants/app_constants.dart';

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
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日概览',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSubtitle,
              fontWeight: AppTheme.fontWeightSemibold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewItem(
                icon: CupertinoIcons.check_mark_circled,
                label: '已完成',
                value: '0',
                color: AppTheme.successColor,
              ),
              _buildOverviewItem(
                icon: CupertinoIcons.timer,
                label: '专注时长',
                value: '0分钟',
                color: AppTheme.primaryColor,
              ),
              _buildOverviewItem(
                icon: CupertinoIcons.heart_fill,
                label: '健康分',
                value: '0',
                color: AppTheme.dangerColor,
              ),
            ],
          ),
        ],
      ),
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

  /// 构建快速操作
  Widget _buildQuickActions() {
    return Column(
      children: [
        _buildActionButton(
          icon: CupertinoIcons.add_circled_solid,
          title: '添加任务',
          subtitle: '快速创建新任务',
          onTap: () {
            // TODO: 导航到添加任务页面
            _showComingSoon();
          },
        ),
        const SizedBox(height: AppTheme.spacingM),
        _buildActionButton(
          icon: CupertinoIcons.timer_fill,
          title: '开始专注',
          subtitle: '启动番茄钟计时',
          onTap: () {
            // TODO: 导航到专注页面
            _showComingSoon();
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
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: AppTheme.primaryColor,
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

  /// 显示"即将推出"提示
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
