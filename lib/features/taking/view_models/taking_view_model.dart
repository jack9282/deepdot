import 'package:flutter/material.dart';
import '../../../manager/data_manager.dart';

class TakingViewModel with ChangeNotifier {
  List<Map<String, dynamic>> _takingList = [];

  List<Map<String, dynamic>> get takingList => List.unmodifiable(_takingList);

  // 초기화
  Future<void> initialize() async {
    await DataManager.initialize();
    _loadTakingList();
  }

  // 데이터 로드
  void _loadTakingList() {
    _takingList = DataManager.getTakingList();
    notifyListeners();
  }

  // 약 추가
  Future<void> addTaking(String name, List<String> times) async {
    await DataManager.addTaking(name, times);
    _loadTakingList();
  }

  // 약 수정
  Future<void> updateTaking(int index, String name, List<String> times) async {
    await DataManager.updateTaking(index, name, times);
    _loadTakingList();
  }

  // 체크박스 상태 업데이트
  Future<void> updateCheck(int itemIndex, int checkIndex, bool value) async {
    await DataManager.updateCheckByIndex(itemIndex, checkIndex, value);
    _loadTakingList();
  }

  // 약 삭제
  Future<void> removeTaking(int index) async {
    await DataManager.removeTaking(index);
    _loadTakingList();
  }

  // 리스트 초기화 (테스트용)
  Future<void> clearAll() async {
    await DataManager.clearAllData();
    _loadTakingList();
  }

  // 체크 상태 가져오기
  List<bool> getChecksForItem(int index) {
    if (index >= 0 && index < _takingList.length) {
      final id = _takingList[index]['id'] as String;
      return DataManager.getTakingChecks(id);
    }
    return [];
  }

  // 시간 추가/삭제 등은 스크린에서 관리하거나, 필요시 추가 구현 가능
}