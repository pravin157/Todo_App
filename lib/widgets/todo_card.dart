import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';

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
        return Colors.redAccent;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.teal;
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
    final priorityColor = _getPriorityColor(todo.priority);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: todo.isCompleted ? 0.5 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: todo.isCompleted
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.3)
              : priorityColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      color: todo.isCompleted
          ? theme.colorScheme.surfaceContainerLowest
          : theme.colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox with custom round styling
              Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  value: todo.isCompleted,
                  onChanged: onToggle,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  activeColor: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Priority Badge
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
                          child: Text(
                            todo.priority,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: priorityColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Overdue badge if needed
                        if (_isOverdue) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 11,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Overdue',
                                  style: TextStyle(
                                    color: Colors.red,
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
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      todo.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: todo.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: todo.isCompleted
                            ? theme.colorScheme.outline
                            : theme.colorScheme.onSurface,
                      ),
                    ),

                    // Description if available
                    if (todo.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        todo.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: todo.isCompleted
                              ? theme.colorScheme.outline
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Due date footer
                    if (todo.dueDate != null)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: _isOverdue
                                ? Colors.red
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            DateFormat('MMM dd, yyyy • hh:mm a')
                                .format(todo.dueDate!.toLocal()),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: _isOverdue
                                  ? Colors.red
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight:
                                  _isOverdue ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Action Popup Menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
