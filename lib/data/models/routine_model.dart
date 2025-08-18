class RoutineModel {
  final String id;
  final String name;
  final List<String> goals;
  final List<String> days;
  final bool notificationEnabled;
  final String notificationTime;
  final String memo;
  final List<bool> checks; // 단순화: List<List<bool>> -> List<bool>
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? alarmId; // 알람 ID 추가


  RoutineModel({
    required this.id,
    required this.name,
    required this.goals,
    required this.days,
    required this.notificationEnabled,
    required this.notificationTime,
    required this.memo,
    required this.checks,
    required this.createdAt,
    this.updatedAt,
    this.alarmId,
  });

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    // 기존 List<List<bool>> 구조를 List<bool>로 변환
    List<bool> checks = [];
    final checksData = json['checks'] as List? ?? [];
    
    if (checksData.isNotEmpty && checksData.first is List) {
      // 기존 구조: List<List<bool>>
      checks = checksData.map((item) {
        if (item is List && item.isNotEmpty) {
          return item.first as bool? ?? false;
        }
        return false;
      }).toList();
    } else {
      // 새로운 구조: List<bool>
      checks = checksData.map((item) => item as bool? ?? false).toList();
    }
    
    // 7일치 체크 상태 보장
    while (checks.length < 7) {
      checks.add(false);
    }
    if (checks.length > 7) {
      checks = checks.take(7).toList();
    }

    return RoutineModel(
      id: json['id'] as String,
      name: json['name'] as String,
      goals: List<String>.from(json['goals'] as List? ?? []),
      days: List<String>.from(json['days'] as List? ?? []),
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      notificationTime: json['notificationTime'] as String? ?? '08:20',
      memo: json['memo'] as String? ?? '',
      checks: checks,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      alarmId: json['alarmId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'goals': goals,
      'days': days,
      'notificationEnabled': notificationEnabled,
      'notificationTime': notificationTime,
      'memo': memo,
      'checks': checks,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (alarmId != null) 'alarmId': alarmId,
    };
  }

  // 체크 상태 업데이트를 위한 복사 메서드
  RoutineModel copyWith({
    String? id,
    String? name,
    List<String>? goals,
    List<String>? days,
    bool? notificationEnabled,
    String? notificationTime,
    String? memo,
    List<bool>? checks,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? alarmId,
  }) {
    return RoutineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      goals: goals ?? this.goals,
      days: days ?? this.days,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
      memo: memo ?? this.memo,
      checks: checks ?? this.checks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      alarmId: alarmId ?? this.alarmId,
    );
  }
} 