# 时间与健康管理APP - 完整开发计划

## 📋 项目概述

### 项目名称
**FocusLife** (专注生活)

### 项目定位
一款集时间管理、任务规划、专注力提升、健康管理于一体的个人效率助手APP，帮助用户告别拖延、提升效率、保持健康。

### 核心价值
- ✅ **防遗忘**：智能任务提醒，不再遗漏重要事项
- ⏰ **防拖延**：番茄钟+时间预算，严格控制时间分配
- 🎯 **提专注**：防分心机制+专注模式，沉浸式工作学习
- 💡 **给建议**：AI智能分析，提供效率提升建议
- 🏃 **保健康**：睡眠、饮食、运动全方位健康管理

---

## 🎨 功能架构设计

### 一期核心功能（MVP - 最小可行产品）

#### 1. 任务管理模块 📝
**功能清单：**
- [ ] 快速添加任务（语音输入/文字输入）
- [ ] 任务分类管理（工作、学习、生活、健康）
- [ ] 任务优先级设置（紧急重要四象限）
- [ ] 任务时间预估（预计完成时间）
- [ ] 子任务分解（大任务拆解为小步骤）
- [ ] 任务状态标记（待办、进行中、已完成、已延期）
- [ ] 重复任务设置（每日、每周、自定义）
- [ ] 任务截止日期提醒

**借鉴来源：**
- Microsoft To Do：简洁的任务管理+智能建议
- 滴答清单：灵活的分类系统
- Todoist：优先级管理

#### 2. 时间管理模块 ⏰
**功能清单：**
- [ ] 番茄钟计时器（25分钟工作+5分钟休息，可自定义）
- [ ] 时间预算功能（为任务分配时间额度）
- [ ] 时间记录与统计（实际耗时vs预计耗时）
- [ ] 日程日历视图（日/周/月视图）
- [ ] 时间分配分析（各类任务时间占比）
- [ ] 超时警告提醒（任务超出预算时间提醒）
- [ ] 日程冲突检测（避免时间重叠）

**借鉴来源：**
- Forest专注森林：番茄钟机制
- 番茄ToDo：时间统计与分析
- Google Calendar：日历视图

#### 3. 专注力提升模块 🎯
**功能清单：**
- [ ] 专注模式（防止切换其他APP，学霸模式）
- [ ] 白噪音/环境音（雨声、咖啡厅、森林等）
- [ ] 专注成就系统（种树/积分/勋章）
- [ ] 专注时长统计（每日/每周/每月）
- [ ] 专注排行榜（好友PK）
- [ ] 分心次数记录（离开APP次数统计）
- [ ] 专注目标设定（每日专注时长目标）

**借鉴来源：**
- Forest：种树游戏化机制
- 潮汐：白噪音+番茄钟
- Offtime：防分心功能

#### 4. 健康管理模块 🏃
**功能清单：**
- [ ] 睡眠提醒（设定就寝时间，提前30分钟提醒）
- [ ] 睡眠时长记录（手动记录睡眠起止时间）
- [ ] 久坐提醒（默认60分钟，可自定义）
- [ ] 饮水提醒（每2小时提醒喝水）
- [ ] 用餐提醒（早中晚餐时间提醒）
- [ ] 运动建议（根据久坐时长推荐运动）
- [ ] 健康数据统计（睡眠时长、饮水次数、运动时长）
- [ ] 健康目标设定（每日8小时睡眠、8杯水等）

**借鉴来源：**
- 小米运动：久坐提醒+健康统计
- Apple健康：全面的健康数据管理
- WearPro：喝水提醒+卡路里

#### 5. 智能建议模块 💡
**功能清单：**
- [ ] 任务效率分析（根据历史数据分析最佳工作时段）
- [ ] 拖延预警（识别经常延期的任务类型）
- [ ] 时间分配建议（根据任务重要性推荐时间分配）
- [ ] 休息建议（根据连续工作时长提醒休息）
- [ ] 每日总结报告（完成情况、时间利用率）
- [ ] 每周复盘报告（趋势分析、改进建议）

**借鉴来源：**
- RescueTime：时间使用分析
- Clockify：时间追踪与报告

---

### 二期扩展功能（增强版）

#### 6. 高级功能模块
- [ ] AI语音助手（语音添加任务、查询日程）
- [ ] 习惯养成追踪（21天/66天习惯打卡）
- [ ] 项目管理（多任务组合成项目）
- [ ] 团队协作（共享任务、进度同步）
- [ ] 目标管理（OKR目标设定与追踪）
- [ ] 云同步（多设备数据同步）
- [ ] 数据导出（PDF报告、Excel数据）
- [ ] 主题定制（多种UI主题切换）

---

## 🛠️ 技术架构设计

### 技术栈选型

#### 前端框架
- **Flutter 3.x**（跨平台开发）
- **Dart语言**

#### UI框架
- **Cupertino组件库**（iOS风格UI）
- 主要组件：
  - CupertinoNavigationBar（导航栏）
  - CupertinoTabBar（底部标签栏）
  - CupertinoButton（按钮）
  - CupertinoDatePicker（日期选择器）
  - CupertinoSwitch（开关）
  - CupertinoContextMenu（长按菜单）

#### 状态管理
- **Provider**（轻量级，适合中小型项目）
- 或 **Riverpod**（Provider的改进版，更现代）

#### 本地存储
- **Hive**（轻量级NoSQL数据库，性能优秀）
- **Shared Preferences**（简单配置存储）

#### 本地通知
- **flutter_local_notifications**（任务提醒、健康提醒）

#### 音频播放
- **audioplayers**（白噪音播放）

#### 日期时间处理
- **intl**（国际化与日期格式化）
- **table_calendar**（日历视图）

#### 图表统计
- **fl_chart**（数据可视化）

---

## 📂 项目目录结构

```
focus_life/
├── lib/
│   ├── main.dart                 # 应用入口
│   ├── app.dart                  # App根组件
│   │
│   ├── core/                     # 核心层
│   │   ├── constants/            # 常量定义
│   │   ├── themes/               # 主题配置
│   │   ├── utils/                # 工具类
│   │   └── services/             # 服务类
│   │
│   ├── data/                     # 数据层
│   │   ├── models/               # 数据模型
│   │   │   ├── task_model.dart
│   │   │   ├── focus_session_model.dart
│   │   │   └── health_record_model.dart
│   │   ├── repositories/         # 数据仓库
│   │   └── local/                # 本地存储
│   │
│   ├── business/                 # 业务逻辑层
│   │   ├── providers/            # 状态管理
│   │   └── services/             # 业务服务
│   │
│   └── presentation/             # 展示层
│       ├── screens/              # 页面
│       │   ├── home/             # 首页
│       │   ├── tasks/            # 任务管理
│       │   ├── focus/            # 专注模式
│       │   ├── health/           # 健康管理
│       │   └── statistics/       # 数据统计
│       ├── widgets/              # 通用组件
│       └── navigation/           # 路由导航
│
├── assets/                       # 资源文件
│   ├── images/                   # 图片
│   ├── icons/                    # 图标
│   └── sounds/                   # 音频文件
│
├── test/                         # 测试文件
└── pubspec.yaml                  # 依赖配置
```

---

## 📅 开发里程碑计划（12周完成MVP）

### 第1-2周：项目初始化与基础架构
**学习目标：**
- Flutter基础：Widget、State管理、生命周期
- Dart语法：异步编程、空安全
- Cupertino组件库使用

**开发任务：**
- [x] Week 1.1: 创建Flutter项目，配置开发环境
- [x] Week 1.2: 设计UI风格规范（颜色、字体、组件）
- [x] Week 1.3: 搭建项目目录结构
- [x] Week 1.4: 配置路由导航系统
- [x] Week 2.1: 设计数据模型（Task、FocusSession、HealthRecord）
- [x] Week 2.2: 集成Hive本地数据库
- [x] Week 2.3: 搭建Provider状态管理
- [x] Week 2.4: 完成底部TabBar导航框架

**学习资源：**
- Flutter官方文档：https://flutter.dev/docs
- Flutter中文网：https://flutter.cn
- Cupertino Design：https://developer.apple.com/design/human-interface-guidelines/

---

### 第3-4周：任务管理模块
**学习目标：**
- 表单处理与验证
- 列表渲染与状态更新
- 本地数据CRUD操作

**开发任务：**
- [x] Week 3.1: 设计任务列表UI（CupertinoListTile）
- [x] Week 3.2: 实现任务添加功能（弹窗表单）
- [x] Week 3.3: 实现任务编辑与删除
- [x] Week 3.4: 实现任务分类与筛选
- [x] Week 4.1: 实现任务优先级设置
- [x] Week 4.2: 实现子任务功能
- [x] Week 4.3: 实现任务拖拽排序
- [x] Week 4.4: 集成本地通知（任务提醒）

**核心代码示例：**
```dart
// Task数据模型
class Task {
  final String id;
  final String title;
  final String? description;
  final TaskCategory category;
  final TaskPriority priority;
  final DateTime? dueDate;
  final int estimatedMinutes;
  final bool isCompleted;
  final List<SubTask> subTasks;
  
  Task({...});
}

// TaskProvider状态管理
class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  
  void addTask(Task task) {
    _tasks.add(task);
    _saveToLocal();
    notifyListeners();
  }
  
  void updateTask(Task task) {...}
  void deleteTask(String id) {...}
}
```

---

### 第5-6周：时间管理模块
**学习目标：**
- Timer定时器使用
- 日历组件集成
- 日期时间处理

**开发任务：**
- [x] Week 5.1: 设计日历视图UI（table_calendar）
- [x] Week 5.2: 实现日程添加与展示
- [x] Week 5.3: 实现时间预算功能
- [x] Week 5.4: 设计时间分配分析图表
- [x] Week 6.1: 实现时间记录功能
- [x] Week 6.2: 实现超时警告机制
- [x] Week 6.3: 实现日程冲突检测
- [x] Week 6.4: 完成时间统计页面

---

### 第7-8周：专注力提升模块
**学习目标：**
- 计时器精确控制
- 音频播放处理
- 动画效果实现

**开发任务：**
- [x] Week 7.1: 设计番茄钟UI（圆形进度条）
- [x] Week 7.2: 实现番茄钟倒计时逻辑
- [x] Week 7.3: 实现专注模式（防切换）
- [x] Week 7.4: 集成白噪音音频播放
- [x] Week 8.1: 实现种树/积分成就系统
- [x] Week 8.2: 实现专注时长统计
- [x] Week 8.3: 设计专注数据可视化
- [x] Week 8.4: 完成专注排行榜（本地）

**核心代码示例：**
```dart
// 番茄钟计时器
class FocusTimer extends ChangeNotifier {
  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  
  void start() {
    _isRunning = true;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _onSessionComplete();
      }
    });
  }
  
  void pause() {...}
  void reset() {...}
}
```

---

### 第9-10周：健康管理模块
**学习目标：**
- 后台定时任务
- 通知权限管理
- 数据图表绘制

**开发任务：**
- [x] Week 9.1: 设计健康管理UI
- [x] Week 9.2: 实现睡眠提醒功能
- [x] Week 9.3: 实现久坐提醒（后台定时）
- [x] Week 9.4: 实现饮水提醒
- [x] Week 10.1: 实现用餐提醒
- [x] Week 10.2: 实现健康数据记录
- [x] Week 10.3: 设计健康数据统计图表
- [x] Week 10.4: 完成健康目标设定功能

---

### 第11周：智能建议模块
**学习目标：**
- 数据分析算法
- 图表库使用（fl_chart）
- 报告生成

**开发任务：**
- [x] Week 11.1: 实现任务效率分析算法
- [x] Week 11.2: 实现拖延预警功能
- [x] Week 11.3: 设计每日总结报告
- [x] Week 11.4: 设计每周复盘报告

---

### 第12周：测试优化与发布
**学习目标：**
- 单元测试编写
- 性能优化
- 应用打包发布

**开发任务：**
- [x] Week 12.1: 全功能测试与Bug修复
- [x] Week 12.2: 性能优化（启动速度、内存优化）
- [x] Week 12.3: UI细节优化与动画完善
- [x] Week 12.4: 编写用户文档，准备发布

---

## 🎨 UI设计规范（iOS风格）

### 颜色方案
```dart
// 主色调
const primaryColor = CupertinoColors.systemBlue;
const secondaryColor = CupertinoColors.systemGreen;

// 功能色
const successColor = CupertinoColors.systemGreen;
const warningColor = CupertinoColors.systemOrange;
const dangerColor = CupertinoColors.systemRed;

// 背景色
const backgroundColor = CupertinoColors.systemBackground;
const cardColor = CupertinoColors.secondarySystemBackground;

// 文字色
const primaryTextColor = CupertinoColors.label;
const secondaryTextColor = CupertinoColors.secondaryLabel;
```

### 字体规范
- 标题：SF Pro Display, 28pt, Bold
- 副标题：SF Pro Text, 20pt, Semibold
- 正文：SF Pro Text, 16pt, Regular
- 说明：SF Pro Text, 14pt, Regular
- 小字：SF Pro Text, 12pt, Regular

### 组件规范
- 圆角：8px（卡片）、12px（按钮）
- 间距：8px、12px、16px、24px
- 阴影：轻微阴影（elevation: 1）
- 按钮高度：44px（最小点击区域）

---

## 📊 数据库设计

### 表结构

#### tasks表（任务）
```dart
@HiveType(typeId: 0)
class Task {
  @HiveField(0) String id;
  @HiveField(1) String title;
  @HiveField(2) String? description;
  @HiveField(3) int category; // 0:工作, 1:学习, 2:生活, 3:健康
  @HiveField(4) int priority; // 0:低, 1:中, 2:高, 3:紧急
  @HiveField(5) DateTime? dueDate;
  @HiveField(6) int estimatedMinutes;
  @HiveField(7) int actualMinutes;
  @HiveField(8) bool isCompleted;
  @HiveField(9) DateTime createdAt;
  @HiveField(10) List<String> subTaskIds;
}
```

#### focus_sessions表（专注记录）
```dart
@HiveType(typeId: 1)
class FocusSession {
  @HiveField(0) String id;
  @HiveField(1) String? taskId;
  @HiveField(2) DateTime startTime;
  @HiveField(3) DateTime? endTime;
  @HiveField(4) int durationMinutes;
  @HiveField(5) int interruptionCount; // 分心次数
  @HiveField(6) bool completed;
}
```

#### health_records表（健康记录）
```dart
@HiveType(typeId: 2)
class HealthRecord {
  @HiveField(0) String id;
  @HiveField(1) DateTime date;
  @HiveField(2) int sleepMinutes;
  @HiveField(3) int waterCount; // 喝水次数
  @HiveField(4) int sitMinutes; // 久坐时长
  @HiveField(5) int exerciseMinutes; // 运动时长
  @HiveField(6) List<String> mealTimes; // 用餐时间记录
}
```

---

## 🚀 开发环境配置

### 必需工具
1. **Flutter SDK** (3.0+)
   - 下载：https://flutter.dev/docs/get-started/install
   
2. **IDE选择**
   - VS Code + Flutter插件（推荐新手）
   - Android Studio（功能更强大）

3. **iOS开发（macOS）**
   - Xcode 14+
   - CocoaPods

4. **Android开发**
   - Android SDK
   - Android模拟器

### 依赖包配置（pubspec.yaml）
```yaml
name: focus_life
description: 时间与健康管理APP

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  
  # 状态管理
  provider: ^6.1.1
  
  # 本地存储
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.2
  
  # UI组件
  table_calendar: ^3.0.9
  fl_chart: ^0.66.0
  
  # 通知
  flutter_local_notifications: ^16.3.0
  
  # 音频
  audioplayers: ^5.2.1
  
  # 工具类
  intl: ^0.18.1
  uuid: ^4.3.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  hive_generator: ^2.0.1
  build_runner: ^2.4.8
```

---

## 📝 开发规范与最佳实践

### 代码规范
1. **命名规范**
   - 文件名：小写下划线（task_list_screen.dart）
   - 类名：大驼峰（TaskListScreen）
   - 变量/方法：小驼峰（taskList, addTask()）
   - 常量：全大写下划线（MAX_TASK_COUNT）

2. **代码组织**
   - 一个文件一个类
   - 相关文件放在同一目录
   - 导入顺序：Dart SDK → Flutter → 第三方包 → 项目内部

3. **注释规范**
   ```dart
   /// 任务列表页面
   /// 
   /// 展示所有任务，支持添加、编辑、删除、完成等操作
   class TaskListScreen extends StatefulWidget {
     // ...
   }
   ```

### Git提交规范
```
feat: 新功能
fix: Bug修复
docs: 文档更新
style: 代码格式调整
refactor: 重构
test: 测试相关
chore: 构建/工具链相关

示例：
feat: 添加任务优先级筛选功能
fix: 修复番茄钟暂停后无法恢复的问题
```

### 测试策略
- 单元测试：核心业务逻辑（Provider、Service）
- Widget测试：关键组件
- 集成测试：主要用户流程

---

## 🎯 学习路径建议

### 阶段一：Flutter基础（第1-2周）
1. Dart语言基础
   - 变量、类型、函数
   - 面向对象（类、继承、接口）
   - 异步编程（Future、async/await）

2. Flutter核心概念
   - Widget树
   - StatelessWidget vs StatefulWidget
   - 生命周期
   - 布局系统（Row、Column、Stack等）

3. Cupertino组件
   - 常用组件使用
   - iOS设计规范

**推荐资源：**
- 《Flutter实战》（开源电子书）
- Flutter官方Codelabs
- YouTube: The Flutter Way频道

---

### 阶段二：状态管理与数据存储（第3-4周）
1. Provider使用
   - ChangeNotifier
   - Consumer
   - Provider.of

2. Hive数据库
   - TypeAdapter
   - CRUD操作
   - 数据迁移

**实战练习：**
- 完成任务管理模块
- 实现数据持久化

---

### 阶段三：高级功能（第5-10周）
1. 定时器与后台任务
2. 本地通知
3. 音频播放
4. 数据可视化

**实战项目：**
- 完成番茄钟功能
- 实现健康提醒

---

### 阶段四：优化与发布（第11-12周）
1. 性能优化
2. 用户体验优化
3. 打包发布

---

## 📌 关键技术难点与解决方案

### 1. 番茄钟后台运行
**问题：** APP切到后台时，计时器可能暂停

**解决方案：**
- 使用`WidgetsBindingObserver`监听APP生命周期
- 记录进入后台的时间戳
- 返回前台时计算时间差，更新UI

```dart
class FocusTimerProvider extends ChangeNotifier with WidgetsBindingObserver {
  DateTime? _pausedTime;
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _pausedTime != null) {
      final elapsed = DateTime.now().difference(_pausedTime!);
      _updateTimer(elapsed);
    }
  }
}
```

---

### 2. 本地通知权限处理
**问题：** iOS和Android通知权限请求不同

**解决方案：**
```dart
Future<void> requestNotificationPermission() async {
  if (Platform.isIOS) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  } else if (Platform.isAndroid) {
    // Android 13+需要请求权限
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
  }
}
```

---

### 3. 数据统计性能优化
**问题：** 大量数据查询导致卡顿

**解决方案：**
- 使用索引查询
- 分页加载
- 异步计算
- 缓存计算结果

```dart
Future<List<Task>> loadTasksByDate(DateTime date) async {
  return compute(_filterTasksByDate, {
    'tasks': _allTasks,
    'date': date,
  });
}

// 在独立Isolate中执行
static List<Task> _filterTasksByDate(Map<String, dynamic> params) {
  final tasks = params['tasks'] as List<Task>;
  final date = params['date'] as DateTime;
  return tasks.where((task) => 
    task.createdAt.year == date.year &&
    task.createdAt.month == date.month &&
    task.createdAt.day == date.day
  ).toList();
}
```

---

## 🔄 迭代优化计划

### 版本规划

#### v1.0 MVP版本（12周完成）
- ✅ 核心功能完整可用
- ✅ UI美观流畅
- ✅ 数据安全存储

#### v1.1 优化版本（+2周）
- 用户反馈收集
- Bug修复
- 性能优化
- 细节打磨

#### v2.0 增强版本（+4周）
- AI智能建议（基于历史数据）
- 云同步功能
- 数据导出
- 习惯养成模块

#### v3.0 社交版本（+6周）
- 好友系统
- 排行榜
- 团队协作
- 社区分享

---

## 💡 开发建议与注意事项

### 开发原则
1. **小步快跑**：每个功能分小步实现，及时测试
2. **用户至上**：始终站在用户角度思考交互
3. **性能优先**：确保APP流畅运行
4. **代码质量**：遵循规范，编写可维护代码

### 常见陷阱
❌ 一次性开发所有功能（容易半途而废）
❌ 忽视UI细节（影响用户体验）
❌ 不做错误处理（导致APP崩溃）
❌ 不写注释（后期维护困难）

✅ MVP优先，逐步迭代
✅ 注重交互细节和动画
✅ 完善的异常捕获和提示
✅ 清晰的代码注释和文档

---

## 📚 推荐学习资源

### 官方文档
- Flutter官网：https://flutter.dev
- Dart官网：https://dart.dev
- Flutter中文网：https://flutter.cn

### 视频教程
- YouTube: Flutter官方频道
- B站：Flutter实战教程
- 慕课网：Flutter从入门到精通

### 开源项目
- Flutter Gallery（官方示例）
- FlutterGo（组件库）
- Todo List开源项目

### 社区
- Flutter中文社区
- Stack Overflow
- GitHub Discussions

---

## 🎉 总结

这个项目不仅能解决你的实际问题，还能系统学习Flutter开发。建议：

1. **严格按照12周计划执行**，每周完成对应任务
2. **遇到问题先搜索**，90%的问题都有人遇到过
3. **多写代码多实践**，看100遍不如写1遍
4. **持续优化**，MVP完成后不断改进

记住：**完成比完美更重要！** 先做出来，再慢慢优化。

预祝项目成功！🚀

---

## 📞 下一步行动

1. **立即行动**：安装Flutter开发环境
2. **创建项目**：`flutter create focus_life`
3. **开始第一周任务**：搭建项目框架
4. **持续学习**：每天至少2小时编码
5. **定期复盘**：每周总结进度与问题

**相信自己，坚持12周，你一定能做出优秀的APP！**
