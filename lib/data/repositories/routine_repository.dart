import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine_model.dart';

class RoutineRepository {
  static const String _routineListKey = 'routine_list';

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
        
        // 기존 데이터에 체크 상태가 없는 경우 초기화
        if (routine.checks.isEmpty || routine.checks.length != 7) {
          return RoutineModel(
            id: routine.id,
            name: routine.name,
            goals: routine.goals,
            days: routine.days,
            notificationEnabled: routine.notificationEnabled,
            memo: routine.memo,
            checks: List.generate(7, (_) => [false]),
            createdAt: routine.createdAt,
            updatedAt: routine.updatedAt,
          );
        }
        return routine;
      }).toList();
    }
  }

  Future<void> saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_routineListKey, jsonEncode(_routineList.map((e) => e.toJson()).toList()));
  }

  Future<void> addRoutine(String name, List<String> goals, List<String> days, bool notificationEnabled, String memo) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    // 체크 상태 초기화 (7일 모두 false로 설정)
    final checks = List.generate(7, (_) => [false]);
    
    final newRoutine = RoutineModel(
      id: id,
      name: name,
      goals: goals,
      days: days,
      notificationEnabled: notificationEnabled,
      memo: memo,
      checks: checks,
      createdAt: DateTime.now(),
    );
    _routineList.add(newRoutine);
    await saveToStorage();
  }

  Future<void> updateRoutine(int index, String name, List<String> goals, List<String> days, bool notificationEnabled, String memo) async {
    if (index >= 0 && index < _routineList.length) {
      final oldId = _routineList[index].id;
      _routineList[index] = RoutineModel(
        id: oldId,
        name: name,
        goals: goals,
        days: days,
        notificationEnabled: notificationEnabled,
        memo: memo,
        checks: _routineList[index].checks,
        createdAt: _routineList[index].createdAt,
        updatedAt: DateTime.now(),
      );
      await saveToStorage();
    }
  }

  Future<void> updateRoutineCheck(int routineIndex, int dayIndex, bool isChecked) async {
    if (routineIndex >= 0 && routineIndex < _routineList.length) {
      final routine = _routineList[routineIndex];
      
      // 체크 상태 배열이 비어있거나 잘못된 경우 초기화
      List<List<bool>> newChecks;
      if (routine.checks.isEmpty || routine.checks.length != 7) {
        newChecks = List.generate(7, (_) => [false]);
      } else {
        newChecks = List<List<bool>>.from(routine.checks);
      }
      
      // 요일 인덱스가 유효한지 확인
      if (dayIndex >= 0 && dayIndex < 7) {
        // 해당 요일의 체크 상태를 업데이트
        newChecks[dayIndex] = [isChecked];
      }
      
      _routineList[routineIndex] = RoutineModel(
        id: routine.id,
        name: routine.name,
        goals: routine.goals,
        days: routine.days,
        notificationEnabled: routine.notificationEnabled,
        memo: routine.memo,
        checks: newChecks,
        createdAt: routine.createdAt,
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
} 