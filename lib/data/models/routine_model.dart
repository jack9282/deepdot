class RoutineModel {
  final int? routineId;
  final String name;
  final int goalId;
  final String goalName;
  final bool mon;
  final bool tue;
  final bool wed;
  final bool thu;
  final bool fri;
  final bool sat;
  final bool sun;
  final bool active;
  final String memo;
  final Map<String, int> startTime;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? alarmId;
  final List<bool> checkStates;

  RoutineModel({
    this.routineId,
    required this.name,
    required this.goalId,
    required this.goalName,
    required this.mon,
    required this.tue,
    required this.wed,
    required this.thu,
    required this.fri,
    required this.sat,
    required this.sun,
    required this.active,
    required this.memo,
    required this.startTime,
    required this.createdAt,
    this.updatedAt,
    this.alarmId,
    List<bool>? checkStates,
  }) : checkStates = checkStates ?? List.generate(7, (_) => false);

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    int parseGoalId(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    return RoutineModel(
      routineId: json['routineId'] != null ? int.tryParse(json['routineId'].toString()) : null,
      name: json['name'] as String? ?? '',
      goalId: parseGoalId(json['goalId']),
      goalName: json['goalName'] as String? ?? '새 목표',
      mon: json['mon'] as bool? ?? false,
      tue: json['tue'] as bool? ?? false,
      wed: json['wed'] as bool? ?? false,
      thu: json['thu'] as bool? ?? false,
      fri: json['fri'] as bool? ?? false,
      sat: json['sat'] as bool? ?? false,
      sun: json['sun'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
      memo: json['memo'] as String? ?? '',
      startTime: _parseStartTime(json['start_time'] ?? json['startTime']),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      alarmId: json['alarmId'] != null ? int.tryParse(json['alarmId'].toString()) : null,
      checkStates: _parseCheckStates(json['checkStates']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (routineId != null) 'routineId': routineId,
      'name': name,
      'goalId': goalId,
      'goalName': goalName,
      'mon': mon,
      'tue': tue,
      'wed': wed,
      'thu': thu,
      'fri': fri,
      'sat': sat,
      'sun': sun,
      'active': active,
      'memo': memo,
      'start_time': startTime,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (alarmId != null) 'alarmId': alarmId,
      'checkStates': checkStates,
    };
  }

  Map<String, dynamic> toApiJson() {
    return {
      'name': name,
      'goalId': goalId,
      'mon': mon,
      'tue': tue,
      'wed': wed,
      'thu': thu,
      'fri': fri,
      'sat': sat,
      'sun': sun,
      'active': active,
      'memo': memo,
      'start_time': startTime,
    };
  }

  RoutineModel copyWith({
    int? routineId,
    String? name,
    int? goalId,
    String? goalName,
    bool? mon,
    bool? tue,
    bool? wed,
    bool? thu,
    bool? fri,
    bool? sat,
    bool? sun,
    bool? active,
    String? memo,
    Map<String, int>? startTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? alarmId,
    List<bool>? checkStates,
  }) {
    return RoutineModel(
      routineId: routineId ?? this.routineId,
      name: name ?? this.name,
      goalId: goalId ?? this.goalId,
      goalName: goalName ?? this.goalName,
      mon: mon ?? this.mon,
      tue: tue ?? this.tue,
      wed: wed ?? this.wed,
      thu: thu ?? this.thu,
      fri: fri ?? this.fri,
      sat: sat ?? this.sat,
      sun: sun ?? this.sun,
      active: active ?? this.active,
      memo: memo ?? this.memo,
      startTime: startTime ?? this.startTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      alarmId: alarmId ?? this.alarmId,
      checkStates: checkStates ?? this.checkStates,
    );
  }

  List<String> get days {
    final days = <String>[];
    if (mon) days.add('월');
    if (tue) days.add('화');
    if (wed) days.add('수');
    if (thu) days.add('목');
    if (fri) days.add('금');
    if (sat) days.add('토');
    if (sun) days.add('일');
    return days;
  }

  String get startTimeString {
    final hour = startTime['hour'] ?? 8;
    final minute = startTime['minute'] ?? 0;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  bool get notificationEnabled => active;

  static Map<String, int> _defaultStartTime() => {
    'hour': 8,
    'minute': 0,
    'second': 0,
    'nano': 0,
  };

  static Map<String, int> _parseStartTime(dynamic startTime) {
    if (startTime == null) {
      return _defaultStartTime();
    }
    
    if (startTime is Map<String, dynamic>) {
      return {
        'hour': startTime['hour'] as int? ?? 8,
        'minute': startTime['minute'] as int? ?? 0,
        'second': startTime['second'] as int? ?? 0,
        'nano': startTime['nano'] as int? ?? 0,
      };
    }
    
    if (startTime is String) {
      final parts = startTime.split(':');
      if (parts.length >= 2) {
        return {
          'hour': int.tryParse(parts[0]) ?? 8,
          'minute': int.tryParse(parts[1]) ?? 0,
          'second': parts.length >= 3 ? (int.tryParse(parts[2]) ?? 0) : 0,
          'nano': 0,
        };
      }
    }
    
    return _defaultStartTime();
  }

  static List<bool> _parseCheckStates(dynamic checkStates) {
    if (checkStates == null) {
      return List.generate(7, (_) => false);
    }
    
    if (checkStates is List) {
      return checkStates.map((item) => item == true).toList();
    }
    
    return List.generate(7, (_) => false);
  }
} 