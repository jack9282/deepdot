import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/models/task_model.dart';

class StatisticsViewModel with ChangeNotifier {
  final TaskRepository _taskRepository = TaskRepository();

  // 상태 변수들
  DateTime _currentWeekStart = DateTime.now();
  int _weeklyFocusMinutes = 0;
  int _dailyFocusMinutes = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  int get weeklyFocusMinutes => _weeklyFocusMinutes;
  int get dailyFocusMinutes => _dailyFocusMinutes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
    return date.subtract(Duration(days: weekday - 1));
  }

  // 현재 주 텍스트 반환
  String getCurrentWeekText() {
    final now = DateTime.now();
    final thisWeekStart = _getWeekStart(now);
    
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
      _calculateFocusTime();
    } catch (e) {
      _setError('통계 데이터를 불러오는데 실패했습니다: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // 집중 시간 계산
  void _calculateFocusTime() {
    final tasks = _taskRepository.tasks;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));

    int weeklyTotal = 0;
    int dailyTotal = 0;

    for (final task in tasks) {
      // 루틴은 제외 (일정만 포함)
      final taskDate = DateTime(
        task.createdAt.year,
        task.createdAt.month,
        task.createdAt.day,
      );

      // 주간 집중 시간 계산
      if (taskDate.isAfter(_currentWeekStart.subtract(const Duration(days: 1))) &&
          taskDate.isBefore(weekEnd.add(const Duration(days: 1)))) {
        weeklyTotal += _calculateTaskFocusTime(task);
      }

      // 오늘 집중 시간 계산
      if (taskDate.isAtSameMomentAs(today)) {
        dailyTotal += _calculateTaskFocusTime(task);
      }
    }

    _weeklyFocusMinutes = weeklyTotal;
    _dailyFocusMinutes = dailyTotal;
    notifyListeners();
  }

  // 개별 태스크의 집중 시간 계산
  int _calculateTaskFocusTime(TaskModel task) {
    // 기본 60분 기준으로 진행률 계산
    // 실제로는 포모도로 타이머의 실제 집중 시간을 사용해야 하지만,
    // 현재는 임의로 계산 (완료된 태스크는 100%, 미완료는 50% 가정)
    const baseFocusMinutes = 60;
    
    if (task.isCompleted) {
      return baseFocusMinutes; // 완료된 태스크는 전체 집중 시간
    } else {
      return (baseFocusMinutes * 0.5).round(); // 미완료 태스크는 50% 가정
    }
  }

  // 주간 집중 시간 포맷팅
  String getFormattedWeeklyTime() {
    return _formatMinutes(_weeklyFocusMinutes);
  }

  // 일간 집중 시간 포맷팅
  String getFormattedDailyTime() {
    return _formatMinutes(_dailyFocusMinutes);
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

  // 데이터 새로고침
  Future<void> refresh() async {
    await loadCurrentWeekData();
  }
} 