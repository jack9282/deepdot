import '../models/schedule_model.dart';
import '../../api/schedule_api.dart';

class ScheduleRepository {
  /// 일정 생성
  Future<int> createSchedule(ScheduleModel schedule) async {
    try {
      return await ScheduleApi.createSchedule(schedule);
    } catch (e) {
      throw Exception('일정 생성 실패: $e');
    }
  }

  /// 일정 단일 조회
  Future<ScheduleModel> getSchedule(int scheduleId) async {
    try {
      return await ScheduleApi.getSchedule(scheduleId);
    } catch (e) {
      throw Exception('일정 조회 실패: $e');
    }
  }

  /// 모든 일정 조회
  Future<List<ScheduleModel>> getAllSchedules() async {
    try {
      return await ScheduleApi.getAllSchedules();
    } catch (e) {
      throw Exception('일정 목록 조회 실패: $e');
    }
  }

  /// 특정 날짜 일정 조회
  Future<List<ScheduleModel>> getSchedulesByDate(DateTime date) async {
    try {
      final dateStr = _formatDate(date);
      return await ScheduleApi.getSchedulesByDate(dateStr);
    } catch (e) {
      throw Exception('날짜별 일정 조회 실패: $e');
    }
  }

  /// 기간별 일정 조회
  Future<List<ScheduleModel>> getSchedulesByRange(DateTime from, DateTime to) async {
    try {
      final fromStr = _formatDate(from);
      final toStr = _formatDate(to);
      return await ScheduleApi.getSchedulesByRange(fromStr, toStr);
    } catch (e) {
      throw Exception('기간별 일정 조회 실패: $e');
    }
  }

  /// 일정 배치 생성 (여러 날짜에 동일한 일정 생성)
  Future<List<int>> createScheduleBatch(DateTime from, DateTime to, ScheduleModel schedule) async {
    try {
      final fromStr = _formatDate(from);
      final toStr = _formatDate(to);
      return await ScheduleApi.createScheduleBatch(fromStr, toStr, schedule);
    } catch (e) {
      throw Exception('일정 배치 생성 실패: $e');
    }
  }

  /// 일정 수정
  Future<void> updateSchedule(int scheduleId, ScheduleModel schedule) async {
    try {
      await ScheduleApi.updateSchedule(scheduleId, schedule);
    } catch (e) {
      throw Exception('일정 수정 실패: $e');
    }
  }

  /// 일정 삭제
  Future<void> deleteSchedule(int scheduleId) async {
    try {
      await ScheduleApi.deleteSchedule(scheduleId);
    } catch (e) {
      throw Exception('일정 삭제 실패: $e');
    }
  }

  /// 날짜를 yyyy-MM-dd 형식으로 변환
  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }

  /// 시간을 HH:mm 형식으로 변환
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}';
  }

  /// 오늘 일정 조회
  Future<List<ScheduleModel>> getTodaySchedules() async {
    return getSchedulesByDate(DateTime.now());
  }

  /// 이번 주 일정 조회
  Future<List<ScheduleModel>> getWeekSchedules() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return getSchedulesByRange(startOfWeek, endOfWeek);
  }

  /// 이번 달 일정 조회
  Future<List<ScheduleModel>> getMonthSchedules() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return getSchedulesByRange(startOfMonth, endOfMonth);
  }

  /// 특정 타입의 일정만 필터링
  Future<List<ScheduleModel>> getSchedulesByType(String type) async {
    final allSchedules = await getAllSchedules();
    return allSchedules.where((schedule) => schedule.type == type).toList();
  }

  /// 알람이 설정된 일정만 조회
  Future<List<ScheduleModel>> getSchedulesWithAlarm() async {
    final allSchedules = await getAllSchedules();
    return allSchedules.where((schedule) => 
      schedule.alarm30Before || schedule.alarm60Before || schedule.alarm120Before
    ).toList();
  }

  /// 반복 일정만 조회
  Future<List<ScheduleModel>> getRecurringSchedules() async {
    final allSchedules = await getAllSchedules();
    return allSchedules.where((schedule) => schedule.isRecurring).toList();
  }
}