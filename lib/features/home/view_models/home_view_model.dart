import 'package:flutter/material.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/repositories/focus_session_repository.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/schedule_model.dart';
import '../../../api/mainpage_api.dart';
import '../../../api/token_manager.dart';
import '../../../utils/alarm.dart';

class HomeViewModel with ChangeNotifier {
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  final TaskRepository _taskRepository = TaskRepository(); // 로컬 저장용 유지

  // 생성자
  HomeViewModel() {
    // Repository 변경사항 구독
    _taskRepository.addListener(_onRepositoryChanged);
    // Schedule API에서 데이터 로드
    loadTasks();
  }

  // API 동기화 관련 플래그
  bool _syncEnabled = true;
  bool _syncInProgress = false; // 동기화 진행 중 플래그
  DateTime? _lastSyncAttempt; // 마지막 동기화 시도 시간

  @override
  void dispose() {
    _taskRepository.removeListener(_onRepositoryChanged);
    super.dispose();
  }

  // Repository 변경사항 감지 시 UI 업데이트
  void _onRepositoryChanged() {
    print('[HomeViewModel] Repository 변경 감지');
    print('[HomeViewModel] 현재 tasks 수: ${_taskRepository.tasks.length}');
    for (var task in _taskRepository.tasks) {
      print('[HomeViewModel] Task - ID: ${task.id}, Title: ${task.title}');
    }

    // 로컬 데이터만 업데이트 (API 동기화 제외)
    _setTasks(_taskRepository.tasks);
    // 홈화면 요약 정보도 다시 계산
    loadTodaySummary();
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
      if (task.isRecurring &&
          task.startDateRange != null &&
          task.endDateRange != null) {
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
          final startDateOnly = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          );
          final endDateOnly = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
          );
          shouldInclude =
              !today.isBefore(startDateOnly) && !today.isAfter(endDateOnly);
        }
      } else {
        // 일반 일정인 경우: 여러 날에 걸친 일정도 처리
        final startDate = task.startDate;
        final endDate = task.dueDate;

        if (startDate != null && endDate != null) {
          // 시작일과 종료일이 모두 있는 경우
          final startDateOnly = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          );
          final endDateOnly = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
          );

          // 오늘이 일정 기간 내에 있는지 확인
          shouldInclude =
              !today.isBefore(startDateOnly) && !today.isAfter(endDateOnly);
        } else if (startDate != null) {
          // 시작일만 있는 경우
          final startDateOnly = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          );
          shouldInclude = _isSameDay(startDateOnly, today);
        } else if (endDate != null) {
          // 종료일만 있는 경우
          final endDateOnly = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
          );
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

    // 이모티콘 변환 (아이콘 코드를 이모티콘으로)
    final emoji = _convertIconCodeToEmoji(schedule.image ?? '📅');

    return TaskModel(
      id:
          schedule.scheduleId?.toString() ??
          'temp_${DateTime.now().millisecondsSinceEpoch}',
      title: schedule.title,
      memo: schedule.memo,
      location: schedule.location,
      priority: priority,
      alarm:
          schedule.alarm30Before ||
          schedule.alarm60Before ||
          schedule.alarm120Before,
      alarm30Before: schedule.alarm30Before,
      alarm60Before: schedule.alarm60Before,
      alarm120Before: schedule.alarm120Before,
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
      emoji: emoji,
    );
  }

  // TaskPriority를 ScheduleType으로 변환
  ScheduleType _priorityToScheduleType(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgentImportant:
        return ScheduleType.urgentNow; // 중요&긴급 → 지금 바로 해야해요
      case TaskPriority.important:
        return ScheduleType.planAhead; // 중요 → 미리 계획해서 준비해요
      case TaskPriority.urgent:
        return ScheduleType.laterProcessing; // 긴급 → 나중에 처리해요
      case TaskPriority.neither:
        return ScheduleType.whenFree; // 둘다 아님 → 시간이 남을 때 해요
    }
  }

  // ScheduleType을 TaskPriority로 변환
  TaskPriority _scheduleTypeToPriority(ScheduleType type) {
    switch (type) {
      case ScheduleType.urgentNow:
        return TaskPriority.urgentImportant; // 지금 바로 해야해요 → 중요&긴급
      case ScheduleType.planAhead:
        return TaskPriority.important; // 미리 계획해서 준비해요 → 중요
      case ScheduleType.laterProcessing:
        return TaskPriority.urgent; // 나중에 처리해요 → 긴급
      case ScheduleType.whenFree:
        return TaskPriority.neither; // 시간이 남을 때 해요 → 둘다 아님
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

      // 비회원 모드 확인
      final isGuest = await TokenManager.instance.isGuestMode();
      
      // 회원인 경우만 API 동기화
      if (!isGuest && _syncEnabled && !_syncInProgress) {
        print('[HomeViewModel] API 동기화 시작 예정');
        _syncWithScheduleAPI();
      } else {
        print('[HomeViewModel] API 동기화 스킵 - isGuest: $isGuest, syncEnabled: $_syncEnabled, syncInProgress: $_syncInProgress');
      }
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
          final startDateOnly = DateTime(
            task.startDate!.year,
            task.startDate!.month,
            task.startDate!.day,
          );
          final endDateOnly = DateTime(
            task.dueDate!.year,
            task.dueDate!.month,
            task.dueDate!.day,
          );
          return !today.isBefore(startDateOnly) && !today.isAfter(endDateOnly);
        }
        return false;
      }).toList();

      final urgentImportantCount = todayTasks
          .where((t) => t.priority == TaskPriority.urgentImportant)
          .length;
      final importantCount = todayTasks
          .where((t) => t.priority == TaskPriority.important)
          .length;
      final urgentCount = todayTasks
          .where((t) => t.priority == TaskPriority.urgent)
          .length;
      final neitherCount = todayTasks
          .where((t) => t.priority == TaskPriority.neither)
          .length;
      final completedCount = todayTasks.where((t) => t.isCompleted).length;

      // 로컬 요약 데이터 생성
      _todaySummary = {
        'success': true,
        'data': {
          'todayDate':
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
          'totalTasks': todayTasks.length,
          'completedTasks': completedCount,
          'urgentImportantCount': urgentImportantCount,
          'importantCount': importantCount,
          'urgentCount': urgentCount,
          'neitherCount': neitherCount,
          'todayFocusMinutes': 0,
          'weeklyFocusMinutes': 0,
        },
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
    // 비회원 모드에서는 API 동기화 비활성화
    final isGuest = await TokenManager.instance.isGuestMode();
    if (isGuest) {
      print('[HomeViewModel] 비회원 모드 - API 동기화 스킵');
      return;
    }
    
    // 동기화 중복 방지
    if (_syncInProgress) {
      print('[HomeViewModel] API 동기화 이미 진화 중 - 스킵');
      return;
    }
    
    // debounce - 1초 이내 재호출 방지
    if (_lastSyncAttempt != null) {
      final timeSinceLastSync = DateTime.now().difference(_lastSyncAttempt!);
      if (timeSinceLastSync.inSeconds < 1) {
        print('[HomeViewModel] API 동기화 너무 빈번함 - 스킵');
        return;
      }
    }
    
    _syncInProgress = true;
    _lastSyncAttempt = DateTime.now();
    
    try {
      print('[HomeViewModel] API 동기화 시작');
      // API 호출 시도 (인증 실패 시 무시)
      final schedules = await _scheduleRepository.getAllSchedules();
      print('[HomeViewModel] API에서 받은 schedules 수: ${schedules.length}');

      // API 데이터가 있으면 병합
      if (schedules.isNotEmpty) {
        final apiTasks = schedules
            .map((schedule) => _scheduleToTask(schedule))
            .toList();
        print('[HomeViewModel] 변환된 API tasks 수: ${apiTasks.length}');

        // scheduleId 기반으로 중복 제거
        final taskMap = <int, TaskModel>{}; // scheduleId를 키로 사용
        final localOnlyTasks = <TaskModel>[]; // 로컬 전용 tasks (task_xxx ID)
        
        // 먼저 API 데이터 추가 (서버 데이터 우선)
        print('[HomeViewModel] API tasks 추가 중...');
        for (final apiTask in apiTasks) {
          final scheduleId = int.tryParse(apiTask.id);
          if (scheduleId != null && scheduleId < 0) {
            // 음수 ID는 서버 scheduleId
            taskMap[scheduleId] = apiTask;
            print(
              '[HomeViewModel] API Task 추가 - scheduleId: $scheduleId, Title: ${apiTask.title}',
            );
          }
        }
        
        // 로컬 데이터 확인 (이미 API에 있는 건 제외)
        print('[HomeViewModel] 로컬 tasks 확인 중...');
        for (final task in _tasks) {
          if (task.id.startsWith('task_')) {
            // 로컬 전용 task (아직 서버에 없음)
            localOnlyTasks.add(task);
            print(
              '[HomeViewModel] 로컬 전용 Task - ID: ${task.id}, Title: ${task.title}',
            );
          } else {
            // scheduleId가 있는 task - API 데이터가 우선
            final scheduleId = int.tryParse(task.id);
            if (scheduleId != null && !taskMap.containsKey(scheduleId)) {
              // API에 없는 경우만 추가 (삭제된 일정일 수 있음)
              print(
                '[HomeViewModel] 로컬 Task (API에 없음) - scheduleId: $scheduleId, Title: ${task.title}',
              );
            }
          }
        }

        // 병합: API 데이터 + 로컬 전용 데이터
        final mergedTasks = [...taskMap.values, ...localOnlyTasks];
        print('[HomeViewModel] 최종 병합된 tasks 수: ${mergedTasks.length}');
        
        // 리스너 일시 해제 후 업데이트
        _taskRepository.removeListener(_onRepositoryChanged);
        _setTasks(mergedTasks);
        
        // 로컬 저장소도 업데이트
        await _taskRepository.clearAllTasks();
        for (final task in mergedTasks) {
          await _taskRepository.addTask(task);
        }
        
        _taskRepository.addListener(_onRepositoryChanged);
      }
    } catch (e) {
      // API 실패는 무시 (비회원이거나 네트워크 오류)
      print('[HomeViewModel] Schedule API 동기화 실패: $e');
    } finally {
      _syncInProgress = false;
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

      // Schedule API 먼저 시도 (회원인 경우)
      String taskId = 'task_${DateTime.now().millisecondsSinceEpoch}';
      
      try {
        final type = _priorityToScheduleType(priority);
        final schedule = ScheduleModel(
          title: title,
          time: dueDate != null
              ? '${dueDate.hour.toString().padLeft(2, '0')}:${dueDate.minute.toString().padLeft(2, '0')}'
              : null,
          startDate: _formatDate(dueDate ?? DateTime.now()),
          endDate: _formatDate(dueDate ?? DateTime.now()),
          type: type.value,
          location: null,
          memo: description,
          image: '📅',
          alarm30Before: false,
          alarm60Before: false,
          alarm120Before: false,
          isRecurring: false,
        );

        // API 호출하고 scheduleId 받기
        final scheduleId = await _scheduleRepository.createSchedule(schedule);
        // API 성공하면 음수 ID 사용
        taskId = scheduleId.toString();
        print('[HomeViewModel] Schedule API 생성 성공 - scheduleId: $scheduleId');
      } catch (e) {
        // API 실패 시 로컬 ID 유지
        print('[HomeViewModel] Schedule API 생성 실패, 로컬 ID 사용: $e');
      }

      // 로컬에 저장 (API ID 또는 로컬 ID 사용)
      final task = TaskModel(
        id: taskId,
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
      // 알림 취소
      await _cancelScheduleAlarms(taskId);

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
      print(
        '[HomeViewModel] updateTask 시작 - ID: ${updatedTask.id}, Title: ${updatedTask.title}',
      );

      // 기존 task를 먼저 가져와서 제목 변경 여부 확인
      final oldTask = getTaskById(updatedTask.id);
      final titleChanged =
          oldTask != null && oldTask.title != updatedTask.title;
      final oldTitle = oldTask?.title ?? '';
      print('[HomeViewModel] 기존 task - Title: $oldTitle, 변경됨: $titleChanged');

      // 리스너 일시 해제 (중복 업데이트 방지)
      _taskRepository.removeListener(_onRepositoryChanged);

      // 로컬에서 수정
      await _taskRepository.updateTask(updatedTask);
      print('[HomeViewModel] Repository updateTask 완료');

      // 수동으로 현재 데이터 업데이트 (중복 없이)
      _setTasks(_taskRepository.tasks);

      // 리스너 다시 추가
      _taskRepository.addListener(_onRepositoryChanged);

      // 제목이 변경되었다면 focus session의 제목도 업데이트
      if (titleChanged && oldTitle.isNotEmpty) {
        final focusRepository = FocusSessionRepository();
        await focusRepository.loadSessionsFromStorage();
        await focusRepository.updateSessionTaskTitle(
          oldTitle,
          updatedTask.title,
        );
      }

      // 백그라운드에서 Schedule API 시도 (회원인 경우)
      final isGuest = await TokenManager.instance.isGuestMode();
      if (!isGuest) {
        final scheduleId = int.tryParse(updatedTask.id);
        if (scheduleId != null && scheduleId < 0) { // 음수 ID만 API 업데이트
          print('[HomeViewModel] 백그라운드 API 업데이트 시작 - scheduleId: $scheduleId');
          // API 업데이트 후 동기화 방지
          _syncEnabled = false;
          await _updateScheduleInBackground(scheduleId, updatedTask);
          // 3초 후 동기화 다시 활성화
          Future.delayed(Duration(seconds: 3), () {
            _syncEnabled = true;
            _lastSyncAttempt = null; // 다음 동기화 허용
          });
        }
      } else {
        print('[HomeViewModel] 비회원 모드 - API 업데이트 스킵');
      }

      // 홈화면 요약 정보 업데이트
      await loadTodaySummary();
      print('[HomeViewModel] updateTask 완료');
      return true;
    } catch (e) {
      print('[HomeViewModel] updateTask 실패: $e');
      // 에러 발생 시에도 리스너 복원
      _taskRepository.addListener(_onRepositoryChanged);
      _setError('할일 수정 중 오류가 발생했습니다');
      return false;
    }
  }

  // 백그라운드에서 Schedule 수정
  Future<void> _updateScheduleInBackground(
    int scheduleId,
    TaskModel task,
  ) async {
    try {
      final type = _priorityToScheduleType(task.priority);
      final schedule = ScheduleModel(
        scheduleId: scheduleId,
        title: task.title,
        time: task.startTime,
        startDate:
            task.calendarDate ?? _formatDate(task.startDate ?? DateTime.now()),
        endDate:
            task.calendarDate ?? _formatDate(task.dueDate ?? DateTime.now()),
        type: type.value,
        location: task.location,
        memo: task.memo ?? task.description,
        image: task.icon ?? task.emoji ?? '📅',
        alarm30Before: task.alarm30Before ?? task.alarm,
        alarm60Before: task.alarm60Before ?? false,
        alarm120Before: task.alarm120Before ?? false,
        isRecurring: task.isRecurring,
      );

      print('[HomeViewModel] API 업데이트 시작');
      await _scheduleRepository.updateSchedule(scheduleId.abs(), schedule); // 양수로 변환하여 API 호출
      print('[HomeViewModel] API 업데이트 완료');
    } catch (e) {
      // API 실패는 무시
      print('[HomeViewModel] Schedule API 수정 실패: $e');
    }
  }

  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // 아이콘 코드를 이모티콘으로 변환
  String _convertIconCodeToEmoji(String? iconCode) {
    if (iconCode == null || iconCode.isEmpty) return '😊';

    // 이미 이모티콘인 경우 그대로 반환
    if (iconCode.contains(RegExp(r'[^\x00-\x7F]'))) {
      return iconCode;
    }

    // 아이콘 코드를 이모티콘으로 매핑
    final iconToEmojiMap = {
      'SMILE': '😀',
      'HAPPY': '😃',
      'JOY': '😄',
      'GRIN': '😁',
      'LAUGH': '😆',
      'TOUCHED': '🥹',
      'SWEAT': '😅',
      'CRY_LAUGH': '😂',
      'ROFL': '🤣',
      'TEAR_JOY': '🥲',
      'BLUSH': '☺️',
      'HAPPY_EYES': '😊',
      'SLIGHT_SMILE': '🙂',
      'HEART_EYES': '😍',
      'LOVE': '🥰',
      'KISS': '😘',
      'KISS_SMILE': '😙',
      'KISS_EYES': '😚',
      'YUM': '😋',
      'TONGUE': '😝',
      'RAISED_EYEBROW': '🤨',
      'NERD': '🤓',
      'COOL': '😎',
      'SMIRK': '😏',
      'PARTY': '🥳',
      'WORRIED': '😟',
      'CONFOUNDED': '😖',
      'TIRED': '😫',
      'PLEADING': '🥺',
      'ANGRY': '😡',
      'SICK': '🤒',
      'MELT': '😄',
      'SCREAM': '😱',
      'GASP': '🤭',
      'SLEEPY': '😪',
      'SURPRISE': '😮',
      'THUMBS_UP': '👍',
      'THUMBS_DOWN': '👎',
      'PRAY': '🙏',
      'POINT': '👊',
      'SOCCER': '⚽',
      'ART': '🎨',
      'TICKET': '🎟️',
      'PUZZLE': '🧩',
      'MIC': '🎤',
      'MOVIE': '🎬',
      'COMPUTER': '🖥️',
      'IDEA': '💡',
      'ALARM': '⏰',
      'PILL': '💊',
      'BATH': '🛁',
      'TISSUE': '🧻',
      'BIKE': '🚴‍♂️',
      'GAME': '🎮',
      'APPLE': '🍎',
      'SALAD': '🥗',
      'HEART': '❤️',
      'BOMB': '💣',
      'PARTY_POPPER': '🎉',
      'CLOVER': '🍀',
      'MOON': '🌙',
      'DOG': '🐶',
      'MUSCLE': '💪',
      'TENNIS': '🎾',
      'RUN': '🏃',
      'FLAG': '🚩',
      'YARN': '🧶',
      'FIRE': '🔥',
      'BRIEFCASE': '💼',
      'DINNER': '🍽️',
      'COFFEE': '☕',
      'TOOTHBRUSH': '🪥',
      'CAR': '🚗',
      'HOSPITAL': '🏥',
      'PHONE': '📱',
      'NOTE': '📅',
    };

    return iconToEmojiMap[iconCode] ?? '😊';
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
        return const Color(0xFFE53E3E); // 빨간색 - 지금 바로 해야해요
      case TaskPriority.important:
        return const Color(0xFF3182CE); // 파란색 - 미리 계획해서 준비해요
      case TaskPriority.urgent:
        return const Color(0xFFD69E2E); // 노란색 - 나중에 처리해요
      case TaskPriority.neither:
        return const Color(0xFF74787B); // 회색 - 시간이 남을 때 해요
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
    // 로컬 데이터 다시 로드
    await _taskRepository.loadTasksFromStorage();
    _setTasks(_taskRepository.tasks);
    // 홈화면 요약 정보 업데이트
    await loadTodaySummary();
    // 백그라운드에서 API 동기화
    _syncWithScheduleAPI();
  }

  // ===== 알림 관련 메서드 =====

  // 시간 포맷팅 함수 (오전/오후)
  String _formatTimeToKorean(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$period ${displayHour.toString()}:${minute.toString().padLeft(2, '0')}';
  }

  // 우선순위별 알림 텍스트 가져오기
  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgentImportant:
        return '지금 바로 해야해요'; // 중요&긴급
      case TaskPriority.important:
        return '미리 계획해서 준비해요'; // 중요
      case TaskPriority.urgent:
        return '나중에 처리해요'; // 긴급
      case TaskPriority.neither:
        return '시간이 남을 때 해요'; // 둘다 아님
    }
  }

  // 사용자 이름 가져오기
  Future<String> _getUserName() async {
    try {
      final username = await TokenManager.instance.getUsername();
      if (username != null && username.isNotEmpty) {
        return username;
      }
    } catch (e) {
      print('사용자 이름 가져오기 실패: $e');
    }
    return '구름'; // 기본값 (비회원)
  }

  // 일정 알림 설정
  Future<void> _setScheduleAlarms({
    required String taskId,
    required String title,
    required DateTime startDate,
    required TaskPriority priority,
    bool alarm30Before = false,
    bool alarm60Before = false,
    bool alarm120Before = false,
  }) async {
    try {
      // taskId를 숫자로 변환 (알림 ID 생성용)
      final baseId = taskId.hashCode.abs() % 1000000;

      // 사용자 이름 가져오기
      final userName = await _getUserName();

      // 일정 시작 시간 포맷
      final formattedTime = _formatTimeToKorean(startDate);

      // 우선순위 텍스트 가져오기
      final priorityText = _getPriorityText(priority);

      // 30분 전 알림
      if (alarm30Before) {
        final alarmTime = startDate.subtract(const Duration(minutes: 30));
        if (alarmTime.isAfter(DateTime.now())) {
          final alarmId = baseId * 10 + 0; // 30분전 = 0
          await AlarmUtility.setAlarm(
            id: alarmId,
            scheduledTime: alarmTime,
            title: '$userName님 $title 30분전이에요!',
            body: '$formattedTime $priorityText',
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
            title: '$userName님 $title 1시간전이에요!',
            body: '$formattedTime $priorityText',
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
            title: '$userName님 $title 2시간전이에요!',
            body: '$formattedTime $priorityText',
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
      final titleChanged =
          oldTask != null && oldTask.title != updatedTask.title;
      final oldTitle = oldTask?.title ?? '';

      // 리스너 일시 해제 (중복 업데이트 방지)
      _taskRepository.removeListener(_onRepositoryChanged);

      // 로컬에서 수정
      await _taskRepository.updateTask(updatedTask);

      // 수동으로 현재 데이터 업데이트 (중복 없이)
      _setTasks(_taskRepository.tasks);

      // 리스너 다시 추가
      _taskRepository.addListener(_onRepositoryChanged);

      // 제목이 변경되었다면 focus session의 제목도 업데이트
      if (titleChanged && oldTitle.isNotEmpty) {
        final focusRepository = FocusSessionRepository();
        await focusRepository.loadSessionsFromStorage();
        await focusRepository.updateSessionTaskTitle(
          oldTitle,
          updatedTask.title,
        );
      }

      // 기존 알림 취소 후 새로 설정
      await _cancelScheduleAlarms(updatedTask.id);
      if (updatedTask.alarm && updatedTask.startDate != null) {
        await _setScheduleAlarms(
          taskId: updatedTask.id,
          title: updatedTask.title,
          startDate: updatedTask.startDate!,
          priority: updatedTask.priority,
          alarm30Before: alarm30Before,
          alarm60Before: alarm60Before,
          alarm120Before: alarm120Before,
        );
      }

      // 백그라운드에서 Schedule API 시도 (회원인 경우)
      final isGuest = await TokenManager.instance.isGuestMode();
      if (!isGuest) {
        final scheduleId = int.tryParse(updatedTask.id);
        if (scheduleId != null && scheduleId < 0) { // 음수 ID만 API 업데이트
          print('[HomeViewModel] 백그라운드 API 업데이트 시작 - scheduleId: $scheduleId');
          // API 업데이트 후 동기화 방지
          _syncEnabled = false;
          await _updateScheduleInBackground(scheduleId, updatedTask);
          // 3초 후 동기화 다시 활성화
          Future.delayed(Duration(seconds: 3), () {
            _syncEnabled = true;
            _lastSyncAttempt = null; // 다음 동기화 허용
          });
        }
      } else {
        print('[HomeViewModel] 비회원 모드 - API 업데이트 스킵');
      }

      // 홈화면 요약 정보 업데이트
      await loadTodaySummary();
      return true;
    } catch (e) {
      // 에러 발생 시에도 리스너 복원
      _taskRepository.addListener(_onRepositoryChanged);
      _setError('할일 수정 중 오류가 발생했습니다');
      return false;
    }
  }
}
