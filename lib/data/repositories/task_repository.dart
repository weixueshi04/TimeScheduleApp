import '../services/api_client.dart';
import '../models/task.dart';

class TaskRepository {
  final ApiClient _apiClient;

  TaskRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// 获取任务列表
  Future<List<Task>> getTasks({
    String? status,
    String? category,
    bool? isCompleted,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (category != null) queryParams['category'] = category;
    if (isCompleted != null) queryParams['isCompleted'] = isCompleted;

    final response = await _apiClient.get('/tasks', queryParameters: queryParams);
    final List data = response.data['data'];
    return data.map((json) => Task.fromJson(json)).toList();
  }

  /// 获取任务详情
  Future<Task> getTaskDetail(int taskId) async {
    final response = await _apiClient.get('/tasks/$taskId');
    return Task.fromJson(response.data['data']);
  }

  /// 创建任务
  Future<Task> createTask(CreateTaskRequest request) async {
    final response = await _apiClient.post(
      '/tasks',
      data: request.toJson(),
    );
    return Task.fromJson(response.data['data']);
  }

  /// 更新任务
  Future<Task> updateTask(int taskId, UpdateTaskRequest request) async {
    final response = await _apiClient.put(
      '/tasks/$taskId',
      data: request.toJson(),
    );
    return Task.fromJson(response.data['data']);
  }

  /// 删除任务
  Future<void> deleteTask(int taskId) async {
    await _apiClient.delete('/tasks/$taskId');
  }

  /// 完成任务
  Future<Task> completeTask(int taskId) async {
    final response = await _apiClient.put('/tasks/$taskId/complete');
    return Task.fromJson(response.data['data']);
  }

  /// 取消完成任务
  Future<Task> uncompleteTask(int taskId) async {
    final response = await _apiClient.put('/tasks/$taskId/uncomplete');
    return Task.fromJson(response.data['data']);
  }

  /// 获取今日任务
  Future<List<Task>> getTodayTasks() async {
    final response = await _apiClient.get('/tasks/today');
    final List data = response.data['data'];
    return data.map((json) => Task.fromJson(json)).toList();
  }

  /// 获取任务统计
  Future<TaskStats> getTaskStats() async {
    final response = await _apiClient.get('/tasks/stats');
    return TaskStats.fromJson(response.data['data']);
  }
}
