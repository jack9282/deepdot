import 'package:flutter/material.dart';
import '../../../data/repositories/taking_repository.dart';
import '../../../data/models/taking_model.dart';

class TakingViewModel with ChangeNotifier {
  List<TakingModel> _takingList = [];

  List<TakingModel> get takingList => List.unmodifiable(_takingList);

  // 초기화
  Future<void> initialize() async {
    await TakingRepository().loadFromStorage();
    _loadTakingList();
  }

  // 데이터 로드
  void _loadTakingList() {
    _takingList = TakingRepository().takingList;
    notifyListeners();
  }

  // 약 추가
  Future<void> addTaking(String name, List<String> times) async {
    await TakingRepository().addTaking(name, times);
    _loadTakingList();
  }

  // 약 수정
  Future<void> updateTaking(int index, String name, List<String> times) async {
    await TakingRepository().updateTaking(index, name, times);
    _loadTakingList();
  }

  // 체크박스 상태 업데이트
  Future<void> updateCheck(int itemIndex, int checkIndex, bool value) async {
    await TakingRepository().updateCheckByIndex(itemIndex, checkIndex, value);
    _loadTakingList();
  }

  // 약 삭제
  Future<void> removeTaking(int index) async {
    await TakingRepository().removeTaking(index);
    _loadTakingList();
  }

  // 리스트 초기화 (테스트용)
  Future<void> clearAll() async {
    TakingRepository().clearAllData();
    _loadTakingList();
  }

  // 체크 상태 가져오기
  List<bool> getChecksForItem(int index) {
    if (index >= 0 && index < _takingList.length) {
      final id = _takingList[index].id;
      return TakingRepository().getTakingChecks(id);
    }
    return [];
  }
}