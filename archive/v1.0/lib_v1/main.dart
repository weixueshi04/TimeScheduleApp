import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:focus_life/core/themes/app_theme.dart';
import 'package:focus_life/core/constants/app_constants.dart';
import 'package:focus_life/presentation/navigation/main_tab_navigator.dart';
import 'package:focus_life/data/local/hive_service.dart';
import 'package:focus_life/business/providers/task_provider.dart';
import 'package:focus_life/business/providers/focus_session_provider.dart';
import 'package:focus_life/business/providers/health_record_provider.dart';
import 'package:focus_life/core/services/audio_service.dart';

/// 应用主入口
void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化Hive数据库
  await HiveService.instance.init();

  // 初始化音频服务
  await AudioService.instance.init();

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
    return MultiProvider(
      providers: [
        // 任务管理Provider
        ChangeNotifierProvider(
          create: (_) => TaskProvider()..loadTasks(),
        ),
        // 专注会话Provider
        ChangeNotifierProvider(
          create: (_) => FocusSessionProvider()..loadSettings(),
        ),
        // 健康记录Provider
        ChangeNotifierProvider(
          create: (_) => HealthRecordProvider()..loadTodayRecord(),
        ),
        // TODO: 添加其他Providers
        // ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: CupertinoApp(
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
      ),
    );
  }
}
