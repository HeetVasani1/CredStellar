import 'package:dio/dio.dart';
import 'api_client.dart';

/// Payment API service — preview + execute.
class PaymentService {
  final ApiClient _client = ApiClient();

  /// POST /payment/preview
  /// Body: { amount_local, merchant_name }
  Future<Map<String, dynamic>> preview({
    required double amountLocal,
    required String merchantName,
  }) async {
    try {
      final response = await _client.dio.post('/payment/preview', data: {
        'amount_local': amountLocal,
        'merchant_name': merchantName,
      });
      final data = response.data;
      if (data['success'] == true) {
        return data['data'] as Map<String, dynamic>;
      }
      throw Exception(data['error'] ?? 'Preview failed.');
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  /// POST /payment/execute
  /// Body: { amount_local, merchant_name }
  Future<Map<String, dynamic>> execute({
    required double amountLocal,
    required String merchantName,
  }) async {
    try {
      final response = await _client.dio.post('/payment/execute', data: {
        'amount_local': amountLocal,
        'merchant_name': merchantName,
      });
      final data = response.data;
      if (data['success'] == true) {
        return data['data'] as Map<String, dynamic>;
      }
      throw Exception(data['error'] ?? 'Payment failed.');
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
