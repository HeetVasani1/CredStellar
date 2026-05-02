import 'package:dio/dio.dart';
import 'api_client.dart';

/// Transaction API service — list + details.
class TransactionService {
  final ApiClient _client = ApiClient();

  /// GET /transactions
  /// Backend returns: { success, data: { transactions: [...], count } }
  Future<List<Map<String, dynamic>>> getAll() async {
    try {
      final response = await _client.dio.get('/transactions');
      final data = response.data;
      if (data['success'] == true) {
        // Backend wraps in { transactions, count }
        final inner = data['data'];
        if (inner is Map && inner['transactions'] != null) {
          return List<Map<String, dynamic>>.from(inner['transactions']);
        }
        // Fallback: if data is already a list
        if (inner is List) {
          return List<Map<String, dynamic>>.from(inner);
        }
        return [];
      }
      throw Exception(data['error'] ?? 'Failed to fetch transactions.');
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  /// GET /transactions/:id
  /// Backend returns: { success, data: { transaction: {...} } }
  Future<Map<String, dynamic>> getById(String id) async {
    try {
      final response = await _client.dio.get('/transactions/$id');
      final data = response.data;
      if (data['success'] == true) {
        final inner = data['data'];
        // Backend wraps in { transaction }
        if (inner is Map && inner['transaction'] != null) {
          return Map<String, dynamic>.from(inner['transaction'] as Map);
        }
        // Fallback: data is the transaction itself
        if (inner is Map) {
          return Map<String, dynamic>.from(inner);
        }
        throw Exception('Invalid response format.');
      }
      throw Exception(data['error'] ?? 'Transaction not found.');
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
