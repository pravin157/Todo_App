import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  final List<Todo> todos;
  final VoidCallback onAddTask;
  final Function(String status, String priority) onNavigateToTasksWithFilter;
  final Function(Todo todo, bool? val) onToggleTodo;
  final VoidCallback onRefresh;

  const DashboardScreen({
    super.key,
    required this.todos,
    required this.onAddTask,
    required this.onNavigateToTasksWithFilter,
    required this.onToggleTodo,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeController = AppThemeController.instance;
    final accent = themeController.currentAccent;
    final isDark = themeController.isDarkMode;
    final user = AuthService.instance.currentUser;

    final total = todos.length;
    final completed = todos.where((t) => t.isCompleted).length;
    final pending = total - completed;
    final highPriority =
        todos.where((t) => t.priority == 'HIGH' && !t.isCompleted).length;
    final mediumPriority =
        todos.where((t) => t.priority == 'MEDIUM' && !t.isCompleted).length;
    final lowPriority =
        todos.where((t) => t.priority == 'LOW' && !t.isCompleted).length;

    final overdueTodos = todos.where((t) {
      if (t.dueDate == null || t.isCompleted) return false;
      return t.dueDate!.isBefore(DateTime.now());
    }).toList();

    final urgentFocusTodos = todos
        .where((t) => !t.isCompleted)
        .toList()
      ..sort((a, b) {
        if (a.priority == 'HIGH' && b.priority != 'HIGH') return -1;
        if (b.priority == 'HIGH' && a.priority != 'HIGH') return 1;
        if (a.dueDate != null && b.dueDate != null) {
          return a.dueDate!.compareTo(b.dueDate!);
        }
        if (a.dueDate != null) return -1;
        if (b.dueDate != null) return 1;
        return 0;
      });

    final double completionRate = total == 0 ? 0.0 : (completed / total);

    String greetingMessage = 'Welcome back!';
    if (completionRate >= 0.8 && total > 0) {
      greetingMessage = 'Exceptional productivity today!';
    } else if (completionRate >= 0.4) {
      greetingMessage = 'Great momentum, keep going!';
    } else if (total > 0) {
      greetingMessage = "Let's conquer your pending tasks!";
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Progress Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF161F36),
                          const Color(0xFF101728),
                        ]
                      : [
                          Colors.white,
                          const Color(0xFFF8FAFC),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accent.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user?.username != null
                                ? 'Hello, ${user!.username}'
                                : 'Daily Overview',
                            style: TextStyle(
                              color: accent.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          greetingMessage,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$completed of $total tasks finished',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Circular Progress Ring Gauge
                  SizedBox(
                    width: 86,
                    height: 86,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: completionRate),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return SizedBox(
                              width: 86,
                              height: 86,
                              child: CircularProgressIndicator(
                                value: value,
                                strokeWidth: 8,
                                backgroundColor: isDark
                                    ? Colors.white12
                                    : const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  accent.primary,
                                ),
                              ),
                            );
                          },
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(completionRate * 100).toInt()}%',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'DONE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white54 : Colors.black45,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4 Quick Metric Cards Grid
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Total Tasks',
                    count: '$total',
                    icon: Icons.checklist_rounded,
                    color: accent.primary,
                    onTap: () => onNavigateToTasksWithFilter('ALL', 'ALL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Pending',
                    count: '$pending',
                    icon: Icons.hourglass_top_rounded,
                    color: const Color(0xFFF59E0B),
                    onTap: () => onNavigateToTasksWithFilter('PENDING', 'ALL'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Completed',
                    count: '$completed',
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () => onNavigateToTasksWithFilter('COMPLETED', 'ALL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'Overdue',
                    count: '${overdueTodos.length}',
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFF43F5E),
                    onTap: () => onNavigateToTasksWithFilter('PENDING', 'ALL'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Priority Distribution Breakdown Section
            Text(
              'PRIORITY DISTRIBUTION',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131B2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  // Multi-segment Proportional Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 12,
                      child: Row(
                        children: [
                          if (highPriority > 0)
                            Expanded(
                              flex: highPriority,
                              child: Container(color: const Color(0xFFF43F5E)),
                            ),
                          if (mediumPriority > 0)
                            Expanded(
                              flex: mediumPriority,
                              child: Container(color: const Color(0xFFF59E0B)),
                            ),
                          if (lowPriority > 0)
                            Expanded(
                              flex: lowPriority,
                              child: Container(color: const Color(0xFF10B981)),
                            ),
                          if (pending == 0)
                            Expanded(
                              child: Container(
                                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Priority Items
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _PriorityPill(
                        label: 'High',
                        count: highPriority,
                        color: const Color(0xFFF43F5E),
                        onTap: () => onNavigateToTasksWithFilter('PENDING', 'HIGH'),
                      ),
                      _PriorityPill(
                        label: 'Medium',
                        count: mediumPriority,
                        color: const Color(0xFFF59E0B),
                        onTap: () => onNavigateToTasksWithFilter('PENDING', 'MEDIUM'),
                      ),
                      _PriorityPill(
                        label: 'Low',
                        count: lowPriority,
                        color: const Color(0xFF10B981),
                        onTap: () => onNavigateToTasksWithFilter('PENDING', 'LOW'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Top Focus / Urgent Queue
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOP FOCUS QUEUE',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigateToTasksWithFilter('ALL', 'ALL'),
                  child: const Text('View All', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 4),

            if (urgentFocusTodos.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131B2E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.celebration_rounded,
                      size: 36,
                      color: accent.primary,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'All caught up!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No pending urgent tasks right now.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...urgentFocusTodos.take(3).map((todo) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131B2E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    leading: GestureDetector(
                      onTap: () => onToggleTodo(todo, !todo.isCompleted),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black12,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        ),
                        child: todo.isCompleted
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                    title: Text(
                      todo.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: todo.dueDate != null
                        ? Text(
                            DateFormat('MMM d, h:mm a').format(todo.dueDate!),
                            style: const TextStyle(fontSize: 11),
                          )
                        : null,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(todo.priority).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        todo.priority,
                        style: TextStyle(
                          color: _getPriorityColor(todo.priority),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFFF43F5E);
      case 'MEDIUM':
        return const Color(0xFFF59E0B);
      case 'LOW':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MetricCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = AppThemeController.instance.isDarkMode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131B2E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                count,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _PriorityPill({
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$label: ',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Text(
              '$count',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
