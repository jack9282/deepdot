enum TaskPriority {
  urgentImportant, // 중요 & 긴급
  important,       // 중요
  urgent,          // 긴급
  neither,         // 중요하지 않음
}

class TaskModel {
  final String id; // 내부적으로는 String ID 유지
  final int? userId; // API에서 온 userId
  final String title;
  final String? memo; // API 연동을 위한 memo 필드
  final String? location; // API 연동을 위한 location 필드
  final TaskPriority priority; // 내부적으로는 enum 유지
  final bool alarm; // 알림 설정
  final bool isCompleted;
  final DateTime createdAt;
  final String? calendarDate; // yyyy-MM-dd 형식
  final String? startTime; // HH:mm:ss 형식
  final String? endTime; // HH:mm:ss 형식
  final String? icon; // 아이콘 코드
  final DateTime? modifiedDate; // 일정 내용 수정일
  final DateTime? timeModified; // 시간만 수정한 일시
  final DateTime? completedAt;
  
  // 기존 필드들 (하위 호환성을 위해 유지)
  final String? description; // memo와 location 조합
  final DateTime? dueDate; // endTime을 DateTime으로 변환
  final DateTime? startDate; // startTime을 DateTime으로 변환
  final DateTime? startDateRange; // 일정 시작 날짜 범위
  final DateTime? endDateRange; // 일정 종료 날짜 범위
  final bool isRecurring; // 반복 일정 여부
  final String? emoji; // icon을 이모지로 변환

  const TaskModel({
    required this.id,
    this.userId,
    required this.title,
    this.memo,
    this.location,
    required this.priority,
    this.alarm = false,
    this.isCompleted = false,
    required this.createdAt,
    this.calendarDate,
    this.startTime,
    this.endTime,
    this.icon,
    this.modifiedDate,
    this.timeModified,
    this.completedAt,
    // 기존 필드들 (하위 호환성)
    this.description,
    this.dueDate,
    this.startDate,
    this.startDateRange,
    this.endDateRange,
    this.isRecurring = false,
    this.emoji,
  });

  TaskModel copyWith({
    String? id,
    int? userId,
    String? title,
    String? memo,
    String? location,
    TaskPriority? priority,
    bool? alarm,
    bool? isCompleted,
    DateTime? createdAt,
    String? calendarDate,
    String? startTime,
    String? endTime,
    String? icon,
    DateTime? modifiedDate,
    DateTime? timeModified,
    DateTime? completedAt,
    // 기존 필드들
    String? description,
    DateTime? dueDate,
    DateTime? startDate,
    DateTime? startDateRange,
    DateTime? endDateRange,
    bool? isRecurring,
    String? emoji,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      memo: memo ?? this.memo,
      location: location ?? this.location,
      priority: priority ?? this.priority,
      alarm: alarm ?? this.alarm,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      calendarDate: calendarDate ?? this.calendarDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      icon: icon ?? this.icon,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      timeModified: timeModified ?? this.timeModified,
      completedAt: completedAt ?? this.completedAt,
      // 기존 필드들
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      startDate: startDate ?? this.startDate,
      startDateRange: startDateRange ?? this.startDateRange,
      endDateRange: endDateRange ?? this.endDateRange,
      isRecurring: isRecurring ?? this.isRecurring,
      emoji: emoji ?? this.emoji,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 기존 로컬 저장용 필드들
      'id': id,
      'userId': userId,
      'title': title,
      'memo': memo,
      'location': location,
      'priority': priority.index,
      'alarm': alarm,
      'isCompleted': isCompleted,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'calendarDate': calendarDate,
      'startTime': startTime,
      'endTime': endTime,
      'icon': icon,
      'modifiedDate': modifiedDate?.millisecondsSinceEpoch,
      'timeModified': timeModified?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      // 기존 필드들 (하위 호환성)
      'description': description,
      'startDate': startDate?.millisecondsSinceEpoch,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'startDateRange': startDateRange?.millisecondsSinceEpoch,
      'endDateRange': endDateRange?.millisecondsSinceEpoch,
      'isRecurring': isRecurring,
      'emoji': emoji,
    };
  }

  /// 기존 로컬 JSON에서 TaskModel 생성 (하위 호환성)
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      userId: json['userId'] as int?,
      title: json['title'] as String,
      memo: json['memo'] as String?,
      location: json['location'] as String?,
      priority: TaskPriority.values[json['priority'] as int],
      alarm: json['alarm'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool,
      createdAt: json['createdAt'] is int 
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : DateTime.parse(json['createdAt'] as String),
      calendarDate: json['calendarDate'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      icon: json['icon'] as String?,
      modifiedDate: json['modifiedDate'] != null
          ? (json['modifiedDate'] is int 
              ? DateTime.fromMillisecondsSinceEpoch(json['modifiedDate'] as int)
              : DateTime.parse(json['modifiedDate'] as String))
          : null,
      timeModified: json['timeModified'] != null
          ? (json['timeModified'] is int 
              ? DateTime.fromMillisecondsSinceEpoch(json['timeModified'] as int)
              : DateTime.parse(json['timeModified'] as String))
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'] as int)
          : null,
      // 기존 필드들 (하위 호환성)
      description: json['description'] as String?,
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
    );
  }

  /// 장소와 메모를 description으로 결합
  static String? _buildDescription(String? location, String? memo) {
    if (location != null && memo != null) {
      return '$location\n$memo';
    } else if (location != null) {
      return location;
    } else if (memo != null) {
      return memo;
    }
    return null;
  }

  /// 아이콘 코드를 이모지로 변환
  static String? _iconToEmoji(String? icon) {
    final iconToEmojiMap = {
      'SMILE': '😀',
      'HAPPY': '😃',
      'JOY': '😄',
      'GRIN': '😁',
      'LAUGH': '😆',
      'HAPPY_EYES': '😊',
      'HEART_EYES': '😍',
      'COOL': '😎',
      'NOTE': '📝',
      'ALARM': '⏰',
      'COMPUTER': '🖥️',
      'IDEA': '💡',
      'HEART': '❤️',
      'FIRE': '🔥',
      // 기본값들
    };
    return iconToEmojiMap[icon] ?? '😊';
  }

  /// 날짜와 시간을 DateTime으로 결합
  static DateTime? _buildDateTime(String? date, String? time) {
    if (date == null || time == null) return null;
    try {
      return DateTime.parse('${date}T$time');
    } catch (e) {
      return null;
    }
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