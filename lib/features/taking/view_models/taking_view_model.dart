import 'package:flutter/material.dart';

class TakingViewModel with ChangeNotifier {
  // 약 리스트 (name, times, checks)
  final List<Map<String, dynamic>> _takingList = [
    {
      'name': '약 이름1',
      'times': ['07:00', '12:00', '18:00'],
      'checks': [false, false, false],
    },
    {
      'name': '약 이름2',
      'times': ['07:00', '12:00', '18:00'],
      'checks': [false, false, false],
    },
    {
      'name': '약 이름3',
      'times': ['07:00', '12:00', '18:00'],
      'checks': [false, false, false],
    },
  ];

  List<Map<String, dynamic>> get takingList => List.unmodifiable(_takingList);

  // 약 추가
  void addTaking(String name, List<String> times) {
    _takingList.add({
      'name': name,
      'times': List<String>.from(times),
      'checks': List.generate(times.length, (_) => false),
    });
    notifyListeners();
  }

  // 약 수정
  void updateTaking(int index, String name, List<String> times) {
    if (index >= 0 && index < _takingList.length) {
      final existingChecks = _takingList[index]['checks'] as List<bool>? ?? [];
      final newChecks = List.generate(times.length, (i) {
        return i < existingChecks.length ? existingChecks[i] : false;
      });
      
      _takingList[index] = {
        'name': name,
        'times': List<String>.from(times),
        'checks': newChecks,
      };
      notifyListeners();
    }
  }

  // 체크박스 상태 업데이트
  void updateCheck(int itemIndex, int checkIndex, bool value) {
    if (itemIndex >= 0 && itemIndex < _takingList.length) {
      final item = _takingList[itemIndex];
      final checks = List<bool>.from(item['checks'] as List<bool>);
      
      if (checkIndex >= 0 && checkIndex < checks.length) {
        checks[checkIndex] = value;
        _takingList[itemIndex] = {
          ...item,
          'checks': checks,
        };
        notifyListeners();
      }
    }
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