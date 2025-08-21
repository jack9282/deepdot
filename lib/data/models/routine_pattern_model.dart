/// 루틴 패턴을 감지하고 저장하기 위한 모델
class RoutinePatternModel {
  final String title;        // 일정 제목
  final String? time;         // 시간 (HH:mm)
  final List<int> weekdays;  // 요일 패턴 [1,2,3,4,5] = 월~금
  final int count;           // 반복 횟수
  final DateTime lastAdded;  // 마지막 추가 시간
  
  const RoutinePatternModel({
    required this.title,
    this.time,
    required this.weekdays,
    required this.count,
    required this.lastAdded,
  });
  
  /// JSON에서 모델 생성
  factory RoutinePatternModel.fromJson(Map<String, dynamic> json) {
    return RoutinePatternModel(
      title: json['title'] as String,
      time: json['time'] as String?,
      weekdays: (json['weekdays'] as List<dynamic>).cast<int>(),
      count: json['count'] as int,
      lastAdded: DateTime.parse(json['lastAdded'] as String),
    );
  }
  
  /// 모델을 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'time': time,
      'weekdays': weekdays,
      'count': count,
      'lastAdded': lastAdded.toIso8601String(),
    };
  }
  
  /// 패턴 키 생성 (제목과 시간을 조합한 유니크 키)
  String get patternKey => '${title.toLowerCase()}_${time ?? 'no_time'}';
  
  /// 새로운 카운트로 복사
  RoutinePatternModel copyWithNewCount(int newCount) {
    return RoutinePatternModel(
      title: title,
      time: time,
      weekdays: weekdays,
      count: newCount,
      lastAdded: DateTime.now(),
    );
  }
  
  /// 요일 추가
  RoutinePatternModel addWeekday(int weekday) {
    final newWeekdays = List<int>.from(weekdays);
    if (!newWeekdays.contains(weekday)) {
      newWeekdays.add(weekday);
      newWeekdays.sort();
    }
    return RoutinePatternModel(
      title: title,
      time: time,
      weekdays: newWeekdays,
      count: count,
      lastAdded: lastAdded,
    );
  }
  
  /// 패턴이 일치하는지 확인 (제목과 시간이 같은지)
  bool matchesPattern(String otherTitle, String? otherTime) {
    return title.toLowerCase() == otherTitle.toLowerCase() && 
           time == otherTime;
  }
  
  /// 루틴으로 추천할 수 있는지 확인 (5번 이상 반복)
  bool get isRecommendable => count >= 5;
  
  /// 요일 패턴을 문자열로 변환
  String get weekdayPattern {
    if (weekdays.isEmpty) return '패턴 없음';
    
    // 연속된 요일 체크
    if (weekdays.length >= 5 && _isConsecutiveWeekdays()) {
      if (weekdays.contains(1) && weekdays.contains(5) && !weekdays.contains(6) && !weekdays.contains(7)) {
        return '평일';
      }
    }
    
    if (weekdays.length == 2 && weekdays.contains(6) && weekdays.contains(7)) {
      return '주말';
    }
    
    // 개별 요일 표시
    const weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays.map((day) => weekdayNames[day - 1]).join(', ');
  }
  
  /// 연속된 요일인지 확인
  bool _isConsecutiveWeekdays() {
    if (weekdays.isEmpty) return false;
    for (int i = 0; i < weekdays.length - 1; i++) {
      if (weekdays[i + 1] - weekdays[i] != 1) {
        // 금요일(5) -> 월요일(1) 패턴은 예외
        if (!(weekdays[i] == 5 && weekdays[i + 1] == 1)) {
          return false;
        }
      }
    }
    return true;
  }
}