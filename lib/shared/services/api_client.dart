import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mechmate_app/core/constants/constants.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Singleton API client shared across all services.
///
/// Call [initialize] once after the user logs in (e.g. from [AppAuthProvider])
/// to authenticate with the backend and obtain a JWT. All subsequent API calls
/// from any service will reuse the same token.
class ApiClient {
  ApiClient._internal() : baseUrl = AppConfig.apiBaseUrl;
  static final ApiClient instance = ApiClient._internal();

  final String baseUrl;
  String? _jwtToken;
  String? _role;
  bool _initialized = false;

  /// Whether the client has been initialized (authenticated) at least once.
  bool get isInitialized => _initialized;

  /// Initialize the shared client with the user's [role].
  ///
  /// Call this once after login — subsequent calls are no-ops if already
  /// authenticated.
  Future<void> initialize(String role) async {
    if (_initialized && _jwtToken != null) return;
    _role = role;
    await _authenticate();
    _initialized = true;
  }

  /// Force re-authentication (e.g. after 401).
  Future<void> reauthenticate() async {
    _jwtToken = null;
    _initialized = false;
    await _authenticate();
    _initialized = true;
  }

  Future<void> _authenticate() async {
    if (_role == null) throw const ApiException('No role set. Call initialize(role) first.');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw const ApiException('Not signed in');

    final idToken = await user.getIdToken();
    if (idToken == null) throw const ApiException('Failed to get auth token');

    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/firebase'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'idToken': idToken,
            'role': _role,
            'displayName': user.displayName,
          }),
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () =>
              throw const ApiException('Authentication request timed out'),
        );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = _extractErrorMessage(response);
      throw ApiException(msg, statusCode: response.statusCode);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    _jwtToken = data?['token'] as String?;

    if (_jwtToken == null || _jwtToken!.isEmpty) {
      throw const ApiException('No token received from server');
    }
  }

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_jwtToken != null) {
      headers['Authorization'] = 'Bearer $_jwtToken';
    }
    return headers;
  }

  Future<void> _ensureAuth() async {
    if (_jwtToken != null) return;
    if (!_initialized) {
      throw const ApiException(
      'ApiClient not initialized. Call ApiClient.instance.initialize(role) after login.',
    );
    }
    await _authenticate();
  }

  /// Send a GET request and parse the response as a single object.
  Future<T> get<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final result = await _request('GET', path);
    return fromJson(result);
  }

  /// Send a GET request and parse the response as a list of objects.
  Future<List<T>> getList<T>(
    String path, {
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final result = await _request('GET', path);
    if (result is List) {
      return result
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw const ApiException('Unexpected response format: expected array');
  }

  /// Send a POST request and parse the response as a single object.
  Future<T> post<T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final result = await _request('POST', path, body: body);
    return fromJson(result);
  }

  /// Send a PATCH request and return the parsed response.
  Future<T?> patch<T>(
    String path, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final result = await _request('PATCH', path, body: body);
    if (fromJson != null && result != null) {
      return fromJson(result as Map<String, dynamic>);
    }
    return null;
  }

  /// Send a DELETE request.
  Future<void> delete(String path) async {
    await _request('DELETE', path);
  }

  /// Extract an error message from an unsuccessful HTTP response.
  String _extractErrorMessage(http.Response response) {
    try {
      final errorBody = jsonDecode(response.body);
      if (errorBody is Map<String, dynamic>) {
        return (errorBody['message'] as String?) ??
            (errorBody['error'] as String?) ??
            'Request failed (${response.statusCode})';
      }
    } catch (_) {}
    return 'Request failed (${response.statusCode})';
  }

  Future<dynamic> _request(String method, String path,
      {Map<String, dynamic>? body}) async {
    await _ensureAuth();

    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers();

    var response = await _send(method, uri, headers, body);

    // Log response for debugging
    final truncatedBody = response.body.length > 500
        ? '${response.body.substring(0, 500)}...'
        : response.body;
    debugPrint('$method $path -> ${response.statusCode}: $truncatedBody');

    // Handle 401 — token may have expired, retry once
    if (response.statusCode == 401) {
      debugPrint('401 on $path — re-authenticating and retrying');
      _jwtToken = null;
      await reauthenticate();
      final newHeaders = await _headers();
      response = await _send(method, uri, newHeaders, body);
      debugPrint('Retry $method $path -> ${response.statusCode}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = _extractErrorMessage(response);
      throw ApiException(msg, statusCode: response.statusCode);
    }

    // For DELETE or empty responses, return null
    if (response.body.isEmpty) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic> && decoded['success'] == true) {
      return decoded['data'];
    }

    return decoded;
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) async {
    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return http.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PATCH':
        return http.patch(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return http.delete(uri, headers: headers);
      default:
        throw ApiException('Unsupported method: $method');
    }
  }
}
