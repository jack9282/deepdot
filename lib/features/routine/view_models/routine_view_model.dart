import 'package:flutter/material.dart';
import '../../../data/repositories/routine_repository.dart';
import '../../../data/models/routine_model.dart';
import '../../../utils/alarm.dart';
import '../../../utils/alarm_id_generator.dart';
import '../../../api/token_manager.dart';

class RoutineViewModel extends ChangeNotifier {
  List<RoutineModel> _routineList = [];
  Map<String, int> _routineAlarmIds = {}; // 루틴 ID와 알람 ID 매핑
  bool _isLoading = false;
  String? _errorMessage;

  List<RoutineModel> get routineList => List.unmodifiable(_routineList);
  List<String> get availableGoals => RoutineRepository().availableGoals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      print('이미 초기화됨 - 건너뛰기');
      return;
    }
    
    print('앱 초기화 시작');
    _setLoading(true);
    _clearError();
    
    try {
      // 앱 시작 시 모든 알람 초기화
      print('앱 시작 - 모든 알람 초기화');
      await removeAllRoutineAlarms();
      
      await RoutineRepository().loadFromStorage();
      await _syncWithApi();
      _loadRoutineList();
      _isInitialized = true;
      
      // 루틴 알람 복원
      await restoreAllRoutineAlarms();
      print('앱 초기화 완료');
    } catch (e) {
      _setError('데이터 로드 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _syncWithApi() async {
    try {
      // 비회원 모드일 때는 API 동기화를 하지 않음
      if (await TokenManager.instance.isGuestMode()) {
        print('비회원 모드 - API 동기화 건너뛰기');
        return;
      }
      
      await RoutineRepository().syncFromApi();
    } catch (e) {
      print('API 동기화 실패, 로컬 데이터 사용: $e');
      // API 실패 시에도 로컬 데이터는 계속 사용
    }
  }

  void _loadRoutineList() {
    _routineList = RoutineRepository().routineList;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  Future<void> addRoutine(String name, List<String> goals, List<String> days, bool notificationEnabled, String notificationTime, String memo) async {
    _setLoading(true);
    _clearError();
    
    try {
      await RoutineRepository().addRoutine(name, goals, days, notificationEnabled, notificationTime, memo);
      _loadRoutineList();
      
      if (notificationEnabled && days.isNotEmpty) {
        final routine = _routineList.last;
        await setupRoutineAlarm(routine);
      }
    } catch (e) {
      // 서버 연결 실패로 로컬에만 저장된 경우는 성공으로 처리
      if (e.toString().contains('서버 연결 실패로 로컬에만 저장되었습니다')) {
        print('서버 연결 실패로 로컬에만 저장됨 - 성공으로 처리');
        return;
      }
      _setError('루틴 추가 중 오류가 발생했습니다: $e');
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateRoutine(int index, String name, List<String> goals, List<String> days, bool notificationEnabled, String notificationTime, String memo) async {
    if (index >= 0 && index < _routineList.length) {
      _setLoading(true);
      _clearError();
      
      try {
        final oldRoutine = _routineList[index];
        
        // 기존 알람 제거
        await removeRoutineAlarm(oldRoutine.id);
        
        await RoutineRepository().updateRoutine(index, name, goals, days, notificationEnabled, notificationTime, memo);
        _loadRoutineList();
        
        if (notificationEnabled && days.isNotEmpty) {
          final updatedRoutine = _routineList[index];
          await setupRoutineAlarm(updatedRoutine);
        }
      } catch (e) {
        // 서버 연결 실패로 로컬에만 저장된 경우는 성공으로 처리
        if (e.toString().contains('서버 연결 실패로 로컬에만 저장되었습니다')) {
          print('서버 연결 실패로 로컬에만 저장됨 - 성공으로 처리');
          return;
        }
        _setError('루틴 수정 중 오류가 발생했습니다: $e');
        throw e;
      } finally {
        _setLoading(false);
      }
    }
  }

  Future<void> updateRoutineCheck(int routineIndex, int dayIndex, bool isChecked) async {
    try {
      await RoutineRepository().updateRoutineCheck(routineIndex, dayIndex, isChecked);
      // 체크 상태 변경 시에는 전체 리스트를 다시 로드하지 않고 즉시 반영
      notifyListeners();
    } catch (e) {
      _setError('체크 상태 업데이트 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> removeRoutine(int index) async {
    if (index >= 0 && index < _routineList.length) {
      _setLoading(true);
      _clearError();
      
      try {
        final routine = _routineList[index];
        
        // 알람 제거
        await removeRoutineAlarm(routine.id);
        
        await RoutineRepository().removeRoutine(index);
        _loadRoutineList();
      } catch (e) {
        // 서버 연결 실패로 로컬에만 저장된 경우는 성공으로 처리
        if (e.toString().contains('서버 연결 실패로 로컬에만 저장되었습니다')) {
          print('서버 연결 실패로 로컬에만 저장됨 - 성공으로 처리');
          return;
        }
        _setError('루틴 삭제 중 오류가 발생했습니다: $e');
        throw e;
      } finally {
        _setLoading(false);
      }
    }
  }

  List<bool> getRoutineChecks(int routineIndex) {
    return RoutineRepository().getRoutineChecks(routineIndex);
  }

  Future<void> clearAll() async {
    _setLoading(true);
    _clearError();
    
    try {
      // 모든 알람 제거
      await removeAllRoutineAlarms();
      
      RoutineRepository().clearAllData();
      _loadRoutineList();
    } catch (e) {
      _setError('데이터 초기화 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    await initialize();
  }

  /// 오류 메시지 초기화
  void clearError() {
    _clearError();
  }

  /// 특정 목표의 루틴 목록 조회
  List<RoutineModel> getRoutinesByGoal(String goal) {
    return RoutineRepository().getRoutinesByGoal(goal);
  }

  /// 체크 상태 통계 조회
  Map<String, dynamic> getRoutineStats() {
    return RoutineRepository().getRoutineStats();
  }

  /// 목표 추가
  Future<void> addGoal(String goal) async {
    try {
      await RoutineRepository().addGoal(goal);
      notifyListeners();
    } catch (e) {
      _setError('목표 추가 중 오류가 발생했습니다: $e');
    }
  }

  /// 목표 수정
  Future<void> updateGoal(String oldGoal, String newGoal) async {
    try {
      await RoutineRepository().updateGoal(oldGoal, newGoal);
      _loadRoutineList(); // 루틴 목록도 다시 로드
      notifyListeners();
    } catch (e) {
      _setError('목표 수정 중 오류가 발생했습니다: $e');
    }
  }

  /// 목표 삭제
  Future<void> deleteGoal(String goal) async {
    try {
      await RoutineRepository().deleteGoal(goal);
      _loadRoutineList(); // 루틴 목록도 다시 로드
      notifyListeners();
    } catch (e) {
      _setError('목표 삭제 중 오류가 발생했습니다: $e');
    }
  }

  /// 요일 문자열을 숫자로 변환
  List<int> _convertDaysToNumbers(List<String> days) {
    return days.map((day) {
      switch (day) {
        case '월': return 1;
        case '화': return 2;
        case '수': return 3;
        case '목': return 4;
        case '금': return 5;
        case '토': return 6;
        case '일': return 7;
        default: return 1;
      }
    }).toList();
  }

  /// 시간 문자열을 DateTime으로 변환
  DateTime _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    return DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  /// 루틴 알람 설정
  Future<void> setupRoutineAlarm(RoutineModel routine) async {
    if (!routine.notificationEnabled || routine.days.isEmpty) {
      return;
    }

    try {
      // 기존 알람 제거
      await removeRoutineAlarm(routine.id);
      
      // 새 알람 설정
      final alarmId = AlarmIdGenerator.generateRoutineId();
      final time = _parseTimeString(routine.notificationTime);
      final weekdays = _convertDaysToNumbers(routine.days);
      
      print('루틴 알람 설정 시작: ${routine.name}, 시간=${routine.notificationTime}, 요일=${routine.days}');
      
      await AlarmUtility.setWeeklyAlarm(
        baseId: alarmId,
        scheduledTime: time,
        title: '루틴 알림 (${routine.days.join(', ')})',
        body: '${routine.name} 시간입니다!',
        weekdays: weekdays,
      );
      
      _routineAlarmIds[routine.id] = alarmId;
      
      print('루틴 알람 설정 완료: ${routine.name}, 알람ID=$alarmId');
    } catch (e) {
      print('루틴 알람 설정 실패: ${routine.name} - $e');
    }
  }

  /// 루틴 알람 제거
  Future<void> removeRoutineAlarm(String routineId) async {
    final alarmId = _routineAlarmIds[routineId];
    if (alarmId != null) {
      try {
        await AlarmUtility.cancelAllWeeklyAlarmsForBaseId(alarmId);
        _routineAlarmIds.remove(routineId);
      } catch (e) {
        print('루틴 알람 제거 실패: $routineId - $e');
      }
    }
  }

  /// 모든 루틴 알람 제거
  Future<void> removeAllRoutineAlarms() async {
    try {
      print('모든 루틴 알람 제거 시작');
      await AlarmUtility.cancelAllAlarms();
      _routineAlarmIds.clear();
      print('모든 루틴 알람 제거 완료');
    } catch (e) {
      print('모든 루틴 알람 제거 실패: $e');
    }
  }

  /// 루틴 알람 ID 가져오기
  int? getRoutineAlarmId(String routineId) {
    return _routineAlarmIds[routineId];
  }

  /// 루틴 알람 ID 설정
  void setRoutineAlarmId(String routineId, int alarmId) {
    _routineAlarmIds[routineId] = alarmId;
  }

  /// 모든 루틴의 알람 복원
  Future<void> restoreAllRoutineAlarms() async {
    try {
      for (final routine in _routineList) {
        if (routine.notificationEnabled && routine.days.isNotEmpty) {
          await setupRoutineAlarm(routine);
        }
      }
    } catch (e) {
      print('모든 루틴 알람 복원 실패: $e');
    }
  }

  /// 테스트용 즉시 알람 설정 (5초 후)
  Future<void> setTestAlarm() async {
    try {
      await AlarmUtility.setImmediateAlarm();
      print('테스트 알람 설정 완료');
    } catch (e) {
      print('테스트 알람 설정 실패: $e');
    }
  }

  /// 현재 예약된 모든 알람 조회
  Future<void> checkPendingAlarms() async {
    try {
      final pendingAlarms = await AlarmUtility.getPendingAlarms();
      print('=== 현재 예약된 알람 목록 ===');
      print('총 알람 개수: ${pendingAlarms.length}');
      for (var alarm in pendingAlarms) {
        print('ID: ${alarm.id}, 제목: ${alarm.title}, 본문: ${alarm.body}');
      }
      print('============================');
    } catch (e) {
      print('알람 목록 조회 실패: $e');
    }
  }
}

