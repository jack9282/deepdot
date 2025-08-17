import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine_model.dart';
import '../../api/token_manager.dart';

class RoutineRepository {
  static const String _routineListKey = 'routine_list';
  static const String _lastSyncKey = 'routine_last_sync_timestamp';

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
        
        // 체크 상태가 올바르지 않은 경우 초기화
        if (routine.checks.length != 7) {
          return routine.copyWith(
            checks: List.generate(7, (_) => false),
          );
        }
        return routine;
      }).toList();
    }
  }

  Future<void> saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_routineListKey, jsonEncode(_routineList.map((e) => e.toJson()).toList()));
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> addRoutine(String name, List<String> goals, List<String> days, bool notificationEnabled, String notificationTime, String memo) async {
    // 비회원 모드 체크
    if (await TokenManager.instance.isGuestMode()) {
      print('비회원 모드 - 로컬에서만 저장');
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final checks = List.generate(7, (_) => false);
      
      final newRoutine = RoutineModel(
        id: id,
        name: name,
        goals: goals,
        days: days,
        notificationEnabled: notificationEnabled,
        notificationTime: notificationTime,
        memo: memo,
        checks: checks,
        createdAt: DateTime.now(),
      );
      _routineList.add(newRoutine);
      await saveToStorage();
      return;
    }

    try {
      // TODO: RoutineApi.createRoutine() 구현 후 실제 API 호출로 교체
      // final newRoutine = await RoutineApi.createRoutine(
      //   name: name,
      //   goals: goals,
      //   days: days,
      //   notificationEnabled: notificationEnabled,
      //   notificationTime: notificationTime,
      //   memo: memo,
      // );
      
      // 현재는 로컬에서만 저장
      print('API 호출 건너뛰고 로컬에서만 저장');
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final checks = List.generate(7, (_) => false);
      
      final newRoutine = RoutineModel(
        id: id,
        name: name,
        goals: goals,
        days: days,
        notificationEnabled: notificationEnabled,
        notificationTime: notificationTime,
        memo: memo,
        checks: checks,
        createdAt: DateTime.now(),
      );
      _routineList.add(newRoutine);
      await saveToStorage();
    } catch (e) {
      print('API 추가 실패, 로컬에서만 저장: $e');
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final checks = List.generate(7, (_) => false);
      
      final newRoutine = RoutineModel(
        id: id,
        name: name,
        goals: goals,
        days: days,
        notificationEnabled: notificationEnabled,
        notificationTime: notificationTime,
        memo: memo,
        checks: checks,
        createdAt: DateTime.now(),
      );
      _routineList.add(newRoutine);
      await saveToStorage();
      throw e;
    }
  }

  Future<void> updateRoutine(int index, String name, List<String> goals, List<String> days, bool notificationEnabled, String notificationTime, String memo) async {
    if (index >= 0 && index < _routineList.length) {
      final oldRoutine = _routineList[index];
      
      // 비회원 모드 체크
      if (await TokenManager.instance.isGuestMode()) {
        print('비회원 모드 - 로컬에서만 저장');
        _routineList[index] = oldRoutine.copyWith(
          name: name,
          goals: goals,
          days: days,
          notificationEnabled: notificationEnabled,
          notificationTime: notificationTime,
          memo: memo,
          updatedAt: DateTime.now(),
        );
        await saveToStorage();
        return;
      }
      
      try {
        // TODO: RoutineApi.updateRoutine() 구현 후 실제 API 호출로 교체
        // final updatedRoutine = await RoutineApi.updateRoutine(
        //   routineId: int.parse(oldRoutine.id),
        //   name: name,
        //   goals: goals,
        //   days: days,
        //   notificationEnabled: notificationEnabled,
        //   notificationTime: notificationTime,
        //   memo: memo,
        // );
        
        // 현재는 로컬에서만 저장
        print('API 호출 건너뛰고 로컬에서만 저장');
        _routineList[index] = oldRoutine.copyWith(
          name: name,
          goals: goals,
          days: days,
          notificationEnabled: notificationEnabled,
          notificationTime: notificationTime,
          memo: memo,
          updatedAt: DateTime.now(),
        );
      } catch (e) {
        print('API 수정 실패, 로컬에서만 저장: $e');
        _routineList[index] = oldRoutine.copyWith(
          name: name,
          goals: goals,
          days: days,
          notificationEnabled: notificationEnabled,
          notificationTime: notificationTime,
          memo: memo,
          updatedAt: DateTime.now(),
        );
        throw e;
      }
      
      await saveToStorage();
    }
  }

  Future<void> updateRoutineCheck(int routineIndex, int dayIndex, bool isChecked) async {
    if (routineIndex >= 0 && routineIndex < _routineList.length) {
      final routine = _routineList[routineIndex];
      
      // 체크 상태 배열이 올바르지 않은 경우 초기화
      List<bool> newChecks;
      if (routine.checks.length != 7) {
        newChecks = List.generate(7, (_) => false);
      } else {
        newChecks = List<bool>.from(routine.checks);
      }
      
      // 요일 인덱스가 유효한지 확인
      if (dayIndex >= 0 && dayIndex < 7) {
        newChecks[dayIndex] = isChecked;
      }
      
      _routineList[routineIndex] = routine.copyWith(
        checks: newChecks,
        updatedAt: DateTime.now(),
      );
      await saveToStorage();
    }
  }

  Future<void> removeRoutine(int index) async {
    if (index >= 0 && index < _routineList.length) {
      final id = _routineList[index].id;
      
      // 비회원 모드 체크
      if (await TokenManager.instance.isGuestMode()) {
        print('비회원 모드 - 로컬에서만 삭제');
        _routineList.removeAt(index);
        await saveToStorage();
        return;
      }
      
      try {
        // TODO: RoutineApi.deleteRoutine() 구현 후 실제 API 호출로 교체
        // await RoutineApi.deleteRoutine(int.parse(id));
        print('API 호출 건너뛰고 로컬에서만 삭제');
      } catch (e) {
        print('API 삭제 실패, 로컬에서만 삭제: $e');
      }
      
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

  /// 마지막 동기화 시간 확인
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// 특정 목표의 루틴 목록 조회
  List<RoutineModel> getRoutinesByGoal(String goal) {
    return _routineList.where((routine) => routine.goals.contains(goal)).toList();
  }

  /// 특정 루틴의 체크 상태 조회
  List<bool> getRoutineChecks(int routineIndex) {
    if (routineIndex >= 0 && routineIndex < _routineList.length) {
      final routine = _routineList[routineIndex];
      
      // 체크 상태 배열이 올바르지 않은 경우 기본값 반환
      if (routine.checks.length != 7) {
        return List.generate(7, (_) => false);
      }
      
      return List<bool>.from(routine.checks);
    }
    return List.generate(7, (_) => false);
  }

  /// 체크 상태 통계 조회
  Map<String, dynamic> getRoutineStats() {
    int totalRoutines = _routineList.length;
    int totalChecks = 0;
    int completedChecks = 0;

    for (final routine in _routineList) {
      for (final check in routine.checks) {
        totalChecks++;
        if (check) completedChecks++;
      }
    }

    return {
      'totalRoutines': totalRoutines,
      'totalChecks': totalChecks,
      'completedChecks': completedChecks,
      'completionRate': totalChecks > 0 ? (completedChecks / totalChecks) : 0.0,
    };
  }

  /// API에서 모든 루틴 데이터 동기화
  Future<void> syncFromApi() async {
    // 비회원 모드 체크
    if (await TokenManager.instance.isGuestMode()) {
      print('비회원 모드 - API 동기화 건너뛰기');
      return;
    }
    
    try {
      // TODO: RoutineApi 구현 후 실제 API 호출로 교체
      // final apiRoutines = await RoutineApi.getAllRoutines();
      
      // 현재는 로컬 데이터만 유지
      print('루틴 API 동기화 - 현재는 로컬 데이터만 사용');
      await saveToStorage();
    } catch (e) {
      print('루틴 API 동기화 실패: $e');
      // API 실패 시 로컬 데이터 유지
    }
  }

  /// 루틴의 알람 ID를 업데이트합니다.
  Future<void> updateRoutineAlarmId(int routineIndex, int alarmId) async {
    try {
      if (routineIndex >= 0 && routineIndex < _routineList.length) {
        final routine = _routineList[routineIndex];
        final updatedRoutine = routine.copyWith(alarmId: alarmId);
        _routineList[routineIndex] = updatedRoutine;
        await saveToStorage();
      }
    } catch (e) {
      print('알람 ID 업데이트 중 오류 발생: $e');
    }
  }

  /// 마지막에 추가된 루틴의 알람 ID를 설정합니다.
  Future<void> setLastAddedRoutineAlarmId(int alarmId) async {
    try {
      if (_routineList.isNotEmpty) {
        final lastIndex = _routineList.length - 1;
        final lastRoutine = _routineList[lastIndex];
        final updatedRoutine = lastRoutine.copyWith(alarmId: alarmId);
        _routineList[lastIndex] = updatedRoutine;
        await saveToStorage();
      }
    } catch (e) {
      print('마지막 루틴 알람 ID 설정 중 오류 발생: $e');
    }
  }
} 