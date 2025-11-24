import '../services/api_client.dart';
import '../models/health_record.dart';

class HealthRepository {
  final ApiClient _apiClient;

  HealthRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// 获取健康记录列表
  Future<List<HealthRecord>> getHealthRecords({int? days}) async {
    final queryParams = <String, dynamic>{};
    if (days != null) queryParams['days'] = days;

    final response = await _apiClient.get(
      '/health',
      queryParameters: queryParams,
    );
    final List data = response.data['data'];
    return data.map((json) => HealthRecord.fromJson(json)).toList();
  }

  /// 获取今日健康记录
  Future<HealthRecord?> getTodayRecord() async {
    final response = await _apiClient.get('/health/today');
    final data = response.data['data'];
    return data != null ? HealthRecord.fromJson(data) : null;
  }

  /// 创建或更新健康记录
  Future<HealthRecord> saveHealthRecord(HealthRecordRequest request) async {
    final response = await _apiClient.post(
      '/health',
      data: request.toJson(),
    );
    return HealthRecord.fromJson(response.data['data']);
  }

  /// 更新健康记录
  Future<HealthRecord> updateHealthRecord(
    int recordId,
    HealthRecordRequest request,
  ) async {
    final response = await _apiClient.put(
      '/health/$recordId',
      data: request.toJson(),
    );
    return HealthRecord.fromJson(response.data['data']);
  }

  /// 删除健康记录
  Future<void> deleteHealthRecord(int recordId) async {
    await _apiClient.delete('/health/$recordId');
  }

  /// 获取健康统计
  Future<HealthStats> getHealthStats({int? days}) async {
    final queryParams = <String, dynamic>{};
    if (days != null) queryParams['days'] = days;

    final response = await _apiClient.get(
      '/health/stats',
      queryParameters: queryParams,
    );
    return HealthStats.fromJson(response.data['data']);
  }
}
