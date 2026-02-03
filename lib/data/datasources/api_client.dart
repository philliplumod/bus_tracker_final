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
    debugPrint('✅ API auth token set');
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  /// Get headers with authentication
  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// Generic GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      debugPrint('🌐 GET $url');

      final response = await httpClient.get(url, headers: _headers);

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ API GET error: $e');
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
