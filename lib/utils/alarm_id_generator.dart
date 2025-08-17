class AlarmIdGenerator {
  static int _takingCounter = 1000;
  static int _routineCounter = 2000;
  static int _scheduleCounter = 3000;

  /// 약물 복용 알람을 위한 ID를 생성합니다.
  static int generateTakingId() {
    _takingCounter = (_takingCounter + 1) % 1999;
    if (_takingCounter < 1000) _takingCounter = 1000;
    return _takingCounter;
  }

  /// 루틴 알람을 위한 ID를 생성합니다.
  static int generateRoutineId() {
    _routineCounter = (_routineCounter + 1) % 2999;
    if (_routineCounter < 2000) _routineCounter = 2000;
    return _routineCounter;
  }

  /// 스케줄 알람을 위한 ID를 생성합니다.
  static int generateScheduleId() {
    _scheduleCounter = (_scheduleCounter + 1) % 3999;
    if (_scheduleCounter < 3000) _scheduleCounter = 3000;
    return _scheduleCounter;
  }

  /// 주간 알람을 위한 ID를 생성합니다.
  /// baseId와 weekday를 조합하여 고유한 ID를 생성합니다.
  static int generateWeeklyId(int baseId, int weekday) {
    final combined = (baseId * 10) + weekday;
    return combined % 2999 + 2000; // 2000-2999 범위 보장
  }

  /// 복용 알람을 위한 ID를 생성합니다.
  /// baseId와 index를 조합하여 고유한 ID를 생성합니다.
  static int generateTakingIdWithIndex(int baseId, int index) {
    final combined = (baseId * 10) + index;
    return combined % 999 + 1000; // 1000-1999 범위 보장
  }

  /// 기존 호환성을 위한 메서드 (deprecated)
  @Deprecated('Use generateTakingId() instead')
  static int generateId() {
    return generateTakingId();
  }
} 