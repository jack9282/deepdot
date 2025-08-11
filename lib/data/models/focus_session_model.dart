class FocusSessionModel {
  final String id;
  final String taskTitle;
  final int focusMinutes; // 실제 집중한 시간 (분)
  final int plannedMinutes; // 설정된 집중시간 (분)
  final DateTime startTime;
  final DateTime endTime;
  final bool completedNaturally; // true: 타이머 완료, false: 수동 완료
  final DateTime createdAt;

  const FocusSessionModel({
    required this.id,
    required this.taskTitle,
    required this.focusMinutes,
    required this.plannedMinutes,
    required this.startTime,
    required this.endTime,
    required this.completedNaturally,
    required this.createdAt,
  });

  FocusSessionModel copyWith({
    String? id,
    String? taskTitle,
    int? focusMinutes,
    int? plannedMinutes,
    DateTime? startTime,
    DateTime? endTime,
    bool? completedNaturally,
    DateTime? createdAt,
  }) {
    return FocusSessionModel(
      id: id ?? this.id,
      taskTitle: taskTitle ?? this.taskTitle,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      completedNaturally: completedNaturally ?? this.completedNaturally,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskTitle': taskTitle,
      'focusMinutes': focusMinutes,
      'plannedMinutes': plannedMinutes,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'completedNaturally': completedNaturally,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory FocusSessionModel.fromJson(Map<String, dynamic> json) {
    return FocusSessionModel(
      id: json['id'] as String,
      taskTitle: json['taskTitle'] as String,
      focusMinutes: json['focusMinutes'] as int,
      plannedMinutes: json['plannedMinutes'] as int? ?? 25, // 기본값 25분 (기존 데이터 호환성)
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime'] as int),
      endTime: DateTime.fromMillisecondsSinceEpoch(json['endTime'] as int),
      completedNaturally: json['completedNaturally'] as bool,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }

  @override
  String toString() {
    return 'FocusSessionModel(id: $id, taskTitle: $taskTitle, focusMinutes: $focusMinutes)';
  }
}
