import 'package:flutter/material.dart';
import '../../../data/repositories/routine_repository.dart';
import '../../../data/models/routine_model.dart';
import '../../../utils/alarm.dart';

class RoutineViewModel extends ChangeNotifier {
  List<RoutineModel> _routineList = [];
  Map<String, int> _alarmIds = {}; // 루틴 ID와 알람 ID 매핑
  bool _isLoading = false;
  String? _errorMessage;

  List<RoutineModel> get routineList => List.unmodifiable(_routineList);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _setLoading(true);
    _clearError();
    
    try {
      await RoutineRepository().loadFromStorage();
      _loadRoutineList();
    } catch (e) {
      _setError('데이터 로드 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
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
    if (routineIndex >= 0 && routineIndex < _routineList.length) {
      final routine = _routineList[routineIndex];
      
      // 체크 상태 배열이 올바르지 않은 경우 기본값 반환
      if (routine.checks.length != 7) {
        return List.generate(7, (_) => false);
      }
      
      return List<bool>.from(routine.checks);
    }
    return List.generate(7, (_) => false);
  }

  Future<void> clearAll() async {
    _setLoading(true);
    _clearError();
    
    try {
      // 모든 알람 제거
      for (final alarmId in _alarmIds.values) {
        await AlarmUtility.cancelAlarm(alarmId);
      }
      _alarmIds.clear();
      
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
    final alarmId = DateTime.now().millisecondsSinceEpoch;
    final timeParts = notificationTime.split(':');
    
    if (timeParts.length == 2) {
      final scheduledTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      
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
        id: alarmId,
        scheduledTime: scheduledTime,
        title: '루틴 알림',
        body: '${routine.name} 시간입니다!',
        weekdays: weekdays,
      );
      
      _alarmIds[routine.id] = alarmId;
    }
  }

  Future<void> _removeAlarms(RoutineModel routine) async {
    if (routine.notificationEnabled) {
      final alarmId = _alarmIds[routine.id];
      if (alarmId != null) {
        await AlarmUtility.cancelAlarm(alarmId);
        _alarmIds.remove(routine.id);
      }
    }
  }
}

