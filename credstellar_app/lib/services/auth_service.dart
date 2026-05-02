import 'package:dio/dio.dart';
import 'api_client.dart';

/// Auth API service — login and signup.
/// Returns parsed response maps, throws on failure.
class AuthService {
  final ApiClient _client = ApiClient();

  /// POST /auth/signup
  /// Returns { token, user } on success
  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _client.dio.post('/auth/signup', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
      });

      final data = response.data;
      if (data['success'] == true) {
        final token = data['data']['token'] as String;
        await _client.saveToken(token);
        return data['data'];
      } else {
        throw Exception(data['error'] ?? 'Signup failed.');
      }
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  /// POST /auth/login
  /// Returns { token, user } on success
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
      if (data['success'] == true) {
        final token = data['data']['token'] as String;
        await _client.saveToken(token);
        return data['data'];
      } else {
        throw Exception(data['error'] ?? 'Login failed.');
      }
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  /// Logout — clear stored token
  Future<void> logout() async {
    await _client.clearToken();
  }

  /// Check if user has a stored session
  Future<bool> hasSession() async {
    return _client.hasToken();
  }

  /// Extract human-readable error from Dio exception
  String _extractError(DioException e) {
    if (e.response?.data != null && e.response!.data is Map) {
      return e.response!.data['error']?.toString() ?? 'Request failed.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Check your network.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server. Is the backend running?';
    }
    return 'Something went wrong. Please try again.';
  }
}
