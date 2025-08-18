enum ScheduleType {
  urgentNow('지금_바로_해야해요'),
  planAhead('미리_계획해서_준비해요'),
  whenFree('시간이_남을_때_해요'),
  laterProcessing('나중에_처리해요');

  final String value;
  const ScheduleType(this.value);

  static ScheduleType fromString(String value) {
    return values.firstWhere(
      (type) => type.value == value,
      orElse: () => ScheduleType.laterProcessing,
    );
  }
}

class ScheduleModel {
  final int? scheduleId;
  final String title;
  final String? time;
  final String startDate;
  final String endDate;
  final String type;
  final String? location;
  final String? memo;
  final String? image;
  final bool alarm30Before;
  final bool alarm60Before;
  final bool alarm120Before;
  final bool isRecurring;

  const ScheduleModel({
    this.scheduleId,
    required this.title,
    this.time,
    required this.startDate,
    required this.endDate,
    required this.type,
    this.location,
    this.memo,
    this.image,
    this.alarm30Before = false,
    this.alarm60Before = false,
    this.alarm120Before = false,
    this.isRecurring = false,
  });

  Map<String, dynamic> toJson() {
    return {
      if (scheduleId != null) 'scheduleId': scheduleId,
      'title': title,
      'time': time,
      'startDate': startDate,
      'endDate': endDate,
      'type': type,
      'location': location,
      'memo': memo,
      'image': image,
      'alarm30Before': alarm30Before,
      'alarm60Before': alarm60Before,
      'alarm120Before': alarm120Before,
      'isRecurring': isRecurring,
    };
  }

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      scheduleId: json['scheduleId'] as int?,
      title: json['title'] as String,
      time: json['time'] as String?,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      type: json['type'] as String,
      location: json['location'] as String?,
      memo: json['memo'] as String?,
      image: json['image'] as String?,
      alarm30Before: json['alarm30Before'] as bool? ?? false,
      alarm60Before: json['alarm60Before'] as bool? ?? false,
      alarm120Before: json['alarm120Before'] as bool? ?? false,
      isRecurring: json['recurring'] as bool? ?? json['isRecurring'] as bool? ?? false,
    );
  }

  ScheduleModel copyWith({
    int? scheduleId,
    String? title,
    String? time,
    String? startDate,
    String? endDate,
    String? type,
    String? location,
    String? memo,
    String? image,
    bool? alarm30Before,
    bool? alarm60Before,
    bool? alarm120Before,
    bool? isRecurring,
  }) {
    return ScheduleModel(
      scheduleId: scheduleId ?? this.scheduleId,
      title: title ?? this.title,
      time: time ?? this.time,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      location: location ?? this.location,
      memo: memo ?? this.memo,
      image: image ?? this.image,
      alarm30Before: alarm30Before ?? this.alarm30Before,
      alarm60Before: alarm60Before ?? this.alarm60Before,
      alarm120Before: alarm120Before ?? this.alarm120Before,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }

  @override
  String toString() {
    return 'ScheduleModel(scheduleId: $scheduleId, title: $title, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleModel && other.scheduleId == scheduleId;
  }

  @override
  int get hashCode => scheduleId.hashCode;
}