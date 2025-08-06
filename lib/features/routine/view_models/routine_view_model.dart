import 'package:flutter/material.dart';
import '../../../data/repositories/routine_repository.dart';
import '../../../data/models/routine_model.dart';

class RoutineViewModel extends ChangeNotifier {
  List<RoutineModel> _routineList = [];

  List<RoutineModel> get routineList => List.unmodifiable(_routineList);

  // 초기화
  Future<void> initialize() async {
    await RoutineRepository().loadFromStorage();
    _loadRoutineList();
  }

  // 데이터 로드
  void _loadRoutineList() {
    _routineList = RoutineRepository().routineList;
    notifyListeners();
  }

  // 루틴 추가
  Future<void> addRoutine(String name, List<RoutineItem> items, bool notificationEnabled, int hour, int minute, bool isAM) async {
    await RoutineRepository().addRoutine(name, items, notificationEnabled, hour, minute, isAM);
    _loadRoutineList();
  }

  // 루틴 수정
  Future<void> updateRoutine(int index, String name, List<RoutineItem> items, bool notificationEnabled, int hour, int minute, bool isAM) async {
    await RoutineRepository().updateRoutine(index, name, items, notificationEnabled, hour, minute, isAM);
    _loadRoutineList();
  }

  // 루틴 삭제
  Future<void> removeRoutine(int index) async {
    await RoutineRepository().removeRoutine(index);
    _loadRoutineList();
  }

  // 체크박스 상태 업데이트
  Future<void> updateCheck(int routineIndex, int itemIndex, int dayIndex, bool value) async {
    await RoutineRepository().updateRoutineCheckByIndex(routineIndex, itemIndex, dayIndex, value);
    _loadRoutineList();
  }

  // 체크 상태 가져오기
  List<List<bool>> getChecksForRoutine(int index) {
    if (index >= 0 && index < _routineList.length) {
      final id = _routineList[index].id;
      return RoutineRepository().getRoutineChecks(id);
    }
    return [];
  }

  // 리스트 초기화 (테스트용)
  Future<void> clearAll() async {
    RoutineRepository().clearAllData();
    _loadRoutineList();
  }

  // 강제 새로고침
  Future<void> refresh() async {
    await RoutineRepository().loadFromStorage();
    _loadRoutineList();
  }
}

