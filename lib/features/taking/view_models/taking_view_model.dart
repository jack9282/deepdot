import 'package:flutter/material.dart';
import '../../../data/repositories/taking_repository.dart';
import '../../../data/models/taking_model.dart';
import '../../../utils/alarm.dart';
import '../../../utils/alarm_id_generator.dart';
import '../../../api/token_manager.dart';

class TakingViewModel with ChangeNotifier {
  List<TakingModel> _takingList = [];
  Map<String, int> _alarmIds = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  List<TakingModel> get takingList => List.unmodifiable(_takingList);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _clearError();

    try {
      await _removeAllTakingAlarms();

      await TakingRepository().loadFromStorage();
      await _syncWithApi();
      _loadTakingList();
      _isInitialized = true;

      await _restoreAllTakingAlarms();
    } catch (e) {
      _setError('데이터 로드 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _syncWithApi() async {
    try {
      if (await TokenManager.instance.isGuestMode()) {
        return;
      }

      await TakingRepository().syncFromApi();
    } catch (e) {
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
      if (!await TokenManager.instance.isGuestMode()) {
        _setError('약물 추가 중 오류가 발생했습니다: $e');
        throw e;
      }

      if (e.toString().contains('서버 연결에 실패했습니다') ||
          e.toString().contains('로컬에 저장되었습니다')) {
        _loadTakingList();

        if (alarmEnabled) {
          final taking = _takingList.last;
          await _setupAlarms(taking, times);
        }

        _setError('서버 연결 문제로 로컬에만 저장되었습니다.');
      } else {
        _setError('약물 추가 중 오류가 발생했습니다: $e');
        throw e;
      }
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
        await _removeAlarms(oldTaking);

        await TakingRepository().updateTaking(index, name, times, alarmEnabled, alarmTime);
        _loadTakingList();

        if (alarmEnabled) {
          final updatedTaking = _takingList[index];
          await _setupAlarms(updatedTaking, times);
        }
      } catch (e) {
        if (!await TokenManager.instance.isGuestMode()) {
          _setError('약물 수정 중 오류가 발생했습니다: $e');
          throw e;
        }

        if (e.toString().contains('서버 연결에 실패했습니다') ||
            e.toString().contains('로컬에 저장되었습니다')) {
          _loadTakingList();

          if (alarmEnabled) {
            final updatedTaking = _takingList[index];
            await _setupAlarms(updatedTaking, times);
          }

          _setError('서버 연결 문제로 로컬에만 저장되었습니다.');
        } else {
          _setError('약물 수정 중 오류가 발생했습니다: $e');
          throw e;
        }
      } finally {
        _setLoading(false);
      }
    }
  }

  Future<void> updateCheck(int itemIndex, int checkIndex, bool value) async {
    try {
      await TakingRepository().updateCheckByIndex(itemIndex, checkIndex, value);
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
        await _removeAlarms(taking);

        await TakingRepository().removeTaking(index);
        _loadTakingList();
      } catch (e) {
        if (e.toString().contains('서버 내부 오류') ||
            e.toString().contains('서버 연결에 실패했습니다') ||
            e.toString().contains('로컬에서 삭제되었습니다')) {
          _loadTakingList();

          if (!await TokenManager.instance.isGuestMode()) {
            _setError('서버 연결 문제로 로컬에서만 삭제되었습니다.');
          }
        } else {
          if (!await TokenManager.instance.isGuestMode()) {
            _setError('약물 삭제 중 오류가 발생했습니다: $e');
            throw e;
          }

          _loadTakingList();
          _setError('약물 삭제 중 오류가 발생했습니다: $e');
        }
      } finally {
        _setLoading(false);
      }
    }
  }

  Future<void> clearAll() async {
    _setLoading(true);
    _clearError();

    try {
      final alarmIdsToRemove = Map<String, int>.from(_alarmIds);
      _alarmIds.clear();

      for (final alarmId in alarmIdsToRemove.values) {
        try {
          await AlarmUtility.cancelAlarm(alarmId);
        } catch (_) {}
      }

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
    try {
      final baseAlarmId = AlarmIdGenerator.generateTakingId();

      for (int i = 0; i < times.length; i++) {
        final alarmKey = '${taking.id}_$i';

        if (_alarmIds.containsKey(alarmKey)) {
          continue;
        }

        final timeParts = times[i].split(':');
        if (timeParts.length == 2) {
          final scheduledTime = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );

          final alarmId = AlarmIdGenerator.generateTakingIdWithIndex(baseAlarmId, i);
          _alarmIds[alarmKey] = alarmId;

          await AlarmUtility.setDailyAlarm(
            id: alarmId,
            scheduledTime: scheduledTime,
            title: '복용 알림',
            body: '${taking.name} 복용 시간입니다!',
          );
        }
      }
    } catch (e) {}
  }

  Future<void> _removeAlarms(TakingModel taking) async {
    try {
      if (taking.alarmEnabled) {
        for (int i = 0; i < taking.times.length; i++) {
          final alarmId = _alarmIds['${taking.id}_$i'];
          if (alarmId != null) {
            await AlarmUtility.cancelAlarm(alarmId);
            _alarmIds.remove('${taking.id}_$i');
          }
        }
      }
    } catch (e) {}
  }

  Future<void> _restoreAlarms() async {
    try {
      final alarmIdsToRemove = Map<String, int>.from(_alarmIds);
      _alarmIds.clear();

      for (final alarmId in alarmIdsToRemove.values) {
        try {
          await AlarmUtility.cancelAlarm(alarmId);
        } catch (_) {}
      }

      for (final taking in _takingList) {
        if (taking.alarmEnabled) {
          await _setupAlarms(taking, taking.times);
        }
      }
    } catch (e) {}
  }

  /// 모든 약물 복용 알람 제거
  Future<void> _removeAllTakingAlarms() async {
    try {
      await AlarmUtility.cancelAllAlarms();
      _alarmIds.clear();
    } catch (e) {}
  }

  /// 모든 약물 복용 알람 복원 (중복 방지)
  Future<void> _restoreAllTakingAlarms() async {
    try {
      _alarmIds.clear();

      for (final taking in _takingList) {
        if (taking.alarmEnabled) {
          bool hasExistingAlarm = false;
          for (int i = 0; i < taking.times.length; i++) {
            final alarmKey = '${taking.id}_$i';
            if (_alarmIds.containsKey(alarmKey)) {
              hasExistingAlarm = true;
              break;
            }
          }

          if (!hasExistingAlarm) {
            await _setupAlarms(taking, taking.times);
          }
        }
      }
    } catch (e) {}
  }

  /// 강제 새로고침
  Future<void> refresh() async {
    _setLoading(true);
    _clearError();

    try {
      await TakingRepository().loadFromStorage();
      _loadTakingList();
      await _restoreAllTakingAlarms();
    } catch (e) {
      _setError('데이터 새로고침 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 오류 메시지 초기화
  void clearError() {
    _clearError();
  }
}