# Flutter依赖版本升级指南 (2025年11月更新)

## 快速概览

本指南提供了Time Schedule App所有重要依赖的最新版本信息、升级说明和潜在的破坏性变化。

---

## 一、核心依赖版本对比表

### 1.1 状态管理

| 包名 | 当前版本 | 推荐版本 | 重点变化 | 优先级 |
|-----|---------|---------|--------|--------|
| **provider** | ^6.1.1 | ^6.2.1 | 性能改进、Bug修复 | 中 |

**升级说明**:
```bash
# v6.1.1 -> v6.2.1
# 主要改进：
# - 更好的内存管理
# - 改进的dispose处理
# - 兼容最新Flutter版本
flutter pub upgrade provider
```

---

### 1.2 网络请求

| 包名 | 当前版本 | 推荐版本 | 重点变化 | 优先级 |
|-----|---------|---------|--------|--------|
| **dio** | ^5.4.0 | ^5.4.3 | Bug修复、安全更新 | 高 |
| **socket_io_client** | ^2.0.3+1 | ^2.0.3+1 | 已是最新 | 低 |

**Dio升级说明**:
```bash
# v5.4.0 -> v5.4.3
# 主要改进：
# - 修复特定HTTP方法的问题
# - 改进错误处理
# - WebSocket兼容性提升
flutter pub upgrade dio

# Dio 5.x 相比 4.x 的主要变化：
# 1. DioError改名为DioException
#    // 旧代码
#    catch (e) { if (e is DioError) { ... } }
#
#    // 新代码
#    catch (e) { if (e is DioException) { ... } }

# 2. 拦截器签名变化
#    // 旧代码
#    onRequest: (options, handler) => handler.next(options)
#
#    // 新代码
#    onRequest: (options, handler) async => handler.next(options)

# 3. Response类型参数化
#    Response<T> 而不是 Response
```

**Socket.IO Client 说明**:
```bash
# 版本 ^2.0.3+1 已是最新稳定版
# 当前无需升级，但需要注意以下最佳实践：

# 重要：避免重复事件
socket = IO.io(
  url,
  OptionBuilder()
    .setTransports(['websocket'])  // 必须！
    .disableAutoConnect()          // 必须！
    .build(),
);
socket.connect();  // 手动连接一次
```

---

### 1.3 本地存储和安全

| 包名 | 当前版本 | 推荐版本 | 重点变化 | 优先级 |
|-----|---------|---------|--------|--------|
| **flutter_secure_storage** | ^9.0.0 | ^9.2.2 | 安全加固、平台兼容性 | 高 |
| **shared_preferences** | ^2.2.2 | ^2.2.3 | Bug修复 | 低 |
| **hive** | ^2.2.3 | ^2.2.3 | 已是最新 | 低 |
| **hive_flutter** | ^1.1.0 | ^1.1.0 | 已是最新 | 低 |

**FlutterSecureStorage升级说明**:
```bash
# v9.0.0 -> v9.2.2
# 主要改进：
# - iOS Keychain兼容性改进
# - Android KeyStore安全性加强
# - 更好的错误处理
flutter pub upgrade flutter_secure_storage

# 升级后需要在Android中配置：
# android/app/build.gradle
android {
  ...
  buildTypes {
    release {
      ...
      // flutter_secure_storage要求
      debuggable false
    }
  }
}

# iOS配置（Podfile）：
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    # flutter_secure_storage要求
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'FLUTTER_FRAMEWORK_DIR=\${FLUTTER_ROOT}/bin/cache/artifacts/engine/ios',
      ]
    end
  end
end
```

---

### 1.4 工具和日志

| 包名 | 当前版本 | 推荐版本 | 重点变化 | 优先级 |
|-----|---------|---------|--------|--------|
| **logger** | ^2.0.2+1 | ^2.4.0 | 功能增强、性能改进 | 中 |
| **intl** | ^0.18.1 | ^0.19.0 | API改进、新语言支持 | 低 |
| **uuid** | ^4.3.3 | ^4.3.3 | 已是最新 | 低 |
| **equatable** | ^2.0.5 | ^2.0.5 | 已是最新 | 低 |
| **path_provider** | ^2.1.2 | ^2.1.2 | 已是最新 | 低 |

**Logger升级说明**:
```bash
# v2.0.2+1 -> v2.4.0
# 主要改进：
# - 新的日志级别控制
# - 更灵活的格式化选项
# - 性能优化
flutter pub upgrade logger

// 新增功能示例：
final logger = Logger(
  level: Level.debug,
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
```

**Intl升级说明**:
```bash
# v0.18.1 -> v0.19.0
# 主要改进：
# - 更好的国际化支持
# - 新的API便利方法
flutter pub upgrade intl

// 使用示例
import 'package:intl/intl.dart';

// 格式化日期
final formatter = DateFormat('yyyy-MM-dd', 'zh_CN');
final formatted = formatter.format(DateTime.now());

// 格式化数字
final numberFormatter = NumberFormat.currency(
  locale: 'zh_CN',
  symbol: '¥',
);
```

---

### 1.5 JSON序列化

| 包名 | 当前版本 | 推荐版本 | 重点变化 | 优先级 |
|-----|---------|---------|--------|--------|
| **json_annotation** | ^4.8.1 | ^4.9.0 | Bug修复 | 低 |
| **json_serializable** | ^6.7.1 | ^6.8.0 | Bug修复 | 低 |

**升级说明**:
```bash
# json_annotation和json_serializable必须同步升级
flutter pub upgrade json_annotation json_serializable

# 重新生成代码
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### 1.6 UI组件

| 包名 | 当前版本 | 推荐版本 | 重点变化 | 优先级 |
|-----|---------|---------|--------|--------|
| **table_calendar** | ^3.0.9 | ^3.0.9 | 已是最新 | 低 |
| **fl_chart** | ^0.66.0 | ^0.66.0 | 已是最新 | 低 |
| **cupertino_icons** | ^1.0.6 | ^1.0.8 | 图标库更新 | 低 |
| **flutter_local_notifications** | ^16.3.0 | ^16.3.0 | 已是最新 | 低 |
| **audioplayers** | ^5.2.1 | ^5.2.1 | 已是最新 | 低 |
| **cached_network_image** | ^3.3.1 | ^3.3.1 | 已是最新 | 低 |
| **flutter_svg** | ^2.0.9 | ^2.0.9 | 已是最新 | 低 |

---

## 二、升级步骤指南

### 步骤1: 备份当前状态
```bash
cd /home/user/TimeScheduleApp
git status
git commit -m "backup: current dependencies before upgrade"
```

### 步骤2: 逐个升级重要依赖

**首先升级核心依赖**:
```bash
# 更新Provider (状态管理)
flutter pub upgrade provider

# 更新Dio (网络请求)
flutter pub upgrade dio

# 更新FlutterSecureStorage (安全存储)
flutter pub upgrade flutter_secure_storage

# 更新Logger (日志)
flutter pub upgrade logger
flutter pub upgrade intl
```

### 步骤3: 获取所有依赖
```bash
flutter pub get
```

### 步骤4: 检查破坏性变化
```bash
# 运行代码分析
flutter analyze

# 查看所有警告
dart analyze lib
```

### 步骤5: 修复代码中的兼容性问题
```bash
# 重新生成代码（如果使用build_runner）
flutter pub run build_runner build --delete-conflicting-outputs
```

### 步骤6: 测试
```bash
# 运行单元测试
flutter test

# 构建应用验证
flutter build apk  # Android
flutter build ios  # iOS
```

### 步骤7: 提交更新
```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: upgrade dependencies to latest versions"
```

---

## 三、V1.0版本 vs V2.0版本的依赖差异

### V1.0 (本地应用) 依赖配置
```yaml
# V1.0只需要本地数据存储，无网络功能
dependencies:
  flutter:
    sdk: flutter

  # 本地存储
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.2

  # 状态管理（可选）
  provider: ^6.1.1

  # UI
  table_calendar: ^3.0.9
  fl_chart: ^0.66.0
  cupertino_icons: ^1.0.6

  # 工具
  intl: ^0.18.1
  uuid: ^4.3.3
  path_provider: ^2.1.2
  audioplayers: ^5.2.1
  flutter_local_notifications: ^16.3.0
```

### V2.0 (网络应用) 额外依赖
```yaml
# V2.0在V1.0基础上增加网络功能
dependencies:
  # ... V1.0所有依赖 ...

  # 额外的网络和安全依赖
  dio: ^5.4.0              # HTTP客户端
  socket_io_client: ^2.0.3+1  # WebSocket
  flutter_secure_storage: ^9.0.0  # 安全存储Token
  logger: ^2.0.2+1         # 网络日志
  json_annotation: ^4.8.1  # JSON序列化
  equatable: ^2.0.5        # 数据模型对比

dev_dependencies:
  json_serializable: ^6.7.1  # JSON代码生成
```

---

## 四、关键依赖升级前后对比

### Provider v6.1.1 -> v6.2.1

**兼容性**: 完全向后兼容
**无需修改代码** ✓

**改进点**:
```dart
// 性能改进示例
// v6.2.1 中的 Consumer 性能更好
Consumer<TaskProvider>(
  builder: (context, provider, child) {
    // 重建优化，减少不必要的重绘
    return ListView.builder(...);
  },
);
```

### Dio v5.4.0 -> v5.4.3

**兼容性**: 完全向后兼容
**可能需要修改的地方**: 错误处理

**升级代码示例**:
```dart
// 旧方式（v5.3及以下）
try {
  Response response = await dio.get('/api/data');
} on DioError catch (e) {
  print(e.message);
}

// 新方式（v5.4+）- DioError改为DioException
try {
  Response response = await dio.get('/api/data');
} on DioException catch (e) {
  print(e.message);  // 同样可用，但类名改了
}
```

### FlutterSecureStorage v9.0.0 -> v9.2.2

**兼容性**: 完全向后兼容
**无需修改代码** ✓

**安全性改进**:
```dart
// 推荐的初始化方式（v9.2.2）
final secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    keyCipherAlgorithm: KeyCipherAlgorithm.AES_ECB_OAEPwithSHA_256andMGF1Padding,
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
  ),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_this_device_this_app_only,
  ),
);
```

---

## 五、升级后的完整pubspec.yaml模板

### V2.0推荐配置 (适用于网络版本)

```yaml
name: timeschedule_app_v2
description: TimeScheduleApp v2.0 - 有温度的网络自习室
publish_to: 'none'
version: 2.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # 状态管理 (已更新)
  provider: ^6.2.1

  # 网络请求 (已更新)
  dio: ^5.4.3
  socket_io_client: ^2.0.3+1

  # 本地存储 (已更新)
  shared_preferences: ^2.2.3
  flutter_secure_storage: ^9.2.2

  # UI组件
  cupertino_icons: ^1.0.8
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.1

  # 工具类 (已更新)
  intl: ^0.19.0
  uuid: ^4.3.3
  logger: ^2.4.0

  # 数据模型
  json_annotation: ^4.9.0
  equatable: ^2.0.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.8
  json_serializable: ^6.8.0

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/icons/
```

---

## 六、升级风险评估

### 低风险升级
- provider: ^6.1.1 -> ^6.2.1 (纯性能和Bug修复)
- flutter_secure_storage: ^9.0.0 -> ^9.2.2 (兼容性强)
- logger: ^2.0.2+1 -> ^2.4.0 (可选依赖)
- intl: ^0.18.1 -> ^0.19.0 (向后兼容)

### 中风险升级
- dio: ^5.4.0 -> ^5.4.3 (需要检查错误处理代码)

### 注意事项
- 升级前备份project
- 逐个升级依赖，及时发现问题
- 重点检查网络请求和Token处理代码
- 在iOS和Android模拟器/真机上都进行测试

---

## 七、常见升级问题

### 问题1: "DioError is not defined"错误
**原因**: Dio升级到v5.4后，DioError改名为DioException
**解决**:
```dart
// 将所有
on DioError catch (e) { ... }
// 改为
on DioException catch (e) { ... }

// 或者使用更通用的方式
} catch (e) {
  if (e is DioException) {
    // 处理网络错误
  }
}
```

### 问题2: Flutter Secure Storage初始化失败
**原因**: Android KeyStore初始化错误
**解决**:
```bash
# 清理构建缓存
flutter clean

# 重新生成Android项目
cd android
./gradlew clean
cd ..

# 重新运行
flutter run
```

### 问题3: 构建失败 "build_runner"
**原因**: JSON序列化代码生成失败
**解决**:
```bash
# 删除旧生成的文件
flutter pub run build_runner clean

# 重新生成
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 八、升级检查清单

- [ ] 备份当前项目到Git分支
- [ ] 逐个升级核心依赖（provider, dio, flutter_secure_storage）
- [ ] 运行 `flutter analyze` 检查错误
- [ ] 检查所有网络请求代码（特别是错误处理）
- [ ] 检查Token管理代码
- [ ] 运行单元测试 `flutter test`
- [ ] 在Android模拟器测试
- [ ] 在iOS模拟器测试
- [ ] 在真机设备上测试网络功能
- [ ] 测试离线模式（断开网络）
- [ ] 测试Token刷新功能
- [ ] 测试WebSocket连接
- [ ] 提交升级日志到Git

---

## 附录：快速升级脚本

```bash
#!/bin/bash

echo "=== Flutter依赖升级脚本 ==="

# 备份
git status
read -p "请确保工作目录干净。继续升级吗? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

echo "正在升级核心依赖..."
flutter pub upgrade provider dio flutter_secure_storage logger intl

echo "正在升级JSON序列化工具..."
flutter pub upgrade json_annotation json_serializable

echo "获取所有依赖..."
flutter pub get

echo "分析代码..."
flutter analyze

echo "运行测试..."
flutter test

echo "清理构建..."
flutter clean

echo "构建APK验证..."
flutter build apk

echo "升级完成！"
echo "请运行: git diff pubspec.yaml pubspec.lock"
echo "检查变更后提交: git commit -m 'chore: upgrade dependencies'"
```

保存为 `upgrade.sh` 并执行:
```bash
chmod +x upgrade.sh
./upgrade.sh
```
