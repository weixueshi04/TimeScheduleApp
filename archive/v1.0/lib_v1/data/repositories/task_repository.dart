import 'package:focus_life/data/models/task_model.dart';
import 'package:focus_life/data/local/hive_service.dart';

/// 任务数据仓库 - 负责任务数据的CRUD操作
class TaskRepository {
  final HiveService _hiveService = HiveService.instance;

  // ==================== 创建 Create ====================

  /// 添加新任务
  Future<void> addTask(Task task) async {
    final box = _hiveService.tasksBox;
    await box.put(task.id, task);
  }

  /// 批量添加任务
  Future<void> addTasks(List<Task> tasks) async {
    final box = _hiveService.tasksBox;
    final map = {for (var task in tasks) task.id: task};
    await box.putAll(map);
  }

  // ==================== 读取 Read ====================

  /// 获取所有任务
  List<Task> getAllTasks() {
    return _hiveService.tasksBox.values.toList();
  }

  /// 根据ID获取任务
  Task? getTaskById(String id) {
    return _hiveService.tasksBox.get(id);
  }

  /// 获取未完成的任务
  List<Task> getPendingTasks() {
    return getAllTasks().where((task) => !task.isCompleted).toList();
  }

  /// 获取已完成的任务
  List<Task> getCompletedTasks() {
    return getAllTasks().where((task) => task.isCompleted).toList();
  }

  /// 根据分类获取任务
  List<Task> getTasksByCategory(TaskCategory category) {
    return getAllTasks().where((task) => task.category == category).toList();
  }

  /// 根据优先级获取任务
  List<Task> getTasksByPriority(TaskPriority priority) {
    return getAllTasks().where((task) => task.priority == priority).toList();
  }

  /// 获取今天的任务
  List<Task> getTodayTasks() {
    final today = DateTime.now();
    return getAllTasks().where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.year == today.year &&
          task.dueDate!.month == today.month &&
          task.dueDate!.day == today.day;
    }).toList();
  }

  /// 获取本周的任务
  List<Task> getThisWeekTasks() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return getAllTasks().where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.isAfter(startOfWeek) &&
          task.dueDate!.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
  }

  /// 获取已超期的任务
  List<Task> getOverdueTasks() {
    return getAllTasks().where((task) => task.isOverdue).toList();
  }

  /// 搜索任务（按标题或描述）
  List<Task> searchTasks(String query) {
    final lowerQuery = query.toLowerCase();
    return getAllTasks().where((task) {
      return task.title.toLowerCase().contains(lowerQuery) ||
          (task.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// 根据标签获取任务
  List<Task> getTasksByTag(String tag) {
    return getAllTasks().where((task) => task.tags.contains(tag)).toList();
  }

  // ==================== 更新 Update ====================

  /// 更新任务
  Future<void> updateTask(Task task) async {
    task.updatedAt = DateTime.now();
    await _hiveService.tasksBox.put(task.id, task);
  }

  /// 标记任务为完成
  Future<void> markTaskAsCompleted(String taskId) async {
    final task = getTaskById(taskId);
    if (task != null) {
      task.markAsCompleted();
    }
  }

  /// 标记任务为未完成
  Future<void> markTaskAsIncomplete(String taskId) async {
    final task = getTaskById(taskId);
    if (task != null) {
      task.markAsIncomplete();
    }
  }

  /// 更新任务的实际用时
  Future<void> updateTaskActualTime(String taskId, int minutes) async {
    final task = getTaskById(taskId);
    if (task != null) {
      task.updateActualTime(minutes);
    }
  }

  // ==================== 删除 Delete ====================

  /// 删除任务
  Future<void> deleteTask(String taskId) async {
    await _hiveService.tasksBox.delete(taskId);
  }

  /// 批量删除任务
  Future<void> deleteTasks(List<String> taskIds) async {
    await _hiveService.tasksBox.deleteAll(taskIds);
  }

  /// 删除所有已完成的任务
  Future<void> deleteAllCompletedTasks() async {
    await _hiveService.clearCompletedTasks();
  }

  // ==================== 统计 Statistics ====================

  /// 获取任务总数
  int getTotalTasksCount() {
    return getAllTasks().length;
  }

  /// 获取已完成任务数
  int getCompletedTasksCount() {
    return getCompletedTasks().length;
  }

  /// 获取未完成任务数
  int getPendingTasksCount() {
    return getPendingTasks().length;
  }

  /// 获取完成率
  double getCompletionRate() {
    final total = getTotalTasksCount();
    if (total == 0) return 0.0;
    return getCompletedTasksCount() / total;
  }

  /// 获取各分类的任务数量
  Map<TaskCategory, int> getTasksCountByCategory() {
    final tasks = getAllTasks();
    return {
      for (var category in TaskCategory.values)
        category: tasks.where((task) => task.category == category).length,
    };
  }

  /// 获取各优先级的任务数量
  Map<TaskPriority, int> getTasksCountByPriority() {
    final tasks = getAllTasks();
    return {
      for (var priority in TaskPriority.values)
        priority: tasks.where((task) => task.priority == priority).length,
    };
  }

  /// 获取平均时间效率
  double getAverageTimeEfficiency() {
    final completedTasks = getCompletedTasks().where((task) => task.actualMinutes > 0);
    if (completedTasks.isEmpty) return 100.0;

    final totalEfficiency = completedTasks.fold<double>(
      0.0,
      (sum, task) => sum + task.timeEfficiency,
    );

    return totalEfficiency / completedTasks.length;
  }

  // ==================== 排序 Sorting ====================

  /// 按优先级排序任务（高优先级在前）
  List<Task> sortTasksByPriority(List<Task> tasks) {
    return tasks..sort((a, b) => a.priority.sortOrder.compareTo(b.priority.sortOrder));
  }

  /// 按截止日期排序任务（最近的在前）
  List<Task> sortTasksByDueDate(List<Task> tasks) {
    return tasks
      ..sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
  }

  /// 按创建时间排序任务（最新的在前）
  List<Task> sortTasksByCreatedDate(List<Task> tasks) {
    return tasks..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 按更新时间排序任务（最近更新的在前）
  List<Task> sortTasksByUpdatedDate(List<Task> tasks) {
    return tasks..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // ==================== 高级查询 ====================

  /// 获取高优先级且未完成的任务
  List<Task> getHighPriorityPendingTasks() {
    return getPendingTasks().where((task) =>
        task.priority == TaskPriority.high ||
        task.priority == TaskPriority.urgent).toList();
  }

  /// 获取今天的高优先级任务
  List<Task> getTodayHighPriorityTasks() {
    final todayTasks = getTodayTasks();
    return todayTasks.where((task) =>
        task.priority == TaskPriority.high ||
        task.priority == TaskPriority.urgent).toList();
  }

  /// 获取需要关注的任务（未完成 + 高优先级或即将到期）
  List<Task> getFocusTasks() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    return getPendingTasks().where((task) {
      // 高优先级
      if (task.priority == TaskPriority.urgent ||
          task.priority == TaskPriority.high) {
        return true;
      }

      // 明天到期
      if (task.dueDate != null &&
          task.dueDate!.isBefore(tomorrow) &&
          task.dueDate!.isAfter(now)) {
        return true;
      }

      // 已超期
      if (task.isOverdue) {
        return true;
      }

      return false;
    }).toList();
  }
}
