enum TaskPriority {
  urgentImportant, // 중요 & 긴급
  important,       // 중요
  urgent,          // 긴급
  neither,         // 중요하지 않음
}

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    this.isCompleted = false,
    required this.createdAt,
    this.dueDate,
    this.completedAt,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? completedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.index,
      'isCompleted': isCompleted,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: TaskPriority.values[json['priority'] as int],
      isCompleted: json['isCompleted'] as bool,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      dueDate: json['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['dueDate'] as int)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'] as int)
          : null,
    );
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, title: $title, priority: $priority, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 