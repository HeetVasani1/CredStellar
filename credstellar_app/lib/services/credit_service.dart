import 'package:dio/dio.dart';
import 'api_client.dart';

/// Credit API service — fetches credit summary from backend.
class CreditService {
  final ApiClient _client = ApiClient();

  /// GET /credit/summary
  /// Returns { total_credit_limit, used_balance, available }
  Future<Map<String, dynamic>> getSummary() async {
    try {
      final response = await _client.dio.get('/credit/summary');
      final data = response.data;
      if (data['success'] == true) {
        return data['data'] as Map<String, dynamic>;
      }
      throw Exception(data['error'] ?? 'Failed to fetch credit summary.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server.');
      }
      throw Exception('Failed to load credit data.');
    }
  }
}
