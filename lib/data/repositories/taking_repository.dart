import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/taking_model.dart';

class TakingRepository {
  static const String _takingListKey = 'taking_list';
  static const String _takingChecksKey = 'taking_checks';

  static final TakingRepository _instance = TakingRepository._internal();
  factory TakingRepository() => _instance;
  TakingRepository._internal();

  List<TakingModel> _takingList = [];
  Map<String, List<bool>> _takingChecks = {};

  List<TakingModel> get takingList => List.unmodifiable(_takingList);
  Map<String, List<bool>> get takingChecks => Map.unmodifiable(_takingChecks);

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final takingJson = prefs.getString(_takingListKey);
    if (takingJson != null) {
      final List<dynamic> jsonList = jsonDecode(takingJson);
      _takingList = jsonList.map((item) => TakingModel.fromJson(item)).toList();
    }
    final checksJson = prefs.getString(_takingChecksKey);
    if (checksJson != null) {
      final Map<String, dynamic> jsonMap = jsonDecode(checksJson);
      _takingChecks = jsonMap.map((key, value) => MapEntry(key, List<bool>.from(value)));
    }
  }

  Future<void> saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_takingListKey, jsonEncode(_takingList.map((e) => e.toJson()).toList()));
    await prefs.setString(_takingChecksKey, jsonEncode(_takingChecks));
  }

  Future<void> addTaking(String name, List<String> times) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newTaking = TakingModel(
      id: id,
      name: name,
      times: times,
      createdAt: DateTime.now(),
    );
    _takingList.add(newTaking);
    _takingChecks[id] = List.generate(times.length, (_) => false);
    await saveToStorage();
  }

  Future<void> updateTaking(int index, String name, List<String> times) async {
    if (index >= 0 && index < _takingList.length) {
      final oldId = _takingList[index].id;
      _takingList[index] = TakingModel(
        id: oldId,
        name: name,
        times: times,
        createdAt: _takingList[index].createdAt,
        updatedAt: DateTime.now(),
      );
      // Update checks if times length changed
      if (_takingChecks.containsKey(oldId)) {
        final currentChecks = _takingChecks[oldId]!;
        if (currentChecks.length != times.length) {
          _takingChecks[oldId] = List.generate(times.length, (i) => i < currentChecks.length ? currentChecks[i] : false);
        }
      }
      await saveToStorage();
    }
  }

  Future<void> removeTaking(int index) async {
    if (index >= 0 && index < _takingList.length) {
      final id = _takingList[index].id;
      _takingList.removeAt(index);
      _takingChecks.remove(id);
      await saveToStorage();
    }
  }

  List<bool> getTakingChecks(String id) {
    return _takingChecks[id] ?? [];
  }

  Future<void> updateCheck(String id, int timeIndex, bool isChecked) async {
    if (_takingChecks.containsKey(id)) {
      final checks = _takingChecks[id]!;
      if (timeIndex >= 0 && timeIndex < checks.length) {
        checks[timeIndex] = isChecked;
        await saveToStorage();
      }
    }
  }

  Future<void> updateCheckByIndex(int takingIndex, int timeIndex, bool isChecked) async {
    if (takingIndex >= 0 && takingIndex < _takingList.length) {
      final id = _takingList[takingIndex].id;
      await updateCheck(id, timeIndex, isChecked);
    }
  }

  void clearAllData() async {
    _takingList.clear();
    _takingChecks.clear();
    await saveToStorage();
  }

  TakingModel? getTakingById(String id) {
    try {
      return _takingList.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  int getTakingCount() => _takingList.length;
} 