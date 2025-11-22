import 'package:flutter/cupertino.dart';
import 'package:focus_life/core/themes/app_theme.dart';
import 'package:focus_life/presentation/screens/home/home_screen.dart';
import 'package:focus_life/presentation/screens/tasks/task_list_screen.dart';
import 'package:focus_life/presentation/screens/focus/focus_screen.dart';
import 'package:focus_life/presentation/screens/health/health_screen.dart';
import 'package:focus_life/presentation/screens/statistics/statistics_screen.dart';

/// 主导航 - TabBar底部导航栏
///
/// 包含5个主要页面：
/// 1. 首页 - 今日概览
/// 2. 任务 - 任务管理
/// 3. 专注 - 番茄钟和专注模式
/// 4. 健康 - 健康管理
/// 5. 统计 - 数据分析
class MainTabNavigator extends StatelessWidget {
  const MainTabNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: AppTheme.cardColor,
        activeColor: AppTheme.primaryColor,
        inactiveColor: AppTheme.secondaryTextColor,
        height: AppTheme.tabBarHeight,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            activeIcon: Icon(CupertinoIcons.house_fill),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.list_bullet),
            activeIcon: Icon(CupertinoIcons.list_bullet),
            label: '任务',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.timer),
            activeIcon: Icon(CupertinoIcons.timer_fill),
            label: '专注',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.heart),
            activeIcon: Icon(CupertinoIcons.heart_fill),
            label: '健康',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar),
            activeIcon: Icon(CupertinoIcons.chart_bar_fill),
            label: '统计',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        late final Widget screen;

        switch (index) {
          case 0:
            screen = const HomeScreen();
            break;
          case 1:
            screen = const TaskListScreen();
            break;
          case 2:
            screen = const FocusScreen();
            break;
          case 3:
            screen = const HealthScreen();
            break;
          case 4:
            screen = const StatisticsScreen();
            break;
          default:
            screen = const HomeScreen();
        }

        return CupertinoTabView(
          builder: (context) => screen,
        );
      },
    );
  }
}
