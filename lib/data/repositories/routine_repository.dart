import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/routine_model.dart';
import '../../api/token_manager.dart';
import '../../api/routine_api.dart';
import '../../utils/alarm.dart';

class RoutineRepository extends ChangeNotifier {
  static const String _routineListKey = 'routine_list';
  static const String _lastSyncKey = 'routine_last_sync_timestamp';
  static const String _availableGoalsKey = 'available_goals';

  static final RoutineRepository _instance = RoutineRepository._internal();
  factory RoutineRepository() => _instance;
  RoutineRepository._internal();

  List<RoutineModel> _routineList = [];
  List<Map<String, dynamic>> _availableGoals = [
    {'goalId': '1', 'name': '아침루틴', 'inUse': false},
    {'goalId': '2', 'name': '개강까지 -5KG', 'inUse': false},
    {'goalId': '3', 'name': '정돈된 일상', 'inUse': false},
  ];

  List<RoutineModel> get routineList => List.unmodifiable(_routineList);
  List<Map<String, dynamic>> get availableGoals =>
      List.unmodifiable(_availableGoals);

  // Helpers
  Future<bool> _isGuest() => TokenManager.instance.isGuestMode();

  bool _hasSelectedDays({
    required bool mon,
    required bool tue,
    required bool wed,
    required bool thu,
    required bool fri,
    required bool sat,
    required bool sun,
  }) {
    return mon || tue || wed || thu || fri || sat || sun;
  }

  bool _isValidStartTime(Map<String, int> startTime) {
    return startTime['hour'] != null && startTime['minute'] != null;
  }

  bool _isValidRoutineParams({
    required String name,
    required int goalId,
    required bool mon,
    required bool tue,
    required bool wed,
    required bool thu,
    required bool fri,
    required bool sat,
    required bool sun,
    required Map<String, int> startTime,
  }) {
    if (goalId <= 0) return false;
    if (name.trim().isEmpty) return false;
    if (!_hasSelectedDays(
      mon: mon,
      tue: tue,
      wed: wed,
      thu: thu,
      fri: fri,
      sat: sat,
      sun: sun,
    ))
      return false;
    if (!_isValidStartTime(startTime)) return false;
    return true;
  }

  Future<void> _saveAndNotify() async {
    await saveToStorage();
    notifyListeners();
  }

  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final routineJson = prefs.getString(_routineListKey);
      if (routineJson != null) {
        final List<dynamic> jsonList = jsonDecode(routineJson);
        _routineList = jsonList
            .map((item) {
              try {
                return RoutineModel.fromJson(item);
              } catch (_) {
                return null;
              }
            })
            .where((routine) => routine != null)
            .cast<RoutineModel>()
            .toList();
      }

      final goalsJson = prefs.getString(_availableGoalsKey);
      if (goalsJson != null) {
        try {
          final List<dynamic> goalsList = jsonDecode(goalsJson);
          _availableGoals = goalsList
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _routineListKey,
      jsonEncode(_routineList.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(_availableGoalsKey, jsonEncode(_availableGoals));
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
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
    try {
      if (await _isGuest()) {
        final newRoutine = RoutineModel(
          name: name,
          goalId: goalId,
          goalName: _getGoalNameById(goalId) ?? '새 목표',
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
          createdAt: DateTime.now(),
        );
        _routineList.add(newRoutine);
        await _saveAndNotify();
        return true;
      }

      if (!_isValidRoutineParams(
        name: name,
        goalId: goalId,
        mon: mon,
        tue: tue,
        wed: wed,
        thu: thu,
        fri: fri,
        sat: sat,
        sun: sun,
        startTime: startTime,
      )) {
        return false;
      }

      final response = await RoutineApi.createRoutine(
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

      final newRoutine = RoutineModel(
        routineId: response['routineId'] as int?,
        name: name,
        goalId: response['goalId'] as int? ?? goalId,
        goalName:
            response['goalName'] as String? ??
            _getGoalNameById(goalId) ??
            '새 목표',
        mon: mon,
        tue: tue,
        wed: wed,
        thu: thu,
        fri: fri,
        sat: sat,
        sun: sun,
        active: response['active'] as bool? ?? active,
        memo: memo,
        startTime: startTime,
        createdAt: DateTime.now(),
      );

      _routineList.add(newRoutine);
      await _saveAndNotify();
      return true;
    } catch (_) {
      return false;
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
    try {
      final index = _routineList.indexWhere(
        (routine) => routine.routineId == routineId,
      );
      if (index == -1) return false;

      if (await _isGuest()) {
        _routineList[index] = _routineList[index].copyWith(
          name: name,
          goalId: goalId,
          goalName: _getGoalNameById(goalId) ?? '새 목표',
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
          updatedAt: DateTime.now(),
        );
        await _saveAndNotify();
        return true;
      }

      final response = await RoutineApi.updateRoutine(
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

      _routineList[index] = _routineList[index].copyWith(
        name: name,
        goalId: response['goalId'] as int,
        goalName: response['goalName'] as String,
        mon: mon,
        tue: tue,
        wed: wed,
        thu: thu,
        fri: fri,
        sat: sat,
        sun: sun,
        active: response['active'] as bool,
        memo: memo,
        startTime: startTime,
        updatedAt: DateTime.now(),
      );

      await _saveAndNotify();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeRoutine(int routineId) async {
    try {
      final index = _routineList.indexWhere(
        (routine) => routine.routineId == routineId,
      );
      if (index == -1) return false;

      if (await _isGuest()) {
        _routineList.removeAt(index);
        await _saveAndNotify();
        return true;
      }

      await RoutineApi.deleteRoutine(routineId: routineId);
      _routineList.removeAt(index);
      await _saveAndNotify();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> loadGoalsFromServer() async {
    try {
      if (await _isGuest()) {
        return false;
      }

      final response = await RoutineApi.getGoals();
      if (response['data'] != null) {
        final goalsData = List<Map<String, dynamic>>.from(response['data']);
        _availableGoals = goalsData;
        await _saveAndNotify();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addGoal(String name) async {
    try {
      if (await _isGuest()) {
        final newGoal = {
          'goalId': (_availableGoals.length + 1).toString(),
          'name': name,
          'inUse': false,
        };
        _availableGoals.add(newGoal);
        await _saveAndNotify();
        return true;
      }

      final response = await RoutineApi.createGoal(name: name);
      if (response['data'] != null) {
        _availableGoals.add(Map<String, dynamic>.from(response['data']));
        await _saveAndNotify();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateGoal(String goalId, String name) async {
    try {
      final index = _availableGoals.indexWhere(
        (goal) => goal['goalId'] == goalId,
      );
      if (index == -1) {
        return false;
      }

      if (await _isGuest()) {
        _availableGoals[index]['name'] = name;
        await _saveAndNotify();
        return true;
      }

      final response = await RoutineApi.updateGoal(
        goalId: int.tryParse(goalId) ?? 0,
        name: name,
      );
      if (response['data'] != null) {
        _availableGoals[index] = Map<String, dynamic>.from(response['data']);
        await _saveAndNotify();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteGoal(String goalId) async {
    try {
      final index = _availableGoals.indexWhere(
        (goal) => goal['goalId'] == goalId,
      );
      if (index == -1) {
        return false;
      }

      final isInUse = _availableGoals[index]['inUse'] == true;
      if (isInUse) {
        return false;
      }

      if (await _isGuest()) {
        _availableGoals.removeAt(index);
        await _saveAndNotify();
        return true;
      }

      await RoutineApi.deleteGoal(goalId: int.tryParse(goalId) ?? 0);
      _availableGoals.removeAt(index);
      await _saveAndNotify();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> loadRoutinesFromServer() async {
    try {
      if (await _isGuest()) {
        return false;
      }

      final allRoutines = <RoutineModel>[];
      for (final goal in _availableGoals) {
        final goalId = int.tryParse(goal['goalId'].toString()) ?? 0;
        try {
          final response = await RoutineApi.getRoutinesByGoal(goalId: goalId);
          if (response['data'] != null) {
            final routines = List<Map<String, dynamic>>.from(response['data']);
            for (final routineData in routines) {
              try {
                final routine = RoutineModel.fromJson(routineData);
                allRoutines.add(routine);
              } catch (_) {}
            }
          }
        } catch (_) {}
      }

      _routineList = allRoutines;
      await _saveAndNotify();
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearAllData() async {
    _routineList.clear();
    _availableGoals.clear();
    await saveToStorage();
    notifyListeners();
  }

  RoutineModel? getRoutineById(int routineId) {
    try {
      return _routineList.firstWhere((item) => item.routineId == routineId);
    } catch (_) {
      return null;
    }
  }

  int getRoutineCount() => _routineList.length;

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  List<RoutineModel> getRoutinesByGoal(int goalId) {
    return _routineList.where((routine) => routine.goalId == goalId).toList();
  }

  Future<void> updateRoutineAlarmId(int routineId, int alarmId) async {
    try {
      final index = _routineList.indexWhere(
        (routine) => routine.routineId == routineId,
      );
      if (index != -1 && _routineList[index].alarmId != alarmId) {
        _routineList[index] = _routineList[index].copyWith(alarmId: alarmId);
        await saveToStorage();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> updateRoutineCheckState(
    int routineId,
    int dayIndex,
    bool isChecked,
  ) async {
    try {
      final index = _routineList.indexWhere(
        (routine) => routine.routineId == routineId,
      );
      if (index != -1) {
        final currentCheckStates = List<bool>.from(
          _routineList[index].checkStates,
        );
        if (dayIndex >= 0 && dayIndex < currentCheckStates.length) {
          currentCheckStates[dayIndex] = isChecked;
          _routineList[index] = _routineList[index].copyWith(
            checkStates: currentCheckStates,
          );
          await saveToStorage();
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  String? _getGoalNameById(int goalId) {
    try {
      final goal = _availableGoals.firstWhere(
        (goal) => int.tryParse(goal['goalId'].toString()) == goalId,
      );
      return goal['name'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> syncWithServer() async {
    try {
      if (await _isGuest()) {
        return false;
      }

      await loadGoalsFromServer();
      await loadRoutinesFromServer();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 모든 루틴 알림을 재설정합니다
  Future<void> rescheduleAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('routine_notification') ?? true;

      if (!isEnabled) {
        // 알림이 비활성화되어 있으면 아무것도 하지 않음
        return;
      }

      // 활성화된 모든 루틴에 대해 알림 설정
      for (final routine in _routineList) {
        if (routine.active &&
            routine.startTime.containsKey('hour') &&
            routine.startTime.containsKey('minute')) {
          // 선택된 요일들 추출
          final List<int> weekdays = [];
          if (routine.mon) weekdays.add(1);
          if (routine.tue) weekdays.add(2);
          if (routine.wed) weekdays.add(3);
          if (routine.thu) weekdays.add(4);
          if (routine.fri) weekdays.add(5);
          if (routine.sat) weekdays.add(6);
          if (routine.sun) weekdays.add(7);

          if (weekdays.isNotEmpty) {
            final hour = routine.startTime['hour'] ?? 9;
            final minute = routine.startTime['minute'] ?? 0;
            final scheduledTime = DateTime.now().copyWith(
              hour: hour,
              minute: minute,
            );

            // 알람 ID는 30000번대 사용 (루틴용)
            // hashCode를 0-19999 범위로 제한하여 30000-49999 사이가 되도록 함
            final baseId = 30000 + (routine.routineId.hashCode % 20000).abs();

            await AlarmUtility.setWeeklyAlarm(
              baseId: baseId,
              scheduledTime: scheduledTime,
              title: '루틴 알림',
              body: AlarmUtility.generateRoutineMessage('사용자', routine.name),
              weekdays: weekdays,
            );
          }
        }
      }
    } catch (e) {
      print('루틴 알림 재설정 중 오류: $e');
    }
  }
}
