import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// API client for Bus Tracking Dashboard backend
class ApiClient {
  final String baseUrl;
  final http.Client httpClient;
  String? _authToken;

  ApiClient({required this.baseUrl, http.Client? client})
    : httpClient = client ?? http.Client();

  /// Set authentication token for API requests
  void setAuthToken(String token) {
    _authToken = token;
    debugPrint('✅ API auth token set (length: ${token.length} chars)');
    debugPrint(
      '   Token preview: ${token.substring(0, token.length > 50 ? 50 : token.length)}...',
    );
  }

  /// Check if auth token is set
  bool hasAuthToken() {
    return _authToken != null && _authToken!.isNotEmpty;
  }

  /// Get current token (for debugging)
  String? getCurrentToken() {
    return _authToken;
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
    debugPrint('🗑️ API auth token cleared');
  }

  /// Get headers with authentication
  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    } else {
      debugPrint('⚠️ WARNING: Request has NO auth token!');
    }

    return headers;
  }

  /// Generic GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      debugPrint('🌐 GET $url');

      // Verify token is set for authenticated endpoints
      if (_authToken == null && !endpoint.contains('/auth/')) {
        debugPrint('❌ CRITICAL: No auth token set for authenticated endpoint!');
        debugPrint('   Endpoint: $endpoint');
        debugPrint('   This request will likely fail with 401 Unauthorized');
        debugPrint('   ');
        debugPrint(
          '   🔧 Try logging out and logging back in to refresh token',
        );
      } else if (_authToken != null) {
        debugPrint('✅ Auth token present (${_authToken!.length} chars)');
        debugPrint(
          '   Token preview: ${_authToken!.substring(0, _authToken!.length > 30 ? 30 : _authToken!.length)}...',
        );
      }

      // Debug: Show the actual headers being sent
      final headers = _headers;
      debugPrint('📤 Request headers:');
      headers.forEach((key, value) {
        if (key == 'Authorization') {
          debugPrint(
            '   $key: ${value.substring(0, value.length > 50 ? 50 : value.length)}...',
          );
        } else {
          debugPrint('   $key: $value');
        }
      });

      final response = await httpClient.get(url, headers: headers);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ API GET error: $e');

      // Check if it's an auth error
      if (e.toString().contains('Unauthorized') ||
          e.toString().contains('401')) {
        debugPrint('   ');
        debugPrint('   🚨 AUTHENTICATION ERROR DETECTED');
        debugPrint('   Possible causes:');
        debugPrint('   1. Token has expired');
        debugPrint('   2. Token was not set after login');
        debugPrint('   3. Backend rejected the token');
        debugPrint('   ');
        debugPrint('   💡 SOLUTION: Logout and login again');
      }

      throw ApiException('GET request failed: $e');
    }
  }

  /// Generic POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      debugPrint('🌐 POST $url');

      final response = await httpClient.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ API POST error: $e');
      throw ApiException('POST request failed: $e');
    }
  }

  /// Generic PUT request
  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      debugPrint('🌐 PUT $url');

      final response = await httpClient.put(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ API PUT error: $e');
      throw ApiException('PUT request failed: $e');
    }
  }

  /// Generic DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      debugPrint('🌐 DELETE $url');

      final response = await httpClient.delete(url, headers: _headers);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ API DELETE error: $e');
      throw ApiException('DELETE request failed: $e');
    }
  }

  /// Handle API response
  dynamic _handleResponse(http.Response response) {
    debugPrint('📥 Response status: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw UnauthorizedException('Unauthorized: Invalid or expired token');
    } else if (response.statusCode == 403) {
      throw ForbiddenException('Forbidden: Insufficient permissions');
    } else if (response.statusCode == 404) {
      throw NotFoundException('Resource not found');
    } else if (response.statusCode >= 500) {
      throw ServerException('Server error: ${response.statusCode}');
    } else {
      throw ApiException('Request failed with status: ${response.statusCode}');
    }
  }

  /// Dispose the HTTP client
  void dispose() {
    httpClient.close();
  }
}

/// Base API exception
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

/// 401 Unauthorized
class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}

/// 403 Forbidden
class ForbiddenException extends ApiException {
  ForbiddenException(super.message);
}

/// 404 Not Found
class NotFoundException extends ApiException {
  NotFoundException(super.message);
}

/// 500+ Server Error
class ServerException extends ApiException {
  ServerException(super.message);
}
