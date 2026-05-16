import 'dart:developer';

import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  AuthStatus _status = AuthStatus.initial;
  String _errorMessage = '';

  AuthStatus get status => _status;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final loggedIn = await _service.isLoggedIn();
    _status = loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading();

    try {
      final result = await _service.login(email, password);
      if (result['success'] == true) {
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      _setError(result['message'] as String? ?? 'Login failed');
    } catch (e) {
      _setError(_friendlyError(e));
    }

    return false;
  }

  Future<bool> signup(String name, String email, String password) async {
    _setLoading();

    try {
      final result = await _service.signup(name, email, password);
      if (result['success'] == true) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return true;
      }
      _setError(result['message'] as String? ?? 'Signup failed');
    } catch (e) {
      _setError(_friendlyError(e));
    }

    return false;
  }

  Future<void> logout() async {
    await _service.logout();

    _status = AuthStatus.unauthenticated;

    _errorMessage = '';

    notifyListeners();
  }

  Future<void> deleteAccount(String password) async {
    await _service.deleteAccount(password);

    log("IN Authprovider deletefunction");
    _status = AuthStatus.unauthenticated;

    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    if (_status == AuthStatus.error) _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = '';
    notifyListeners();
  }

  void _setError(String msg) {
    _status = AuthStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Connection')) {
      return 'Unable to reach server. Check your connection.';
    }
    if (msg.contains('TimeoutException')) return 'Request timed out.';
    return msg.replaceFirst('Exception: ', '');
  }
}
