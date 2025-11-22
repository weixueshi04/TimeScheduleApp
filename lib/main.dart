import 'package:flutter/cupertino.dart';
import 'package:focus_life/core/themes/app_theme.dart';
import 'package:focus_life/core/constants/app_constants.dart';
import 'package:focus_life/presentation/navigation/main_tab_navigator.dart';

/// 应用主入口
void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: 初始化Hive数据库
  // await HiveService.init();

  // TODO: 初始化本地通知
  // await NotificationService.init();

  // 运行应用
  runApp(const FocusLifeApp());
}

/// FocusLife应用根组件
class FocusLifeApp extends StatelessWidget {
  const FocusLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      home: const MainTabNavigator(),
      debugShowCheckedModeBanner: false,
      // 设置本地化
      localizationsDelegates: const [
        DefaultCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'), // 中文
        Locale('en', 'US'), // 英文
      ],
    );
  }
}
