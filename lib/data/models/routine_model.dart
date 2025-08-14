class RoutineModel {
  final String id;
  final String name;
  final List<String> goals;
  final List<String> days;
  final bool notificationEnabled;
  final String memo;
  final List<List<bool>> checks; // 체크 상태 추가
  final DateTime createdAt;
  final DateTime? updatedAt;

  RoutineModel({
    required this.id,
    required this.name,
    required this.goals,
    required this.days,
    required this.notificationEnabled,
    required this.memo,
    required this.checks,
    required this.createdAt,
    this.updatedAt,
  });

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    return RoutineModel(
      id: json['id'] as String,
      name: json['name'] as String,
      goals: List<String>.from(json['goals'] as List? ?? []),
      days: List<String>.from(json['days'] as List? ?? []),
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      memo: json['memo'] as String? ?? '',
      checks: (json['checks'] as List? ?? []).map((item) => List<bool>.from(item)).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'goals': goals,
      'days': days,
      'notificationEnabled': notificationEnabled,
      'memo': memo,
      'checks': checks,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
} 