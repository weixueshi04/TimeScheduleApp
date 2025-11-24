import 'package:flutter/foundation.dart';
import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';

enum TaskLoadingStatus {
  initial,
  loading,
  loaded,
  error,
}

class TaskProvider with ChangeNotifier {
  final TaskRepository _repository;

  TaskProvider({required TaskRepository repository}) : _repository = repository;

  // State
  TaskLoadingStatus _status = TaskLoadingStatus.initial;
  List<Task> _tasks = [];
  List<Task> _todayTasks = [];
  TaskStats? _stats;
  String? _errorMessage;
  bool _isLoading = false;

  // Filter state
  String _filterStatus = 'all'; // all, pending, in_progress, completed
  String? _filterCategory;

  // Getters
  TaskLoadingStatus get status => _status;
  List<Task> get tasks => _filterTasks(_tasks);
  List<Task> get todayTasks => _todayTasks;
  TaskStats? get stats => _stats;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  String get filterStatus => _filterStatus;
  String? get filterCategory => _filterCategory;

  // Filter tasks
  List<Task> _filterTasks(List<Task> tasks) {
    return tasks.where((task) {
      // Filter by status
      if (_filterStatus != 'all') {
        if (_filterStatus == 'completed' && !task.isCompleted) return false;
        if (_filterStatus == 'pending' && task.status != 'pending') return false;
        if (_filterStatus == 'in_progress' && task.status != 'in_progress') {
          return false;
        }
      }

      // Filter by category
      if (_filterCategory != null && task.category != _filterCategory) {
        return false;
      }

      return true;
    }).toList();
  }

  // Set filter
  void setFilter({String? status, String? category}) {
    if (status != null) _filterStatus = status;
    if (category != null) {
      _filterCategory = category == 'all' ? null : category;
    }
    notifyListeners();
  }

  // Fetch all tasks
  Future<void> fetchTasks() async {
    _setStatus(TaskLoadingStatus.loading);
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _repository.getTasks();
      _setStatus(TaskLoadingStatus.loaded);
      _errorMessage = null;
    } catch (e) {
      _setStatus(TaskLoadingStatus.error);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch today's tasks
  Future<void> fetchTodayTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _todayTasks = await _repository.getTodayTasks();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch stats
  Future<void> fetchStats() async {
    try {
      _stats = await _repository.getTaskStats();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  // Create task
  Future<Task?> createTask(CreateTaskRequest request) async {
    _isLoading = true;
    notifyListeners();

    try {
      final task = await _repository.createTask(request);
      _tasks.insert(0, task);
      _errorMessage = null;
      notifyListeners();
      return task;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update task
  Future<bool> updateTask(int taskId, UpdateTaskRequest request) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedTask = await _repository.updateTask(taskId, request);

      // Update in list
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete task
  Future<bool> deleteTask(int taskId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.deleteTask(taskId);

      // Remove from list
      _tasks.removeWhere((t) => t.id == taskId);
      _todayTasks.removeWhere((t) => t.id == taskId);

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle task completion
  Future<bool> toggleTaskCompletion(int taskId, bool isCompleted) async {
    try {
      final updatedTask = isCompleted
          ? await _repository.completeTask(taskId)
          : await _repository.uncompleteTask(taskId);

      // Update in list
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }

      // Update in today's tasks
      final todayIndex = _todayTasks.indexWhere((t) => t.id == taskId);
      if (todayIndex != -1) {
        _todayTasks[todayIndex] = updatedTask;
      }

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Helper to set status
  void _setStatus(TaskLoadingStatus status) {
    _status = status;
    notifyListeners();
  }

  // Get tasks by category
  List<Task> getTasksByCategory(String category) {
    return _tasks.where((task) => task.category == category).toList();
  }

  // Get completed tasks count
  int get completedTasksCount {
    return _tasks.where((task) => task.isCompleted).length;
  }

  // Get pending tasks count
  int get pendingTasksCount {
    return _tasks.where((task) => !task.isCompleted).length;
  }

  // Get overdue tasks count
  int get overdueTasksCount {
    return _tasks.where((task) => task.isOverdue).length;
  }
}
