import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/focus_session_model.dart';
import '../../api/focus_api.dart';
import '../../api/token_manager.dart';

class FocusSessionRepository {
  static const String _key = 'focus_sessions';
  
  List<FocusSessionModel> _sessions = [];
  
  List<FocusSessionModel> get sessions => List.unmodifiable(_sessions);

  // SharedPreferences에서 집중 세션 데이터 로드
  Future<void> loadSessionsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? sessionsJson = prefs.getString(_key);
      
      if (sessionsJson != null && sessionsJson.isNotEmpty) {
        final List<dynamic> sessionsList = json.decode(sessionsJson);
        _sessions = sessionsList
            .map((sessionJson) => FocusSessionModel.fromJson(sessionJson))
            .toList();
      } else {
        _sessions = [];
      }
    } catch (e) {
      print('집중 세션 데이터 로드 실패: $e');
      _sessions = [];
    }
  }

  // SharedPreferences에 집중 세션 데이터 저장
  Future<bool> saveSessionsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = json.encode(_sessions.map((session) => session.toJson()).toList());
      return await prefs.setString(_key, sessionsJson);
    } catch (e) {
      print('집중 세션 데이터 저장 실패: $e');
      return false;
    }
  }

  // 새로운 집중 세션 추가 (API 연동)
  Future<bool> addFocusSession(FocusSessionModel session) async {
    try {
      // 로컬에 먼저 저장
      _sessions.add(session);
      final localSaved = await saveSessionsToStorage();
      
      // 백그라운드에서 API 호출
      _syncSessionToAPI(session);
      
      return localSaved;
    } catch (e) {
      print('집중 세션 추가 실패: $e');
      return false;
    }
  }
  
  // API로 세션 동기화 (백그라운드) - 자정에 하루 집중시간 전송
  Future<void> _syncSessionToAPI(FocusSessionModel session) async {
    try {
      // 비회원인 경우 건너뛰기
      final isGuest = await TokenManager.instance.isGuestMode();
      if (isGuest) return;
      
      // 하루 집중시간은 자정에 한번만 전송하므로 여기서는 로컬 저장만
      // 실제 전송은 sendDailyFocusTimeToAPI() 메서드에서 처리
    } catch (e) {
      print('집중 세션 API 동기화 실패: $e');
    }
  }
  
  // 하루 집중시간 API로 전송 (자정에 호출)
  Future<void> sendDailyFocusTimeToAPI(DateTime date) async {
    try {
      final isGuest = await TokenManager.instance.isGuestMode();
      if (isGuest) return;
      
      // 해당 날짜의 총 집중시간 계산
      final totalMinutes = getTotalFocusTimeByDate(date);
      if (totalMinutes == 0) return;
      
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      // API로 전송
      await FocusAPI.sendDailyFocusTime(
        localDate: dateStr,
        totalMinutes: totalMinutes,
        zoneId: 'Asia/Seoul',
      );
      
      print('하루 집중시간 전송 성공: $dateStr - ${totalMinutes}분');
    } catch (e) {
      print('하루 집중시간 전송 실패: $e');
    }
  }
  
  // 특정 일정의 제목이 변경되었을 때 관련 세션들 업데이트
  Future<bool> updateSessionTaskTitle(String oldTitle, String newTitle) async {
    try {
      bool updated = false;
      final updatedSessions = <FocusSessionModel>[];
      
      for (final session in _sessions) {
        if (session.taskTitle == oldTitle) {
          final updatedSession = session.copyWith(taskTitle: newTitle);
          updatedSessions.add(updatedSession);
          updated = true;
        } else {
          updatedSessions.add(session);
        }
      }
      
      if (updated) {
        _sessions = updatedSessions;
        return await saveSessionsToStorage();
      }
      return true;
    } catch (e) {
      print('세션 제목 업데이트 실패: $e');
      return false;
    }
  }
  

  // 특정 날짜의 집중 세션들 가져오기
  List<FocusSessionModel> getSessionsByDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    
    return _sessions.where((session) {
      final sessionDate = DateTime(
        session.createdAt.year,
        session.createdAt.month,
        session.createdAt.day,
      );
      return sessionDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  // 특정 주간의 집중 세션들 가져오기
  List<FocusSessionModel> getSessionsByWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    return _sessions.where((session) {
      final sessionDate = DateTime(
        session.createdAt.year,
        session.createdAt.month,
        session.createdAt.day,
      );
      return !sessionDate.isBefore(weekStart) && !sessionDate.isAfter(weekEnd);
    }).toList();
  }

  // 특정 날짜의 총 집중 시간 계산 (분)
  int getTotalFocusTimeByDate(DateTime date) {
    final sessions = getSessionsByDate(date);
    return sessions.fold(0, (total, session) => total + session.focusMinutes);
  }

  // 특정 주간의 요일별 집중 시간 계산
  List<int> getWeeklyFocusTime(DateTime weekStart) {
    List<int> weeklyData = [0, 0, 0, 0, 0, 0, 0]; // 월~일
    
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      weeklyData[i] = getTotalFocusTimeByDate(date);
    }
    
    return weeklyData;
  }

  // 특정 주간의 총 집중 시간 계산
  int getTotalWeeklyFocusTime(DateTime weekStart) {
    final weeklyData = getWeeklyFocusTime(weekStart);
    return weeklyData.fold(0, (total, time) => total + time);
  }

  // 가장 긴 집중 세션의 태스크 제목 가져오기
  String getLongestFocusTask(DateTime date) {
    final sessions = getSessionsByDate(date);
    if (sessions.isEmpty) return '집중 기록 없음';
    
    sessions.sort((a, b) => b.focusMinutes.compareTo(a.focusMinutes));
    return sessions.first.taskTitle;
  }

  // 특정 날짜의 집중 달성률 계산 (실제시간/설정시간)
  double getFocusAchievementRateByDate(DateTime date) {
    final sessions = getSessionsByDate(date);
    if (sessions.isEmpty) return 0.0;
    
    final totalPlannedMinutes = sessions.fold(0, (total, session) => total + session.plannedMinutes);
    final totalFocusMinutes = sessions.fold(0, (total, session) => total + session.focusMinutes);
    
    if (totalPlannedMinutes == 0) return 0.0;
    return (totalFocusMinutes / totalPlannedMinutes).clamp(0.0, 1.0);
  }

  // 특정 주간의 요일별 집중 달성률 계산
  List<double> getWeeklyFocusAchievementRates(DateTime weekStart) {
    List<double> weeklyRates = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]; // 월~일
    
    print('Weekly achievement calculation - weekStart: $weekStart');
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final sessions = getSessionsByDate(date);
      final rate = getFocusAchievementRateByDate(date);
      weeklyRates[i] = rate;
      
      if (sessions.isNotEmpty) {
        print('Day $i (${date.month}/${date.day}, weekday=${date.weekday}): ${sessions.length} sessions, rate=$rate');
        for (final session in sessions) {
          print('  - Session: ${session.taskTitle} on ${session.createdAt}');
        }
      }
    }
    
    return weeklyRates;
  }

  // 특정 날짜의 설정된 총 집중시간 계산
  int getTotalPlannedTimeByDate(DateTime date) {
    final sessions = getSessionsByDate(date);
    return sessions.fold(0, (total, session) => total + session.plannedMinutes);
  }

  // 특정 주간의 설정된 총 집중시간 계산
  int getTotalWeeklyPlannedTime(DateTime weekStart) {
    int totalPlanned = 0;
    
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      totalPlanned += getTotalPlannedTimeByDate(date);
    }
    
    return totalPlanned;
  }

  // 특정 주간의 전체 집중 달성률 계산
  double getWeeklyOverallAchievementRate(DateTime weekStart) {
    final totalPlannedMinutes = getTotalWeeklyPlannedTime(weekStart);
    final totalFocusMinutes = getTotalWeeklyFocusTime(weekStart);
    
    if (totalPlannedMinutes == 0) return 0.0;
    return (totalFocusMinutes / totalPlannedMinutes).clamp(0.0, 1.0);
  }

  // 데이터 강제 새로고침
  Future<void> forceRefresh() async {
    await loadSessionsFromStorage();
  }

  // 특정 일정 제목의 집중 세션 삭제
  Future<bool> deleteSessionsByTaskTitle(String taskTitle) async {
    try {
      final initialCount = _sessions.length;
      _sessions.removeWhere((session) => session.taskTitle == taskTitle);
      final removedCount = initialCount - _sessions.length;
      
      print('삭제된 집중 세션: $removedCount개 (일정: $taskTitle)');
      
      if (removedCount > 0) {
        return await saveSessionsToStorage();
      }
      return true; // 삭제할 세션이 없어도 성공으로 처리
    } catch (e) {
      print('Error deleting sessions for task "$taskTitle": $e');
      return false;
    }
  }

  // 모든 집중 세션 삭제 (테스트용)
  Future<bool> clearAllSessions() async {
    try {
      _sessions.clear();
      return await saveSessionsToStorage();
    } catch (e) {
      print('집중 세션 데이터 삭제 실패: $e');
      return false;
    }
  }
}
