import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/todo.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  String _baseUrl = 'http://127.0.0.1:8000/api';
  String? _authToken;

  static const List<String> fallbackUrls = [
    'http://127.0.0.1:8000/api',
    'http://10.0.2.2:8000/api',
    'http://10.163.155.79:8000/api',
  ];

  String get baseUrl => _baseUrl;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  void setBaseUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    _baseUrl = trimmed;
  }

  Uri _uriFor(String base, String path) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$base/$cleanPath');
  }

  Uri _uri(String path) {
    return _uriFor(_baseUrl, path);
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Token $_authToken';
    }
    return headers;
  }

  /// Helper to send requests with fallback URL support
  Future<http.Response> _sendWithFallback(
    Future<http.Response> Function(String base) requestFn,
  ) async {
    try {
      return await requestFn(_baseUrl);
    } catch (initialError) {
      debugPrint('Request failed on $_baseUrl: $initialError');
      for (final candidate in fallbackUrls) {
        if (candidate == _baseUrl) continue;
        try {
          debugPrint('Retrying with fallback $candidate');
          final res = await requestFn(candidate);
          _baseUrl = candidate;
          return res;
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Register user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final body = jsonEncode({
      'username': username.trim(),
      'email': email.trim(),
      'password': password,
    });

    final response = await _sendWithFallback((base) {
      final url = _uriFor(base, 'auth/register/');
      return http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 8));
    });

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 201) {
      return data as Map<String, dynamic>;
    } else {
      String errorMsg = 'Registration failed.';
      if (data is Map) {
        final messages = <String>[];
        data.forEach((k, v) {
          if (v is List) {
            messages.add('$k: ${v.join(", ")}');
          } else {
            messages.add('$k: $v');
          }
        });
        if (messages.isNotEmpty) errorMsg = messages.join('\n');
      }
      throw Exception(errorMsg);
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final body = jsonEncode({
      'username': username.trim(),
      'password': password,
    });

    final response = await _sendWithFallback((base) {
      final url = _uriFor(base, 'auth/login/');
      return http
          .post(url, headers: _headers, body: body)
          .timeout(const Duration(seconds: 8));
    });

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return data as Map<String, dynamic>;
    } else {
      String errorMsg = 'Invalid username or password.';
      if (data is Map && data['detail'] != null) {
        errorMsg = data['detail'].toString();
      }
      throw Exception(errorMsg);
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      final url = _uri('auth/logout/');
      await http
          .post(url, headers: _headers)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Logout request notice: $e');
    }
  }

  /// Fetch all todos for authenticated user
  Future<List<Todo>> getTodos() async {
    final response = await _sendWithFallback((base) {
      final url = _uriFor(base, 'todos/');
      return http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 8));
    });

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is List) {
        return decoded
            .map((item) => Todo.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (decoded is Map && decoded.containsKey('results')) {
        final results = decoded['results'] as List;
        return results
            .map((item) => Todo.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  /// Create a new todo
  Future<Todo> createTodo(Todo todo) async {
    final url = _uri('todos/');
    final response = await http
        .post(
          url,
          headers: _headers,
          body: jsonEncode(todo.toJson()),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Todo.fromJson(data as Map<String, dynamic>);
    } else {
      throw Exception(
          'Failed to create todo (HTTP ${response.statusCode}): ${response.body}');
    }
  }

  /// Update an existing todo (full update)
  Future<Todo> updateTodo(Todo todo) async {
    if (todo.id == null) {
      throw Exception('Todo ID is required for update');
    }
    final url = _uri('todos/${todo.id}/');
    final response = await http
        .put(
          url,
          headers: _headers,
          body: jsonEncode(todo.toJson()),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Todo.fromJson(data as Map<String, dynamic>);
    } else {
      throw Exception(
          'Failed to update todo (HTTP ${response.statusCode}): ${response.body}');
    }
  }

  /// Toggle or partially update todo completion status
  Future<Todo> toggleTodoStatus(int id, bool isCompleted) async {
    final url = _uri('todos/$id/');
    final response = await http
        .patch(
          url,
          headers: _headers,
          body: jsonEncode({'is_completed': isCompleted}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Todo.fromJson(data as Map<String, dynamic>);
    } else {
      throw Exception(
          'Failed to toggle todo (HTTP ${response.statusCode}): ${response.body}');
    }
  }

  /// Delete a todo
  Future<void> deleteTodo(int id) async {
    final url = _uri('todos/$id/');
    final response =
        await http.delete(url, headers: _headers).timeout(const Duration(seconds: 10));

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
          'Failed to delete todo (HTTP ${response.statusCode}): ${response.body}');
    }
  }
}
