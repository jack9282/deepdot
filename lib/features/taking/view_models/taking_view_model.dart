import 'package:flutter/material.dart';

class TakingViewModel with ChangeNotifier {
  // 약 리스트 (name, times)
  final List<Map<String, dynamic>> _takingList = [
    {
      'name': '약 이름1',
      'times': ['07:00', '12:00', '18:00'],
    },
    {
      'name': '약 이름2',
      'times': ['07:00', '12:00', '18:00'],
    },
    {
      'name': '약 이름3',
      'times': ['07:00', '12:00', '18:00'],
    },
  ];

  List<Map<String, dynamic>> get takingList => List.unmodifiable(_takingList);

  // 약 추가
  void addTaking(String name, List<String> times) {
    _takingList.add({
      'name': name,
      'times': List<String>.from(times),
    });
    notifyListeners();
  }

  // 약 삭제
  void removeTaking(int index) {
    if (index >= 0 && index < _takingList.length) {
      _takingList.removeAt(index);
      notifyListeners();
    }
  }

  // 리스트 초기화 (테스트용)
  void clearAll() {
    _takingList.clear();
    notifyListeners();
  }

  // 시간 추가/삭제 등은 스크린에서 관리하거나, 필요시 추가 구현 가능
}
