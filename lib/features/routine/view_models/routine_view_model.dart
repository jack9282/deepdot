import 'package:flutter/material.dart';
import '../../../data/repositories/routine_repository.dart';
import '../../../data/models/routine_model.dart';

class RoutineViewModel extends ChangeNotifier {
  List<RoutineModel> _routineList = [];

  List<RoutineModel> get routineList => List.unmodifiable(_routineList);

  Future<void> initialize() async {
    await RoutineRepository().loadFromStorage();
    _loadRoutineList();
  }

  void _loadRoutineList() {
    _routineList = RoutineRepository().routineList;
    notifyListeners();
  }

  Future<void> addRoutine(String name, List<String> goals, List<String> days, bool notificationEnabled, String memo) async {
    await RoutineRepository().addRoutine(name, goals, days, notificationEnabled, memo);
    _loadRoutineList();
  }

  Future<void> updateRoutine(int index, String name, List<String> goals, List<String> days, bool notificationEnabled, String memo) async {
    await RoutineRepository().updateRoutine(index, name, goals, days, notificationEnabled, memo);
    _loadRoutineList();
  }

  Future<void> removeRoutine(int index) async {
    await RoutineRepository().removeRoutine(index);
    _loadRoutineList();
  }

  Future<void> updateRoutineCheck(int routineIndex, int dayIndex, bool isChecked) async {
    await RoutineRepository().updateRoutineCheck(routineIndex, dayIndex, isChecked);
    _loadRoutineList();
  }

  List<bool> getRoutineChecks(int routineIndex) {
    if (routineIndex >= 0 && routineIndex < _routineList.length) {
      final routine = _routineList[routineIndex];
      
      // 체크 상태 배열이 비어있거나 잘못된 경우 기본값 반환
      if (routine.checks.isEmpty || routine.checks.length != 7) {
        return List.generate(7, (_) => false);
      }
      
      return routine.checks.map((check) => check.isNotEmpty ? check.first : false).toList();
    }
    return List.generate(7, (_) => false);
  }

  Future<void> clearAll() async {
    RoutineRepository().clearAllData();
    _loadRoutineList();
  }

  Future<void> refresh() async {
    await RoutineRepository().loadFromStorage();
    _loadRoutineList();
  }
}

