import 'package:flutter/foundation.dart';
import 'package:focus_life/data/models/health_record_model.dart';
import 'package:focus_life/data/repositories/health_record_repository.dart';
import 'package:focus_life/data/local/hive_service.dart';

/// 健康记录状态管理Provider
///
/// 负责管理健康数据的状态和业务逻辑
class HealthRecordProvider with ChangeNotifier {
  final HealthRecordRepository _repository = HealthRecordRepository();

  // ==================== 状态变量 ====================

  /// 今日健康记录
  HealthRecord? _todayRecord;

  /// 历史记录列表
  List<HealthRecord> _records = [];

  /// 是否正在加载
  bool _isLoading = false;

  /// 显示的天数范围(用于趋势图)
  int _daysRange = 7;

  // ==================== Getters ====================

  HealthRecord? get todayRecord => _todayRecord;
  List<HealthRecord> get records => _records;
  bool get isLoading => _isLoading;
  int get daysRange => _daysRange;

  /// 今日健康分数
  int get todayHealthScore => _todayRecord?.healthScore ?? 0;

  /// 今日睡眠时长(分钟)
  int get todaySleepMinutes => _todayRecord?.sleepMinutes ?? 0;

  /// 今日睡眠时长(小时)
  double get todaySleepHours => todaySleepMinutes / 60.0;

  /// 今日饮水次数
  int get todayWaterCount => _todayRecord?.waterCount ?? 0;

  /// 今日用餐次数
  int get todayMealCount => _todayRecord?.mealRecords.length ?? 0;

  /// 今日运动时长(分钟)
  int get todayExerciseMinutes => _todayRecord?.exerciseMinutes ?? 0;

  /// 今日体重
  double? get todayWeight => _todayRecord?.weight;

  /// 本周平均健康分数
  double get weeklyAverageScore => _repository.getAverageHealthScore(days: 7);

  /// 本周平均睡眠时长(分钟)
  double get weeklyAverageSleep => _repository.getAverageSleepMinutes(days: 7);

  /// 本周饮水达标率
  double get weeklyWaterGoalRate => _repository.getWaterGoalAchievementRate(days: 7);

  /// 本周睡眠达标率
  double get weeklySleepGoalRate => _repository.getSleepGoalAchievementRate(days: 7);

  /// 本周运动达标率
  double get weeklyExerciseGoalRate => _repository.getExerciseGoalAchievementRate(days: 7);

  // ==================== 初始化 ====================

  /// 加载今日记录
  Future<void> loadTodayRecord() async {
    _isLoading = true;
    notifyListeners();

    try {
      _todayRecord = await _repository.getOrCreateTodayRecord();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 加载历史记录
  Future<void> loadRecords({int days = 30}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      _records = _repository.getRecordsByDateRange(startDate, endDate);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    await Future.wait([
      loadTodayRecord(),
      loadRecords(days: _daysRange),
    ]);
  }

  // ==================== 睡眠管理 ====================

  /// 更新睡眠时间
  Future<void> updateSleep({
    required int minutes,
    DateTime? bedTime,
    DateTime? wakeUpTime,
  }) async {
    if (_todayRecord == null) {
      await loadTodayRecord();
    }

    _todayRecord!.sleepMinutes = minutes;
    if (bedTime != null) _todayRecord!.bedTime = bedTime;
    if (wakeUpTime != null) _todayRecord!.wakeUpTime = wakeUpTime;

    await _repository.updateHealthRecord(_todayRecord!);
    notifyListeners();
  }

  /// 设置就寝时间
  Future<void> setBedTime(DateTime time) async {
    if (_todayRecord == null) {
      await loadTodayRecord();
    }

    _todayRecord!.bedTime = time;
    await _repository.updateHealthRecord(_todayRecord!);
    notifyListeners();
  }

  /// 设置起床时间(自动计算睡眠时长)
  Future<void> setWakeUpTime(DateTime time) async {
    if (_todayRecord == null) {
      await loadTodayRecord();
    }

    _todayRecord!.wakeUpTime = time;

    // 如果有就寝时间,自动计算睡眠时长
    if (_todayRecord!.bedTime != null) {
      final duration = time.difference(_todayRecord!.bedTime!);
      _todayRecord!.sleepMinutes = duration.inMinutes;
    }

    await _repository.updateHealthRecord(_todayRecord!);
    notifyListeners();
  }

  // ==================== 饮水管理 ====================

  /// 增加饮水次数
  Future<void> addWater() async {
    if (_todayRecord == null) {
      await loadTodayRecord();
    }

    _todayRecord!.waterCount++;
    await _repository.updateHealthRecord(_todayRecord!);
    notifyListeners();
  }

  /// 减少饮水次数
  Future<void> removeWater() async {
    if (_todayRecord == null) {
      await loadTodayRecord();
    }

    if (_todayRecord!.waterCount > 0) {
      _todayRecord!.waterCount--;
      await _repository.updateHealthRecord(_todayRecord!);
      notifyListeners();
    }
  }

  /// 设置饮水次数
  Future<void> setWaterCount(int count) async {
    if (_todayRecord == null) {
      await loadTodayRecord();
    }

    _todayRecord!.waterCount = count.clamp(0, 20);
    await _repository.updateHealthRecord(_todayRecord!);
    notifyListeners();
  }

  // ==================== 用餐管理 ====================

  /// 添加用餐记录
  Future<void> addMeal(MealRecord meal) async {
    if (_todayRecord == null) {
      await loadTodayRecord();
    }

    _todayRecord!.mealRecords.add(meal);
    await _repository.updateHealthRecord(_todayRecord!);
    notifyListeners();
  }

  /// 删除用餐记录
  Future<void> removeMeal(int index) async {
    if (_todayRecord == null) return;

    if (index >= 0 && index < _todayRecord!.mealRecords.length) {
      _todayRecord!.mealRecords.removeAt(index);
      await _repository.updateHealthRecord(_todayRecord!);
      notifyListeners();
    }
  }

  /// 更新用餐记录
  Future<void> updateMeal(int index, MealRecord meal) async {
    if (_todayRecord == null) return;

    if (index >= 0 && index < _todayRecord!.mealRecords.length) {
      _todayRecord!.mealRecords[index] = meal;
      await _repository.updateHealthRecord(_todayRecord!);
      notifyListeners();
    }
  }

  // ==================== 运动管理 ====================

  /// 更新运动时长
  Future<void> updateExercise({
    required int minutes,
    String? type,
    String? notes,
  }) async {
    if (_todayRecord == null) {
      await loadTodayRecord();
    }

    _todayRecord!.exerciseMinutes = minutes;
    if (type != null) _todayRecord!.exerciseType = type;
    if (notes != null) _todayRecord!.exerciseNotes = notes;

    await _repository.updateHealthRecord(_todayRecord!);
    notifyListeners();
  }

  /// 增加运动时长
  Future<void> addExerciseMinutes(int minutes) async {
    if (_todayRecord == null) {
      await loadTodayRecord();
    }

    _todayRecord!.exerciseMinutes += minutes;
    await _repository.updateHealthRecord(_todayRecord!);
    notifyListeners();
  }

  // ==================== 体重管理 ====================

  /// 更新体重
  Future<void> updateWeight(double weight) async {
    if (_todayRecord == null) {
      await loadTodayRecord();
    }

    _todayRecord!.weight = weight;
    await _repository.updateHealthRecord(_todayRecord!);
    notifyListeners();
  }

  /// 获取体重趋势
  Map<DateTime, double> getWeightTrend({int days = 30}) {
    return _repository.getWeightTrend(days: days);
  }

  // ==================== 心情管理 ====================

  /// 更新心情
  Future<void> updateMood(int mood) async {
    if (_todayRecord == null) {
      await loadTodayRecord();
    }

    _todayRecord!.mood = mood.clamp(1, 5);
    await _repository.updateHealthRecord(_todayRecord!);
    notifyListeners();
  }

  /// 添加心情备注
  Future<void> updateMoodNotes(String notes) async {
    if (_todayRecord == null) {
      await loadTodayRecord();
    }

    _todayRecord!.moodNotes = notes;
    await _repository.updateHealthRecord(_todayRecord!);
    notifyListeners();
  }

  // ==================== 统计分析 ====================

  /// 获取健康分数趋势
  Map<DateTime, int> getHealthScoreTrend({int days = 7}) {
    return _repository.getDailyHealthScoreTrend(days: days);
  }

  /// 获取睡眠趋势
  Map<DateTime, int> getSleepTrend({int days = 7}) {
    return _repository.getDailySleepMinutesTrend(days: days);
  }

  /// 获取饮水趋势
  Map<DateTime, int> getWaterTrend({int days = 7}) {
    return _repository.getDailyWaterCountTrend(days: days);
  }

  /// 获取运动趋势
  Map<DateTime, int> getExerciseTrend({int days = 7}) {
    return _repository.getDailyExerciseMinutesTrend(days: days);
  }

  /// 获取各指标达标情况
  Map<String, double> getGoalAchievementRates({int days = 7}) {
    return {
      'sleep': _repository.getSleepGoalAchievementRate(days: days),
      'water': _repository.getWaterGoalAchievementRate(days: days),
      'exercise': _repository.getExerciseGoalAchievementRate(days: days),
    };
  }

  /// 设置显示天数范围
  void setDaysRange(int days) {
    _daysRange = days;
    loadRecords(days: days);
  }

  // ==================== 目标设置 ====================

  /// 获取用户目标设置
  int get sleepGoalMinutes => HiveService.instance.settings.dailySleepGoalMinutes;
  int get waterGoalCount => HiveService.instance.settings.dailyWaterGoalCount;
  int get exerciseGoalMinutes => HiveService.instance.settings.dailyExerciseGoalMinutes;

  /// 设置睡眠目标
  void setSleepGoal(int minutes) {
    HiveService.instance.settings.dailySleepGoalMinutes = minutes;
    HiveService.instance.settings.save();
    notifyListeners();
  }

  /// 设置饮水目标
  void setWaterGoal(int count) {
    HiveService.instance.settings.dailyWaterGoalCount = count;
    HiveService.instance.settings.save();
    notifyListeners();
  }

  /// 设置运动目标
  void setExerciseGoal(int minutes) {
    HiveService.instance.settings.dailyExerciseGoalMinutes = minutes;
    HiveService.instance.settings.save();
    notifyListeners();
  }
}
