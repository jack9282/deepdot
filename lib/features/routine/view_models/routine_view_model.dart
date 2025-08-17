import 'package:flutter/material.dart';
import '../../../data/repositories/routine_repository.dart';
import '../../../data/models/routine_model.dart';
import '../../../utils/alarm.dart';
import '../../../utils/alarm_id_generator.dart';
import '../../../api/token_manager.dart';

class RoutineViewModel extends ChangeNotifier {
  List<RoutineModel> _routineList = [];
  Map<String, int> _alarmIds = {}; // 루틴 ID와 알람 ID 매핑
  bool _isLoading = false;
  String? _errorMessage;

  List<RoutineModel> get routineList => List.unmodifiable(_routineList);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      await RoutineRepository().loadFromStorage();
      await _syncWithApi();
      _loadRoutineList();
      _isInitialized = true;
      
      // 알람 복원은 하지 않음 - 앱 시작 시 모든 알람이 제거되므로
      // 사용자가 직접 알람을 다시 설정하도록 함
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
        await _setupWeeklyAlarm(routine, notificationTime);
      }
    } catch (e) {
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
        await _removeAlarms(oldRoutine);
        
        await RoutineRepository().updateRoutine(index, name, goals, days, notificationEnabled, notificationTime, memo);
        _loadRoutineList();
        
        if (notificationEnabled && days.isNotEmpty) {
          final updatedRoutine = _routineList[index];
          await _setupWeeklyAlarm(updatedRoutine, notificationTime);
        }
      } catch (e) {
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
        await _removeAlarms(routine);
        
        await RoutineRepository().removeRoutine(index);
        _loadRoutineList();
      } catch (e) {
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
      final alarmIdsToRemove = Map<String, int>.from(_alarmIds);
      _alarmIds.clear();
      
      for (final alarmId in alarmIdsToRemove.values) {
        try {
          await AlarmUtility.cancelAlarm(alarmId);
        } catch (e) {
          print('알람 제거 중 오류 발생: $e');
        }
      }
      
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

  Future<void> _setupWeeklyAlarm(RoutineModel routine, String notificationTime) async {
    try {
      // 안전한 알람 ID 생성
      final alarmId = AlarmIdGenerator.generateId();
      final timeParts = notificationTime.split(':');
      
      if (timeParts.length == 2) {
        final scheduledTime = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
        
        // 요일 정보를 알람 제목에 포함
        final weekdays = routine.days.map((day) {
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

        await AlarmUtility.setWeeklyAlarm(
          baseId: alarmId,
          scheduledTime: scheduledTime,
          title: '루틴 알림 (${routine.days.join(', ')})',
          body: '${routine.name} 시간입니다!',
          weekdays: weekdays,
        );
        
        _alarmIds[routine.id] = alarmId;
      }
    } catch (e) {
      print('알람 설정 중 오류 발생: $e');
    }
  }

  Future<void> _removeAlarms(RoutineModel routine) async {
    try {
      if (routine.notificationEnabled) {
        final alarmId = _alarmIds[routine.id];
        if (alarmId != null) {
          await AlarmUtility.cancelAlarm(alarmId);
          _alarmIds.remove(routine.id);
        }
      }
    } catch (e) {
      print('알람 제거 중 오류 발생: $e');
    }
  }

  Future<void> _restoreAlarms() async {
    try {
      // 기존 알람 ID들을 복사하여 안전하게 제거
      final alarmIdsToRemove = Map<String, int>.from(_alarmIds);
      _alarmIds.clear();
      
      for (final alarmId in alarmIdsToRemove.values) {
        try {
          await AlarmUtility.cancelAlarm(alarmId);
        } catch (e) {
          print('기존 알람 제거 중 오류: $e');
        }
      }
      
      // 새로운 알람 설정
      for (final routine in _routineList) {
        if (routine.notificationEnabled && routine.days.isNotEmpty) {
          await _setupWeeklyAlarm(routine, routine.notificationTime);
        }
      }
    } catch (e) {
      print('알람 복원 중 오류 발생: $e');
    }
  }
}

