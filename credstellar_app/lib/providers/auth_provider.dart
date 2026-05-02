import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// Auth state — holds user info and loading/error states.
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final Map<String, dynamic>? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    Map<String, dynamic>? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
    );
  }
}

/// Auth notifier — manages login/signup/logout actions.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authService.login(
        email: email,
        password: password,
      );
      state = AuthState(
        isAuthenticated: true,
        user: data['user'] as Map<String, dynamic>?,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Signup with email, password, full_name
  Future<bool> signup(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _authService.signup(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = AuthState(
        isAuthenticated: true,
        user: data['user'] as Map<String, dynamic>?,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Logout — clear state and token
  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }

  /// Check for existing session on app start
  Future<void> checkSession() async {
    final hasSession = await _authService.hasSession();
    if (hasSession) {
      state = state.copyWith(isAuthenticated: true);
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ── Providers ──

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
