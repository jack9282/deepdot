import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import 'dart:convert';

class TaskRepository {
  static const String _tasksKey = 'tasks';
  
  // 메모리에 캐시된 할일 목록
  List<TaskModel> _tasks = [];

  // 할일 목록 getter
  List<TaskModel> get tasks => List.unmodifiable(_tasks);

  // 우선순위별 할일 목록 가져오기
  List<TaskModel> getTasksByPriority(TaskPriority priority) {
    return _tasks.where((task) => task.priority == priority && !task.isCompleted).toList();
  }

  // 완료된 할일 목록 가져오기
  List<TaskModel> getCompletedTasks() {
    return _tasks.where((task) => task.isCompleted).toList();
  }

  // 우선순위별 할일 개수 가져오기
  int getTaskCountByPriority(TaskPriority priority) {
    return getTasksByPriority(priority).length;
  }

  // 할일 추가
  Future<bool> addTask(TaskModel task) async {
    try {
      _tasks.add(task);
      await _saveTasksToStorage();
      return true;
    } catch (e) {
      return false;
    }
  }

  // 할일 업데이트
  Future<bool> updateTask(TaskModel updatedTask) async {
    try {
      final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        await _saveTasksToStorage();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // 할일 삭제
  Future<bool> deleteTask(String taskId) async {
    try {
      _tasks.removeWhere((task) => task.id == taskId);
      await _saveTasksToStorage();
      return true;
    } catch (e) {
      return false;
    }
  }

  // 할일 완료 상태 토글
  Future<bool> toggleTaskCompletion(String taskId) async {
    try {
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        final task = _tasks[index];
        final updatedTask = task.copyWith(
          isCompleted: !task.isCompleted,
          completedAt: !task.isCompleted ? DateTime.now() : null,
        );
        _tasks[index] = updatedTask;
        await _saveTasksToStorage();
        return true;
      }
      return false;
    } catch (e) {
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

  // 로컬 스토리지에서 할일 목록 로드
  Future<bool> loadTasksFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString(_tasksKey);

      if (tasksJson != null) {
        final List<dynamic> tasksList = json.decode(tasksJson);
        _tasks = tasksList
            .map((taskJson) => TaskModel.fromJson(taskJson as Map<String, dynamic>))
            .toList();
        return true;
      }
      
      // 저장된 데이터가 없으면 샘플 데이터 생성
      await _createSampleTasks();
      return true;
    } catch (e) {
      // 오류 발생 시 샘플 데이터 생성
      await _createSampleTasks();
      return false;
    }
  }

  // 로컬 스토리지에 할일 목록 저장
  Future<void> _saveTasksToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = json.encode(_tasks.map((task) => task.toJson()).toList());
    await prefs.setString(_tasksKey, tasksJson);
  }

  // 샘플 할일 데이터 생성 (처음 앱을 사용할 때)
  Future<void> _createSampleTasks() async {
    final now = DateTime.now();
    
    _tasks = [
      TaskModel(
        id: 'sample_1',
        title: '프로젝트 마감일 확인',
        description: '내일까지 제출해야 하는 중요한 프로젝트',
        priority: TaskPriority.urgentImportant,
        createdAt: now.subtract(const Duration(hours: 2)),
        dueDate: now.add(const Duration(days: 1)),
      ),
      TaskModel(
        id: 'sample_2',
        title: '운동 계획 세우기',
        description: '주 3회 운동 루틴 만들기',
        priority: TaskPriority.important,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      TaskModel(
        id: 'sample_3',
        title: '친구 생일선물 사기',
        description: '이번 주 토요일이 생일',
        priority: TaskPriority.urgent,
        createdAt: now.subtract(const Duration(minutes: 30)),
        dueDate: now.add(const Duration(days: 3)),
      ),
      TaskModel(
        id: 'sample_4',
        title: '유튜브 시청',
        description: '관심있는 영상들 보기',
        priority: TaskPriority.neither,
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),
    ];

    await _saveTasksToStorage();
  }

  // 모든 할일 삭제 (개발/테스트용)
  Future<void> clearAllTasks() async {
    _tasks.clear();
    await _saveTasksToStorage();
  }
} 