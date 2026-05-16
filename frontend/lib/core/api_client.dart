import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'token_storage.dart';

class ApiClient {
  static const Duration _timeout = Duration(seconds: 15);

  // ---------------- Headers ----------------
  static Future<Map<String, String>> _buildHeaders({
    bool withAuth = true,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth) {
      final token = await TokenStorage.getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // ---------------- GET ----------------
  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final headers = await _buildHeaders();

      final uri = Uri.parse(
        ApiConstants.baseUrl + endpoint,
      ).replace(queryParameters: queryParams);

      log("GET => $uri");

      final response = await http
          .get(uri, headers: headers)
          .timeout(_timeout);

      _validateResponse(response);

      return response;
    } on SocketException {
      throw ApiException(
        'Cannot connect to server.\nCheck WiFi and backend IP.',
      );
    } on TimeoutException {
      throw ApiException(
        'Request timed out. Server taking too long.',
      );
    } catch (e) {
      throw ApiException("GET Error: $e");
    }
  }

  // ---------------- POST ----------------
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    try {
      log("In ApiClient POST method with endpoint: ${endpoint} and body: ${body} and withAuth: ${withAuth}");
      final headers = await _buildHeaders(
        withAuth: withAuth,
      );

      final uri = Uri.parse(
        ApiConstants.baseUrl + endpoint,
      );

      log("POST => $uri");
      log("BODY => ${jsonEncode(body)}");

      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      _validateResponse(response);

      return response;
    } on SocketException {
      throw ApiException(
        'Cannot reach backend.\nIf using physical phone, replace 10.0.2.2 with PC IP.',
      );
    } on TimeoutException {
      throw ApiException(
        'Request timeout.',
      );
    } catch (e) {
      throw ApiException("POST Error: $e");
    }
  }

  // ---------------- PUT ----------------
  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final headers = await _buildHeaders();

      final uri = Uri.parse(
        ApiConstants.baseUrl + endpoint,
      );

      final response = await http
          .put(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      _validateResponse(response);

      return response;
    } on SocketException {
      throw ApiException(
        'No server connection',
      );
    } on TimeoutException {
      throw ApiException(
        'Request timed out',
      );
    } catch (e) {
      throw ApiException("PUT Error: $e");
    }
  }

  // ---------------- DELETE ----------------
  static Future<http.Response> delete(
    String endpoint,
  ) async {
    try {
      final headers = await _buildHeaders();

      final uri = Uri.parse(
        ApiConstants.baseUrl + endpoint,
      );

      final response = await http
          .delete(
            uri,
            headers: headers,
          )
          .timeout(_timeout);

      _validateResponse(response);

      return response;
    } on SocketException {
      throw ApiException(
        'No internet or backend unavailable',
      );
    } on TimeoutException {
      throw ApiException(
        'Delete request timeout',
      );
    } catch (e) {
      throw ApiException("DELETE Error: $e");
    }
  }

  // ---------------- Response Validation ----------------
  static void _validateResponse(
    http.Response response,
  ) {
    log(
      "STATUS => ${response.statusCode}",
    );

    log(
      "RESPONSE => ${response.body}",
    );

    if (response.statusCode >= 500) {
      throw ApiException(
        'Server error (${response.statusCode})',
      );
    }

    if (response.statusCode == 401) {
      throw ApiException(
        'Unauthorized. Login again.',
      );
    }

    if (response.statusCode == 403) {
      throw ApiException(
        'Access denied',
      );
    }
  }

  // ---------------- Decode JSON ----------------
  static Map<String, dynamic> decodeResponse(
    http.Response response,
  ) {
    try {
      return jsonDecode(
        response.body,
      ) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException(
        'Invalid JSON response',
      );
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() {
    return message;
  }
}