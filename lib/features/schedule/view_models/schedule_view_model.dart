import 'package:flutter/material.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/repositories/focus_session_repository.dart';
import '../../../data/models/task_model.dart';
import 'dart:math';

class ScheduleViewModel with ChangeNotifier {
  final TaskRepository _taskRepository = TaskRepository();
  final FocusSessionRepository _focusRepository = FocusSessionRepository();
  
  // 생성자에서 Repository 변경사항 구독
  ScheduleViewModel() {
    _taskRepository.addListener(_onRepositoryChanged);
  }
  
  @override
  void dispose() {
    _taskRepository.removeListener(_onRepositoryChanged);
    super.dispose();
  }
  
  // Repository 변경사항 감지 시 UI 업데이트
  void _onRepositoryChanged() {
    _setTasks(_taskRepository.tasks);
  }

  // 상태 변수들
  List<TaskModel> _tasks = [];
  TaskPriority? _currentPriority;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<TaskModel> get tasks => List.unmodifiable(_tasks);
  TaskPriority? get currentPriority => _currentPriority;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 현재 우선순위의 할일만 필터링해서 가져오기
  List<TaskModel> get filteredTasks {
    if (_currentPriority == null) return _tasks;
    return _tasks.where((task) => task.priority == _currentPriority).toList();
  }

  // 완료되지 않은 할일들만 가져오기
  List<TaskModel> get incompleteTasks {
    return filteredTasks.where((task) => !task.isCompleted).toList();
  }

  // 완료된 할일들만 가져오기
  List<TaskModel> get completedTasks {
    return filteredTasks.where((task) => task.isCompleted).toList();
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

  // 할일 목록 설정
  void _setTasks(List<TaskModel> tasks) {
    _tasks = tasks;
    notifyListeners();
  }

  // 특정 우선순위의 할일들 로드 (API 동기화 포함)
  Future<void> loadTasksByPriority(TaskPriority priority) async {
    _setLoading(true);
    _setError(null);
    _currentPriority = priority;

    try {
      await _taskRepository.loadTasksWithSync();
      _setTasks(_taskRepository.tasks);
    } catch (e) {
      _setError('할일 목록을 불러오는데 실패했습니다: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // 모든 할일들 로드 (API 동기화 포함)
  Future<void> loadAllTasks() async {
    _setLoading(true);
    _setError(null);
    _currentPriority = null;

    try {
      await _taskRepository.loadTasksWithSync();
      _setTasks(_taskRepository.tasks);
    } catch (e) {
      _setError('할일 목록을 불러오는데 실패했습니다: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // 일반적인 할일 로드 (loadAllTasks의 별칭)
  Future<void> loadTasks() async {
    await loadAllTasks();
  }

  // 할일 추가 (반복 일정 지원)
  Future<bool> addTask({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? dueDate,
    DateTime? startDateRange,
    DateTime? endDateRange,
    bool isRecurring = false,
    TaskPriority? priority,
    String? emoji,
  }) async {
    final taskPriority = priority ?? _currentPriority;
    
    if (taskPriority == null) {
      _setError('우선순위가 설정되지 않았습니다');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      if (title.isEmpty) {
        _setError('할일 제목을 입력해주세요');
        return false;
      }

      // 반복 일정인 경우
      if (isRecurring && startDateRange != null && endDateRange != null) {
        return await _addRecurringTask(
          title: title,
          description: description,
          startDate: startDate,
          dueDate: dueDate,
          startDateRange: startDateRange,
          endDateRange: endDateRange,
          priority: taskPriority,
          emoji: emoji,
        );
      } else {
        // 단일 일정인 경우
        final task = TaskModel(
          id: 'task_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          description: description,
          priority: taskPriority,
          createdAt: DateTime.now(),
          startDate: startDate,
          dueDate: dueDate,
          isRecurring: false,
          emoji: emoji,
        );

        final success = await _taskRepository.addTask(task);
        if (success) {
          _setTasks(_taskRepository.tasks);
          return true;
        } else {
          _setError('할일 추가에 실패했습니다');
          return false;
        }
      }
    } catch (e) {
      _setError('할일 추가 중 오류가 발생했습니다: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 반복 일정 추가
  Future<bool> _addRecurringTask({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? dueDate,
    required DateTime startDateRange,
    required DateTime endDateRange,
    required TaskPriority priority,
    String? emoji,
  }) async {
    try {
      // 날짜 범위 내의 모든 날짜에 대해 일정 생성
      DateTime currentDate = DateTime(
        startDateRange.year,
        startDateRange.month,
        startDateRange.day,
      );
      final endDate = DateTime(
        endDateRange.year,
        endDateRange.month,
        endDateRange.day,
      );

      int taskCount = 0;
      print('반복 일정 생성 시작: $startDateRange ~ $endDateRange');
      while (!currentDate.isAfter(endDate)) {
        // 각 날짜에 대해 시작 시간과 종료 시간 설정
        DateTime? taskStartDate;
        DateTime? taskDueDate;

        if (startDate != null) {
          taskStartDate = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            startDate.hour,
            startDate.minute,
          );
        }

        if (dueDate != null) {
          taskDueDate = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            dueDate.hour,
            dueDate.minute,
          );
        }

        final task = TaskModel(
          id: 'task_${DateTime.now().millisecondsSinceEpoch}_${taskCount}_${currentDate.millisecondsSinceEpoch}_${Random().nextInt(999999)}',
          title: title,
          description: description,
          priority: priority,
          createdAt: DateTime.now(),
          startDate: taskStartDate,
          dueDate: taskDueDate,
          startDateRange: startDateRange,
          endDateRange: endDateRange,
          isRecurring: true,
          emoji: emoji,
        );

        final success = await _taskRepository.addTask(task);
        if (!success) {
          _setError('반복 일정 추가 중 오류가 발생했습니다');
          return false;
        }

        taskCount++;
        currentDate = currentDate.add(const Duration(days: 1));
      }

      _setTasks(_taskRepository.tasks);
      return true;
    } catch (e) {
      _setError('반복 일정 추가 중 오류가 발생했습니다: ${e.toString()}');
      return false;
    }
  }

  // 할일 완료 상태 토글
  Future<bool> toggleTaskCompletion(String taskId) async {
    try {
      final success = await _taskRepository.toggleTaskCompletion(taskId);
      if (success) {
        _setTasks(_taskRepository.tasks);
        // UI 즉시 업데이트
        notifyListeners();
        return true;
      } else {
        _setError('할일 상태 변경에 실패했습니다');
        return false;
      }
    } catch (e) {
      _setError('할일 상태 변경 중 오류가 발생했습니다');
      return false;
    }
  }

  // 할일 삭제
  Future<bool> deleteTask(String taskId) async {
    try {
      // 🔧 수정: 삭제하기 전에 일정 정보를 가져와서 제목 확인
      final taskToDelete = getTaskById(taskId);
      if (taskToDelete == null) {
        _setError('삭제할 일정을 찾을 수 없습니다');
        return false;
      }
      
      // 일정 삭제
      final success = await _taskRepository.deleteTask(taskId);
      if (success) {
        // 🆕 추가: 해당 일정의 집중시간 데이터도 함께 삭제
        await _focusRepository.loadSessionsFromStorage();
        await _focusRepository.deleteSessionsByTaskTitle(taskToDelete.title);
        
        _setTasks(_taskRepository.tasks);
        print('일정 "${taskToDelete.title}" 삭제 완료 (집중시간 데이터 포함)');
        return true;
      } else {
        _setError('할일 삭제에 실패했습니다');
        return false;
      }
    } catch (e) {
      _setError('할일 삭제 중 오류가 발생했습니다');
      return false;
    }
  }

  // 할일 수정
  Future<bool> updateTask(TaskModel updatedTask) async {
    try {
      final success = await _taskRepository.updateTask(updatedTask);
      if (success) {
        _setTasks(_taskRepository.tasks);
        return true;
      } else {
        _setError('할일 수정에 실패했습니다');
        return false;
      }
    } catch (e) {
      _setError('할일 수정 중 오류가 발생했습니다');
      return false;
    }
  }

  // ID로 할일 찾기
  TaskModel? getTaskById(String taskId) {
    try {
      return _tasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      return null;
    }
  }

  // 우선순위별 색상 가져오기
  Color getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgentImportant:
        return const Color(0xFFE53E3E); // 빨간색
      case TaskPriority.important:
        return const Color(0xFFD69E2E); // 노란색
      case TaskPriority.urgent:
        return const Color(0xFF3182CE); // 파란색
      case TaskPriority.neither:
        return const Color(0xFF38A169); // 초록색
    }
  }

  // 우선순위별 제목 가져오기
  String getPriorityTitle(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgentImportant:
        return '중요 & 긴급';
      case TaskPriority.important:
        return '중요';
      case TaskPriority.urgent:
        return '긴급';
      case TaskPriority.neither:
        return '중요하지 않음';
    }
  }

  // 우선순위별 설명 가져오기
  String getPriorityDescription(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgentImportant:
        return '지금 해야 할 것들';
      case TaskPriority.important:
        return '계획해서 해야 할 것들';
      case TaskPriority.urgent:
        return '위임하거나 빠르게 처리';
      case TaskPriority.neither:
        return '여유가 있을 때';
    }
  }

  // 에러 메시지 지우기
  void clearError() {
    _setError(null);
  }

  // 데이터 새로고침
  Future<void> refresh() async {
    if (_currentPriority != null) {
      await loadTasksByPriority(_currentPriority!);
    } else {
      await loadAllTasks();
    }
  }

  /// API에서 데이터 강제 동기화
  Future<void> syncFromApi() async {
    _setLoading(true);
    _setError(null);

    try {
      await _taskRepository.syncFromApi();
      _setTasks(_taskRepository.tasks);
    } catch (e) {
      _setError('서버와 동기화하는데 실패했습니다: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
} 