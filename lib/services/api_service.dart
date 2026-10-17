import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/todo.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  String _baseUrl = 'http://127.0.0.1:8000/api';

  static const List<String> fallbackUrls = [
    'http://127.0.0.1:8000/api',
    'http://10.0.2.2:8000/api',
    'http://10.163.155.79:8000/api',
  ];

  String get baseUrl => _baseUrl;

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

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Fetch all todos with automatic fallback to alternate URLs if initial fails
  Future<List<Todo>> getTodos() async {
    // Try current _baseUrl first
    try {
      return await _fetchFromUrl(_baseUrl);
    } catch (initialError) {
      debugPrint('Initial connection failed on $_baseUrl: $initialError');

      // Try fallbacks
      for (final candidate in fallbackUrls) {
        if (candidate == _baseUrl) continue;
        try {
          debugPrint('Attempting fallback to $candidate');
          final results = await _fetchFromUrl(candidate);
          _baseUrl = candidate; // Remember working URL
          debugPrint('Connected successfully to fallback: $candidate');
          return results;
        } catch (_) {
          // Continue to next candidate
        }
      }

      throw Exception(
        'Could not connect to Django backend at $_baseUrl.\n'
        '• If using a physical phone over USB: ensure "adb reverse tcp:8000 tcp:8000" is run.\n'
        '• If using Wi-Fi: ensure your phone and PC are on the same Wi-Fi and Django is running.\n'
        'Error: $initialError',
      );
    }
  }

  Future<List<Todo>> _fetchFromUrl(String base) async {
    final url = _uriFor(base, 'todos/');
    final response = await http
        .get(url, headers: _headers)
        .timeout(const Duration(seconds: 4));

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
      throw Exception(
          'HTTP ${response.statusCode}: ${response.body}');
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
