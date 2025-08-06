class TakingModel {
  final String id;
  final String name;
  final List<String> times;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TakingModel({
    required this.id,
    required this.name,
    required this.times,
    required this.createdAt,
    this.updatedAt,
  });

  factory TakingModel.fromJson(Map<String, dynamic> json) {
    return TakingModel(
      id: json['id'] as String,
      name: json['name'] as String,
      times: List<String>.from(json['times'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'times': times,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
} 