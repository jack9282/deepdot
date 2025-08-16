class TakingModel {
  final String id;
  final String name;
  final List<String> times;
  final bool alarmEnabled;
  final String alarmTime;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TakingModel({
    required this.id,
    required this.name,
    required this.times,
    required this.alarmEnabled,
    required this.alarmTime,
    required this.createdAt,
    this.updatedAt,
  });

  factory TakingModel.fromJson(Map<String, dynamic> json) {
    return TakingModel(
      id: json['id'] as String,
      name: json['name'] as String,
      times: List<String>.from(json['times'] as List),
      alarmEnabled: json['alarmEnabled'] as bool? ?? false,
      alarmTime: json['alarmTime'] as String? ?? '08:00',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'times': times,
      'alarmEnabled': alarmEnabled,
      'alarmTime': alarmTime,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
} 