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
      id: json['medicationId']?.toString() ?? json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? '',
      // API의 times는 {hour, minute, second, nano} 객체 배열이므로 문자열로 변환
      times: json['times'] != null 
          ? (json['times'] as List).map((timeObj) {
              if (timeObj is Map<String, dynamic>) {
                final hour = timeObj['hour']?.toString().padLeft(2, '0') ?? '00';
                final minute = timeObj['minute']?.toString().padLeft(2, '0') ?? '00';
                return '$hour:$minute';
              } else if (timeObj is String) {
                return timeObj;
              } else {
                return '08:00';
              }
            }).toList()
          : ['08:00', '12:00', '18:00'],
      alarmEnabled: json['alarm'] as bool? ?? json['alarmEnabled'] as bool? ?? false,
      // API는 alarmTime을 반환하지 않으므로 기본값 사용 (로컬에서 설정됨)
      alarmTime: json['alarmTime']?.toString() ?? '08:00',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
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