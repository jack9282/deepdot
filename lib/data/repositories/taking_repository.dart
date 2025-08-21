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

        if (taking.times.isEmpty) {
          return TakingModel(
            id: taking.id,
            name: taking.name,
            times: ['08:00', '12:00', '18:00'],
            timeIds: [1, 2, 3],
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
    if (await TokenManager.instance.isGuestMode()) {
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
          continue;
        }
      }

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
        alarmTime: alarmTime,
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

      if (await TokenManager.instance.isGuestMode()) {
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
        
        try {
          await TakingApi.deleteAllMedicationTimes(int.parse(updatedTaking.id));
        } catch (deleteError) {
          throw Exception('기존 시간 삭제에 실패했습니다: $deleteError');
        }
        
        final List<int> newTimeIds = [];
        for (final newTime in times) {
          try {
            final timeId = await TakingApi.addMedicationTime(int.parse(updatedTaking.id), newTime);
            if (timeId != null) {
              newTimeIds.add(timeId);
            }
          } catch (timeError) {
            continue;
          }
        }

        TakingModel? refreshed;
        try {
          refreshed = await TakingApi.getMedication(
            int.parse(updatedTaking.id),
          );
        } catch (_) {}

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
          alarmTime: alarmTime,
          createdAt: updatedTaking.createdAt,
          updatedAt: DateTime.now(),
        );

        _takingList[index] = takingWithTimes;
      } catch (e) {
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

      if (await TokenManager.instance.isGuestMode()) {
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
        _takingList.removeAt(index);
        _takingChecks.remove(id);
        await saveToStorage();

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

  Future<void> syncFromApi() async {
    if (await TokenManager.instance.isGuestMode()) {
      return;
    }

    try {
      final apiMedications = await TakingApi.getAllMedications();

      final List<TakingModel> newTakingList = [];
      final Map<String, TakingModel> processedIds = {};
      final Map<String, TakingModel> processedNames = {};

      for (final apiMedication in apiMedications) {
        try {
          final existingLocal = _takingList
              .where((item) => item.id == apiMedication.id)
              .firstOrNull;

          if (existingLocal != null) {
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
              alarmTime: existingLocal.alarmTime,
              createdAt: apiMedication.createdAt,
              updatedAt: apiMedication.updatedAt ?? existingLocal.updatedAt,
            );
            newTakingList.add(mergedMedication);
            processedIds[apiMedication.id] = mergedMedication;
            processedNames[apiMedication.name.toLowerCase()] = mergedMedication;
          } else {
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
              alarmTime: '08:00',
              createdAt: apiMedication.createdAt,
              updatedAt: apiMedication.updatedAt,
            );
            newTakingList.add(newMedication);
            processedIds[apiMedication.id] = newMedication;
            processedNames[apiMedication.name.toLowerCase()] = newMedication;
          }
        } catch (itemError) {
          continue;
        }
      }

      for (final localMedication in _takingList) {
        if (!processedIds.containsKey(localMedication.id) &&
            !processedNames.containsKey(localMedication.name.toLowerCase())) {
          newTakingList.add(localMedication);
        }
      }

      _takingList = newTakingList;

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
      // API 실패 시 로컬 데이터 유지
    }
  }

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  Future<void> rescheduleAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('medication_notification') ?? true;

      if (!isEnabled) {
        return;
      }

      for (final taking in _takingList) {
        if (taking.alarmEnabled) {
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

            if (alarmTime.isBefore(now)) {
              alarmTime = alarmTime.add(const Duration(days: 1));
            }

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
