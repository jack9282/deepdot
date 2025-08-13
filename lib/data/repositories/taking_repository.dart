import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/taking_model.dart';
import '../../api/taking-api.dart';

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
    try {
      // API 호출
      final newTaking = await TakingApi.createMedication(
        name: name,
        alarm: true, // 기본값으로 true 설정
      );
      
      // 로컬 저장소에 추가
      _takingList.add(newTaking);
      _takingChecks[newTaking.id] = List.generate(times.length, (_) => false);
      await saveToStorage();
    } catch (e) {
      // API 실패 시 로컬에만 저장
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
      throw e;
    }
  }

  Future<void> updateTaking(int index, String name, List<String> times) async {
    if (index >= 0 && index < _takingList.length) {
      final oldId = _takingList[index].id;
      
      try {
        // API 호출
        final updatedTaking = await TakingApi.updateMedication(
          medicationId: int.parse(oldId),
          name: name,
          alarm: true, // 기본값으로 true 설정
        );
        
        // 로컬 저장소 업데이트
        _takingList[index] = updatedTaking;
      } catch (e) {
        // API 실패 시 로컬에만 업데이트
        _takingList[index] = TakingModel(
          id: oldId,
          name: name,
          times: times,
          createdAt: _takingList[index].createdAt,
          updatedAt: DateTime.now(),
        );
        throw e;
      }
      
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
      
      try {
        // API 호출
        await TakingApi.deleteMedication(int.parse(id));
      } catch (e) {
        // API 실패 시에도 로컬에서 삭제
        print('API 삭제 실패, 로컬에서만 삭제: $e');
      }
      
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

  /// API에서 모든 약물 데이터 동기화
  Future<void> syncFromApi() async {
    try {
      final apiMedications = await TakingApi.getAllMedications();
      _takingList = apiMedications;
      
      // 체크 상태 초기화
      for (final medication in _takingList) {
        if (!_takingChecks.containsKey(medication.id)) {
          _takingChecks[medication.id] = List.generate(medication.times.length, (_) => false);
        }
      }
      
      await saveToStorage();
    } catch (e) {
      print('API 동기화 실패: $e');
      // API 실패 시 로컬 데이터 유지
    }
  }
} 