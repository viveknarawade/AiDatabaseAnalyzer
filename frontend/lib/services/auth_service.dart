import 'dart:developer';

import '../core/api_client.dart';
import '../core/api_constants.dart';
import '../core/token_storage.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiClient.post(ApiConstants.login, {
      'email': email,
      'password': password,
    }, withAuth: false);

    final body = ApiClient.decodeResponse(response);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        body['success'] == true) {
      // FIXED
      final accessToken = body['data']['accessToken'] as String?;

      final refreshToken = body['data']['refreshToken'] as String?;

      if (accessToken != null) {
        await TokenStorage.saveToken(accessToken, refreshToken ?? '');
      }

      log("Login successful: ${body['message']}");
      return {'success': true, 'data': body['data']};
    }

    log("Login failed: ${response.statusCode} - ${body['message']}");
    return {
      'success': false,
      'message': body['message'] ?? 'Invalid credentials',
    };
  }

  Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
  ) async {
    final response = await ApiClient.post(ApiConstants.signup, {
      'name': name,
      'email': email,
      'password': password,
    }, withAuth: false);

    final body = ApiClient.decodeResponse(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'message': body['message'] ?? 'Account created'};
    }

    log("Signup failed: ${response.statusCode} - ${body['message']}");
    return {
      'success': false,
      'message': body['message'] ?? 'Registration failed',
    };
  }

  Future<void> logout() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        await ApiClient.post(ApiConstants.logout, {
          "refreshToken": refreshToken,
        });
      }
      log(" Logout successful");
    } catch (e) {
      log("Logout API error: $e");
    } finally {
      await TokenStorage.deleteToken();
    }
  }

  Future<bool> isLoggedIn() => TokenStorage.hasToken();

  Future<void> deleteAccount(String password) async {
    final response = await ApiClient.post(ApiConstants.deleteAccount, {
      "password": password,
    });

    final body = ApiClient.decodeResponse(response);

    if (response.statusCode != 200 || body['success'] != true) {
      throw ApiException(body['message'] ?? 'Failed to delete account');
    }
      log("AUTHSERVICE : DELETE ACCOUNT RESPONSE => $response");

    await TokenStorage.deleteToken();
  }
}
