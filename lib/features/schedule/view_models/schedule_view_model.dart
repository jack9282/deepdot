import 'package:flutter/material.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/repositories/focus_session_repository.dart';
import '../../../data/models/schedule_model.dart';
import '../../../data/models/task_model.dart';
import '../../../utils/alarm.dart';
import '../../../utils/alarm_id_generator.dart';

class ScheduleViewModel with ChangeNotifier {
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
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
  List<ScheduleModel> _schedules = [];
  List<TaskModel> _tasks = [];
  ScheduleType? _currentType;
  TaskPriority? _currentPriority;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  // Getters
  List<ScheduleModel> get schedules => List.unmodifiable(_schedules);
  List<TaskModel> get tasks => List.unmodifiable(_tasks);
  ScheduleType? get currentType => _currentType;
  TaskPriority? get currentPriority => _currentPriority;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;

  // 현재 타입의 일정만 필터링해서 가져오기
  List<ScheduleModel> get filteredSchedules {
    if (_currentType == null) return _schedules;
    return _schedules.where((schedule) => schedule.type == _currentType!.value).toList();
  }
  
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

  // 일정 목록 설정
  void _setSchedules(List<ScheduleModel> schedules) {
    _schedules = schedules;
    notifyListeners();
  }
  
  // 할일 목록 설정
  void _setTasks(List<TaskModel> tasks) {
    _tasks = tasks;
    notifyListeners();
  }

  // 선택된 날짜 변경
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
    loadSchedulesByDate(date);
  }

  // 모든 일정 로드 (비회원 지원 - 로컬 우선)
  Future<void> loadAllSchedules() async {
    _setLoading(true);
    _setError(null);
    _currentType = null;

    try {
      // 먼저 로컬 데이터 로드
      await _taskRepository.loadTasksFromStorage();
      
      // 중복 제거
      final uniqueTasks = <String, TaskModel>{};
      for (final task in _taskRepository.tasks) {
        uniqueTasks[task.id] = task;
      }
      _setTasks(uniqueTasks.values.toList());
      
      // 백그라운드에서 Schedule API 시도 (회원인 경우만 동작)
      _syncSchedulesWithAPI();
    } catch (e) {
      _setError('일정 목록을 불러오는데 실패했습니다: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // 특정 날짜의 일정 로드 (비회원 지원)
  Future<void> loadSchedulesByDate(DateTime date) async {
    _setLoading(true);
    _setError(null);

    try {
      // 로컬 데이터에서 날짜별 필터링
      await _taskRepository.loadTasksFromStorage();
      final dateOnly = DateTime(date.year, date.month, date.day);
      final filteredTasks = _taskRepository.tasks.where((task) {
        final taskDate = task.startDate ?? task.dueDate;
        if (taskDate == null) return false;
        final taskDateOnly = DateTime(taskDate.year, taskDate.month, taskDate.day);
        return taskDateOnly.isAtSameMomentAs(dateOnly);
      }).toList();
      _setTasks(filteredTasks);
      
      // 백그라운드에서 API 시도
      _syncSchedulesByDateWithAPI(date);
    } catch (e) {
      _setError('날짜별 일정을 불러오는데 실패했습니다: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // 기간별 일정 로드 (비회원 지원)
  Future<void> loadSchedulesByRange(DateTime from, DateTime to) async {
    _setLoading(true);
    _setError(null);

    try {
      // 로컬 데이터에서 기간별 필터링
      await _taskRepository.loadTasksFromStorage();
      final fromOnly = DateTime(from.year, from.month, from.day);
      final toOnly = DateTime(to.year, to.month, to.day, 23, 59, 59);
      final filteredTasks = _taskRepository.tasks.where((task) {
        final taskDate = task.startDate ?? task.dueDate;
        if (taskDate == null) return false;
        return !taskDate.isBefore(fromOnly) && !taskDate.isAfter(toOnly);
      }).toList();
      _setTasks(filteredTasks);
      
      // 백그라운드에서 API 시도
      _syncSchedulesByRangeWithAPI(from, to);
    } catch (e) {
      _setError('기간별 일정을 불러오는데 실패했습니다: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // 오늘 일정 로드
  Future<void> loadTodaySchedules() async {
    await loadSchedulesByDate(DateTime.now());
  }

  // 이번 주 일정 로드 (비회원 지원)
  Future<void> loadWeekSchedules() async {
    _setLoading(true);
    _setError(null);

    try {
      // 이번 주의 시작과 끝 계산
      final now = DateTime.now();
      final weekday = now.weekday;
      final weekStart = now.subtract(Duration(days: weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      
      // 로컬 데이터 로드 및 필터링
      await loadSchedulesByRange(weekStart, weekEnd);
    } catch (e) {
      _setError('이번 주 일정을 불러오는데 실패했습니다: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // 이번 달 일정 로드 (비회원 지원)
  Future<void> loadMonthSchedules() async {
    _setLoading(true);
    _setError(null);

    try {
      // 이번 달의 시작과 끝 계산
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);
      
      // 로컬 데이터 로드 및 필터링
      await loadSchedulesByRange(monthStart, monthEnd);
    } catch (e) {
      _setError('이번 달 일정을 불러오는데 실패했습니다: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // 특정 타입의 일정 로드
  Future<void> loadSchedulesByType(ScheduleType type) async {
    _setLoading(true);
    _setError(null);
    _currentType = type;

    try {
      final schedules = await _scheduleRepository.getSchedulesByType(type.value);
      _setSchedules(schedules);
    } catch (e) {
      _setError('타입별 일정을 불러오는데 실패했습니다: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // 일정 추가 (비회원 지원)
  Future<bool> addSchedule({
    required String title,
    String? time,
    required DateTime startDate,
    required DateTime endDate,
    required ScheduleType type,
    String? location,
    String? memo,
    String? image,
    bool alarm30Before = false,
    bool alarm60Before = false,
    bool alarm120Before = false,
    bool isRecurring = false,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      if (title.isEmpty) {
        _setError('일정 제목을 입력해주세요');
        return false;
      }

      // 로컬에 먼저 저장
      final task = TaskModel(
        id: 'task_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        priority: scheduleTypeToPriority(type),
        createdAt: DateTime.now(),
        startDate: startDate,
        dueDate: endDate,
        location: location,
        memo: memo,
        icon: image ?? '📅',
        alarm: alarm30Before || alarm60Before || alarm120Before,
        isRecurring: isRecurring,
        startTime: time,
        endTime: time,
      );
      
      final success = await _taskRepository.addTask(task);
      if (!success) {
        _setError('일정 추가에 실패했습니다');
        return false;
      }
      
      // 알림 설정
      await _setScheduleAlarms(
        taskId: task.id,
        title: title,
        startDate: startDate,
        alarm30Before: alarm30Before,
        alarm60Before: alarm60Before,
        alarm120Before: alarm120Before,
      );

      // 백그라운드에서 Schedule API 시도 (회원인 경우)
      final schedule = ScheduleModel(
        title: title,
        time: time,
        startDate: _formatDate(startDate),
        endDate: _formatDate(endDate),
        type: type.value,
        location: location,
        memo: memo,
        image: image ?? '📅',
        alarm30Before: alarm30Before,
        alarm60Before: alarm60Before,
        alarm120Before: alarm120Before,
        isRecurring: isRecurring,
      );
      
      _createScheduleInBackground(schedule);
      
      await refresh();
      return true;
    } catch (e) {
      _setError('일정 추가 중 오류가 발생했습니다: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 일정 배치 추가 (여러 날짜에 동일한 일정 추가)
  Future<bool> addScheduleBatch({
    required String title,
    String? time,
    required DateTime fromDate,
    required DateTime toDate,
    required ScheduleType type,
    String? location,
    String? memo,
    String? image,
    bool alarm30Before = false,
    bool alarm60Before = false,
    bool alarm120Before = false,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final schedule = ScheduleModel(
        title: title,
        time: time,
        startDate: _formatDate(fromDate),
        endDate: _formatDate(toDate),
        type: type.value,
        location: location,
        memo: memo,
        image: image ?? '📅',
        alarm30Before: alarm30Before,
        alarm60Before: alarm60Before,
        alarm120Before: alarm120Before,
        isRecurring: false,
      );

      final scheduleIds = await _scheduleRepository.createScheduleBatch(
        fromDate,
        toDate,
        schedule,
      );

      if (scheduleIds.isNotEmpty) {
        await refresh();
        return true;
      } else {
        _setError('일정 배치 추가에 실패했습니다');
        return false;
      }
    } catch (e) {
      _setError('일정 배치 추가 중 오류가 발생했습니다: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 일정 수정 (비회원 지원)
  Future<bool> updateSchedule(ScheduleModel updatedSchedule) async {
    _setLoading(true);
    _setError(null);

    try {
      // ScheduleModel을 TaskModel로 변환하여 로컬 업데이트
      final task = scheduleToTask(updatedSchedule);
      final success = await _taskRepository.updateTask(task);
      
      if (!success) {
        _setError('일정 수정에 실패했습니다');
        return false;
      }
      
      // 백그라운드에서 Schedule API 시도 (회원인 경우)
      if (updatedSchedule.scheduleId != null && updatedSchedule.scheduleId! > 0) {
        _updateScheduleInBackground(updatedSchedule.scheduleId!, updatedSchedule);
      }
      
      await refresh();
      return true;
    } catch (e) {
      _setError('일정 수정 중 오류가 발생했습니다: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 일정 삭제 (비회원 지원)
  Future<bool> deleteSchedule(int scheduleId) async {
    _setLoading(true);
    _setError(null);

    try {
      // 로컬에서 먼저 삭제
      final taskId = scheduleId.toString();
      final taskToDelete = _taskRepository.getTaskById(taskId);
      if (taskToDelete != null) {
        // 알림 취소
        await _cancelScheduleAlarms(taskId);
        
        await _taskRepository.deleteTask(taskId);
        
        // 해당 일정의 집중시간 데이터도 함께 삭제
        await _focusRepository.loadSessionsFromStorage();
        await _focusRepository.deleteSessionsByTaskTitle(taskToDelete.title);
      }
      
      // 백그라운드에서 Schedule API 시도 (회원인 경우)
      if (scheduleId > 0) {
        _deleteScheduleInBackground(scheduleId);
      }
      
      await refresh();
      return true;
    } catch (e) {
      _setError('일정 삭제 중 오류가 발생했습니다: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ID로 일정 찾기
  ScheduleModel? getScheduleById(int scheduleId) {
    try {
      return _schedules.firstWhere((schedule) => schedule.scheduleId == scheduleId);
    } catch (e) {
      return null;
    }
  }

  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }

  // 타입별 색상 가져오기
  Color getTypeColor(ScheduleType type) {
    switch (type) {
      case ScheduleType.urgentNow:
        return const Color(0xFFE53E3E);
      case ScheduleType.planAhead:
        return const Color(0xFFD69E2E);
      case ScheduleType.whenFree:
        return const Color(0xFF3182CE);
      case ScheduleType.laterProcessing:
        return const Color(0xFF38A169);
    }
  }

  // 타입별 제목 가져오기
  String getTypeTitle(ScheduleType type) {
    switch (type) {
      case ScheduleType.urgentNow:
        return '지금 바로 해야해요';
      case ScheduleType.planAhead:
        return '미리 계획해서 준비해요';
      case ScheduleType.whenFree:
        return '시간이 남을 때 해요';
      case ScheduleType.laterProcessing:
        return '나중에 처리해요';
    }
  }

  // 타입별 설명 가져오기
  String getTypeDescription(ScheduleType type) {
    switch (type) {
      case ScheduleType.urgentNow:
        return '긴급하고 중요한 일정';
      case ScheduleType.planAhead:
        return '계획적으로 준비할 일정';
      case ScheduleType.whenFree:
        return '여유 시간에 처리할 일정';
      case ScheduleType.laterProcessing:
        return '나중에 처리해도 되는 일정';
    }
  }

  // 에러 메시지 지우기
  void clearError() {
    _setError(null);
  }

  // 데이터 새로고침
  Future<void> refresh() async {
    if (_currentType != null) {
      await loadSchedulesByType(_currentType!);
    } else if (_schedules.isNotEmpty) {
      await loadSchedulesByDate(_selectedDate);
    } else {
      await loadAllSchedules();
    }
  }

  // 알람이 설정된 일정 조회
  Future<void> loadSchedulesWithAlarm() async {
    _setLoading(true);
    _setError(null);

    try {
      final schedules = await _scheduleRepository.getSchedulesWithAlarm();
      _setSchedules(schedules);
    } catch (e) {
      _setError('알람 일정을 불러오는데 실패했습니다: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // 반복 일정 조회
  Future<void> loadRecurringSchedules() async {
    _setLoading(true);
    _setError(null);

    try {
      final schedules = await _scheduleRepository.getRecurringSchedules();
      _setSchedules(schedules);
    } catch (e) {
      _setError('반복 일정을 불러오는데 실패했습니다: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // ===== Task 관련 메서드들 (하위 호환성) =====
  
  // 특정 우선순위의 할일들 로드
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

  // 모든 할일들 로드
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

  // 일반적인 할일 로드
  Future<void> loadTasks() async {
    await loadAllTasks();
  }

  // 할일 삭제
  Future<bool> deleteTask(String taskId) async {
    try {
      final taskToDelete = getTaskById(taskId);
      if (taskToDelete == null) {
        _setError('삭제할 일정을 찾을 수 없습니다');
        return false;
      }
      
      // 알림 취소
      await _cancelScheduleAlarms(taskId);
      
      final success = await _taskRepository.deleteTask(taskId);
      if (success) {
        await _focusRepository.loadSessionsFromStorage();
        await _focusRepository.deleteSessionsByTaskTitle(taskToDelete.title);
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
      // 기존 task를 먼저 가져와서 제목 변경 여부 확인
      final oldTask = getTaskById(updatedTask.id);
      final titleChanged = oldTask != null && oldTask.title != updatedTask.title;
      final oldTitle = oldTask?.title ?? '';
      
      final success = await _taskRepository.updateTask(updatedTask);
      if (success) {
        // 제목이 변경되었다면 focus session의 제목도 업데이트
        if (titleChanged && oldTitle.isNotEmpty) {
          await _focusRepository.loadSessionsFromStorage();
          await _focusRepository.updateSessionTaskTitle(oldTitle, updatedTask.title);
        }
        
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
  
  // 할일 수정 및 알림 업데이트
  Future<bool> updateTaskWithAlarms({
    required TaskModel updatedTask,
    bool alarm30Before = false,
    bool alarm60Before = false,
    bool alarm120Before = false,
  }) async {
    try {
      // 기존 task를 먼저 가져와서 제목 변경 여부 확인
      final oldTask = getTaskById(updatedTask.id);
      final titleChanged = oldTask != null && oldTask.title != updatedTask.title;
      final oldTitle = oldTask?.title ?? '';
      
      final success = await _taskRepository.updateTask(updatedTask);
      if (success) {
        // 제목이 변경되었다면 focus session의 제목도 업데이트
        if (titleChanged && oldTitle.isNotEmpty) {
          await _focusRepository.loadSessionsFromStorage();
          await _focusRepository.updateSessionTaskTitle(oldTitle, updatedTask.title);
        }
        
        // 기존 알림 취소 후 새로 설정
        await _cancelScheduleAlarms(updatedTask.id);
        if (updatedTask.alarm && updatedTask.startDate != null) {
          await _setScheduleAlarms(
            taskId: updatedTask.id,
            title: updatedTask.title,
            startDate: updatedTask.startDate!,
            alarm30Before: alarm30Before,
            alarm60Before: alarm60Before,
            alarm120Before: alarm120Before,
          );
        }
        
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

  // 할일 완료 상태 토글
  Future<bool> toggleTaskCompletion(String taskId) async {
    try {
      final success = await _taskRepository.toggleTaskCompletion(taskId);
      if (success) {
        _setTasks(_taskRepository.tasks);
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

  // ID로 할일 찾기
  TaskModel? getTaskById(String taskId) {
    try {
      return _tasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      return null;
    }
  }

  // ===== TaskPriority 관련 메서드 (UI 호환성) =====
  
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

  // ===== 매핑 헬퍼 메서드 =====
  
  // TaskPriority를 ScheduleType으로 변환
  ScheduleType priorityToScheduleType(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgentImportant:
        return ScheduleType.urgentNow; // 지금 바로 해야해요
      case TaskPriority.important:
        return ScheduleType.planAhead; // 미리 계획해서 준비해요
      case TaskPriority.urgent:
        return ScheduleType.whenFree; // 시간이 남을 때 해요
      case TaskPriority.neither:
        return ScheduleType.laterProcessing; // 나중에 처리해요
    }
  }

  // ScheduleType을 TaskPriority로 변환
  TaskPriority scheduleTypeToPriority(ScheduleType type) {
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

  // TaskModel을 ScheduleModel로 변환
  ScheduleModel taskToSchedule(TaskModel task) {
    return ScheduleModel(
      scheduleId: int.tryParse(task.id),
      title: task.title,
      time: task.startTime,
      startDate: task.calendarDate ?? _formatDate(task.startDate ?? DateTime.now()),
      endDate: task.calendarDate ?? _formatDate(task.dueDate ?? DateTime.now()),
      type: priorityToScheduleType(task.priority).value,
      location: task.location,
      memo: task.memo ?? task.description,
      image: task.icon ?? task.emoji ?? '📅',
      alarm30Before: task.alarm,
      alarm60Before: false,
      alarm120Before: false,
      isRecurring: task.isRecurring,
    );
  }

  // ScheduleModel을 TaskModel로 변환
  TaskModel scheduleToTask(ScheduleModel schedule) {
    final type = ScheduleType.fromString(schedule.type);
    return TaskModel(
      id: schedule.scheduleId?.toString() ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
      title: schedule.title,
      memo: schedule.memo,
      location: schedule.location,
      priority: scheduleTypeToPriority(type),
      alarm: schedule.alarm30Before || schedule.alarm60Before || schedule.alarm120Before,
      isCompleted: false,
      createdAt: DateTime.now(),
      calendarDate: schedule.startDate,
      startTime: schedule.time,
      endTime: schedule.time,
      icon: schedule.image,
      isRecurring: schedule.isRecurring,
    );
  }
  
  // ===== 백그라운드 API 동기화 메서드 (비회원 지원) =====
  
  // Schedule API와 동기화 (백그라운드)
  Future<void> _syncSchedulesWithAPI() async {
    try {
      // API 호출 시도 (인증 실패 시 무시)
      final schedules = await _scheduleRepository.getAllSchedules();
      
      // API 데이터가 있으면 병합
      if (schedules.isNotEmpty) {
        _setSchedules(schedules);
      }
    } catch (e) {
      // API 실패는 무시 (비회원이거나 네트워크 오류)
      print('Schedule API 동기화 건너뜀: $e');
    }
  }
  
  // 날짜별 Schedule API 동기화 (백그라운드)
  Future<void> _syncSchedulesByDateWithAPI(DateTime date) async {
    try {
      final schedules = await _scheduleRepository.getSchedulesByDate(date);
      if (schedules.isNotEmpty) {
        _setSchedules(schedules);
      }
    } catch (e) {
      print('Schedule API 날짜별 동기화 건너뜀: $e');
    }
  }
  
  // 기간별 Schedule API 동기화 (백그라운드)
  Future<void> _syncSchedulesByRangeWithAPI(DateTime from, DateTime to) async {
    try {
      final schedules = await _scheduleRepository.getSchedulesByRange(from, to);
      if (schedules.isNotEmpty) {
        _setSchedules(schedules);
      }
    } catch (e) {
      print('Schedule API 기간별 동기화 건너뜀: $e');
    }
  }
  
  // 백그라운드에서 Schedule 생성
  Future<void> _createScheduleInBackground(ScheduleModel schedule) async {
    try {
      await _scheduleRepository.createSchedule(schedule);
    } catch (e) {
      // API 실패는 무시
      print('Schedule API 생성 건너뜀: $e');
    }
  }
  
  // 백그라운드에서 Schedule 수정
  Future<void> _updateScheduleInBackground(int scheduleId, ScheduleModel schedule) async {
    try {
      await _scheduleRepository.updateSchedule(scheduleId, schedule);
    } catch (e) {
      // API 실패는 무시
      print('Schedule API 수정 건너뜀: $e');
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
  
  // ===== 알림 관련 메서드 =====
  
  // 일정 알림 설정
  Future<void> _setScheduleAlarms({
    required String taskId,
    required String title,
    required DateTime startDate,
    bool alarm30Before = false,
    bool alarm60Before = false,
    bool alarm120Before = false,
  }) async {
    try {
      // taskId를 숫자로 변환 (알림 ID 생성용)
      final baseId = taskId.hashCode.abs() % 1000000;
      
      // 30분 전 알림
      if (alarm30Before) {
        final alarmTime = startDate.subtract(const Duration(minutes: 30));
        if (alarmTime.isAfter(DateTime.now())) {
          final alarmId = baseId * 10 + 0; // 30분전 = 0
          await AlarmUtility.setAlarm(
            id: alarmId,
            scheduledTime: alarmTime,
            title: '일정 알림',
            body: '30분 후 "$title" 일정이 있습니다.',
          );
        }
      }
      
      // 1시간 전 알림
      if (alarm60Before) {
        final alarmTime = startDate.subtract(const Duration(hours: 1));
        if (alarmTime.isAfter(DateTime.now())) {
          final alarmId = baseId * 10 + 1; // 1시간전 = 1
          await AlarmUtility.setAlarm(
            id: alarmId,
            scheduledTime: alarmTime,
            title: '일정 알림',
            body: '1시간 후 "$title" 일정이 있습니다.',
          );
        }
      }
      
      // 2시간 전 알림
      if (alarm120Before) {
        final alarmTime = startDate.subtract(const Duration(hours: 2));
        if (alarmTime.isAfter(DateTime.now())) {
          final alarmId = baseId * 10 + 2; // 2시간전 = 2
          await AlarmUtility.setAlarm(
            id: alarmId,
            scheduledTime: alarmTime,
            title: '일정 알림',
            body: '2시간 후 "$title" 일정이 있습니다.',
          );
        }
      }
    } catch (e) {
      print('일정 알림 설정 중 오류: $e');
    }
  }
  
  // 일정 알림 취소
  Future<void> _cancelScheduleAlarms(String taskId) async {
    try {
      final baseId = taskId.hashCode.abs() % 1000000;
      
      // 모든 가능한 알림 취소 (30분전, 1시간전, 2시간전)
      for (int i = 0; i < 3; i++) {
        final alarmId = baseId * 10 + i;
        await AlarmUtility.cancelAlarm(alarmId);
      }
    } catch (e) {
      print('일정 알림 취소 중 오류: $e');
    }
  }
}