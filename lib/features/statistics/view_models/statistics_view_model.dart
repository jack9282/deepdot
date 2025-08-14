import 'package:flutter/material.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/repositories/focus_session_repository.dart';

class StatisticsViewModel with ChangeNotifier {
  final TaskRepository _taskRepository = TaskRepository();
  final FocusSessionRepository _focusRepository = FocusSessionRepository();

  // 상태 변수들
  DateTime _currentWeekStart = DateTime.now();
  int _weeklyFocusMinutes = 0;
  int _previousWeekFocusMinutes = 0; // 이전 주 집중시간
  int _dailyFocusMinutes = 0;
  int _dailyTargetMinutes = 300; // 하루 목표 시간 (5시간)
  int _completedRoutines = 3; // 완료된 루틴 수
  int _totalRoutines = 5; // 전체 루틴 수
  String _longestRoutine = '디자인 작업'; // 최장 집중 루틴
  bool _isLoading = false;
  String? _errorMessage;

  // 주간 데이터 (일별 집중 시간)
  List<int> _weeklyData = [0, 0, 0, 0, 0, 0, 0]; // 월~일
  List<double> _weeklyAchievementRates = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]; // 주간 달성률
  
  // 🆕 하루 집중시간 관련 데이터
  double _dailyAchievementRate = 0.0; // 하루 집중 달성률
  int _completedTasksCount = 0; // 완료한 일정 개수

  // Getters
  int get weeklyFocusMinutes => _weeklyFocusMinutes;
  int get previousWeekFocusMinutes => _previousWeekFocusMinutes;
  int get dailyFocusMinutes => _dailyFocusMinutes;
  int get dailyTargetMinutes => _dailyTargetMinutes;
  int get completedRoutines => _completedRoutines;
  int get totalRoutines => _totalRoutines;
  String get longestRoutine => _longestRoutine;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<int> get weeklyData => _weeklyData;
  List<double> get weeklyAchievementRates => _weeklyAchievementRates;
  
  // 🆕 하루 집중시간 관련 getters
  double get dailyAchievementRate => _dailyAchievementRate;
  int get completedTasksCount => _completedTasksCount;

  StatisticsViewModel() {
    _currentWeekStart = _getWeekStart(DateTime.now());
  }

  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 에러 메시지 설정
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // 주의 시작일 계산 (월요일)
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    final startDate = date.subtract(Duration(days: weekday - 1));
    // 시간 정보를 제거하고 날짜만 반환
    return DateTime(startDate.year, startDate.month, startDate.day);
  }

  // 현재 주 텍스트 반환
  String getCurrentWeekText() {
    final now = DateTime.now();
    final thisWeekStart = _getWeekStart(now);
    
    // _getWeekStart는 이미 시간 정보가 제거된 날짜를 반환
    if (_currentWeekStart.isAtSameMomentAs(thisWeekStart)) {
      return '이번주';
    } else if (_currentWeekStart.isBefore(thisWeekStart)) {
      final weeksDiff = thisWeekStart.difference(_currentWeekStart).inDays ~/ 7;
      if (weeksDiff == 1) {
        return '저번주';
      } else {
        return '$weeksDiff주 전';
      }
    } else {
      final weeksDiff = _currentWeekStart.difference(thisWeekStart).inDays ~/ 7;
      if (weeksDiff == 1) {
        return '다음주';
      } else {
        return '$weeksDiff주 후';
      }
    }
  }

  // 주간 날짜 범위 텍스트
  String getWeekDateRange() {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final startMonth = _currentWeekStart.month;
    final startDay = _currentWeekStart.day;
    final endMonth = weekEnd.month;
    final endDay = weekEnd.day;
    
    if (startMonth == endMonth) {
      return '${startMonth}월 ${startDay}일 ~ ${endMonth}월 ${endDay}일';
    } else {
      return '${startMonth}월 ${startDay}일 ~ ${endMonth}월 ${endDay}일';
    }
  }

  // 이전 주로 이동
  void goToPreviousWeek() {
    _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    loadCurrentWeekData();
  }

  // 다음 주로 이동
  void goToNextWeek() {
    _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    loadCurrentWeekData();
  }

  // 현재 주 데이터 로드
  Future<void> loadCurrentWeekData() async {
    _setLoading(true);
    _setError(null);

    try {
      await _taskRepository.loadTasksFromStorage();
      await _focusRepository.loadSessionsFromStorage();
      _calculateFocusTime();
    } catch (e) {
      _setError('통계 데이터를 불러오는데 실패했습니다: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // 집중 시간 계산
  void _calculateFocusTime() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 현재 주 데이터 계산
    final weeklyFocusMinutes = _focusRepository.getTotalWeeklyFocusTime(_currentWeekStart);
    final dailyFocusMinutes = _focusRepository.getTotalFocusTimeByDate(today);
    final weeklyData = _focusRepository.getWeeklyFocusTime(_currentWeekStart);
    final weeklyAchievementRates = _focusRepository.getWeeklyFocusAchievementRates(_currentWeekStart);
    
    // 데이터 계산 완료
    
    // 이전 주 데이터 계산
    final previousWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    final previousWeekFocusMinutes = _focusRepository.getTotalWeeklyFocusTime(previousWeekStart);
    
    // 최장 집중 루틴 업데이트
    final longestTask = _focusRepository.getLongestFocusTask(today);
    
    // 🆕 하루 집중시간 관련 데이터 계산
    final dailyAchievementRate = _focusRepository.getFocusAchievementRateByDate(today);
    final dailySessions = _focusRepository.getSessionsByDate(today);
    final completedTasksCount = dailySessions.length; // 완료한 일정 개수
    final totalPlannedMinutes = _focusRepository.getTotalPlannedTimeByDate(today);

    _weeklyFocusMinutes = weeklyFocusMinutes;
    _previousWeekFocusMinutes = previousWeekFocusMinutes;
    _dailyFocusMinutes = dailyFocusMinutes;
    _weeklyData = weeklyData;
    _weeklyAchievementRates = weeklyAchievementRates;
    _longestRoutine = longestTask;
    
    // 🆕 하루 집중시간 관련 데이터 업데이트
    _dailyAchievementRate = dailyAchievementRate;
    _completedTasksCount = completedTasksCount;
    
    notifyListeners();
  }

  // 주간 집중 시간 포맷팅
  String getFormattedWeeklyTime() {
    return _formatMinutes(_weeklyFocusMinutes);
  }

  // 일간 집중 시간 포맷팅
  String getFormattedDailyTime() {
    return _formatMinutes(_dailyFocusMinutes);
  }

  // 일간 목표 시간 포맷팅
  String getFormattedDailyTargetTime() {
    return _formatMinutes(_dailyTargetMinutes);
  }

  // 분을 시간:분 형태로 포맷팅
  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}분';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}시간';
      } else {
        return '${hours}시간 ${remainingMinutes}분';
      }
    }
  }

  // 일간 진행률 계산 (0.0 ~ 1.0)
  double getDailyProgress() {
    if (_dailyTargetMinutes == 0) return 0.0;
    return (_dailyFocusMinutes / _dailyTargetMinutes).clamp(0.0, 1.0);
  }

  // 루틴 달성률 계산 (0.0 ~ 1.0)
  double getRoutineAchievementRate() {
    if (_totalRoutines == 0) return 0.0;
    return (_completedRoutines / _totalRoutines).clamp(0.0, 1.0);
  }

  // 주간 최대 집중 시간 (차트 스케일링용) - 최대 8시간
  int getWeeklyMaxFocusTime() {
    const maxHours = 1; // 최대 8시간 (테스트로 인해 1시간으로 설정)
    const maxMinutes = maxHours * 60; // 480분
    
    if (_weeklyData.isEmpty) return maxMinutes;
    final max = _weeklyData.reduce((a, b) => a > b ? a : b);
    
    // 실제 최대값과 설정된 최대값 중 더 큰 값을 사용하되, 차트 스케일링을 위해 최소 480분 유지
    return max > maxMinutes ? max : maxMinutes;
  }

  // 주간 비교 결과 확인
  bool isCurrentWeekBetterThanPrevious() {
    return _weeklyFocusMinutes > _previousWeekFocusMinutes;
  }

  // 주간 비교 메시지 가져오기
  String? getWeeklyComparisonMessage() {
    if (isCurrentWeekBetterThanPrevious()) {
      return '전주보다 집중했어요!';
    }
    return null; // 메시지를 숨김
  }

  // 주간 비교 이모지 가져오기
  String? getWeeklyComparisonEmoji() {
    if (isCurrentWeekBetterThanPrevious()) {
      return '🔥';
    }
    return null;
  }

  // 주간 비교 메시지 표시 여부
  bool shouldShowWeeklyComparison() {
    return isCurrentWeekBetterThanPrevious() && _previousWeekFocusMinutes > 0;
  }

  // 🆕 하루 집중시간 관련 메서드들
  
  // 하루 집중 달성률을 퍼센트로 포맷팅
  String getFormattedDailyAchievementRate() {
    return '${(_dailyAchievementRate * 100).round()}%';
  }
  
  // 완료한 일정 개수 텍스트
  String getCompletedTasksText() {
    return '$_completedTasksCount개 달성';
  }
  
  // 집중 기록이 있는지 확인
  bool hasDailyFocusRecord() {
    return _dailyFocusMinutes > 0;
  }

  // 데이터 새로고침
  Future<void> refresh() async {
    await loadCurrentWeekData();
  }
} 