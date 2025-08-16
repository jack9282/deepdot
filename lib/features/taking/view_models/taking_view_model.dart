import 'package:flutter/material.dart';
import '../../../data/repositories/taking_repository.dart';
import '../../../data/models/taking_model.dart';
import '../../../utils/alarm.dart';

class TakingViewModel with ChangeNotifier {
  List<TakingModel> _takingList = [];
  Map<String, int> _alarmIds = {}; // 약 ID와 알람 ID 매핑
  bool _isLoading = false;
  String? _errorMessage;

  List<TakingModel> get takingList => List.unmodifiable(_takingList);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _setLoading(true);
    _clearError();
    
    try {
      await TakingRepository().loadFromStorage();
      await _syncWithApi();
      _loadTakingList();
    } catch (e) {
      _setError('데이터 로드 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _syncWithApi() async {
    try {
      await TakingRepository().syncFromApi();
    } catch (e) {
      print('API 동기화 실패, 로컬 데이터 사용: $e');
      // API 실패 시에도 로컬 데이터는 계속 사용
    }
  }

  void _loadTakingList() {
    _takingList = TakingRepository().takingList;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  Future<void> addTaking(String name, List<String> times, bool alarmEnabled, String alarmTime) async {
    _setLoading(true);
    _clearError();
    
    try {
      await TakingRepository().addTaking(name, times, alarmEnabled, alarmTime);
      _loadTakingList();
      
      if (alarmEnabled) {
        final taking = _takingList.last;
        await _setupAlarms(taking, times);
      }
    } catch (e) {
      _setError('약물 추가 중 오류가 발생했습니다: $e');
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTaking(int index, String name, List<String> times, bool alarmEnabled, String alarmTime) async {
    if (index >= 0 && index < _takingList.length) {
      _setLoading(true);
      _clearError();
      
      try {
        final oldTaking = _takingList[index];
        
        // 기존 알람 제거
        await _removeAlarms(oldTaking);
        
        await TakingRepository().updateTaking(index, name, times, alarmEnabled, alarmTime);
        _loadTakingList();
        
        if (alarmEnabled) {
          final updatedTaking = _takingList[index];
          await _setupAlarms(updatedTaking, times);
        }
      } catch (e) {
        _setError('약물 수정 중 오류가 발생했습니다: $e');
        throw e;
      } finally {
        _setLoading(false);
      }
    }
  }

  Future<void> updateCheck(int itemIndex, int checkIndex, bool value) async {
    try {
      await TakingRepository().updateCheckByIndex(itemIndex, checkIndex, value);
      // 체크 상태 변경 시에는 전체 리스트를 다시 로드하지 않고 즉시 반영
      notifyListeners();
    } catch (e) {
      _setError('체크 상태 업데이트 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> removeTaking(int index) async {
    if (index >= 0 && index < _takingList.length) {
      _setLoading(true);
      _clearError();
      
      try {
        final taking = _takingList[index];
        
        // 알람 제거
        await _removeAlarms(taking);
        
        await TakingRepository().removeTaking(index);
        _loadTakingList();
      } catch (e) {
        _setError('약물 삭제 중 오류가 발생했습니다: $e');
        throw e;
      } finally {
        _setLoading(false);
      }
    }
  }

  Future<void> clearAll() async {
    _setLoading(true);
    _clearError();
    
    try {
      // 모든 알람 제거
      for (final alarmId in _alarmIds.values) {
        await AlarmUtility.cancelAlarm(alarmId);
      }
      _alarmIds.clear();
      
      TakingRepository().clearAllData();
      _loadTakingList();
    } catch (e) {
      _setError('데이터 초기화 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  List<bool> getChecksForItem(int index) {
    if (index >= 0 && index < _takingList.length) {
      final id = _takingList[index].id;
      return TakingRepository().getTakingChecks(id);
    }
    return [];
  }

  Future<void> _setupAlarms(TakingModel taking, List<String> times) async {
    final baseAlarmId = DateTime.now().millisecondsSinceEpoch;
    
    for (int i = 0; i < times.length; i++) {
      final timeParts = times[i].split(':');
      if (timeParts.length == 2) {
        final scheduledTime = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        final alarmId = baseAlarmId + i;
        _alarmIds['${taking.id}_$i'] = alarmId;

        await AlarmUtility.setAlarm(
          id: alarmId,
          scheduledTime: scheduledTime,
          title: '복용 알림',
          body: '${taking.name} 복용 시간입니다!',
        );
      }
    }
  }

  Future<void> _removeAlarms(TakingModel taking) async {
    if (taking.alarmEnabled) {
      for (int i = 0; i < taking.times.length; i++) {
        final alarmId = _alarmIds['${taking.id}_$i'];
        if (alarmId != null) {
          await AlarmUtility.cancelAlarm(alarmId);
          _alarmIds.remove('${taking.id}_$i');
        }
      }
    }
  }

  /// 강제 새로고침
  Future<void> refresh() async {
    await initialize();
  }

  /// 오류 메시지 초기화
  void clearError() {
    _clearError();
  }
}