/// 날짜와 시간을 API에서 요구하는 형식으로 변환하는 유틸리티 클래스
class DateTimeFormatter {
  /// DateTime을 yyyy-MM-dd 형식의 문자열로 변환
  /// 예: 2025-01-20
  static String toDateString(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
  }

  /// DateTime을 HH:mm:ss 형식의 문자열로 변환
  /// 예: 14:30:00
  static String toTimeString(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }



  /// yyyy-MM-dd HH:mm:ss 형식의 문자열을 DateTime으로 변환
  static DateTime fromDateTimeString(String dateTimeString) {
    return DateTime.parse(dateTimeString);
  }

  /// yyyy-MM-dd 문자열을 DateTime으로 변환
  static DateTime fromDateString(String dateString) {
    return DateTime.parse(dateString);
  }

  /// HH:mm:ss 문자열을 Duration으로 변환
  static Duration fromTimeString(String timeString) {
    final parts = timeString.split(':');
    if (parts.length != 3) {
      throw ArgumentError('시간 형식이 올바르지 않습니다: $timeString');
    }
    
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = int.parse(parts[2]);
    
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  /// 현재 시간을 기준으로 API 요청용 데이터 생성 (테스트용)
  static Map<String, String> getCurrentTimeData() {
    final now = DateTime.now();
    final oneHourLater = now.add(const Duration(hours: 1));
    
    return {
      'calendarDate': toDateString(now),
      'startTime': toTimeString(now),
      'endTime': toTimeString(oneHourLater),
    };
  }
}
