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
  final DateTime? startDate; // 일정 시작 시간
  final DateTime? startDateRange; // 일정 시작 날짜 범위
  final DateTime? endDateRange; // 일정 종료 날짜 범위
  final bool isRecurring; // 반복 일정 여부
  final String? emoji; // 일정 이모지
  final DateTime? completedAt;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    this.isCompleted = false,
    required this.createdAt,
    this.startDate,
    this.dueDate,
    this.startDateRange,
    this.endDateRange,
    this.isRecurring = false,
    this.emoji,
    this.completedAt,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? dueDate,
    DateTime? startDateRange,
    DateTime? endDateRange,
    bool? isRecurring,
    String? emoji,
    DateTime? completedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      startDateRange: startDateRange ?? this.startDateRange,
      endDateRange: endDateRange ?? this.endDateRange,
      isRecurring: isRecurring ?? this.isRecurring,
      emoji: emoji ?? this.emoji,
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
      'startDate': startDate?.millisecondsSinceEpoch,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'startDateRange': startDateRange?.millisecondsSinceEpoch,
      'endDateRange': endDateRange?.millisecondsSinceEpoch,
      'isRecurring': isRecurring,
      'emoji': emoji,
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
      startDate: json['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['startDate'] as int)
          : null,
      dueDate: json['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['dueDate'] as int)
          : null,
      startDateRange: json['startDateRange'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['startDateRange'] as int)
          : null,
      endDateRange: json['endDateRange'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['endDateRange'] as int)
          : null,
      isRecurring: json['isRecurring'] as bool? ?? false,
      emoji: json['emoji'] as String?,
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