import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:erp_purchasing_apps/core/api/api_response.dart';
import 'api_exception.dart';

// Core API Service
// Handles all HTTP requests to Golang backend
// Features:
// - Automatic JWT token injection
// - Request/Response logging
// - Error handling
// - Timeout management

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

// Configuration
  static const String baseUrl = 'http://localhost:8080/api/v1';
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

// Secure storage for JWT token
  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';

// HTTP client
  final http.Client _client = http.Client();

// Save JWT token securely
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Get stored JWT token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Remove JWT token (logout)
  Future<void> removeToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Check if token exists
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Build headers with authorization
  Future<Map<String, String>> _buildHeaders({
    bool requiresAuth = true,
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Log request details (debug only)
  void _logRequest(String method, String url, {dynamic body}) {
    print('🔵 $method $url');
    if (body != null) {
      print('📤 Request Body: ${body is String ? body : jsonEncode(body)}');
    }
  }

  /// Log response details (debug only)
  void _logResponse(http.Response response) {
    print('📥 Response [${response.statusCode}]: ${response.body}');
  }

  /// Handle HTTP response and convert to ApiResponse
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    _logResponse(response);

    // Check if response is successful (2xx)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.fromJson(json, fromJson);
      } catch (e) {
        throw ApiException(
          message: 'Failed to parse response',
          statusCode: response.statusCode,
          error: e.toString(),
        );
      }
    }

    // Handle error responses
    String errorMessage = 'Request failed';
    dynamic errorDetail;

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage = json['message'] ?? errorMessage;
      errorDetail = json['error'];
    } catch (_) {
      errorMessage = response.body;
    }

    throw createException(
      statusCode: response.statusCode,
      message: errorMessage,
      error: errorDetail,
    );
  }

  // Generic GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final uriWithParams = queryParameters != null
          ? uri.replace(queryParameters: queryParameters)
          : uri;

      _logRequest('GET', uriWithParams.toString());

      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await _client
          .get(uriWithParams, headers: headers)
          .timeout(receiveTimeout);

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      throw NetworkException(
        message: 'No internet connection',
      );
    } on TimeoutException {
      throw TimeoutException(
        message: 'Request timeout. Please try again.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  // Generic POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic body,
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      _logRequest('POST', uri.toString(), body: body);

      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final jsonBody = body != null ? jsonEncode(body) : null;

      final response = await _client
          .post(uri, headers: headers, body: jsonBody)
          .timeout(receiveTimeout);

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      throw NetworkException(
        message: 'No internet connection',
      );
    } on TimeoutException {
      throw TimeoutException(
        message: 'Request timeout. Please try again.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Generic PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic body,
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      _logRequest('PUT', uri.toString(), body: body);

      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final jsonBody = body != null ? jsonEncode(body) : null;

      final response = await _client
          .put(uri, headers: headers, body: jsonBody)
          .timeout(receiveTimeout);

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      throw NetworkException(
        message: 'No internet connection',
      );
    } on TimeoutException {
      throw TimeoutException(
        message: 'Request timeout. Please try again.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      _logRequest('DELETE', uri.toString());

      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response =
          await _client.delete(uri, headers: headers).timeout(receiveTimeout);

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      throw NetworkException(
        message: 'No internet connection',
      );
    } on TimeoutException {
      throw TimeoutException(
        message: 'Request timeout. Please try again.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Close HTTP client
  void dispose() {
    _client.close();
  }
}
