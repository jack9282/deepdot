import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine_model.dart';

class RoutineRepository {
  static const String _routineListKey = 'routine_list';
  static const String _lastSyncKey = 'routine_last_sync_timestamp';

  static final RoutineRepository _instance = RoutineRepository._internal();
  factory RoutineRepository() => _instance;
  RoutineRepository._internal();

  List<RoutineModel> _routineList = [];

  List<RoutineModel> get routineList => List.unmodifiable(_routineList);

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final routineJson = prefs.getString(_routineListKey);
    if (routineJson != null) {
      final List<dynamic> jsonList = jsonDecode(routineJson);
      _routineList = jsonList.map((item) {
        final routine = RoutineModel.fromJson(item);
        
        // 체크 상태가 올바르지 않은 경우 초기화
        if (routine.checks.length != 7) {
          return routine.copyWith(
            checks: List.generate(7, (_) => false),
          );
        }
        return routine;
      }).toList();
    }
  }

  Future<void> saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_routineListKey, jsonEncode(_routineList.map((e) => e.toJson()).toList()));
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> addRoutine(String name, List<String> goals, List<String> days, bool notificationEnabled, String notificationTime, String memo) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final checks = List.generate(7, (_) => false);
    
    final newRoutine = RoutineModel(
      id: id,
      name: name,
      goals: goals,
      days: days,
      notificationEnabled: notificationEnabled,
      notificationTime: notificationTime,
      memo: memo,
      checks: checks,
      createdAt: DateTime.now(),
    );
    _routineList.add(newRoutine);
    await saveToStorage();
  }

  Future<void> updateRoutine(int index, String name, List<String> goals, List<String> days, bool notificationEnabled, String notificationTime, String memo) async {
    if (index >= 0 && index < _routineList.length) {
      final oldRoutine = _routineList[index];
      _routineList[index] = oldRoutine.copyWith(
        name: name,
        goals: goals,
        days: days,
        notificationEnabled: notificationEnabled,
        notificationTime: notificationTime,
        memo: memo,
        updatedAt: DateTime.now(),
      );
      await saveToStorage();
    }
  }

  Future<void> updateRoutineCheck(int routineIndex, int dayIndex, bool isChecked) async {
    if (routineIndex >= 0 && routineIndex < _routineList.length) {
      final routine = _routineList[routineIndex];
      
      // 체크 상태 배열이 올바르지 않은 경우 초기화
      List<bool> newChecks;
      if (routine.checks.length != 7) {
        newChecks = List.generate(7, (_) => false);
      } else {
        newChecks = List<bool>.from(routine.checks);
      }
      
      // 요일 인덱스가 유효한지 확인
      if (dayIndex >= 0 && dayIndex < 7) {
        newChecks[dayIndex] = isChecked;
      }
      
      _routineList[routineIndex] = routine.copyWith(
        checks: newChecks,
        updatedAt: DateTime.now(),
      );
      await saveToStorage();
    }
  }

  Future<void> removeRoutine(int index) async {
    if (index >= 0 && index < _routineList.length) {
      _routineList.removeAt(index);
      await saveToStorage();
    }
  }

  void clearAllData() async {
    _routineList.clear();
    await saveToStorage();
  }

  RoutineModel? getRoutineById(String id) {
    try {
      return _routineList.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  int getRoutineCount() => _routineList.length;

  /// 마지막 동기화 시간 확인
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// 특정 목표의 루틴 목록 조회
  List<RoutineModel> getRoutinesByGoal(String goal) {
    return _routineList.where((routine) => routine.goals.contains(goal)).toList();
  }

  /// 체크 상태 통계 조회
  Map<String, dynamic> getRoutineStats() {
    int totalRoutines = _routineList.length;
    int totalChecks = 0;
    int completedChecks = 0;

    for (final routine in _routineList) {
      for (final check in routine.checks) {
        totalChecks++;
        if (check) completedChecks++;
      }
    }

    return {
      'totalRoutines': totalRoutines,
      'totalChecks': totalChecks,
      'completedChecks': completedChecks,
      'completionRate': totalChecks > 0 ? (completedChecks / totalChecks) : 0.0,
    };
  }
} 