import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final String? error;

  AuthState(
      {this.isAuthenticated = false,
      this.isLoading = false,
      this.user,
      this.error});

  AuthState copyWith(
      {bool? isAuthenticated, bool? isLoading, User? user, String? error}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;

  AuthNotifier(this._api) : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    await _api.loadToken();
    if (_api.isAuthenticated) {
      try {
        final userData = await _api.getMe();
        state = AuthState(isAuthenticated: true, user: User.fromJson(userData));
      } catch (_) {
        state = AuthState(isAuthenticated: false);
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.login(email, password);
      final userData = await _api.getMe();
      state = AuthState(isAuthenticated: true, user: User.fromJson(userData));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.register(email, password, fullName);
      return await login(email, password);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void logout() {
    _api.clearToken();
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiServiceProvider));
});
