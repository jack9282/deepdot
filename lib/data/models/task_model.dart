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

  /// API 요청용 JSON 변환 (백엔드 명세서에 맞춤)
  Map<String, dynamic> toApiJson() {
    return {
      'scheduleId': int.tryParse(id) ?? 0, // String ID를 int로 변환
      'userId': userId,
      'title': title,
      'memo': memo ?? '',
      'location': location ?? '',
      'type': priorityToString(priority), // enum을 String으로 변환
      'alarm': alarm,
      'calendarDate': calendarDate,
      'startTime': startTime,
      'endTime': endTime,
      'icon': icon,
      'modifiedDate': modifiedDate?.toIso8601String(),
      'timeModified': timeModified?.toIso8601String(),
    };
  }

  /// ScheduleDetailResponse에서 TaskModel 생성
  factory TaskModel.fromScheduleDetail(dynamic scheduleDetail) {
    // ScheduleDetailResponse 객체 또는 Map<String, dynamic> 모두 처리
    Map<String, dynamic> json;
    if (scheduleDetail is Map<String, dynamic>) {
      json = scheduleDetail;
    } else {
      // ScheduleDetailResponse 객체인 경우 Map으로 변환
      json = {
        'scheduleId': scheduleDetail.scheduleId,
        'userId': scheduleDetail.userId,
        'title': scheduleDetail.title,
        'memo': scheduleDetail.memo,
        'location': scheduleDetail.location,
        'alarm': scheduleDetail.alarm,
        'calendarDate': scheduleDetail.calendarDate,
        'startTime': scheduleDetail.startTime,
        'endTime': scheduleDetail.endTime,
        'type': scheduleDetail.type,
        'modifiedDate': scheduleDetail.modifiedDate,
        'timeModified': scheduleDetail.timeModified,
        'icon': scheduleDetail.icon,
      };
    }

    return TaskModel(
      id: json['scheduleId'].toString(), // int를 String으로 변환
      userId: json['userId'] as int?,
      title: json['title'] as String,
      memo: json['memo'] as String?,
      location: json['location'] as String?,
      priority: _stringToPriority(json['type'] as String?), // String을 enum으로 변환
      alarm: json['alarm'] as bool? ?? false,
      isCompleted: false, // 조회된 일정은 완료되지 않은 상태
      createdAt: DateTime.now(), // 생성일은 현재 시간으로 설정
      calendarDate: json['calendarDate'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      icon: json['icon'] as String?,
      modifiedDate: json['modifiedDate'] != null 
          ? DateTime.parse(json['modifiedDate'] as String)
          : null,
      timeModified: json['timeModified'] != null 
          ? DateTime.parse(json['timeModified'] as String)
          : null,
      // 기존 필드들 (계산된 값들)
      description: _buildDescription(json['location'] as String?, json['memo'] as String?),
      emoji: _iconToEmoji(json['icon'] as String?),
      startDate: _buildDateTime(json['calendarDate'] as String?, json['startTime'] as String?),
      dueDate: _buildDateTime(json['calendarDate'] as String?, json['endTime'] as String?),
    );
  }

  /// API 응답에서 TaskModel 생성 (scheduleId 기준)
  factory TaskModel.fromApiJson(Map<String, dynamic> json) {
    return TaskModel(
      id: (json['scheduleId'] ?? json['id']).toString(), // int를 String으로 변환
      userId: json['userId'] as int?,
      title: json['title'] as String,
      memo: json['memo'] as String?,
      location: json['location'] as String?,
      priority: _stringToPriority(json['type'] as String?), // String을 enum으로 변환
      alarm: json['alarm'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      calendarDate: json['calendarDate'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      icon: json['icon'] as String?,
      modifiedDate: json['modifiedDate'] != null 
          ? DateTime.parse(json['modifiedDate'] as String)
          : null,
      timeModified: json['timeModified'] != null 
          ? DateTime.parse(json['timeModified'] as String)
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      // 기존 필드들 (계산된 값들)
      description: _buildDescription(json['location'] as String?, json['memo'] as String?),
      emoji: _iconToEmoji(json['icon'] as String?),
      startDate: _buildDateTime(json['calendarDate'] as String?, json['startTime'] as String?),
      dueDate: _buildDateTime(json['calendarDate'] as String?, json['endTime'] as String?),
    );
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

  /// 우선순위를 문자열로 변환 (백엔드 API type 필드)
  static String priorityToString(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgentImportant:
        return '중요';  // 가장 중요한 것
      case TaskPriority.important:
        return '중요';
      case TaskPriority.urgent:
        return '긴급';
      case TaskPriority.neither:
        return '일반';  // 백엔드 명세서 예시에 맞춤
    }
  }

  /// 문자열을 우선순위로 변환 (백엔드 API type 필드에서)
  static TaskPriority _stringToPriority(String? type) {
    switch (type) {
      case '중요':
        return TaskPriority.important;
      case '긴급':
        return TaskPriority.urgent;
      case '일반':
        return TaskPriority.neither;
      default:
        return TaskPriority.neither; // 기본값
    }
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