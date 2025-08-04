import 'package:flutter/material.dart';

// 루틴 뷰모델
class RoutineViewModel extends ChangeNotifier {
  // 체크박스 상태 업데이트
  void updateCheck(List<Map<String, dynamic>> routines, int routineIndex, int dayIndex, bool value) {
    routines[routineIndex]['checks'][dayIndex] = value;
    notifyListeners();
  }

  // 루틴 추가
  void addRoutine(List<Map<String, dynamic>> routines, String name) {
    routines.add({
      'name': name,
      'checks': List.generate(7, (_) => false),
    });
    notifyListeners();
  }

  // 루틴 삭제
  void removeRoutine(List<Map<String, dynamic>> routines, int index) {
    routines.removeAt(index);
    notifyListeners();
  }

  // 루틴 수정
  void updateRoutine(List<Map<String, dynamic>> routines, int index, String name) {
    routines[index]['name'] = name;
    notifyListeners();
  }
}

