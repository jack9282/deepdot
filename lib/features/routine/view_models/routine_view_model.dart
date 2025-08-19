import 'package:flutter/material.dart';
import '../../../data/repositories/routine_repository.dart';
import '../../../data/models/routine_model.dart';
import '../../../utils/alarm.dart';
import '../../../utils/alarm_id_generator.dart';
import '../../../api/token_manager.dart';
import '../../../api/routine_api.dart';

class RoutineViewModel extends ChangeNotifier {
  List<RoutineModel> _routineList = [];
  Map<int, int> _routineAlarmIds = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  List<RoutineModel> get routineList => List.unmodifiable(_routineList);
  List<Map<String, dynamic>> get availableGoals {
    return RoutineRepository().availableGoals;
  }
  List<String> get availableGoalNames {
    return RoutineRepository().availableGoals
        .map((goal) => goal['name'] as String)
        .toList();
  }
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      await removeAllRoutineAlarms();
      
      await RoutineRepository().loadFromStorage();
      await _syncWithApi();
      _loadRoutineList();
      _isInitialized = true;
      
      await restoreAllRoutineAlarms();
    } catch (e) {
      _setError('데이터 로드 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _syncWithApi() async {
    try {
      if (await TokenManager.instance.isGuestMode()) {
        return;
      }
      
      await RoutineRepository().syncWithServer();
    } catch (e) {
      // API 실패 시에도 로컬 데이터는 계속 사용
    }
  }

  void _loadRoutineList() {
    try {
      _routineList = RoutineRepository().routineList;
      notifyListeners();
    } catch (e) {
      _routineList = [];
      notifyListeners();
    }
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

  Future<bool> addRoutine({
    required String name,
    required int goalId,
    required bool mon,
    required bool tue,
    required bool wed,
    required bool thu,
    required bool fri,
    required bool sat,
    required bool sun,
    required bool active,
    required String memo,
    required Map<String, int> startTime,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await RoutineRepository().addRoutine(
        name: name,
        goalId: goalId,
        mon: mon,
        tue: tue,
        wed: wed,
        thu: thu,
        fri: fri,
        sat: sat,
        sun: sun,
        active: active,
        memo: memo,
        startTime: startTime,
      );

      if (success) {
        _loadRoutineList();
        
        if (active && _hasSelectedDays(mon, tue, wed, thu, fri, sat, sun)) {
          final routine = _routineList.last;
          await setupRoutineAlarm(routine);
        }
        return true;
      } else {
        _setError('루틴 추가에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _setError('루틴 추가 중 오류가 발생했습니다: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateRoutine({
    required int routineId,
    required String name,
    required int goalId,
    required bool mon,
    required bool tue,
    required bool wed,
    required bool thu,
    required bool fri,
    required bool sat,
    required bool sun,
    required bool active,
    required String memo,
    required Map<String, int> startTime,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      await removeRoutineAlarm(routineId);
      
      final success = await RoutineRepository().updateRoutine(
        routineId: routineId,
        name: name,
        goalId: goalId,
        mon: mon,
        tue: tue,
        wed: wed,
        thu: thu,
        fri: fri,
        sat: sat,
        sun: sun,
        active: active,
        memo: memo,
        startTime: startTime,
      );

      if (success) {
        _loadRoutineList();
        
        if (active && _hasSelectedDays(mon, tue, wed, thu, fri, sat, sun)) {
          final updatedRoutine = _routineList.firstWhere((r) => r.routineId == routineId);
          await setupRoutineAlarm(updatedRoutine);
        }
        return true;
      } else {
        _setError('루틴 수정에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _setError('루틴 수정 중 오류가 발생했습니다: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removeRoutine(int routineId) async {
    _setLoading(true);
    _clearError();
    
    try {
      await removeRoutineAlarm(routineId);
      
      final success = await RoutineRepository().removeRoutine(routineId);
      
      if (success) {
        _loadRoutineList();
        return true;
      } else {
        _setError('루틴 삭제에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _setError('루틴 삭제 중 오류가 발생했습니다: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clearAll() async {
    _setLoading(true);
    _clearError();
    
    try {
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
    _setLoading(true);
    _clearError();
    
    try {
      await RoutineRepository().loadFromStorage();
      await _syncWithApi();
      _loadRoutineList();
    } catch (e) {
      _setError('데이터 새로고침 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  List<RoutineModel> getRoutinesByGoal(String goalName) {
    return _routineList.where((routine) => routine.goalName == goalName).toList();
  }

  Future<bool> addGoal(String name) async {
    return await RoutineRepository().addGoal(name);
  }

  Future<bool> updateGoal(String goalId, String name) async {
    return await RoutineRepository().updateGoal(goalId, name);
  }

  Future<bool> deleteGoal(String goalId) async {
    try {
      final success = await RoutineRepository().deleteGoal(goalId);
      
      if (success) {
        final goalIdInt = int.tryParse(goalId) ?? 0;
        final routinesToRemove = _routineList.where((routine) => routine.goalId == goalIdInt).toList();
        
        for (final routine in routinesToRemove) {
          if (routine.routineId != null) {
            await removeRoutine(routine.routineId!);
          }
        }
        
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> loadRoutinesForGoal(String goalName) async {
    try {
      final goalIndex = availableGoalNames.indexOf(goalName);
      if (goalIndex == -1) {
        return;
      }
      
      final goalData = availableGoals[goalIndex];
      final goalId = int.tryParse(goalData['goalId'].toString()) ?? 0;
      
      if (goalId <= 0) {
        return;
      }
      
      final response = await RoutineApi.getRoutinesByGoal(goalId: goalId);
      
      if (response['data'] != null) {
        final routinesData = List<Map<String, dynamic>>.from(response['data']);
        
        final newRoutines = routinesData.map((data) => RoutineModel.fromJson(data)).toList();
        
        _routineList.removeWhere((routine) => routine.goalName == goalName);
        _routineList.addAll(newRoutines);
        
        notifyListeners();
      }
    } catch (e) {}
  }

  bool _hasSelectedDays(bool mon, bool tue, bool wed, bool thu, bool fri, bool sat, bool sun) {
    return mon || tue || wed || thu || fri || sat || sun;
  }

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

  Future<void> setupRoutineAlarm(RoutineModel routine) async {
    if (!routine.active || routine.days.isEmpty) {
      return;
    }

    try {
      // 안정적인 baseId 결정: 저장된 alarmId > routineId 기반 > 신규 생성 순
      int baseId;
      if (routine.alarmId != null) {
        baseId = routine.alarmId!;
      } else if (routine.routineId != null) {
        baseId = 2000 + (routine.routineId! % 1000);
      } else {
        baseId = AlarmIdGenerator.generateRoutineId();
      }

      // 기존 동일 baseId의 주간 알람 정리 후 설정
      await AlarmUtility.cancelAllWeeklyAlarmsForBaseId(baseId);

      final time = _parseTimeString(routine.startTimeString);
      final weekdays = _convertDaysToNumbers(routine.days);

      await AlarmUtility.setWeeklyAlarm(
        baseId: baseId,
        scheduledTime: time,
        title: '루틴 알림 (${routine.days.join(', ')})',
        body: '${routine.name} 시간입니다!',
        weekdays: weekdays,
      );
      
      if (routine.routineId != null) {
        _routineAlarmIds[routine.routineId!] = baseId;
        // 모델에도 영구 저장
        await RoutineRepository().updateRoutineAlarmId(routine.routineId!, baseId);
      }
    } catch (e) {}
  }

  Future<void> removeRoutineAlarm(int routineId) async {
    try {
      int? alarmId = _routineAlarmIds[routineId];
      if (alarmId == null) {
        // 모델의 alarmId로 보조 취소
        final routine = _routineList.firstWhere(
          (r) => r.routineId == routineId,
          orElse: () => RoutineModel(
            routineId: routineId,
            name: '',
            goalId: 0,
            goalName: '',
            mon: false,
            tue: false,
            wed: false,
            thu: false,
            fri: false,
            sat: false,
            sun: false,
            active: false,
            memo: '',
            startTime: const {'hour': 8, 'minute': 0, 'second': 0, 'nano': 0},
            createdAt: DateTime.now(),
          ),
        );
        alarmId = routine.alarmId;
      }

      if (alarmId != null) {
        await AlarmUtility.cancelAllWeeklyAlarmsForBaseId(alarmId);
        _routineAlarmIds.remove(routineId);
      }
    } catch (e) {}
  }

  Future<void> removeAllRoutineAlarms() async {
    try {
      await AlarmUtility.cancelAllAlarms();
      _routineAlarmIds.clear();
    } catch (e) {}
  }

  int? getRoutineAlarmId(int routineId) {
    return _routineAlarmIds[routineId];
  }

  void setRoutineAlarmId(int routineId, int alarmId) {
    _routineAlarmIds[routineId] = alarmId;
  }

  Future<void> restoreAllRoutineAlarms() async {
    try {
      for (final routine in _routineList) {
        if (routine.active && routine.days.isNotEmpty) {
          await setupRoutineAlarm(routine);
        }
      }
    } catch (e) {}
  }

  Future<void> setTestAlarm() async {
    try {
      await AlarmUtility.setImmediateAlarm();
    } catch (e) {}
  }

  Future<void> checkPendingAlarms() async {
    try {
      final pendingAlarms = await AlarmUtility.getPendingAlarms();
      pendingAlarms.length;
    } catch (e) {}
  }

  void updateGoalNameInRoutines({
    required int oldGoalId,
    required String newGoalName,
  }) {
    bool updated = false;
    for (int i = 0; i < _routineList.length; i++) {
      if (_routineList[i].goalId == oldGoalId) {
        _routineList[i] = _routineList[i].copyWith(goalName: newGoalName);
        updated = true;
      }
    }
    
    if (updated) {
      notifyListeners();
    }
  }
}


