import 'package:flutter/material.dart';
import 'models/todo.dart';
import 'services/api_service.dart';
import 'widgets/server_config_dialog.dart';
import 'widgets/stats_header.dart';
import 'widgets/todo_card.dart';
import 'widgets/todo_form_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF6366F1); // Modern Indigo

    return MaterialApp(
      title: 'Django Todo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const TodoHomeScreen(),
    );
  }
}

class TodoHomeScreen extends StatefulWidget {
  const TodoHomeScreen({super.key});

  @override
  State<TodoHomeScreen> createState() => _TodoHomeScreenState();
}

class _TodoHomeScreenState extends State<TodoHomeScreen> {
  final ApiService _apiService = ApiService.instance;
  List<Todo> _allTodos = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Search & Filter state
  String _searchQuery = '';
  String _statusFilter = 'ALL'; // ALL, PENDING, COMPLETED
  String _priorityFilter = 'ALL'; // ALL, HIGH, MEDIUM, LOW

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTodos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTodos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final todos = await _apiService.getTodos();
      setState(() {
        _allTodos = todos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createTodo(Todo todo) async {
    final created = await _apiService.createTodo(todo);
    setState(() {
      _allTodos.insert(0, created);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "${created.title}" created successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _updateTodo(Todo todo) async {
    final updated = await _apiService.updateTodo(todo);
    setState(() {
      final index = _allTodos.indexWhere((t) => t.id == updated.id);
      if (index != -1) {
        _allTodos[index] = updated;
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "${updated.title}" updated!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleTodoStatus(Todo todo, bool? value) async {
    if (todo.id == null || value == null) return;

    // Optimistic UI update
    final prevCompleted = todo.isCompleted;
    setState(() {
      final index = _allTodos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        _allTodos[index] = todo.copyWith(isCompleted: value);
      }
    });

    try {
      await _apiService.toggleTodoStatus(todo.id!, value);
    } catch (e) {
      // Revert if error
      setState(() {
        final index = _allTodos.indexWhere((t) => t.id == todo.id);
        if (index != -1) {
          _allTodos[index] = todo.copyWith(isCompleted: prevCompleted);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update task: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _deleteTodo(Todo todo) async {
    if (todo.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task?'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.deleteTodo(todo.id!);
      setState(() {
        _allTodos.removeWhere((t) => t.id == todo.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${todo.title}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete task: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _openTodoForm([Todo? todo]) {
    showDialog(
      context: context,
      builder: (ctx) => TodoFormDialog(
        initialTodo: todo,
        onSave: (savedTodo) async {
          if (todo == null) {
            await _createTodo(savedTodo);
          } else {
            await _updateTodo(savedTodo);
          }
        },
      ),
    );
  }

  void _openServerConfig() {
    showDialog(
      context: context,
      builder: (ctx) => ServerConfigDialog(
        onConfigChanged: _fetchTodos,
      ),
    );
  }

  List<Todo> get _filteredTodos {
    return _allTodos.where((todo) {
      // Status filter
      if (_statusFilter == 'PENDING' && todo.isCompleted) return false;
      if (_statusFilter == 'COMPLETED' && !todo.isCompleted) return false;

      // Priority filter
      if (_priorityFilter != 'ALL' && todo.priority != _priorityFilter) {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = todo.title.toLowerCase().contains(query);
        final matchDesc = todo.description.toLowerCase().contains(query);
        if (!matchTitle && !matchDesc) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredTodos;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.check_box_outlined,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TaskFlow',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Django REST + PostgreSQL',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Server Settings',
            icon: const Icon(Icons.settings_ethernet_rounded),
            onPressed: _openServerConfig,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchTodos,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTodos,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Dashboard Stats Header
            SliverToBoxAdapter(
              child: StatsHeader(todos: _allTodos),
            ),

            // Search Bar & Filter Options
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    // Search Field
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() => _searchQuery = val.trim());
                      },
                      decoration: InputDecoration(
                        hintText: 'Search tasks by title or description...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter Chips Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('ALL', 'All Tasks'),
                          const SizedBox(width: 8),
                          _buildFilterChip('PENDING', 'Pending'),
                          const SizedBox(width: 8),
                          _buildFilterChip('COMPLETED', 'Completed'),
                          const SizedBox(width: 16),
                          Container(
                            height: 24,
                            width: 1,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          const SizedBox(width: 16),
                          _buildPriorityChip('ALL', 'Any Priority'),
                          const SizedBox(width: 8),
                          _buildPriorityChip('HIGH', 'High', Colors.redAccent),
                          const SizedBox(width: 8),
                          _buildPriorityChip('MEDIUM', 'Medium', Colors.orange),
                          const SizedBox(width: 8),
                          _buildPriorityChip('LOW', 'Low', Colors.teal),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Main List / States
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Connecting to Django backend...'),
                    ],
                  ),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_off_rounded,
                            size: 48,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Backend Connection Failed',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _openServerConfig,
                              icon: const Icon(Icons.settings_rounded),
                              label: const Text('Server Settings'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: _fetchTodos,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.assignment_turned_in_outlined,
                            size: 56,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _allTodos.isEmpty
                              ? 'No tasks yet!'
                              : 'No tasks match your filters',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _allTodos.isEmpty
                              ? 'Create your first todo task to stay productive.'
                              : 'Try adjusting your search query or filter chips.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        if (_allTodos.isEmpty) ...[
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => _openTodoForm(),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add First Task'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final todo = filtered[index];
                    return TodoCard(
                      key: ValueKey(todo.id),
                      todo: todo,
                      onToggle: (val) => _toggleTodoStatus(todo, val),
                      onEdit: () => _openTodoForm(todo),
                      onDelete: () => _deleteTodo(todo),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTodoForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Task'),
        elevation: 3,
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _statusFilter == filterKey;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) {
        setState(() => _statusFilter = filterKey);
      },
    );
  }

  Widget _buildPriorityChip(String priorityKey, String label, [Color? color]) {
    final isSelected = _priorityFilter == priorityKey;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (color != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(label),
        ],
      ),
      onSelected: (_) {
        setState(() => _priorityFilter = priorityKey);
      },
    );
  }
}
