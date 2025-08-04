import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DataManager {
  static const String _takingListKey = 'taking_list';
  static const String _takingChecksKey = 'taking_checks';
  static const String _routineListKey = 'routine_list';
  static const String _routineChecksKey = 'routine_checks';
  
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  // 복용 이력 데이터 구조
  static List<Map<String, dynamic>> _takingList = [];
  static Map<String, List<bool>> _takingChecks = {};
  
  // 루틴 데이터 구조
  static List<Map<String, dynamic>> _routineList = [];
  static Map<String, List<bool>> _routineChecks = {};

  // 초기화
  static Future<void> initialize() async {
    await _loadTakingList();
    await _loadTakingChecks();
    await _loadRoutineList();
    await _loadRoutineChecks();
  }

  // 복용 이력 목록 가져오기
  static List<Map<String, dynamic>> getTakingList() {
    return List.from(_takingList);
  }

  // 복용 이력 추가
  static Future<void> addTaking(String name, List<String> times) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newTaking = {
      'id': id,
      'name': name,
      'times': times,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    _takingList.add(newTaking);
    await _saveTakingList();
    
    // 체크 상태 초기화
    _takingChecks[id] = List.generate(times.length, (_) => false);
    await _saveTakingChecks();
  }

  // 복용 이력 수정
  static Future<void> updateTaking(int index, String name, List<String> times) async {
    if (index >= 0 && index < _takingList.length) {
      final oldId = _takingList[index]['id'];
      
      _takingList[index] = {
        'id': oldId,
        'name': name,
        'times': times,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      await _saveTakingList();
      
      // 체크 상태 업데이트 (시간 개수가 변경된 경우)
      if (_takingChecks.containsKey(oldId)) {
        final currentChecks = _takingChecks[oldId]!;
        if (currentChecks.length != times.length) {
          _takingChecks[oldId] = List.generate(times.length, (i) => 
            i < currentChecks.length ? currentChecks[i] : false
          );
          await _saveTakingChecks();
        }
      }
    }
  }

  // 복용 이력 삭제
  static Future<void> removeTaking(int index) async {
    if (index >= 0 && index < _takingList.length) {
      final id = _takingList[index]['id'] as String;
      _takingList.removeAt(index);
      await _saveTakingList();
      
      // 체크 상태도 삭제
      _takingChecks.remove(id);
      await _saveTakingChecks();
    }
  }

  // 체크 상태 가져오기
  static List<bool> getTakingChecks(String id) {
    return _takingChecks[id] ?? [];
  }

  // 체크 상태 업데이트
  static Future<void> updateCheck(String id, int timeIndex, bool isChecked) async {
    if (_takingChecks.containsKey(id)) {
      final checks = _takingChecks[id]!;
      if (timeIndex >= 0 && timeIndex < checks.length) {
        checks[timeIndex] = isChecked;
        await _saveTakingChecks();
      }
    }
  }

  // 체크 상태 업데이트 (인덱스 기반)
  static Future<void> updateCheckByIndex(int takingIndex, int timeIndex, bool isChecked) async {
    if (takingIndex >= 0 && takingIndex < _takingList.length) {
      final id = _takingList[takingIndex]['id'] as String;
      await updateCheck(id, timeIndex, isChecked);
    }
  }

  // 데이터 저장 (SharedPreferences)
  static Future<void> _saveTakingList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_takingList);
    await prefs.setString(_takingListKey, jsonString);
  }

  static Future<void> _saveTakingChecks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_takingChecks);
    await prefs.setString(_takingChecksKey, jsonString);
  }

  // 데이터 로드 (SharedPreferences)
  static Future<void> _loadTakingList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_takingListKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _takingList = jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
    }
  }

  static Future<void> _loadTakingChecks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_takingChecksKey);
    if (jsonString != null) {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      _takingChecks = jsonMap.map((key, value) => 
        MapEntry(key, List<bool>.from(value))
      );
    }
  }

  // 데이터 초기화 (테스트용)
  static Future<void> clearAllData() async {
    _takingList.clear();
    _takingChecks.clear();
    await _saveTakingList();
    await _saveTakingChecks();
  }

  // 특정 복용 이력 가져오기
  static Map<String, dynamic>? getTakingById(String id) {
    try {
      return _takingList.firstWhere((item) => item['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // 복용 이력 개수
  static int getTakingCount() {
    return _takingList.length;
  }

  // 오늘의 체크 상태 요약
  static Map<String, dynamic> getTodaySummary() {
    int totalItems = _takingList.length;
    int totalTimes = 0;
    int checkedTimes = 0;

    for (final taking in _takingList) {
      final id = taking['id'];
      final times = List<String>.from(taking['times']);
      final checks = getTakingChecks(id);
      
      totalTimes += times.length;
      checkedTimes += checks.where((check) => check).length;
    }

    return {
      'totalItems': totalItems,
      'totalTimes': totalTimes,
      'checkedTimes': checkedTimes,
      'completionRate': totalTimes > 0 ? (checkedTimes / totalTimes * 100).round() : 0,
    };
  }

  // ========== 루틴 관련 메서드들 ==========

  // 루틴 목록 가져오기
  static List<Map<String, dynamic>> getRoutineList() {
    return List.from(_routineList);
  }

  // 루틴 추가
  static Future<void> addRoutine(String name, List<String> items, List<String> days, bool notificationEnabled, int hour, int minute, bool isAM) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newRoutine = {
      'id': id,
      'name': name,
      'items': items,
      'days': days,
      'notificationEnabled': notificationEnabled,
      'hour': hour,
      'minute': minute,
      'isAM': isAM,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    _routineList.add(newRoutine);
    await _saveRoutineList();
    
    // 체크 상태 초기화 (7일)
    _routineChecks[id] = List.generate(7, (_) => false);
    await _saveRoutineChecks();
  }

  // 루틴 수정
  static Future<void> updateRoutine(int index, String name, List<String> items, List<String> days, bool notificationEnabled, int hour, int minute, bool isAM) async {
    if (index >= 0 && index < _routineList.length) {
      final oldId = _routineList[index]['id'];
      
      _routineList[index] = {
        'id': oldId,
        'name': name,
        'items': items,
        'days': days,
        'notificationEnabled': notificationEnabled,
        'hour': hour,
        'minute': minute,
        'isAM': isAM,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      await _saveRoutineList();
    }
  }

  // 루틴 삭제
  static Future<void> removeRoutine(int index) async {
    if (index >= 0 && index < _routineList.length) {
      final id = _routineList[index]['id'] as String;
      _routineList.removeAt(index);
      await _saveRoutineList();
      
      // 체크 상태도 삭제
      _routineChecks.remove(id);
      await _saveRoutineChecks();
    }
  }

  // 루틴 체크 상태 가져오기
  static List<bool> getRoutineChecks(String id) {
    return _routineChecks[id] ?? [];
  }

  // 루틴 체크 상태 업데이트
  static Future<void> updateRoutineCheck(String id, int dayIndex, bool isChecked) async {
    if (_routineChecks.containsKey(id)) {
      final checks = _routineChecks[id]!;
      if (dayIndex >= 0 && dayIndex < checks.length) {
        checks[dayIndex] = isChecked;
        await _saveRoutineChecks();
      }
    }
  }

  // 루틴 체크 상태 업데이트 (인덱스 기반)
  static Future<void> updateRoutineCheckByIndex(int routineIndex, int dayIndex, bool isChecked) async {
    if (routineIndex >= 0 && routineIndex < _routineList.length) {
      final id = _routineList[routineIndex]['id'] as String;
      await updateRoutineCheck(id, dayIndex, isChecked);
    }
  }

  // 루틴 데이터 저장 (SharedPreferences)
  static Future<void> _saveRoutineList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_routineList);
    await prefs.setString(_routineListKey, jsonString);
  }

  static Future<void> _saveRoutineChecks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_routineChecks);
    await prefs.setString(_routineChecksKey, jsonString);
  }

  // 루틴 데이터 로드 (SharedPreferences)
  static Future<void> _loadRoutineList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_routineListKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _routineList = jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
    }
  }

  static Future<void> _loadRoutineChecks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_routineChecksKey);
    if (jsonString != null) {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      _routineChecks = jsonMap.map((key, value) => 
        MapEntry(key, List<bool>.from(value))
      );
    }
  }

  // 루틴 개수
  static int getRoutineCount() {
    return _routineList.length;
  }

  // 특정 루틴 가져오기
  static Map<String, dynamic>? getRoutineById(String id) {
    try {
      return _routineList.firstWhere((item) => item['id'] == id);
    } catch (e) {
      return null;
    }
  }
}
