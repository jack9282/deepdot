import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine_model.dart';

class RoutineRepository {
  static const String _routineListKey = 'routine_list';
  static const String _routineChecksKey = 'routine_checks';

  static final RoutineRepository _instance = RoutineRepository._internal();
  factory RoutineRepository() => _instance;
  RoutineRepository._internal();

  List<RoutineModel> _routineList = [];
  Map<String, List<List<bool>>> _routineChecks = {};

  List<RoutineModel> get routineList => List.unmodifiable(_routineList);
  Map<String, List<List<bool>>> get routineChecks => Map.unmodifiable(_routineChecks);

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final routineJson = prefs.getString(_routineListKey);
    if (routineJson != null) {
      final List<dynamic> jsonList = jsonDecode(routineJson);
      _routineList = jsonList.map((item) => RoutineModel.fromJson(item)).toList();
    }
    final checksJson = prefs.getString(_routineChecksKey);
    if (checksJson != null) {
      final Map<String, dynamic> jsonMap = jsonDecode(checksJson);
      _routineChecks = jsonMap.map((key, value) {
        final checksList = value as List;
        if (checksList.isNotEmpty && checksList.first is bool) {
          // 기존 데이터: List<bool> → List<List<bool>>로 마이그레이션
          return MapEntry(key, [List<bool>.from(checksList)]);
        } else {
          // 새 데이터: List<List<bool>>
          return MapEntry(key, checksList.map((item) => List<bool>.from(item)).toList());
        }
      });
    }
  }

  Future<void> saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_routineListKey, jsonEncode(_routineList.map((e) => e.toJson()).toList()));
    await prefs.setString(_routineChecksKey, jsonEncode(_routineChecks));
  }

  Future<void> addRoutine(String name, List<RoutineItem> items, bool notificationEnabled, int hour, int minute, bool isAM) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newRoutine = RoutineModel(
      id: id,
      name: name,
      items: items,
      notificationEnabled: notificationEnabled,
      hour: hour,
      minute: minute,
      isAM: isAM,
      createdAt: DateTime.now(),
    );
    _routineList.add(newRoutine);
    _routineChecks[id] = List.generate(items.length, (_) => List.generate(7, (_) => false));
    await saveToStorage();
  }

  Future<void> updateRoutine(int index, String name, List<RoutineItem> items, bool notificationEnabled, int hour, int minute, bool isAM) async {
    if (index >= 0 && index < _routineList.length) {
      final oldId = _routineList[index].id;
      _routineList[index] = RoutineModel(
        id: oldId,
        name: name,
        items: items,
        notificationEnabled: notificationEnabled,
        hour: hour,
        minute: minute,
        isAM: isAM,
        createdAt: _routineList[index].createdAt,
        updatedAt: DateTime.now(),
      );
      // 체크 데이터도 항목 개수에 맞게 맞춰준다
      final oldChecks = _routineChecks[oldId] ?? [];
      if (oldChecks.length != items.length) {
        _routineChecks[oldId] = List.generate(items.length, (i) => List.generate(7, (j) => false));
      }
      await saveToStorage();
    }
  }

  Future<void> removeRoutine(int index) async {
    if (index >= 0 && index < _routineList.length) {
      final id = _routineList[index].id;
      _routineList.removeAt(index);
      _routineChecks.remove(id);
      await saveToStorage();
    }
  }

  List<List<bool>> getRoutineChecks(String id) {
    return _routineChecks[id] ?? [];
  }

  Future<void> updateRoutineCheck(String id, int itemIndex, int dayIndex, bool isChecked) async {
    if (_routineChecks.containsKey(id)) {
      final checks = _routineChecks[id]!;
      if (itemIndex >= 0 && itemIndex < checks.length && dayIndex >= 0 && dayIndex < checks[itemIndex].length) {
        checks[itemIndex][dayIndex] = isChecked;
        await saveToStorage();
      }
    }
  }

  Future<void> updateRoutineCheckByIndex(int routineIndex, int itemIndex, int dayIndex, bool isChecked) async {
    final id = _routineList[routineIndex].id;
    await updateRoutineCheck(id, itemIndex, dayIndex, isChecked);
  }

  void clearAllData() async {
    _routineList.clear();
    _routineChecks.clear();
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
} 