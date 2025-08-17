import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/taking_model.dart';
import '../../api/taking-api.dart';
import '../../api/token_manager.dart';

class TakingRepository {
  static const String _takingListKey = 'taking_list';
  static const String _takingChecksKey = 'taking_checks';
  static const String _lastSyncKey = 'last_sync_timestamp';

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
      _takingList = jsonList.map((item) {
        final taking = TakingModel.fromJson(item);
        
        // times 필드가 비어있거나 null인 경우 기본값 설정
        if (taking.times.isEmpty) {
          return TakingModel(
            id: taking.id,
            name: taking.name,
            times: ['08:00', '12:00', '18:00'], // 기본 복용 시간
            alarmEnabled: taking.alarmEnabled,
            alarmTime: taking.alarmTime.isEmpty ? '08:00' : taking.alarmTime,
            createdAt: taking.createdAt,
            updatedAt: taking.updatedAt,
          );
        }
        return taking;
      }).toList();
    }
    
    final checksJson = prefs.getString(_takingChecksKey);
    if (checksJson != null) {
      final Map<String, dynamic> jsonMap = jsonDecode(checksJson);
      _takingChecks = jsonMap.map((key, value) => MapEntry(key, List<bool>.from(value)));
    }
    
    // 체크 상태가 없는 항목들에 대해 초기화
    for (final taking in _takingList) {
      if (!_takingChecks.containsKey(taking.id)) {
        _takingChecks[taking.id] = List.generate(taking.times.length, (_) => false);
      }
    }
  }

  Future<void> saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_takingListKey, jsonEncode(_takingList.map((e) => e.toJson()).toList()));
    await prefs.setString(_takingChecksKey, jsonEncode(_takingChecks));
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> addTaking(String name, List<String> times, bool alarmEnabled, String alarmTime) async {
    // 비회원 모드 체크
    if (await TokenManager.instance.isGuestMode()) {
      print('비회원 모드 - 로컬에서만 저장');
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final newTaking = TakingModel(
        id: id,
        name: name,
        times: times,
        alarmEnabled: alarmEnabled,
        alarmTime: alarmTime,
        createdAt: DateTime.now(),
      );
      _takingList.add(newTaking);
      _takingChecks[id] = List.generate(times.length, (_) => false);
      await saveToStorage();
      return;
    }

    try {
      final newTaking = await TakingApi.createMedication(
        name: name,
        alarm: alarmEnabled,
      );
      
      // API 응답에 times가 없으면 로컬에서 설정한 times 사용
      final takingWithTimes = TakingModel(
        id: newTaking.id,
        name: newTaking.name,
        times: times,
        alarmEnabled: newTaking.alarmEnabled,
        alarmTime: alarmTime,
        createdAt: newTaking.createdAt,
        updatedAt: newTaking.updatedAt,
      );
      
      _takingList.add(takingWithTimes);
      _takingChecks[takingWithTimes.id] = List.generate(times.length, (_) => false);
      await saveToStorage();
    } catch (e) {
      print('API 추가 실패, 로컬에서만 저장: $e');
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final newTaking = TakingModel(
        id: id,
        name: name,
        times: times,
        alarmEnabled: alarmEnabled,
        alarmTime: alarmTime,
        createdAt: DateTime.now(),
      );
      _takingList.add(newTaking);
      _takingChecks[id] = List.generate(times.length, (_) => false);
      await saveToStorage();
      throw e;
    }
  }

  Future<void> updateTaking(int index, String name, List<String> times, bool alarmEnabled, String alarmTime) async {
    if (index >= 0 && index < _takingList.length) {
      final oldId = _takingList[index].id;
      
      // 비회원 모드 체크
      if (await TokenManager.instance.isGuestMode()) {
        print('비회원 모드 - 로컬에서만 저장');
        _takingList[index] = TakingModel(
          id: oldId,
          name: name,
          times: times,
          alarmEnabled: alarmEnabled,
          alarmTime: alarmTime,
          createdAt: _takingList[index].createdAt,
          updatedAt: DateTime.now(),
        );
        
        // 체크 상태 업데이트
        if (_takingChecks.containsKey(oldId)) {
          final currentChecks = _takingChecks[oldId]!;
          if (currentChecks.length != times.length) {
            _takingChecks[oldId] = List.generate(times.length, (i) => i < currentChecks.length ? currentChecks[i] : false);
          }
        } else {
          _takingChecks[oldId] = List.generate(times.length, (_) => false);
        }
        await saveToStorage();
        return;
      }
      
      try {
        final updatedTaking = await TakingApi.updateMedication(
          medicationId: int.parse(oldId),
          name: name,
          alarm: alarmEnabled,
        );
        
        // API 응답에 times가 없으면 로컬에서 설정한 times 사용
        final takingWithTimes = TakingModel(
          id: updatedTaking.id,
          name: updatedTaking.name,
          times: times,
          alarmEnabled: updatedTaking.alarmEnabled,
          alarmTime: alarmTime,
          createdAt: updatedTaking.createdAt,
          updatedAt: DateTime.now(),
        );
        
        _takingList[index] = takingWithTimes;
      } catch (e) {
        print('API 수정 실패, 로컬에서만 저장: $e');
        _takingList[index] = TakingModel(
          id: oldId,
          name: name,
          times: times,
          alarmEnabled: alarmEnabled,
          alarmTime: alarmTime,
          createdAt: _takingList[index].createdAt,
          updatedAt: DateTime.now(),
        );
        throw e;
      }
      
      // 체크 상태 업데이트
      if (_takingChecks.containsKey(oldId)) {
        final currentChecks = _takingChecks[oldId]!;
        if (currentChecks.length != times.length) {
          _takingChecks[oldId] = List.generate(times.length, (i) => i < currentChecks.length ? currentChecks[i] : false);
        }
      } else {
        _takingChecks[oldId] = List.generate(times.length, (_) => false);
      }
      await saveToStorage();
    }
  }

  Future<void> removeTaking(int index) async {
    if (index >= 0 && index < _takingList.length) {
      final id = _takingList[index].id;
      
      // 비회원 모드 체크
      if (await TokenManager.instance.isGuestMode()) {
        print('비회원 모드 - 로컬에서만 삭제');
        _takingList.removeAt(index);
        _takingChecks.remove(id);
        await saveToStorage();
        return;
      }
      
      try {
        await TakingApi.deleteMedication(int.parse(id));
      } catch (e) {
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
    // 비회원 모드 체크
    if (await TokenManager.instance.isGuestMode()) {
      print('비회원 모드 - API 동기화 건너뛰기');
      return;
    }
    
    try {
      final apiMedications = await TakingApi.getAllMedications();
      
      // 기존 로컬 데이터와 병합
      final Map<String, TakingModel> localMap = {
        for (var item in _takingList) item.id: item
      };
      
      for (final apiMedication in apiMedications) {
        final localMedication = localMap[apiMedication.id];
        if (localMedication != null) {
          // 로컬 데이터의 times 정보 유지
          final mergedMedication = TakingModel(
            id: apiMedication.id,
            name: apiMedication.name,
            times: localMedication.times, // 로컬 times 유지
            alarmEnabled: apiMedication.alarmEnabled,
            alarmTime: apiMedication.alarmTime.isEmpty ? localMedication.alarmTime : apiMedication.alarmTime,
            createdAt: apiMedication.createdAt,
            updatedAt: apiMedication.updatedAt ?? localMedication.updatedAt,
          );
          localMap[apiMedication.id] = mergedMedication;
        } else {
          // 새로운 API 데이터 추가
          final newMedication = TakingModel(
            id: apiMedication.id,
            name: apiMedication.name,
            times: ['08:00', '12:00', '18:00'], // 기본값
            alarmEnabled: apiMedication.alarmEnabled,
            alarmTime: apiMedication.alarmTime.isEmpty ? '08:00' : apiMedication.alarmTime,
            createdAt: apiMedication.createdAt,
            updatedAt: apiMedication.updatedAt,
          );
          localMap[apiMedication.id] = newMedication;
        }
      }
      
      _takingList = localMap.values.toList();
      
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

  /// 마지막 동기화 시간 확인
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
} 