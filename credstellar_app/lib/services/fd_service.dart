import 'package:dio/dio.dart';
import 'api_client.dart';

/// FD API service — create fixed deposits.
class FdService {
  final ApiClient _client = ApiClient();

  /// POST /fd/create
  /// Body: { amount, tenor_months }
  /// Returns: { fixed_deposit: {...}, credit: {...} }
  Future<Map<String, dynamic>> createFd({
    required double amount,
    required int tenorMonths,
  }) async {
    try {
      final response = await _client.dio.post('/fd/create', data: {
        'amount': amount,
        'tenor_months': tenorMonths,
      });

      final data = response.data;
      if (data['success'] == true) {
        return data['data'] as Map<String, dynamic>;
      }
      throw Exception(data['error'] ?? 'Failed to create FD.');
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  /// GET /fd/list
  /// Returns list of user's FDs
  Future<List<Map<String, dynamic>>> listFds() async {
    try {
      final response = await _client.dio.get('/fd/list');
      final data = response.data;
      if (data['success'] == true) {
        final fds = data['data']['fixed_deposits'] as List?;
        return List<Map<String, dynamic>>.from(fds ?? []);
      }
      throw Exception(data['error'] ?? 'Failed to fetch FDs.');
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    if (e.response?.data != null && e.response!.data is Map) {
      return e.response!.data['error']?.toString() ?? 'Request failed.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server.';
    }
    return 'Something went wrong. Please try again.';
  }
}
