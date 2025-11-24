# 🏗️ FocusLife 构建指南

## 前置要求

1. **Flutter SDK** (3.0+)
   ```bash
   flutter --version
   ```

2. **Dart SDK** (随Flutter一起安装)

## 📦 安装依赖

```bash
# 获取所有依赖包
flutter pub get
```

## 🔨 生成Hive Adapter代码

本项目使用Hive作为本地数据库，需要生成TypeAdapter代码。

### 一次性生成

```bash
# 生成所有.g.dart文件
flutter packages pub run build_runner build

# 或者删除冲突文件后重新生成
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Watch模式（自动检测变化）

```bash
# 监听文件变化，自动重新生成
flutter packages pub run build_runner watch
```

### 需要生成的文件

- `lib/data/models/task_model.g.dart`
- `lib/data/models/focus_session_model.g.dart`
- `lib/data/models/health_record_model.g.dart`
- `lib/data/models/user_settings_model.g.dart`

## 🎯 运行项目

### 调试模式

```bash
# 运行在连接的设备上
flutter run

# 指定设备
flutter devices  # 查看可用设备
flutter run -d <device-id>
```

### 发布模式

```bash
# Android APK
flutter build apk --release

# iOS IPA（需要macOS）
flutter build ios --release
```

## 🧪 运行测试

```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/models/task_model_test.dart

# 生成覆盖率报告
flutter test --coverage
```

## 🔍 代码检查

```bash
# 分析代码
flutter analyze

# 格式化代码
flutter format lib/

# 检查格式（不修改文件）
flutter format --set-exit-if-changed lib/
```

## 🛠️ 常见问题

### Q1: build_runner生成失败

```bash
# 清理缓存
flutter clean
flutter pub get

# 删除旧的生成文件
rm -rf lib/**/*.g.dart

# 重新生成
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Q2: Hive初始化失败

确保在`main()`中调用了：
```dart
await HiveService.instance.init();
```

### Q3: 依赖版本冲突

```bash
# 更新依赖
flutter pub upgrade

# 或者删除pubspec.lock后重新获取
rm pubspec.lock
flutter pub get
```

## 📝 开发工作流

1. 修改数据模型后：
   ```bash
   flutter packages pub run build_runner build
   ```

2. 提交代码前：
   ```bash
   flutter analyze
   flutter format lib/
   flutter test
   ```

3. 每次拉取代码后：
   ```bash
   flutter pub get
   flutter packages pub run build_runner build
   ```

## 🚀 发布检查清单

- [ ] 所有测试通过：`flutter test`
- [ ] 代码分析无错误：`flutter analyze`
- [ ] 代码格式正确：`flutter format lib/`
- [ ] Adapter代码已生成
- [ ] 版本号已更新（pubspec.yaml）
- [ ] 更新日志已编写
- [ ] 构建成功：`flutter build apk` 或 `flutter build ios`

## 📚 相关文档

- [Flutter官方文档](https://flutter.dev/docs)
- [Hive文档](https://docs.hivedb.dev/)
- [Flutter Provider文档](https://pub.dev/packages/provider)
- [项目开发计划](./时间健康管理APP开发计划.md)
- [核心数据模型设计](./核心数据模型设计.md)
