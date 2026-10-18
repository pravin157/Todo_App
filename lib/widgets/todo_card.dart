import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../theme/app_theme.dart';

class TodoCard extends StatelessWidget {
  final Todo todo;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TodoCard({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

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

  bool get _isOverdue {
    if (todo.dueDate == null || todo.isCompleted) return false;
    return todo.dueDate!.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppThemeController.instance.currentAccent;
    final isDark = AppThemeController.instance.isDarkMode;
    final priorityColor = _getPriorityColor(todo.priority);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: todo.isCompleted
            ? (isDark ? const Color(0xFF0F1523) : const Color(0xFFF8FAFC))
            : (isDark ? const Color(0xFF131B2E) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: todo.isCompleted
              ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))
              : priorityColor.withValues(alpha: isDark ? 0.4 : 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Animated Checkbox
                GestureDetector(
                  onTap: () => onToggle(!todo.isCompleted),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: todo.isCompleted ? accent.gradient : null,
                      color: todo.isCompleted
                          ? null
                          : (isDark ? Colors.white10 : Colors.black12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: todo.isCompleted
                            ? Colors.transparent
                            : (isDark ? Colors.white24 : Colors.black26),
                        width: 1.5,
                      ),
                    ),
                    child: todo.isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),

                // Main content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Priority Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: priorityColor.withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: priorityColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  todo.priority,
                                  style: TextStyle(
                                    color: priorityColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Overdue badge
                          if (_isOverdue) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 12,
                                    color: Colors.redAccent,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Overdue',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        todo.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: todo.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: todo.isCompleted
                              ? (isDark ? Colors.white38 : Colors.black38)
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),

                      // Description
                      if (todo.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          todo.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],

                      // Footer with Due Date & Quick Actions
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (todo.dueDate != null) ...[
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: _isOverdue
                                  ? Colors.redAccent
                                  : (isDark ? Colors.white54 : Colors.black54),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              DateFormat('MMM d, h:mm a').format(todo.dueDate!),
                              style: TextStyle(
                                fontSize: 11,
                                color: _isOverdue
                                    ? Colors.redAccent
                                    : (isDark ? Colors.white54 : Colors.black54),
                                fontWeight: _isOverdue ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                          const Spacer(),
                          // Edit Button
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Edit',
                            color: isDark ? Colors.white60 : Colors.black54,
                            onPressed: onEdit,
                          ),
                          const SizedBox(width: 14),
                          // Delete Button
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Delete',
                            color: Colors.redAccent.withValues(alpha: 0.8),
                            onPressed: onDelete,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
