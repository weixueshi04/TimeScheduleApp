import 'package:flutter/foundation.dart';
import 'package:focus_life/data/models/task_model.dart';
import 'package:focus_life/data/repositories/task_repository.dart';

/// 任务状态管理Provider
///
/// 负责管理任务的状态和业务逻辑
class TaskProvider with ChangeNotifier {
  final TaskRepository _repository = TaskRepository();

  // ==================== 状态变量 ====================

  /// 所有任务列表
  List<Task> _tasks = [];

  /// 当前筛选条件
  TaskFilter _currentFilter = TaskFilter.all;

  /// 当前排序方式
  TaskSortType _currentSort = TaskSortType.priority;

  /// 是否正在加载
  bool _isLoading = false;

  /// 搜索关键词
  String _searchQuery = '';

  // ==================== Getters ====================

  /// 获取所有任务
  List<Task> get tasks => _tasks;

  /// 获取筛选后的任务
  List<Task> get filteredTasks => _filterTasks();

  /// 获取当前筛选条件
  TaskFilter get currentFilter => _currentFilter;

  /// 获取当前排序方式
  TaskSortType get currentSort => _currentSort;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 搜索关键词
  String get searchQuery => _searchQuery;

  /// 获取未完成任务数量
  int get pendingCount => _repository.getPendingTasksCount();

  /// 获取已完成任务数量
  int get completedCount => _repository.getCompletedTasksCount();

  /// 获取总任务数量
  int get totalCount => _repository.getTotalTasksCount();

  /// 获取完成率
  double get completionRate => _repository.getCompletionRate();

  /// 获取今日任务
  List<Task> get todayTasks => _repository.getTodayTasks();

  /// 获取本周任务
  List<Task> get weekTasks => _repository.getThisWeekTasks();

  /// 获取超期任务
  List<Task> get overdueTasks => _repository.getOverdueTasks();

  /// 获取需要关注的任务
  List<Task> get focusTasks => _repository.getFocusTasks();

  // ==================== 初始化 ====================

  /// 加载所有任务
  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = _repository.getAllTasks();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 刷新任务列表
  Future<void> refresh() async {
    await loadTasks();
  }

  // ==================== CRUD操作 ====================

  /// 添加任务
  Future<void> addTask(Task task) async {
    await _repository.addTask(task);
    await loadTasks();
  }

  /// 更新任务
  Future<void> updateTask(Task task) async {
    await _repository.updateTask(task);
    await loadTasks();
  }

  /// 删除任务
  Future<void> deleteTask(String taskId) async {
    await _repository.deleteTask(taskId);
    await loadTasks();
  }

  /// 批量删除任务
  Future<void> deleteTasks(List<String> taskIds) async {
    await _repository.deleteTasks(taskIds);
    await loadTasks();
  }

  /// 删除所有已完成任务
  Future<void> deleteAllCompletedTasks() async {
    await _repository.deleteAllCompletedTasks();
    await loadTasks();
  }

  // ==================== 任务状态操作 ====================

  /// 切换任务完成状态
  Future<void> toggleTaskCompletion(String taskId) async {
    final task = _repository.getTaskById(taskId);
    if (task == null) return;

    if (task.isCompleted) {
      await _repository.markTaskAsIncomplete(taskId);
    } else {
      await _repository.markTaskAsCompleted(taskId);
    }

    await loadTasks();
  }

  /// 标记任务为完成
  Future<void> markTaskAsCompleted(String taskId) async {
    await _repository.markTaskAsCompleted(taskId);
    await loadTasks();
  }

  /// 标记任务为未完成
  Future<void> markTaskAsIncomplete(String taskId) async {
    await _repository.markTaskAsIncomplete(taskId);
    await loadTasks();
  }

  /// 更新任务实际用时
  Future<void> updateTaskActualTime(String taskId, int minutes) async {
    await _repository.updateTaskActualTime(taskId, minutes);
    await loadTasks();
  }

  // ==================== 筛选和排序 ====================

  /// 设置筛选条件
  void setFilter(TaskFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  /// 设置排序方式
  void setSort(TaskSortType sort) {
    _currentSort = sort;
    notifyListeners();
  }

  /// 设置搜索关键词
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// 清除搜索
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// 根据当前条件筛选任务
  List<Task> _filterTasks() {
    List<Task> result = _tasks;

    // 搜索筛选
    if (_searchQuery.isNotEmpty) {
      result = _repository.searchTasks(_searchQuery);
    }

    // 分类筛选
    switch (_currentFilter) {
      case TaskFilter.all:
        // 显示所有任务
        break;
      case TaskFilter.pending:
        result = result.where((task) => !task.isCompleted).toList();
        break;
      case TaskFilter.completed:
        result = result.where((task) => task.isCompleted).toList();
        break;
      case TaskFilter.today:
        result = _repository.getTodayTasks();
        break;
      case TaskFilter.week:
        result = _repository.getThisWeekTasks();
        break;
      case TaskFilter.overdue:
        result = result.where((task) => task.isOverdue).toList();
        break;
      case TaskFilter.focus:
        result = _repository.getFocusTasks();
        break;
      case TaskFilter.work:
        result = result.where((task) => task.category == TaskCategory.work).toList();
        break;
      case TaskFilter.study:
        result = result.where((task) => task.category == TaskCategory.study).toList();
        break;
      case TaskFilter.life:
        result = result.where((task) => task.category == TaskCategory.life).toList();
        break;
      case TaskFilter.health:
        result = result.where((task) => task.category == TaskCategory.health).toList();
        break;
    }

    // 排序
    switch (_currentSort) {
      case TaskSortType.priority:
        result = _repository.sortTasksByPriority(result);
        break;
      case TaskSortType.dueDate:
        result = _repository.sortTasksByDueDate(result);
        break;
      case TaskSortType.createdDate:
        result = _repository.sortTasksByCreatedDate(result);
        break;
      case TaskSortType.updatedDate:
        result = _repository.sortTasksByUpdatedDate(result);
        break;
    }

    return result;
  }

  // ==================== 统计信息 ====================

  /// 获取各分类的任务数量
  Map<TaskCategory, int> getCategoryStats() {
    return _repository.getTasksCountByCategory();
  }

  /// 获取各优先级的任务数量
  Map<TaskPriority, int> getPriorityStats() {
    return _repository.getTasksCountByPriority();
  }

  /// 获取平均时间效率
  double getAverageTimeEfficiency() {
    return _repository.getAverageTimeEfficiency();
  }
}

/// 任务筛选类型
enum TaskFilter {
  all, // 全部
  pending, // 未完成
  completed, // 已完成
  today, // 今天
  week, // 本周
  overdue, // 已超期
  focus, // 需要关注
  work, // 工作
  study, // 学习
  life, // 生活
  health, // 健康
}

/// 任务排序类型
enum TaskSortType {
  priority, // 按优先级
  dueDate, // 按截止日期
  createdDate, // 按创建时间
  updatedDate, // 按更新时间
}

/// 筛选类型扩展
extension TaskFilterExtension on TaskFilter {
  String get displayName {
    switch (this) {
      case TaskFilter.all:
        return '全部';
      case TaskFilter.pending:
        return '未完成';
      case TaskFilter.completed:
        return '已完成';
      case TaskFilter.today:
        return '今天';
      case TaskFilter.week:
        return '本周';
      case TaskFilter.overdue:
        return '已超期';
      case TaskFilter.focus:
        return '需关注';
      case TaskFilter.work:
        return '工作';
      case TaskFilter.study:
        return '学习';
      case TaskFilter.life:
        return '生活';
      case TaskFilter.health:
        return '健康';
    }
  }
}

/// 排序类型扩展
extension TaskSortTypeExtension on TaskSortType {
  String get displayName {
    switch (this) {
      case TaskSortType.priority:
        return '优先级';
      case TaskSortType.dueDate:
        return '截止日期';
      case TaskSortType.createdDate:
        return '创建时间';
      case TaskSortType.updatedDate:
        return '更新时间';
    }
  }
}
