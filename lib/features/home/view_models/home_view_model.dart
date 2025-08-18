import 'package:flutter/material.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/schedule_model.dart';
import '../../../api/mainpage_api.dart';
import '../../../api/token_manager.dart';

class HomeViewModel with ChangeNotifier {
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  final TaskRepository _taskRepository = TaskRepository(); // 로컬 저장용 유지
  
  // 생성자
  HomeViewModel() {
    // Schedule API에서 데이터 로드
    loadTasks();
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  // 상태 변수들
  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _todaySummary;
  Map<String, dynamic>? _widgets;
  DateTime? _lastSyncTime;

  // Getters
  List<TaskModel> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get todaySummary => _todaySummary;
  Map<String, dynamic>? get widgets => _widgets;

  // 우선순위별 할일 목록 가져오기 (현재 날짜 기준 필터링, 시간순 정렬)
  List<TaskModel> getTasksByPriority(TaskPriority priority) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 중복 제거를 위한 Set 사용
    final uniqueTaskIds = <String>{};
    final filteredTasks = <TaskModel>[];
    
    for (final task in _tasks) {
      // 우선순위 필터링 (완료된 일정도 포함)
      if (task.priority != priority) continue;
      
      // 이미 추가된 일정인지 확인 (중복 방지)
      if (uniqueTaskIds.contains(task.id)) continue;
      
      bool shouldInclude = false;
      
      // 현재 날짜 기준 필터링
      if (task.isRecurring && task.startDateRange != null && task.endDateRange != null) {
        // 반복 일정인 경우: 현재 날짜가 범위 내에 있는지 확인
        final startRange = DateTime(
          task.startDateRange!.year,
          task.startDateRange!.month,
          task.startDateRange!.day,
        );
        final endRange = DateTime(
          task.endDateRange!.year,
          task.endDateRange!.month,
          task.endDateRange!.day,
        );
        
        // 오늘이 반복 일정 기간 내에 있으면 표시
        shouldInclude = !today.isBefore(startRange) && !today.isAfter(endRange);
      } else if (task.isRecurring) {
        // isRecurring이 true인데 범위가 없는 경우 - 날짜로 처리
        final startDate = task.startDate;
        final endDate = task.dueDate;
        
        if (startDate != null && endDate != null) {
          final startDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
          final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
          shouldInclude = !today.isBefore(startDateOnly) && !today.isAfter(endDateOnly);
        }
      } else {
        // 일반 일정인 경우: 여러 날에 걸친 일정도 처리
        final startDate = task.startDate;
        final endDate = task.dueDate;
        
        if (startDate != null && endDate != null) {
          // 시작일과 종료일이 모두 있는 경우
          final startDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
          final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
          
          // 오늘이 일정 기간 내에 있는지 확인
          shouldInclude = !today.isBefore(startDateOnly) && !today.isAfter(endDateOnly);
        } else if (startDate != null) {
          // 시작일만 있는 경우
          final startDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
          shouldInclude = _isSameDay(startDateOnly, today);
        } else if (endDate != null) {
          // 종료일만 있는 경우
          final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
          shouldInclude = _isSameDay(endDateOnly, today);
        }
      }
      
      if (shouldInclude) {
        uniqueTaskIds.add(task.id);
        filteredTasks.add(task);
      }
    }
    
    // 시간순으로 정렬 (시작시간 우선, 없으면 종료시간)
    filteredTasks.sort((a, b) {
      final timeA = a.startDate ?? a.dueDate ?? DateTime.now();
      final timeB = b.startDate ?? b.dueDate ?? DateTime.now();
      return timeA.compareTo(timeB);
    });
    
    return filteredTasks;
  }

  // 같은 날짜인지 확인하는 헬퍼 메서드
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
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

  // ScheduleModel을 TaskModel로 변환
  TaskModel _scheduleToTask(ScheduleModel schedule) {
    final type = ScheduleType.fromString(schedule.type);
    final priority = _scheduleTypeToPriority(type);
    
    // 날짜 파싱
    DateTime? startDateTime;
    DateTime? endDateTime;
    
    try {
      if (schedule.startDate.isNotEmpty) {
        startDateTime = DateTime.parse(schedule.startDate);
        if (schedule.time != null && schedule.time!.isNotEmpty) {
          final timeParts = schedule.time!.split(':');
          if (timeParts.length >= 2) {
            startDateTime = DateTime(
              startDateTime.year,
              startDateTime.month,
              startDateTime.day,
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
            );
          }
        }
      }
      
      if (schedule.endDate.isNotEmpty) {
        endDateTime = DateTime.parse(schedule.endDate);
        if (schedule.time != null && schedule.time!.isNotEmpty) {
          final timeParts = schedule.time!.split(':');
          if (timeParts.length >= 2) {
            endDateTime = DateTime(
              endDateTime.year,
              endDateTime.month,
              endDateTime.day,
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
            );
          }
        }
      }
    } catch (e) {
      print('날짜 파싱 에러: $e');
    }
    
    return TaskModel(
      id: schedule.scheduleId?.toString() ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
      title: schedule.title,
      memo: schedule.memo,
      location: schedule.location,
      priority: priority,
      alarm: schedule.alarm30Before || schedule.alarm60Before || schedule.alarm120Before,
      isCompleted: false,
      createdAt: DateTime.now(),
      calendarDate: schedule.startDate,
      startTime: schedule.time,
      endTime: schedule.time,
      icon: schedule.image,
      isRecurring: schedule.isRecurring,
      startDate: startDateTime,
      dueDate: endDateTime,
      description: schedule.memo ?? schedule.location,
      emoji: schedule.image,
    );
  }

  // TaskPriority를 ScheduleType으로 변환
  ScheduleType _priorityToScheduleType(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgentImportant:
        return ScheduleType.urgentNow;
      case TaskPriority.important:
        return ScheduleType.planAhead;
      case TaskPriority.urgent:
        return ScheduleType.whenFree;
      case TaskPriority.neither:
        return ScheduleType.laterProcessing;
    }
  }

  // ScheduleType을 TaskPriority로 변환
  TaskPriority _scheduleTypeToPriority(ScheduleType type) {
    switch (type) {
      case ScheduleType.urgentNow:
        return TaskPriority.urgentImportant;
      case ScheduleType.planAhead:
        return TaskPriority.important;
      case ScheduleType.whenFree:
        return TaskPriority.urgent;
      case ScheduleType.laterProcessing:
        return TaskPriority.neither;
    }
  }

  // 초기 데이터 로드 (비회원 지원 - 로컬 우선)
  Future<void> loadTasks() async {
    _setLoading(true);
    _setError(null);

    try {
      // 먼저 로컬 데이터 로드
      await _taskRepository.loadTasksFromStorage();
      _setTasks(_taskRepository.tasks);
      
      // 홈화면 요약 정보 로드
      await loadTodaySummary();
      
      // 백그라운드에서 Schedule API 시도 (회원인 경우만 동작)
      _syncWithScheduleAPI();
    } catch (e) {
      print('데이터 로드 실패: $e');
      _setError('데이터를 불러오는데 실패했습니다');
    } finally {
      _setLoading(false);
    }
  }
  
  // 홈화면 요약 정보 로드 (로컬 데이터만 사용)
  Future<void> loadTodaySummary() async {
    try {
      // 로컬 데이터로 요약 생성
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // 오늘의 일정들 계산
      final todayTasks = _tasks.where((task) {
        if (task.startDate != null && task.dueDate != null) {
          final startDateOnly = DateTime(task.startDate!.year, task.startDate!.month, task.startDate!.day);
          final endDateOnly = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
          return !today.isBefore(startDateOnly) && !today.isAfter(endDateOnly);
        }
        return false;
      }).toList();
      
      final urgentImportantCount = todayTasks.where((t) => t.priority == TaskPriority.urgentImportant).length;
      final importantCount = todayTasks.where((t) => t.priority == TaskPriority.important).length;
      final urgentCount = todayTasks.where((t) => t.priority == TaskPriority.urgent).length;
      final neitherCount = todayTasks.where((t) => t.priority == TaskPriority.neither).length;
      final completedCount = todayTasks.where((t) => t.isCompleted).length;
      
      // 로컬 요약 데이터 생성
      _todaySummary = {
        'success': true,
        'data': {
          'todayDate': '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
          'totalTasks': todayTasks.length,
          'completedTasks': completedCount,
          'urgentImportantCount': urgentImportantCount,
          'importantCount': importantCount,
          'urgentCount': urgentCount,
          'neitherCount': neitherCount,
          'todayFocusMinutes': 0,
          'weeklyFocusMinutes': 0,
        }
      };
      
      // MainPageAPI로 우선순위별 데이터 조회 (백그라운드)
      _loadSchedulesFromMainPageAPI();
      
    } catch (e) {
      print('홈화면 요약 로드 실패: $e');
    }
  }
  
  // MainPageAPI로 우선순위별 일정 조회
  Future<void> _loadSchedulesFromMainPageAPI() async {
    try {
      final isGuest = await TokenManager.instance.isGuestMode();
      if (isGuest) return;
      
      // 각 우선순위별로 API 호출
      final types = ['지금_바로_해야해요', '미리_계획해서_준비해요', '시간이_남을_때_해요', '나중에_처리해요'];
      
      for (final type in types) {
        final schedules = await MainPageAPI.getSchedulesByType(type);
        // API 데이터가 있으면 처리 (현재는 로깅만)
        if (schedules.isNotEmpty) {
          print('$type 일정 ${schedules.length}개 조회됨');
        }
      }
    } catch (e) {
      print('MainPage API 조회 실패: $e');
    }
  }
  
  // Schedule API와 동기화 (백그라운드)
  Future<void> _syncWithScheduleAPI() async {
    try {
      // API 호출 시도 (인증 실패 시 무시)
      final schedules = await _scheduleRepository.getAllSchedules();
      
      // API 데이터가 있으면 병합
      if (schedules.isNotEmpty) {
        final apiTasks = schedules.map((schedule) => _scheduleToTask(schedule)).toList();
        
        // 로컬과 API 데이터 병합 (중복 제거 - ID와 제목으로 체크)
        final taskMap = <String, TaskModel>{};
        final taskTitles = <String>{};
        
        // 먼저 로컬 데이터 추가
        for (final task in _tasks) {
          taskMap[task.id] = task;
          taskTitles.add('${task.title}_${task.startDate}_${task.dueDate}');
        }
        
        // API 데이터 추가 (중복 체크)
        for (final apiTask in apiTasks) {
          final taskKey = '${apiTask.title}_${apiTask.startDate}_${apiTask.dueDate}';
          // ID가 다르더라도 같은 제목과 날짜를 가진 일정은 중복으로 처리
          if (!taskTitles.contains(taskKey)) {
            taskMap[apiTask.id] = apiTask;
            taskTitles.add(taskKey);
          }
        }
        
        _setTasks(taskMap.values.toList());
      }
    } catch (e) {
      // API 실패는 무시 (비회원이거나 네트워크 오류)
      print('Schedule API 동기화 건너뜀: $e');
    }
  }

  // 할일 추가 (비회원 지원)
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

      // 로컬에 먼저 저장
      final task = TaskModel(
        id: 'task_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: description,
        priority: priority,
        createdAt: DateTime.now(),
        dueDate: dueDate,
      );
      
      final success = await _taskRepository.addTask(task);
      if (!success) {
        _setError('할일 추가에 실패했습니다');
        return false;
      }

      // 백그라운드에서 Schedule API 시도 (회원인 경우)
      _createScheduleInBackground(task);
      
      // 전체 목록 다시 로드
      await loadTasks();
      return true;
    } catch (e) {
      _setError('할일 추가 중 오류가 발생했습니다: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // 백그라운드에서 Schedule API 호출
  Future<void> _createScheduleInBackground(TaskModel task) async {
    try {
      final type = _priorityToScheduleType(task.priority);
      final schedule = ScheduleModel(
        title: task.title,
        time: task.dueDate != null ? '${task.dueDate!.hour.toString().padLeft(2, '0')}:${task.dueDate!.minute.toString().padLeft(2, '0')}' : null,
        startDate: _formatDate(task.dueDate ?? DateTime.now()),
        endDate: _formatDate(task.dueDate ?? DateTime.now()),
        type: type.value,
        location: null,
        memo: task.description,
        image: '📅',
        alarm30Before: false,
        alarm60Before: false,
        alarm120Before: false,
        isRecurring: false,
      );
      
      await _scheduleRepository.createSchedule(schedule);
    } catch (e) {
      // API 실패는 무시 (비회원이거나 네트워크 오류)
      print('Schedule API 생성 건너뜀: $e');
    }
  }

  // 할일 완료 상태 토글 (로컬만)
  Future<bool> toggleTaskCompletion(String taskId) async {
    try {
      // 로컬에서만 완료 상태 관리
      final success = await _taskRepository.toggleTaskCompletion(taskId);
      if (success) {
        await loadTasks();
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

  // 할일 삭제 (비회원 지원)
  Future<bool> deleteTask(String taskId) async {
    try {
      // 로컬에서 먼저 삭제
      await _taskRepository.deleteTask(taskId);
      
      // 백그라운드에서 Schedule API 시도 (회원인 경우)
      final scheduleId = int.tryParse(taskId);
      if (scheduleId != null && scheduleId > 0) {
        _deleteScheduleInBackground(scheduleId);
      }
      
      // 전체 목록 다시 로드
      await loadTasks();
      return true;
    } catch (e) {
      _setError('할일 삭제 중 오류가 발생했습니다');
      return false;
    }
  }
  
  // 백그라운드에서 Schedule 삭제
  Future<void> _deleteScheduleInBackground(int scheduleId) async {
    try {
      await _scheduleRepository.deleteSchedule(scheduleId);
    } catch (e) {
      // API 실패는 무시
      print('Schedule API 삭제 건너뜀: $e');
    }
  }

  // 할일 수정 (비회원 지원)
  Future<bool> updateTask(TaskModel updatedTask) async {
    try {
      // 로컬에서 먼저 수정
      await _taskRepository.updateTask(updatedTask);
      
      // 백그라운드에서 Schedule API 시도 (회원인 경우)
      final scheduleId = int.tryParse(updatedTask.id);
      if (scheduleId != null && scheduleId > 0) {
        _updateScheduleInBackground(scheduleId, updatedTask);
      }
      
      // 전체 목록 다시 로드
      await loadTasks();
      return true;
    } catch (e) {
      _setError('할일 수정 중 오류가 발생했습니다');
      return false;
    }
  }
  
  // 백그라운드에서 Schedule 수정
  Future<void> _updateScheduleInBackground(int scheduleId, TaskModel task) async {
    try {
      final type = _priorityToScheduleType(task.priority);
      final schedule = ScheduleModel(
        scheduleId: scheduleId,
        title: task.title,
        time: task.startTime,
        startDate: task.calendarDate ?? _formatDate(task.startDate ?? DateTime.now()),
        endDate: task.calendarDate ?? _formatDate(task.dueDate ?? DateTime.now()),
        type: type.value,
        location: task.location,
        memo: task.memo ?? task.description,
        image: task.icon ?? task.emoji ?? '📅',
        alarm30Before: task.alarm,
        alarm60Before: false,
        alarm120Before: false,
        isRecurring: task.isRecurring,
      );
      
      await _scheduleRepository.updateSchedule(scheduleId, schedule);
    } catch (e) {
      // API 실패는 무시
      print('Schedule API 수정 건너뜀: $e');
    }
  }

  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
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