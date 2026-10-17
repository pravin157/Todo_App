class Todo {
  final int? id;
  final String title;
  final String description;
  final bool isCompleted;
  final String priority;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Todo({
    this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.priority = 'MEDIUM',
    this.dueDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isCompleted: json['is_completed'] as bool? ?? false,
      priority: (json['priority'] as String? ?? 'MEDIUM').toUpperCase(),
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'priority': priority,
    };

    if (dueDate != null) {
      map['due_date'] = dueDate!.toIso8601String();
    } else {
      map['due_date'] = null;
    }

    return map;
  }

  Todo copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
