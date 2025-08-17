class AlarmIdGenerator {
  static int _counter = 0;
  static const int _maxId = 2147483647; // 32비트 정수 최대값

  /// 안전한 알람 ID를 생성합니다.
  /// 32비트 정수 범위 내에서 고유한 ID를 반환합니다.
  static int generateId() {
    _counter = (_counter + 1) % _maxId;
    if (_counter == 0) _counter = 1; // 0은 피합니다
    return _counter;
  }

  /// 주간 알람을 위한 ID를 생성합니다.
  /// baseId와 weekday를 조합하여 고유한 ID를 생성합니다.
  static int generateWeeklyId(int baseId, int weekday) {
    final combined = baseId * 10 + weekday;
    return combined % _maxId;
  }

  /// 복용 알람을 위한 ID를 생성합니다.
  /// baseId와 index를 조합하여 고유한 ID를 생성합니다.
  static int generateTakingId(int baseId, int index) {
    final combined = baseId + index;
    return combined % _maxId;
  }
} 