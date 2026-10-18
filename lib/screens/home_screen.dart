import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../screens/dashboard_screen.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stats_header.dart';
import '../widgets/todo_card.dart';
import '../widgets/todo_form_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService.instance;
  final AuthService _authService = AuthService.instance;

  int _selectedTabIndex = 0; // 0: Dashboard, 1: Tasks
  List<Todo> _allTodos = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Search & Filter state
  String _searchQuery = '';
  String _statusFilter = 'ALL'; // ALL, PENDING, COMPLETED
  String _priorityFilter = 'ALL'; // ALL, HIGH, MEDIUM, LOW

  late final PageController _pageController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedTabIndex);
    _fetchTodos();
  }

  @override
  void dispose() {
    _pageController.dispose();
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
      final errorStr = e.toString();
      if (errorStr.contains('401') || errorStr.contains('Invalid token')) {
        await _authService.logout();
        return;
      }
      setState(() {
        _errorMessage = errorStr;
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
          content: Text('Task "${created.title}" created!'),
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
        backgroundColor: const Color(0xFF131B2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF1E293B)),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${todo.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
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
    TodoFormDialog.show(
      context,
      initialTodo: todo,
      onSave: (savedTodo) async {
        if (todo == null) {
          await _createTodo(savedTodo);
        } else {
          await _updateTodo(savedTodo);
        }
      },
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131B2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF1E293B)),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
    }
  }

  void _switchTab(int index) {
    if (_selectedTabIndex == index) return;
    setState(() => _selectedTabIndex = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _navigateToTasksWithFilter(String status, String priority) {
    setState(() {
      _selectedTabIndex = 1;
      _statusFilter = status;
      _priorityFilter = priority;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  List<Todo> get _filteredTodos {
    return _allTodos.where((todo) {
      if (_statusFilter == 'PENDING' && todo.isCompleted) return false;
      if (_statusFilter == 'COMPLETED' && !todo.isCompleted) return false;

      if (_priorityFilter != 'ALL' && todo.priority != _priorityFilter) {
        return false;
      }

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
    final themeController = AppThemeController.instance;
    final accent = themeController.currentAccent;
    final isDark = themeController.isDarkMode;
    final user = _authService.currentUser;
    final filtered = _filteredTodos;

    final initialLetter = (user?.username.isNotEmpty ?? false)
        ? user!.username[0].toUpperCase()
        : 'U';

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _switchTab(0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: [
                // User Avatar with gradient border
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: accent.gradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initialLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user?.username != null ? 'Hi, ${user!.username}' : 'TaskFlow Pro',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.dashboard_outlined,
                          size: 14,
                          color: accent.primary,
                        ),
                      ],
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        _selectedTabIndex == 0
                            ? 'Dashboard Active • Tap anytime'
                            : '${_allTodos.where((t) => !t.isCompleted).length} pending • Tap for Dashboard',
                        key: ValueKey(_selectedTabIndex),
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchTodos,
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _confirmLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),

      // Tab Views: 0 = Dashboard, 1 = Tasks List
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (_selectedTabIndex != index) {
            setState(() => _selectedTabIndex = index);
          }
        },
        physics: const BouncingScrollPhysics(),
        children: [
          DashboardScreen(
            todos: _allTodos,
            onAddTask: () => _openTodoForm(),
            onNavigateToTasksWithFilter: _navigateToTasksWithFilter,
            onToggleTodo: _toggleTodoStatus,
            onRefresh: _fetchTodos,
          ),
          RefreshIndicator(
            onRefresh: _fetchTodos,
            child: CustomScrollView(
              key: const PageStorageKey('my_tasks_scroll_view'),
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
                            prefixIcon:
                                Icon(Icons.search_rounded, color: accent.primary),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
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
                              const SizedBox(width: 14),
                              Container(
                                height: 22,
                                width: 1.2,
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                              const SizedBox(width: 14),
                              _buildPriorityChip('ALL', 'All Priorities'),
                              const SizedBox(width: 8),
                              _buildPriorityChip(
                                  'HIGH', 'High', const Color(0xFFF43F5E)),
                              const SizedBox(width: 8),
                              _buildPriorityChip(
                                  'MEDIUM', 'Medium', const Color(0xFFF59E0B)),
                              const SizedBox(width: 8),
                              _buildPriorityChip(
                                  'LOW', 'Low', const Color(0xFF10B981)),
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
                          Text('Syncing tasks...'),
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
                                color: Colors.redAccent.withValues(alpha: 0.12),
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
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _fetchTodos,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry Connection'),
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
                                gradient: accent.gradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.primary.withValues(alpha: 0.3),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.assignment_turned_in_rounded,
                                size: 46,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _allTodos.isEmpty
                                  ? 'No tasks yet!'
                                  : 'No matching tasks found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _allTodos.isEmpty
                                  ? 'Create your first task to boost your productivity.'
                                  : 'Try adjusting your search keywords or filter pills.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            if (_allTodos.isEmpty) ...[
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
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
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF131B2E),
          border: Border(
            top: BorderSide(
              color: Color(0xFF1E293B),
              width: 1.2,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildNavTab(
                      index: 0,
                      icon: Icons.dashboard_outlined,
                      selectedIcon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNavTab(
                      index: 1,
                      icon: Icons.checklist_outlined,
                      selectedIcon: Icons.checklist_rounded,
                      label: 'My Tasks',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: accent.gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accent.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _openTodoForm(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'New Task',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = _selectedTabIndex == index;
    final accent = AppThemeController.instance.currentAccent;

    return InkWell(
      onTap: () => _switchTab(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 48,
        decoration: BoxDecoration(
          gradient: isSelected ? accent.gradient : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final accent = AppThemeController.instance.currentAccent;
    final isSelected = _statusFilter == filterKey;
    final isDark = AppThemeController.instance.isDarkMode;

    return GestureDetector(
      onTap: () => setState(() => _statusFilter = filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? accent.gradient : null,
          color: isSelected
              ? null
              : (isDark ? const Color(0xFF131B2E) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priorityKey, String label, [Color? color]) {
    final accent = AppThemeController.instance.currentAccent;
    final isSelected = _priorityFilter == priorityKey;
    final isDark = AppThemeController.instance.isDarkMode;

    return GestureDetector(
      onTap: () => setState(() => _priorityFilter = priorityKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? accent.primary).withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF131B2E) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (color ?? accent.primary)
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
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
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (color ?? accent.primary)
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
