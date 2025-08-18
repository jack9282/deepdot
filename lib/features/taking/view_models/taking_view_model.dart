import 'package:flutter/material.dart';
import '../../../data/repositories/taking_repository.dart';
import '../../../data/models/taking_model.dart';
import '../../../utils/alarm.dart';
import '../../../utils/alarm_id_generator.dart';
import '../../../api/token_manager.dart';

class TakingViewModel with ChangeNotifier {
  List<TakingModel> _takingList = [];
  Map<String, int> _alarmIds = {}; // 약 ID와 알람 ID 매핑
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
      // 앱 시작 시 모든 알람 초기화
      print('앱 시작 - 모든 약물 복용 알람 초기화');
      await _removeAllTakingAlarms();
      
      await TakingRepository().loadFromStorage();
      await _syncWithApi();
      _loadTakingList();
      _isInitialized = true;
      
      // 약물 복용 알람 복원 (중복 방지)
      await _restoreAllTakingAlarms();
      print('약물 복용 알람 복원 완료');
    } catch (e) {
      _setError('데이터 로드 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _syncWithApi() async {
    try {
      // 비회원 모드일 때는 API 동기화를 하지 않음
      if (await TokenManager.instance.isGuestMode()) {
        print('비회원 모드 - API 동기화 건너뛰기');
        return;
      }
      
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
      // 비회원 모드가 아닌 경우 서버 오류 시 실패 처리
      if (!await TokenManager.instance.isGuestMode()) {
        _setError('약물 추가 중 오류가 발생했습니다: $e');
        throw e;
      }
      
      // 비회원 모드인 경우에만 로컬 저장 허용
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
        
        // 기존 알람 제거
        await _removeAlarms(oldTaking);
        
        await TakingRepository().updateTaking(index, name, times, alarmEnabled, alarmTime);
        _loadTakingList();
        
        if (alarmEnabled) {
          final updatedTaking = _takingList[index];
          await _setupAlarms(updatedTaking, times);
        }
      } catch (e) {
        // 비회원 모드가 아닌 경우 서버 오류 시 실패 처리
        if (!await TokenManager.instance.isGuestMode()) {
          _setError('약물 수정 중 오류가 발생했습니다: $e');
          throw e;
        }
        
        // 비회원 모드인 경우에만 로컬 저장 허용
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
        // 서버 오류(500) 또는 연결 실패인 경우 로컬에서 삭제
        if (e.toString().contains('서버 내부 오류') || 
            e.toString().contains('서버 연결에 실패했습니다') || 
            e.toString().contains('로컬에서 삭제되었습니다')) {
          _loadTakingList();
          
          // 비회원 모드가 아닌 경우에만 정보성 메시지 표시
          if (!await TokenManager.instance.isGuestMode()) {
            _setError('서버 연결 문제로 로컬에서만 삭제되었습니다.');
          }
        } else {
          // 다른 오류(인증, 권한 등)는 실패 처리
          if (!await TokenManager.instance.isGuestMode()) {
            _setError('약물 삭제 중 오류가 발생했습니다: $e');
            throw e;
          }
          
          // 비회원 모드인 경우 로컬에서 삭제
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
      // 모든 알람 제거
      final alarmIdsToRemove = Map<String, int>.from(_alarmIds);
      _alarmIds.clear();
      
      for (final alarmId in alarmIdsToRemove.values) {
        try {
          await AlarmUtility.cancelAlarm(alarmId);
        } catch (e) {
          print('알람 제거 중 오류 발생: $e');
        }
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
      // 안전한 알람 ID 생성 - 약물 복용 전용 ID 사용
      final baseAlarmId = AlarmIdGenerator.generateTakingId();
      
      for (int i = 0; i < times.length; i++) {
        final alarmKey = '${taking.id}_$i';
        
        // 이미 알람이 설정되어 있는지 확인
        if (_alarmIds.containsKey(alarmKey)) {
          print('이미 설정된 알람 발견: $alarmKey - 건너뛰기');
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

          // 더 안전한 ID 생성 - 약물 복용 전용 범위 사용
          final alarmId = AlarmIdGenerator.generateTakingIdWithIndex(baseAlarmId, i);
          _alarmIds[alarmKey] = alarmId;

          await AlarmUtility.setDailyAlarm(
            id: alarmId,
            scheduledTime: scheduledTime,
            title: '복용 알림',
            body: '${taking.name} 복용 시간입니다!',
          );
          
          print('알람 설정 완료: $alarmKey (ID: $alarmId)');
        }
      }
    } catch (e) {
      print('알람 설정 중 오류 발생: $e');
    }
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
    } catch (e) {
      print('알람 제거 중 오류 발생: $e');
    }
  }

  Future<void> _restoreAlarms() async {
    try {
      // 기존 알람 ID들을 복사하여 안전하게 제거
      final alarmIdsToRemove = Map<String, int>.from(_alarmIds);
      _alarmIds.clear();
      
      for (final alarmId in alarmIdsToRemove.values) {
        try {
          await AlarmUtility.cancelAlarm(alarmId);
        } catch (e) {
          print('기존 알람 제거 중 오류: $e');
        }
      }
      
      // 새로운 알람 설정
      for (final taking in _takingList) {
        if (taking.alarmEnabled) {
          await _setupAlarms(taking, taking.times);
        }
      }
    } catch (e) {
      print('알람 복원 중 오류 발생: $e');
    }
  }

  /// 모든 약물 복용 알람 제거
  Future<void> _removeAllTakingAlarms() async {
    try {
      print('모든 약물 복용 알람 제거 시작');
      await AlarmUtility.cancelAllAlarms();
      _alarmIds.clear();
      print('모든 약물 복용 알람 제거 완료');
    } catch (e) {
      print('모든 약물 복용 알람 제거 실패: $e');
    }
  }

  /// 모든 약물 복용 알람 복원 (중복 방지)
  Future<void> _restoreAllTakingAlarms() async {
    try {
      print('약물 복용 알람 복원 시작');
      
      // 기존 알람 ID들을 모두 제거
      _alarmIds.clear();
      
      for (final taking in _takingList) {
        if (taking.alarmEnabled) {
          // 중복 체크: 이미 알람이 설정되어 있는지 확인
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
      print('약물 복용 알람 복원 완료');
    } catch (e) {
      print('약물 복용 알람 복원 실패: $e');
    }
  }

  /// 강제 새로고침
  Future<void> refresh() async {
    _setLoading(true);
    _clearError();
    
    try {
      // 로컬 데이터만 다시 로드 (API 동기화는 건너뛰기)
      await TakingRepository().loadFromStorage();
      _loadTakingList();
      
      // 알람 복원
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