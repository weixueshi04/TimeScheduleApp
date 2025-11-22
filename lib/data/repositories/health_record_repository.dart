import 'package:focus_life/data/models/health_record_model.dart';
import 'package:focus_life/data/local/hive_service.dart';

/// 健康记录数据仓库 - 负责健康记录数据的CRUD操作
class HealthRecordRepository {
  final HiveService _hiveService = HiveService.instance;

  // ==================== 创建 Create ====================

  /// 添加健康记录
  Future<void> addRecord(HealthRecord record) async {
    final box = _hiveService.healthRecordsBox;
    final key = _getDateKey(record.date);
    await box.put(key, record);
  }

  /// 批量添加健康记录
  Future<void> addRecords(List<HealthRecord> records) async {
    final box = _hiveService.healthRecordsBox;
    final map = {for (var record in records) _getDateKey(record.date): record};
    await box.putAll(map);
  }

  // ==================== 读取 Read ====================

  /// 获取所有健康记录
  List<HealthRecord> getAllRecords() {
    return _hiveService.healthRecordsBox.values.toList();
  }

  /// 根据日期获取健康记录
  HealthRecord? getRecordByDate(DateTime date) {
    final key = _getDateKey(date);
    return _hiveService.healthRecordsBox.get(key);
  }

  /// 获取或创建今日健康记录
  Future<HealthRecord> getOrCreateTodayRecord() async {
    return await _hiveService.getOrCreateTodayHealthRecord();
  }

  /// 获取今日健康记录
  HealthRecord? getTodayRecord() {
    return _hiveService.todayHealthRecord;
  }

  /// 获取本周的健康记录
  List<HealthRecord> getThisWeekRecords() {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return getAllRecords().where((record) {
      return !record.date.isBefore(startOfWeek) &&
          !record.date.isAfter(endOfWeek);
    }).toList();
  }

  /// 获取本月的健康记录
  List<HealthRecord> getThisMonthRecords() {
    final now = DateTime.now();
    return getAllRecords().where((record) {
      return record.date.year == now.year &&
          record.date.month == now.month;
    }).toList();
  }

  /// 根据日期范围获取健康记录
  List<HealthRecord> getRecordsByDateRange(DateTime start, DateTime end) {
    return getAllRecords().where((record) {
      return !record.date.isBefore(start) && !record.date.isAfter(end);
    }).toList();
  }

  /// 获取最近N天的记录
  List<HealthRecord> getRecentRecords({int days = 7}) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));

    return getAllRecords().where((record) {
      return !record.date.isBefore(startDate);
    }).toList();
  }

  // ==================== 更新 Update ====================

  /// 更新健康记录
  Future<void> updateRecord(HealthRecord record) async {
    final key = _getDateKey(record.date);
    await _hiveService.healthRecordsBox.put(key, record);
  }

  /// 添加饮水记录
  Future<void> addWater({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    var record = getRecordByDate(targetDate);

    if (record == null) {
      record = HealthRecord(date: targetDate);
    }

    record.addWater();
    await updateRecord(record);
  }

  /// 添加用餐记录
  Future<void> addMeal(MealType type, {DateTime? date, String? notes}) async {
    final targetDate = date ?? DateTime.now();
    var record = getRecordByDate(targetDate);

    if (record == null) {
      record = HealthRecord(date: targetDate);
    }

    record.addMeal(type, notes: notes);
    await updateRecord(record);
  }

  /// 更新睡眠记录
  Future<void> updateSleep(DateTime bedTime, DateTime wakeTime) async {
    final targetDate = DateTime(wakeTime.year, wakeTime.month, wakeTime.day);
    var record = getRecordByDate(targetDate);

    if (record == null) {
      record = HealthRecord(date: targetDate);
    }

    record.updateSleep(bedTime, wakeTime);
    await updateRecord(record);
  }

  /// 添加运动记录
  Future<void> addExercise(int minutes, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    var record = getRecordByDate(targetDate);

    if (record == null) {
      record = HealthRecord(date: targetDate);
    }

    record.addExercise(minutes);
    await updateRecord(record);
  }

  /// 添加步数
  Future<void> addSteps(int count, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    var record = getRecordByDate(targetDate);

    if (record == null) {
      record = HealthRecord(date: targetDate);
    }

    record.addSteps(count);
    await updateRecord(record);
  }

  // ==================== 删除 Delete ====================

  /// 删除健康记录
  Future<void> deleteRecord(DateTime date) async {
    final key = _getDateKey(date);
    await _hiveService.healthRecordsBox.delete(key);
  }

  /// 批量删除记录
  Future<void> deleteRecords(List<DateTime> dates) async {
    final keys = dates.map(_getDateKey).toList();
    await _hiveService.healthRecordsBox.deleteAll(keys);
  }

  // ==================== 统计 Statistics ====================

  /// 获取今日健康评分
  int getTodayHealthScore() {
    final today = getTodayRecord();
    return today?.healthScore ?? 0;
  }

  /// 获取本周平均健康评分
  double getThisWeekAverageScore() {
    final records = getThisWeekRecords();
    if (records.isEmpty) return 0;

    final totalScore = records.fold(0, (sum, record) => sum + record.healthScore);
    return totalScore / records.length;
  }

  /// 获取本月平均健康评分
  double getThisMonthAverageScore() {
    final records = getThisMonthRecords();
    if (records.isEmpty) return 0;

    final totalScore = records.fold(0, (sum, record) => sum + record.healthScore);
    return totalScore / records.length;
  }

  /// 获取今日饮水次数
  int getTodayWaterCount() {
    final today = getTodayRecord();
    return today?.waterCount ?? 0;
  }

  /// 获取今日睡眠时长（分钟）
  int getTodaySleepMinutes() {
    final today = getTodayRecord();
    return today?.sleepMinutes ?? 0;
  }

  /// 获取今日运动时长（分钟）
  int getTodayExerciseMinutes() {
    final today = getTodayRecord();
    return today?.exerciseMinutes ?? 0;
  }

  /// 获取今日步数
  int getTodaySteps() {
    final today = getTodayRecord();
    return today?.steps ?? 0;
  }

  /// 获取本周总睡眠时长（分钟）
  int getThisWeekTotalSleepMinutes() {
    final records = getThisWeekRecords();
    return records.fold(0, (sum, record) => sum + record.sleepMinutes);
  }

  /// 获取本周平均睡眠时长（分钟）
  double getThisWeekAverageSleepMinutes() {
    final records = getThisWeekRecords();
    if (records.isEmpty) return 0;

    final totalSleep = getThisWeekTotalSleepMinutes();
    return totalSleep / records.length;
  }

  /// 获取本周总运动时长（分钟）
  int getThisWeekTotalExerciseMinutes() {
    final records = getThisWeekRecords();
    return records.fold(0, (sum, record) => sum + record.exerciseMinutes);
  }

  /// 获取本周总饮水次数
  int getThisWeekTotalWaterCount() {
    final records = getThisWeekRecords();
    return records.fold(0, (sum, record) => sum + record.waterCount);
  }

  /// 获取本周总步数
  int getThisWeekTotalSteps() {
    final records = getThisWeekRecords();
    return records.fold(0, (sum, record) => sum + record.steps);
  }

  /// 获取睡眠目标达成率（最近N天）
  double getSleepGoalAchievementRate({int days = 7}) {
    final records = getRecentRecords(days: days);
    if (records.isEmpty) return 0;

    final achievedCount = records.where((record) => record.isSleepGoalMet).length;
    return achievedCount / records.length;
  }

  /// 获取饮水目标达成率（最近N天）
  double getWaterGoalAchievementRate({int days = 7}) {
    final records = getRecentRecords(days: days);
    if (records.isEmpty) return 0;

    final achievedCount = records.where((record) => record.isWaterGoalMet).length;
    return achievedCount / records.length;
  }

  /// 获取运动目标达成率（最近N天）
  double getExerciseGoalAchievementRate({int days = 7}) {
    final records = getRecentRecords(days: days);
    if (records.isEmpty) return 0;

    final achievedCount = records.where((record) => record.isExerciseGoalMet).length;
    return achievedCount / records.length;
  }

  /// 获取每日健康评分趋势（最近N天）
  Map<DateTime, int> getDailyHealthScoreTrend({int days = 7}) {
    final now = DateTime.now();
    final result = <DateTime, int>{};

    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final record = getRecordByDate(date);
      result[date] = record?.healthScore ?? 0;
    }

    return result;
  }

  /// 获取每日睡眠时长趋势（最近N天，单位：小时）
  Map<DateTime, double> getDailySleepHoursTrend({int days = 7}) {
    final now = DateTime.now();
    final result = <DateTime, double>{};

    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final record = getRecordByDate(date);
      result[date] = (record?.sleepMinutes ?? 0) / 60.0;
    }

    return result;
  }

  /// 获取每日运动时长趋势（最近N天，单位：分钟）
  Map<DateTime, int> getDailyExerciseMinutesTrend({int days = 7}) {
    final now = DateTime.now();
    final result = <DateTime, int>{};

    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final record = getRecordByDate(date);
      result[date] = record?.exerciseMinutes ?? 0;
    }

    return result;
  }

  // ==================== 工具方法 ====================

  /// 生成日期键（格式：yyyy-MM-dd）
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 按日期排序记录（最新的在前）
  List<HealthRecord> sortRecordsByDate(List<HealthRecord> records) {
    return records..sort((a, b) => b.date.compareTo(a.date));
  }

  /// 按健康评分排序（最高的在前）
  List<HealthRecord> sortRecordsByScore(List<HealthRecord> records) {
    return records..sort((a, b) => b.healthScore.compareTo(a.healthScore));
  }
}
