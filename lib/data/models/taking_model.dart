class TakingModel {
  final String id;
  final String name;
  final List<String> times;
  final List<int> timeIds; // timeId 목록 추가
  final bool alarmEnabled;
  final String alarmTime;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TakingModel({
    required this.id,
    required this.name,
    required this.times,
    required this.timeIds,
    required this.alarmEnabled,
    required this.alarmTime,
    required this.createdAt,
    this.updatedAt,
  });

  factory TakingModel.fromJson(Map<String, dynamic> json) {
    final timesList = json['times'] != null 
        ? (json['times'] as List).map((timeObj) {
            if (timeObj is String) {
              return timeObj;
            } else if (timeObj is Map<String, dynamic>) {
              // 기존 형식과의 호환성을 위해 유지
              final hour = timeObj['hour']?.toString().padLeft(2, '0') ?? '00';
              final minute = timeObj['minute']?.toString().padLeft(2, '0') ?? '00';
              return '$hour:$minute';
            } else {
              return '08:00';
            }
          }).toList()
        : ['08:00', '12:00', '18:00'];
    
    // timeIds 생성 (API에서 제공하지 않으면 인덱스 기반으로 생성)
    final timeIds = json['timeIds'] != null 
        ? (json['timeIds'] as List).map((id) => id is int ? id : int.tryParse(id.toString()) ?? 0).toList()
        : List.generate(timesList.length, (index) => index + 1);
    
    return TakingModel(
      id: json['medicationId']?.toString() ?? json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? '',
      times: timesList,
      timeIds: timeIds,
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
      'timeIds': timeIds,
      'alarmEnabled': alarmEnabled,
      'alarmTime': alarmTime,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
} 