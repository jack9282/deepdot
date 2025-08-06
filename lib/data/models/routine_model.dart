class RoutineItem {
  final String name;
  final List<String> days;

  RoutineItem({required this.name, required this.days});

  factory RoutineItem.fromJson(Map<String, dynamic> json) {
    return RoutineItem(
      name: json['name'] as String,
      days: List<String>.from(json['days'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'days': days,
    };
  }
}

class RoutineModel {
  final String id;
  final String name;
  final List<RoutineItem> items;
  final bool notificationEnabled;
  final int hour;
  final int minute;
  final bool isAM;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RoutineModel({
    required this.id,
    required this.name,
    required this.items,
    required this.notificationEnabled,
    required this.hour,
    required this.minute,
    required this.isAM,
    required this.createdAt,
    this.updatedAt,
  });

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    return RoutineModel(
      id: json['id'] as String,
      name: json['name'] as String,
      items: (json['items'] as List).map((e) {
        if (e is String) {
          // 기존 데이터: 문자열 리스트 → RoutineItem으로 마이그레이션
          return RoutineItem(name: e, days: []);
        } else {
          // 새 데이터: RoutineItem 객체
          return RoutineItem.fromJson(e);
        }
      }).toList(),
      notificationEnabled: json['notificationEnabled'] as bool,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      isAM: json['isAM'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((e) => e.toJson()).toList(),
      'notificationEnabled': notificationEnabled,
      'hour': hour,
      'minute': minute,
      'isAM': isAM,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
} 