import 'package:flutter/material.dart';
import '../../../manager/data_manager.dart';

class RoutineViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> _routineList = [];

  List<Map<String, dynamic>> get routineList => List.unmodifiable(_routineList);

  // 초기화
  Future<void> initialize() async {
    await DataManager.initialize();
    _loadRoutineList();
  }

  // 데이터 로드
  void _loadRoutineList() {
    _routineList = DataManager.getRoutineList();
    notifyListeners();
  }

  // 루틴 추가
  Future<void> addRoutine(String name, List<String> items, List<String> days, bool notificationEnabled, int hour, int minute, bool isAM) async {
    await DataManager.addRoutine(name, items, days, notificationEnabled, hour, minute, isAM);
    _loadRoutineList();
  }

  // 루틴 수정
  Future<void> updateRoutine(int index, String name, List<String> items, List<String> days, bool notificationEnabled, int hour, int minute, bool isAM) async {
    await DataManager.updateRoutine(index, name, items, days, notificationEnabled, hour, minute, isAM);
    _loadRoutineList();
  }

  // 루틴 삭제
  Future<void> removeRoutine(int index) async {
    await DataManager.removeRoutine(index);
    _loadRoutineList();
  }

  // 체크박스 상태 업데이트
  Future<void> updateCheck(int routineIndex, int dayIndex, bool value) async {
    await DataManager.updateRoutineCheckByIndex(routineIndex, dayIndex, value);
    _loadRoutineList();
  }

  // 체크 상태 가져오기
  List<bool> getChecksForItem(int index) {
    if (index >= 0 && index < _routineList.length) {
      final id = _routineList[index]['id'] as String;
      return DataManager.getRoutineChecks(id);
    }
    return [];
  }

  // 리스트 초기화 (테스트용)
  Future<void> clearAll() async {
    // DataManager에 clearAll 메서드 추가 필요
    _loadRoutineList();
  }

  // 강제 새로고침
  Future<void> refresh() async {
    await DataManager.initialize();
    _loadRoutineList();
  }
}

