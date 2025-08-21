import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/taking_model.dart';
import '../../api/taking_api.dart';
import '../../api/token_manager.dart';
import '../../utils/alarm.dart';

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
            timeIds: [1, 2, 3], // 기본 timeIds
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
      _takingChecks = jsonMap.map(
        (key, value) => MapEntry(key, List<bool>.from(value)),
      );
    }

    // 체크 상태가 없는 항목들에 대해 초기화
    for (final taking in _takingList) {
      if (!_takingChecks.containsKey(taking.id)) {
        _takingChecks[taking.id] = List.generate(
          taking.times.length,
          (_) => false,
        );
      }
    }
  }

  Future<void> saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _takingListKey,
      jsonEncode(_takingList.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(_takingChecksKey, jsonEncode(_takingChecks));
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> addTaking(
    String name,
    List<String> times,
    bool alarmEnabled,
    String alarmTime,
  ) async {
    // 비회원 모드 체크
    if (await TokenManager.instance.isGuestMode()) {
      print('비회원 모드 - 로컬에서만 저장');
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final newTaking = TakingModel(
        id: id,
        name: name,
        times: times,
        timeIds: List.generate(times.length, (index) => index + 1),
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

      // 복용 시간들을 개별적으로 추가
      final List<int> newTimeIds = [];
      for (final time in times) {
        try {
          final timeId = await TakingApi.addMedicationTime(
            int.parse(newTaking.id),
            time,
          );
          if (timeId != null) {
            newTimeIds.add(timeId);
          }
        } catch (timeError) {
          print('복용 시간 추가 실패 (시간: $time): $timeError');
          // 개별 시간 추가 실패는 무시하고 계속 진행
        }
      }

      // API 응답의 times가 있으면 사용, 없으면 로컬에서 설정한 times 사용
      final finalTimes = newTaking.times.isNotEmpty ? newTaking.times : times;
      final finalTimeIds = newTimeIds.isNotEmpty
          ? newTimeIds
          : (newTaking.timeIds.isNotEmpty
                ? newTaking.timeIds
                : List.generate(finalTimes.length, (index) => index + 1));
      final takingWithTimes = TakingModel(
        id: newTaking.id,
        name: newTaking.name,
        times: finalTimes,
        timeIds: finalTimeIds,
        alarmEnabled: newTaking.alarmEnabled,
        alarmTime: alarmTime, // 로컬에서 설정한 알람 시간 사용
        createdAt: newTaking.createdAt,
        updatedAt: newTaking.updatedAt,
      );

      _takingList.add(takingWithTimes);
      _takingChecks[takingWithTimes.id] = List.generate(
        takingWithTimes.times.length,
        (_) => false,
      );
      await saveToStorage();
    } catch (e) {
      print('API 추가 실패, 로컬에서만 저장: $e');

      // 서버 오류인 경우 로컬에 저장하고 사용자에게 알림
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final newTaking = TakingModel(
        id: id,
        name: name,
        times: times,
        timeIds: List.generate(times.length, (index) => index + 1),
        alarmEnabled: alarmEnabled,
        alarmTime: alarmTime,
        createdAt: DateTime.now(),
      );
      _takingList.add(newTaking);
      _takingChecks[id] = List.generate(times.length, (_) => false);
      await saveToStorage();

      // 서버 오류 메시지 반환
      if (e.toString().contains('서버 내부 오류')) {
        throw Exception('서버 연결에 실패했습니다. 로컬에 저장되었으며, 나중에 동기화됩니다.');
      } else if (e.toString().contains('이미 존재하는 약물명')) {
        throw Exception('이미 존재하는 약물명입니다. 다른 이름을 사용해주세요.');
      } else if (e.toString().contains('인증이 필요합니다')) {
        throw Exception('로그인이 필요합니다.');
      } else {
        throw Exception('약물 추가에 실패했습니다. 로컬에 저장되었습니다.');
      }
    }
  }

  Future<void> updateTaking(
    int index,
    String name,
    List<String> times,
    bool alarmEnabled,
    String alarmTime,
  ) async {
    if (index >= 0 && index < _takingList.length) {
      final oldId = _takingList[index].id;

      // 비회원 모드 체크
      if (await TokenManager.instance.isGuestMode()) {
        print('비회원 모드 - 로컬에서만 저장');
        _takingList[index] = TakingModel(
          id: oldId,
          name: name,
          times: times,
          timeIds: List.generate(times.length, (index) => index + 1),
          alarmEnabled: alarmEnabled,
          alarmTime: alarmTime,
          createdAt: _takingList[index].createdAt,
          updatedAt: DateTime.now(),
        );

        // 체크 상태 업데이트
        if (_takingChecks.containsKey(oldId)) {
          final currentChecks = _takingChecks[oldId]!;
          if (currentChecks.length != times.length) {
            _takingChecks[oldId] = List.generate(
              times.length,
              (i) => i < currentChecks.length ? currentChecks[i] : false,
            );
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
        
        // 복용 시간이 변경된 경우 기존 시간들을 전체 삭제하고 새로운 시간들을 추가
        // 1) 기존 시간 전부 삭제
        try {
          await TakingApi.deleteAllMedicationTimes(int.parse(updatedTaking.id));
          print('기존 시간 전체 삭제 성공');
        } catch (deleteError) {
          print('기존 시간 전체 삭제 실패: $deleteError');
          // 삭제 실패 시 예외를 다시 던져서 로컬 저장으로 처리
          throw Exception('기존 시간 삭제에 실패했습니다: $deleteError');
        }
        
        // 2) 새 시간들 추가
        final List<int> newTimeIds = [];
        for (final newTime in times) {
          try {
            final timeId = await TakingApi.addMedicationTime(int.parse(updatedTaking.id), newTime);
            if (timeId != null) {
              newTimeIds.add(timeId);
            }
          } catch (timeError) {
            print('복용 시간 추가 실패 (시간: $newTime): $timeError');
            // 개별 시간 추가 실패는 무시하고 계속 진행
          }
        }

        // 3) 서버에서 최신 데이터 재조회 (timeIds 동기화)
        TakingModel? refreshed;
        try {
          refreshed = await TakingApi.getMedication(
            int.parse(updatedTaking.id),
          );
        } catch (_) {}

        // API 응답의 times가 있으면 사용, 없으면 로컬에서 설정한 times 사용
        final finalTimes = (refreshed != null && refreshed.times.isNotEmpty)
            ? refreshed.times
            : (updatedTaking.times.isNotEmpty ? updatedTaking.times : times);
        final finalTimeIds = newTimeIds.isNotEmpty
            ? newTimeIds
            : ((refreshed != null && refreshed.timeIds.isNotEmpty)
                  ? refreshed.timeIds
                  : (updatedTaking.timeIds.isNotEmpty
                        ? updatedTaking.timeIds
                        : List.generate(
                            finalTimes.length,
                            (index) => index + 1,
                          )));
        final takingWithTimes = TakingModel(
          id: updatedTaking.id,
          name: updatedTaking.name,
          times: finalTimes,
          timeIds: finalTimeIds,
          alarmEnabled: updatedTaking.alarmEnabled,
          alarmTime: alarmTime, // 로컬에서 설정한 알람 시간 사용
          createdAt: updatedTaking.createdAt,
          updatedAt: DateTime.now(),
        );

        _takingList[index] = takingWithTimes;
      } catch (e) {
        print('API 수정 실패, 로컬에서만 저장: $e');

        // 서버 오류인 경우 로컬에 저장하고 사용자에게 알림
        _takingList[index] = TakingModel(
          id: oldId,
          name: name,
          times: times,
          timeIds: List.generate(times.length, (index) => index + 1),
          alarmEnabled: alarmEnabled,
          alarmTime: alarmTime,
          createdAt: _takingList[index].createdAt,
          updatedAt: DateTime.now(),
        );

        // 서버 오류 메시지 반환
        if (e.toString().contains('서버 내부 오류')) {
          throw Exception('서버 연결에 실패했습니다. 로컬에 저장되었으며, 나중에 동기화됩니다.');
        } else if (e.toString().contains('이미 존재하는 약물명')) {
          throw Exception('이미 존재하는 약물명입니다. 다른 이름을 사용해주세요.');
        } else if (e.toString().contains('약물을 찾을 수 없습니다')) {
          throw Exception('수정할 약물을 찾을 수 없습니다.');
        } else if (e.toString().contains('인증이 필요합니다')) {
          throw Exception('로그인이 필요합니다.');
        } else {
          throw Exception('약물 수정에 실패했습니다. 로컬에 저장되었습니다.');
        }
      }

      // 체크 상태 업데이트
      if (_takingChecks.containsKey(oldId)) {
        final currentChecks = _takingChecks[oldId]!;
        if (currentChecks.length != times.length) {
          _takingChecks[oldId] = List.generate(
            times.length,
            (i) => i < currentChecks.length ? currentChecks[i] : false,
          );
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
        _takingList.removeAt(index);
        _takingChecks.remove(id);
        await saveToStorage();
      } catch (e) {
        print('API 삭제 실패, 로컬에서만 삭제: $e');

        // 서버 오류인 경우에도 로컬에서 삭제
        _takingList.removeAt(index);
        _takingChecks.remove(id);
        await saveToStorage();

        // 서버 오류 메시지 반환
        if (e.toString().contains('서버 내부 오류')) {
          throw Exception('서버 연결에 실패했습니다. 로컬에서 삭제되었으며, 나중에 동기화됩니다.');
        } else if (e.toString().contains('약물을 찾을 수 없습니다')) {
          throw Exception('이미 삭제된 약물입니다.');
        } else if (e.toString().contains('인증이 필요합니다')) {
          throw Exception('로그인이 필요합니다.');
        } else {
          throw Exception('약물 삭제에 실패했습니다. 로컬에서 삭제되었습니다.');
        }
      }
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

  Future<void> updateCheckByIndex(
    int takingIndex,
    int timeIndex,
    bool isChecked,
  ) async {
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
      print('API에서 가져온 약물 개수: ${apiMedications.length}');

      // API 데이터를 우선으로 하는 새로운 리스트 생성
      final List<TakingModel> newTakingList = [];
      final Map<String, TakingModel> processedIds = {};
      final Map<String, TakingModel> processedNames = {};

      // 1단계: API 데이터 처리
      for (final apiMedication in apiMedications) {
        try {
          // 기존 로컬 데이터에서 같은 ID를 가진 것 찾기
          final existingLocal = _takingList
              .where((item) => item.id == apiMedication.id)
              .firstOrNull;

          if (existingLocal != null) {
            // 기존 로컬 데이터가 있으면 times와 alarmTime 정보 유지
            // API에서 times가 비어있지 않으면 API 데이터 사용, 아니면 로컬 데이터 사용
            final finalTimes = apiMedication.times.isNotEmpty
                ? apiMedication.times
                : existingLocal.times;
            final mergedMedication = TakingModel(
              id: apiMedication.id,
              name: apiMedication.name,
              times: finalTimes,
              timeIds: apiMedication.timeIds.isNotEmpty
                  ? apiMedication.timeIds
                  : existingLocal.timeIds,
              alarmEnabled: apiMedication.alarmEnabled,
              alarmTime: existingLocal.alarmTime, // 로컬에서 설정한 알람 시간 유지
              createdAt: apiMedication.createdAt,
              updatedAt: apiMedication.updatedAt ?? existingLocal.updatedAt,
            );
            newTakingList.add(mergedMedication);
            processedIds[apiMedication.id] = mergedMedication;
            processedNames[apiMedication.name.toLowerCase()] = mergedMedication;
            print(
              '기존 약물 업데이트: ${apiMedication.name} (ID: ${apiMedication.id})',
            );
          } else {
            // 새로운 API 데이터 추가
            final finalTimes = apiMedication.times.isNotEmpty
                ? apiMedication.times
                : ['08:00', '12:00', '18:00'];
            final newMedication = TakingModel(
              id: apiMedication.id,
              name: apiMedication.name,
              times: finalTimes,
              timeIds: apiMedication.timeIds.isNotEmpty
                  ? apiMedication.timeIds
                  : List.generate(finalTimes.length, (index) => index + 1),
              alarmEnabled: apiMedication.alarmEnabled,
              alarmTime: '08:00', // 기본 알람 시간
              createdAt: apiMedication.createdAt,
              updatedAt: apiMedication.updatedAt,
            );
            newTakingList.add(newMedication);
            processedIds[apiMedication.id] = newMedication;
            processedNames[apiMedication.name.toLowerCase()] = newMedication;
            print('새로운 약물 추가: ${apiMedication.name} (ID: ${apiMedication.id})');
          }
        } catch (itemError) {
          print('개별 약물 데이터 처리 실패 (ID: ${apiMedication.id}): $itemError');
          continue;
        }
      }

      // 2단계: 로컬에만 있는 데이터 추가 (API에 없는 것만)
      for (final localMedication in _takingList) {
        // 이미 처리된 ID나 이름이 아닌 경우만 추가
        if (!processedIds.containsKey(localMedication.id) &&
            !processedNames.containsKey(localMedication.name.toLowerCase())) {
          newTakingList.add(localMedication);
          print(
            '로컬 전용 약물 유지: ${localMedication.name} (ID: ${localMedication.id})',
          );
        }
      }

      print('최종 약물 개수: ${newTakingList.length}');
      _takingList = newTakingList;

      // 체크 상태 초기화
      for (final medication in _takingList) {
        if (!_takingChecks.containsKey(medication.id)) {
          _takingChecks[medication.id] = List.generate(
            medication.times.length,
            (_) => false,
          );
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
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// 모든 복약 알림을 재설정합니다
  Future<void> rescheduleAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('medication_notification') ?? true;

      if (!isEnabled) {
        // 알림이 비활성화되어 있으면 아무것도 하지 않음
        return;
      }

      // 알람이 활성화된 모든 복약 조회
      for (final taking in _takingList) {
        if (taking.alarmEnabled) {
          // 각 복용 시간마다 알람 설정
          for (int i = 0; i < taking.times.length; i++) {
            final timeStr = taking.times[i];
            final timeParts = timeStr.split(':');
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);

            final now = DateTime.now();
            var alarmTime = DateTime(
              now.year,
              now.month,
              now.day,
              hour,
              minute,
            );

            // 이미 지난 시간이면 다음 날로 설정
            if (alarmTime.isBefore(now)) {
              alarmTime = alarmTime.add(const Duration(days: 1));
            }

            // 알람 ID는 20000번대 사용 (복약용)
            // hashCode를 0-9999 범위로 제한하여 20000-29999 사이가 되도록 함
            final alarmId = 20000 + (taking.id.hashCode % 9990).abs() + i;

            await AlarmUtility.setDailyAlarm(
              id: alarmId,
              scheduledTime: alarmTime,
              title: '복약 알림',
              body: AlarmUtility.generateTakingMessage('사용자', alarmTime),
            );
          }
        }
      }
    } catch (e) {
      print('복약 알림 재설정 중 오류: $e');
    }
  }
}
