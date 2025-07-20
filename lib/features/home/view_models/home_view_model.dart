import 'package:flutter/material.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/models/task_model.dart';

class HomeViewModel with ChangeNotifier {
  final TaskRepository _taskRepository = TaskRepository();

  // 상태 변수들
  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<TaskModel> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 우선순위별 할일 목록 가져오기
  List<TaskModel> getTasksByPriority(TaskPriority priority) {
    return _tasks.where((task) => task.priority == priority && !task.isCompleted).toList();
  }

  // 우선순위별 할일 개수 가져오기
  int getTaskCountByPriority(TaskPriority priority) {
    return getTasksByPriority(priority).length;
  }

  // 완료된 할일 개수 가져오기
  int get completedTasksCount {
    return _tasks.where((task) => task.isCompleted).length;
  }

  // 전체 할일 개수 가져오기
  int get totalTasksCount => _tasks.length;

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

  // 초기 데이터 로드
  Future<void> loadTasks() async {
    _setLoading(true);
    _setError(null);

    try {
      await _taskRepository.loadTasksFromStorage();
      _setTasks(_taskRepository.tasks);
    } catch (e) {
      _setError('할일 목록을 불러오는데 실패했습니다: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // 할일 추가
  Future<bool> addTask({
    required String title,
    String? description,
    required TaskPriority priority,
    DateTime? dueDate,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      if (title.isEmpty) {
        _setError('할일 제목을 입력해주세요');
        return false;
      }

      final task = TaskModel(
        id: 'task_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: description,
        priority: priority,
        createdAt: DateTime.now(),
        dueDate: dueDate,
      );

      final success = await _taskRepository.addTask(task);
      if (success) {
        _setTasks(_taskRepository.tasks);
        return true;
      } else {
        _setError('할일 추가에 실패했습니다');
        return false;
      }
    } catch (e) {
      _setError('할일 추가 중 오류가 발생했습니다: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 할일 완료 상태 토글
  Future<bool> toggleTaskCompletion(String taskId) async {
    try {
      final success = await _taskRepository.toggleTaskCompletion(taskId);
      if (success) {
        _setTasks(_taskRepository.tasks);
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
      final success = await _taskRepository.deleteTask(taskId);
      if (success) {
        _setTasks(_taskRepository.tasks);
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
    await loadTasks();
  }
} 