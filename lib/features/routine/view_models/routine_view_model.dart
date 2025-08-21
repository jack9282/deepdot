import 'package:flutter/material.dart';
import '../../../data/repositories/routine_repository.dart';
import '../../../data/repositories/auth_repository.dart';
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
  bool _isAlarmRestoring = false;
  final AuthRepository _authRepository = AuthRepository();

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
      await RoutineRepository().loadFromStorage();
      await _syncWithApi();
      _loadRoutineList();
      _isInitialized = true;
      
      if (!_isAlarmRestoring) {
        _isAlarmRestoring = true;
        await restoreAllRoutineAlarms();
        _isAlarmRestoring = false;
      }
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
    if (_isLoading) return;
    
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
        
        final routinesToRemove = _routineList.where((routine) => routine.goalName == goalName).toList();
        for (final routine in routinesToRemove) {
          if (routine.routineId != null) {
            await removeRoutineAlarm(routine.routineId!);
          }
        }
        
        _routineList.removeWhere((routine) => routine.goalName == goalName);
        _routineList.addAll(newRoutines);
        
        final repository = RoutineRepository();
        for (final routine in newRoutines) {
          if (routine.routineId != null) {
            repository.getRoutineCheckStates(routine.routineId!);
          }
        }
        
        for (final routine in newRoutines) {
          if (routine.active && routine.days.isNotEmpty) {
            await setupRoutineAlarm(routine);
          }
        }
        
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
      if (routine.routineId != null && _routineAlarmIds.containsKey(routine.routineId!)) {
        final existingAlarmId = _routineAlarmIds[routine.routineId!];
        final pendingAlarms = await AlarmUtility.getPendingAlarms();
        final hasActiveAlarm = pendingAlarms.any((alarm) => alarm.id == existingAlarmId);
        
        if (hasActiveAlarm) {
          return;
        }
      }

      int baseId;
      if (routine.alarmId != null) {
        baseId = routine.alarmId!;
      } else if (routine.routineId != null) {
        baseId = 2000 + (routine.routineId! % 1000);
      } else {
        baseId = AlarmIdGenerator.generateRoutineId();
      }

      await AlarmUtility.cancelAllWeeklyAlarmsForBaseId(baseId);

      final time = _parseTimeString(routine.startTimeString);
      final weekdays = _convertDaysToNumbers(routine.days);

      final userName = _authRepository.currentUser?.name ?? _authRepository.currentUser?.username ?? '사용자';
      await AlarmUtility.setWeeklyAlarm(
        baseId: baseId,
        scheduledTime: time,
        title: '루틴 알림 (${routine.days.join(', ')})',
        body: AlarmUtility.generateRoutineMessage(userName, routine.name),
        weekdays: weekdays,
      );
      
      if (routine.routineId != null) {
        _routineAlarmIds[routine.routineId!] = baseId;
        await RoutineRepository().updateRoutineAlarmId(routine.routineId!, baseId);
      }
    } catch (e) {
      _setError('알림 설정에 실패했습니다. 알림 권한을 확인해주세요.');
    }
  }

  Future<void> removeRoutineAlarm(int routineId) async {
    try {
      int? alarmId = _routineAlarmIds[routineId];
      if (alarmId == null) {
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
    } catch (e) {
      // 알람 제거 실패 시 무시
    }
  }

  Future<void> removeAllRoutineAlarms() async {
    try {
      await AlarmUtility.cancelAllAlarms();
      _routineAlarmIds.clear();
    } catch (e) {
      // 알람 제거 실패 시 무시
    }
  }

  int? getRoutineAlarmId(int routineId) {
    return _routineAlarmIds[routineId];
  }

  void setRoutineAlarmId(int routineId, int alarmId) {
    _routineAlarmIds[routineId] = alarmId;
  }

  Future<void> restoreAllRoutineAlarms() async {
    if (_isAlarmRestoring) return;
    
    try {
      _isAlarmRestoring = true;
      
      final pendingAlarms = await AlarmUtility.getPendingAlarms();
      int removedCount = 0;
      
      for (final alarm in pendingAlarms) {
        if ((alarm.id >= 2000 && alarm.id < 3000) || 
            (alarm.id >= 20000 && alarm.id < 30000)) {
          await AlarmUtility.cancelAlarm(alarm.id);
          removedCount++;
        }
      }
      
      _routineAlarmIds.clear();
      
      int restoredCount = 0;
      int skippedCount = 0;
      
      for (final routine in _routineList) {
        if (routine.active && routine.days.isNotEmpty) {
          try {
            await setupRoutineAlarm(routine);
            restoredCount++;
          } catch (e) {
            skippedCount++;
          }
        }
      }
    } catch (e) {
      _setError('알림 복원 중 오류가 발생했습니다.');
    } finally {
      _isAlarmRestoring = false;
    }
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

  RoutineModel? getRoutineById(int routineId) {
    try {
      return _routineList.firstWhere((routine) => routine.routineId == routineId);
    } catch (_) {
      return null;
    }
  }

  List<bool> getRoutineCheckStates(int routineId) {
    return RoutineRepository().getRoutineCheckStates(routineId);
  }

  bool getRoutineCheckState(int routineId, int dayIndex) {
    final checkStates = getRoutineCheckStates(routineId);
    return dayIndex >= 0 && dayIndex < checkStates.length ? checkStates[dayIndex] : false;
  }

  Future<void> updateRoutineCheckState(int routineId, int dayIndex, bool isChecked) async {
    try {
      if (dayIndex < 0 || dayIndex >= 7) {
        return;
      }
      
      await RoutineRepository().updateRoutineCheckState(routineId, dayIndex, isChecked);
      
      notifyListeners();
    } catch (e) {
      // 체크 상태 업데이트 실패 시 무시
    }
  }

  Future<void> syncAlarms() async {
    if (_isAlarmRestoring) return;
    
    try {
      _isAlarmRestoring = true;
      await restoreAllRoutineAlarms();
    } catch (e) {
      // 알람 동기화 실패 시 무시
    } finally {
      _isAlarmRestoring = false;
    }
  }
}


