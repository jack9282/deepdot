import 'dart:convert';
import '../models/schedule_model.dart';
import '../../api/schedule_api.dart';
import '../../utils/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleRepository {
  static const String _localSchedulesKey = 'local_schedules';
  static const String _nextLocalIdKey = 'next_local_schedule_id';
  
  /// 로컬 일정 저장
  Future<void> _saveSchedulesToLocal(List<ScheduleModel> schedules) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schedulesJson = schedules.map((s) => s.toJson()).toList();
      await prefs.setString(_localSchedulesKey, jsonEncode(schedulesJson));
    } catch (e) {
      print('로컬 일정 저장 실패: $e');
    }
  }
  
  /// 로컬 일정 불러오기
  Future<List<ScheduleModel>> _getSchedulesFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schedulesString = prefs.getString(_localSchedulesKey);
      if (schedulesString == null) return [];
      
      final List<dynamic> schedulesJson = jsonDecode(schedulesString);
      return schedulesJson
          .map((json) => ScheduleModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('로컬 일정 불러오기 실패: $e');
      return [];
    }
  }
  
  /// 다음 로컬 ID 가져오기 (오프라인 모드용)
  Future<int> _getNextLocalId() async {
    final prefs = await SharedPreferences.getInstance();
    final currentId = prefs.getInt(_nextLocalIdKey) ?? -1;
    final nextId = currentId - 1; // 음수로 로컬 ID 생성
    await prefs.setInt(_nextLocalIdKey, nextId);
    return nextId;
  }
  
  /// 서버와 로컬 데이터 병합
  Future<List<ScheduleModel>> _mergeSchedules(
    List<ScheduleModel> serverSchedules,
    List<ScheduleModel> localSchedules,
  ) async {
    // 서버 일정 ID 목록
    final serverIds = serverSchedules.map((s) => s.scheduleId).toSet();
    
    // 로컬에만 있는 일정 (오프라인에서 생성된 일정)
    final localOnlySchedules = localSchedules
        .where((local) => !serverIds.contains(local.scheduleId))
        .toList();
    
    // 병합: 서버 데이터 + 로컬 전용 데이터
    final merged = [...serverSchedules, ...localOnlySchedules];
    
    // 병합된 데이터를 로컬에 저장
    await _saveSchedulesToLocal(merged);
    
    return merged;
  }
  /// 일정 생성 (온라인/오프라인 모드 지원)
  Future<int> createSchedule(ScheduleModel schedule) async {
    try {
      // 서버에 생성 시도
      final scheduleId = await ScheduleApi.createSchedule(schedule);
      
      // 서버 생성 성공 시 로컬에도 저장
      final localSchedules = await _getSchedulesFromLocal();
      final scheduleWithId = ScheduleModel(
        scheduleId: scheduleId,
        title: schedule.title,
        time: schedule.time,
        startDate: schedule.startDate,
        endDate: schedule.endDate,
        type: schedule.type,
        location: schedule.location,
        memo: schedule.memo,
        image: schedule.image,
        alarm30Before: schedule.alarm30Before,
        alarm60Before: schedule.alarm60Before,
        alarm120Before: schedule.alarm120Before,
        isRecurring: schedule.isRecurring,
      );
      localSchedules.add(scheduleWithId);
      await _saveSchedulesToLocal(localSchedules);
      
      return scheduleId;
    } catch (e) {
      // 서버 실패 시 로컬에만 저장 (오프라인 모드)
      print('서버 일정 생성 실패, 로컬 저장 시도: $e');
      
      final localSchedules = await _getSchedulesFromLocal();
      final localId = await _getNextLocalId();
      final scheduleWithId = ScheduleModel(
        scheduleId: localId,
        title: schedule.title,
        time: schedule.time,
        startDate: schedule.startDate,
        endDate: schedule.endDate,
        type: schedule.type,
        location: schedule.location,
        memo: schedule.memo,
        image: schedule.image,
        alarm30Before: schedule.alarm30Before,
        alarm60Before: schedule.alarm60Before,
        alarm120Before: schedule.alarm120Before,
        isRecurring: schedule.isRecurring,
      );
      localSchedules.add(scheduleWithId);
      await _saveSchedulesToLocal(localSchedules);
      
      return localId;
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

  /// 모든 일정 조회 (서버 + 로컬 병합)
  Future<List<ScheduleModel>> getAllSchedules() async {
    final localSchedules = await _getSchedulesFromLocal();
    
    try {
      // 서버에서 일정 조회 시도
      final serverSchedules = await ScheduleApi.getAllSchedules();
      
      // 서버와 로컬 데이터 병합
      return await _mergeSchedules(serverSchedules, localSchedules);
    } catch (e) {
      // 서버 실패 시 로컬 데이터만 반환 (오프라인 모드)
      print('서버 일정 조회 실패, 로컬 데이터 사용: $e');
      return localSchedules;
    }
  }

  /// 특정 날짜 일정 조회 (서버 + 로컬 병합)
  Future<List<ScheduleModel>> getSchedulesByDate(DateTime date) async {
    final dateStr = _formatDate(date);
    
    try {
      // 서버에서 날짜별 일정 조회
      final serverSchedules = await ScheduleApi.getSchedulesByDate(dateStr);
      
      // 로컬에서도 날짜별 일정 필터링
      final localSchedules = await _getSchedulesFromLocal();
      final localDateSchedules = localSchedules.where((schedule) {
        final startDate = DateTime.parse(schedule.startDate);
        final endDate = DateTime.parse(schedule.endDate);
        final targetDate = DateTime(date.year, date.month, date.day);
        
        return targetDate.isAtSameMomentAs(startDate) ||
               targetDate.isAtSameMomentAs(endDate) ||
               (targetDate.isAfter(startDate) && targetDate.isBefore(endDate));
      }).toList();
      
      // 병합 후 반환
      final merged = await _mergeSchedules(serverSchedules, localDateSchedules);
      return merged.where((schedule) {
        final startDate = DateTime.parse(schedule.startDate);
        final endDate = DateTime.parse(schedule.endDate);
        final targetDate = DateTime(date.year, date.month, date.day);
        
        return targetDate.isAtSameMomentAs(startDate) ||
               targetDate.isAtSameMomentAs(endDate) ||
               (targetDate.isAfter(startDate) && targetDate.isBefore(endDate));
      }).toList();
    } catch (e) {
      // 서버 실패 시 로컬 데이터만 사용
      print('서버 날짜별 일정 조회 실패, 로컬 데이터 사용: $e');
      
      final localSchedules = await _getSchedulesFromLocal();
      return localSchedules.where((schedule) {
        final startDate = DateTime.parse(schedule.startDate);
        final endDate = DateTime.parse(schedule.endDate);
        final targetDate = DateTime(date.year, date.month, date.day);
        
        return targetDate.isAtSameMomentAs(startDate) ||
               targetDate.isAtSameMomentAs(endDate) ||
               (targetDate.isAfter(startDate) && targetDate.isBefore(endDate));
      }).toList();
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

  /// 일정 수정 (온라인/오프라인 모드 지원)
  Future<void> updateSchedule(int scheduleId, ScheduleModel schedule) async {
    // 로컬 데이터 업데이트
    final localSchedules = await _getSchedulesFromLocal();
    final index = localSchedules.indexWhere((s) => s.scheduleId == scheduleId);
    if (index != -1) {
      localSchedules[index] = schedule;
      await _saveSchedulesToLocal(localSchedules);
    }
    
    try {
      // 서버 업데이트 시도
      await ScheduleApi.updateSchedule(scheduleId, schedule);
    } catch (e) {
      // 서버 실패해도 로컬은 이미 업데이트됨
      print('서버 일정 수정 실패, 로컬만 수정됨: $e');
    }
  }

  /// 일정 삭제 (온라인/오프라인 모드 지원)
  Future<void> deleteSchedule(int scheduleId) async {
    // 로컬 데이터에서 삭제
    final localSchedules = await _getSchedulesFromLocal();
    localSchedules.removeWhere((s) => s.scheduleId == scheduleId);
    await _saveSchedulesToLocal(localSchedules);
    
    try {
      // 서버에서 삭제 시도
      await ScheduleApi.deleteSchedule(scheduleId);
    } catch (e) {
      // 서버 실패해도 로컬은 이미 삭제됨
      print('서버 일정 삭제 실패, 로컬만 삭제됨: $e');
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

  /// 특정 타입의 일정만 필터링 (로컬 캐시 우선)
  Future<List<ScheduleModel>> getSchedulesByType(String type) async {
    final allSchedules = await getAllSchedules(); // 이미 병합된 데이터
    return allSchedules.where((schedule) => schedule.type == type).toList();
  }

  /// 알람이 설정된 일정만 조회 (로컬 캐시 우선)
  Future<List<ScheduleModel>> getSchedulesWithAlarm() async {
    final allSchedules = await getAllSchedules(); // 이미 병합된 데이터
    return allSchedules.where((schedule) => 
      schedule.alarm30Before || schedule.alarm60Before || schedule.alarm120Before
    ).toList();
  }

  /// 반복 일정만 조회 (로컬 캐시 우선)
  Future<List<ScheduleModel>> getRecurringSchedules() async {
    final allSchedules = await getAllSchedules(); // 이미 병합된 데이터
    return allSchedules.where((schedule) => schedule.isRecurring).toList();
  }
  
  /// 로컬 일정 데이터 초기화 (로그아웃 시 사용)
  Future<void> clearLocalSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localSchedulesKey);
    await prefs.remove(_nextLocalIdKey);
  }
  
  /// 서버와 로컬 데이터 강제 동기화
  Future<void> syncWithServer() async {
    try {
      final serverSchedules = await ScheduleApi.getAllSchedules();
      final localSchedules = await _getSchedulesFromLocal();
      
      // 로컬에만 있는 일정 (음수 ID)을 서버에 업로드
      final localOnlySchedules = localSchedules.where((s) => 
        s.scheduleId != null && s.scheduleId! < 0
      ).toList();
      
      final updatedLocalSchedules = <ScheduleModel>[];
      
      for (final localSchedule in localSchedules) {
        if (localSchedule.scheduleId != null && localSchedule.scheduleId! < 0) {
          try {
            // 서버에 생성
            final serverId = await ScheduleApi.createSchedule(localSchedule);
            // 로컬 ID를 서버 ID로 업데이트
            final updatedSchedule = ScheduleModel(
              scheduleId: serverId,
              title: localSchedule.title,
              time: localSchedule.time,
              startDate: localSchedule.startDate,
              endDate: localSchedule.endDate,
              type: localSchedule.type,
              location: localSchedule.location,
              memo: localSchedule.memo,
              image: localSchedule.image,
              alarm30Before: localSchedule.alarm30Before,
              alarm60Before: localSchedule.alarm60Before,
              alarm120Before: localSchedule.alarm120Before,
              isRecurring: localSchedule.isRecurring,
            );
            updatedLocalSchedules.add(updatedSchedule);
          } catch (e) {
            print('로컬 일정 서버 동기화 실패: $e');
            updatedLocalSchedules.add(localSchedule);
          }
        } else {
          updatedLocalSchedules.add(localSchedule);
        }
      }
      
      // 최종 병합
      await _mergeSchedules(serverSchedules, updatedLocalSchedules);
    } catch (e) {
      print('서버 동기화 실패: $e');
    }
  }

  /// 모든 일정 알림을 재설정합니다
  Future<void> rescheduleAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('schedule_notification') ?? true;
      
      if (!isEnabled) {
        // 알림이 비활성화되어 있으면 아무것도 하지 않음
        return;
      }
      
      // 알람이 설정된 모든 일정 조회
      final schedulesWithAlarm = await getSchedulesWithAlarm();
      
      for (final schedule in schedulesWithAlarm) {
        // 일정 시작 시간 파싱
        final dateParts = schedule.startDate.split('-');
        final timeParts = (schedule.time ?? '09:00').split(':');
        final scheduledDate = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
        
        // 각 알림 시간대별로 알람 설정
        if (schedule.alarm30Before) {
          final alarmTime = scheduledDate.subtract(const Duration(minutes: 30));
          if (alarmTime.isAfter(DateTime.now())) {
            await AlarmUtility.setAlarm(
              id: 10000 + schedule.scheduleId.hashCode + 30,
              scheduledTime: alarmTime,
              title: '일정 알림',
              body: '${schedule.title}이(가) 30분 후 시작됩니다.',
            );
          }
        }
        
        if (schedule.alarm60Before) {
          final alarmTime = scheduledDate.subtract(const Duration(minutes: 60));
          if (alarmTime.isAfter(DateTime.now())) {
            await AlarmUtility.setAlarm(
              id: 10000 + schedule.scheduleId.hashCode + 60,
              scheduledTime: alarmTime,
              title: '일정 알림',
              body: '${schedule.title}이(가) 1시간 후 시작됩니다.',
            );
          }
        }
        
        if (schedule.alarm120Before) {
          final alarmTime = scheduledDate.subtract(const Duration(minutes: 120));
          if (alarmTime.isAfter(DateTime.now())) {
            await AlarmUtility.setAlarm(
              id: 10000 + schedule.scheduleId.hashCode + 120,
              scheduledTime: alarmTime,
              title: '일정 알림',
              body: '${schedule.title}이(가) 2시간 후 시작됩니다.',
            );
          }
        }
      }
    } catch (e) {
      print('일정 알림 재설정 중 오류: $e');
    }
  }
}