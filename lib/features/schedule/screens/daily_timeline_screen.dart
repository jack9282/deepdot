import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/theme/app_theme.dart';
import '../../../data/models/task_model.dart';
import '../view_models/schedule_view_model.dart';
import 'task_add_screen.dart';

class DailyTimelineScreen extends StatefulWidget {
  final TaskPriority? priority;
  final String title;

  const DailyTimelineScreen({
    super.key,
    this.priority,
    required this.title,
  });

  @override
  State<DailyTimelineScreen> createState() => _DailyTimelineScreenState();
}

class _DailyTimelineScreenState extends State<DailyTimelineScreen> {
  late ScheduleViewModel _viewModel;
  DateTime _selectedDate = DateTime.now();
  DateTime _baseDate = DateTime.now(); // 7일 주간 표시의 기준 날짜
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _viewModel = ScheduleViewModel();
    _loadTasks();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _loadTasks() {
    if (widget.priority != null) {
      _viewModel.loadTasksByPriority(widget.priority!);
    } else {
      _viewModel.loadAllTasks();
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgentImportant:
        return AppTheme.urgentImportantColor;
      case TaskPriority.important:
        return AppTheme.importantColor;
      case TaskPriority.urgent:
        return AppTheme.urgentColor;
      case TaskPriority.neither:
        return AppTheme.neitherColor;
    }
  }

  String _getTimeString(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ScheduleViewModel>(
      create: (_) => _viewModel,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: const Text(
            '일정',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.add,
                color: Colors.black,
              ),
              onPressed: () {
                // 일정 추가 화면으로 이동
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TaskAddScreen(
                      priority: TaskPriority.urgentImportant, // 기본 우선순위
                    ),
                  ),
                ).then((result) {
                  if (result == true) {
                    // 일정 추가 성공 시 화면 새로고침
                    _loadTasks();
                  }
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // 월/년 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${_baseDate.year}년 ${_baseDate.month}월',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // 날짜 선택 헤더 (현재 날짜 중심으로 ±3일)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // 왼쪽 화살표
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _baseDate = _baseDate.subtract(const Duration(days: 7));
                      });
                    },
                    icon: const Icon(Icons.chevron_left, color: AppTheme.primaryColor, size: 28),
                  ),
                  
                  // 날짜들 (과거 3일 + 현재 + 미래 3일)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(7, (index) {
                        // 기준 날짜를 중심으로 -3, -2, -1, 0, +1, +2, +3일
                        final date = _baseDate.add(Duration(days: index - 3));
                        final isSelected = _isSameDay(date, _selectedDate);
                        final isToday = _isSameDay(date, DateTime.now());
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = date;
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 요일 표시
                              Text(
                                _getWeekdayText(date.weekday),
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              // 날짜 표시
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? AppTheme.primaryColor 
                                      : isToday 
                                          ? AppTheme.primaryColor.withOpacity(0.1)
                                          : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: isToday && !isSelected 
                                      ? Border.all(color: AppTheme.primaryColor, width: 2)
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    date.day.toString(),
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected 
                                          ? Colors.white 
                                          : isToday 
                                              ? AppTheme.primaryColor
                                              : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  
                  // 오른쪽 화살표
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _baseDate = _baseDate.add(const Duration(days: 7));
                      });
                    },
                    icon: const Icon(Icons.chevron_right, color: AppTheme.primaryColor, size: 28),
                  ),
                ],
              ),
            ),
            
            // 타임라인 뷰
            Expanded(
              child: Consumer<ScheduleViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    );
                  }

                  final tasks = viewModel.filteredTasks
                      .where((task) {
                        // 시작시간이 있으면 시작시간 기준, 없으면 종료시간 기준으로 필터링
                        final dateToCheck = task.startDate ?? task.dueDate;
                        return dateToCheck != null && _isSameDay(dateToCheck, _selectedDate);
                      })
                      .toList();
                  
                  // 시작시간 기준으로 정렬 (시작시간이 없으면 종료시간 기준)
                  tasks.sort((a, b) {
                    final timeA = a.startDate ?? a.dueDate ?? DateTime.now();
                    final timeB = b.startDate ?? b.dueDate ?? DateTime.now();
                    return timeA.compareTo(timeB);
                  });

                  if (tasks.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 64,
                            color: AppTheme.textSecondaryColor,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '이 날에는 일정이 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final isLast = index == tasks.length - 1;
                      
                      return _buildTimelineItem(task, isLast, viewModel);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(TaskModel task, bool isLast, ScheduleViewModel viewModel) {
    final priorityColor = _getPriorityColor(task.priority);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 시간 표시 (시작 시간 기준)
          SizedBox(
            width: 80,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                task.startDate != null 
                    ? _getTimeString(task.startDate!)
                    : _getTimeString(task.dueDate ?? DateTime.now()),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          
          // 타임라인 라인과 아이콘
          Column(
            children: [
              // 아이콘이 포함된 타임라인 점
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 아이콘 (이모지 또는 아이콘)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: priorityColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getTaskIcon(task),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 연결선
              if (!isLast)
                Container(
                  width: 2,
                  height: 20,
                  color: Colors.grey[300],
                ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // 일정 카드
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 시간 범위 (시작시간 ~ 종료시간)
                      Text(
                        _getTimeRangeString(task),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      // 완료 체크박스
                      GestureDetector(
                        onTap: () {
                          viewModel.toggleTaskCompletion(task.id);
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: task.isCompleted ? Colors.green : Colors.transparent,
                            border: Border.all(
                              color: task.isCompleted ? Colors.green : Colors.grey[400]!,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: task.isCompleted
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 제목
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: task.isCompleted 
                          ? Colors.grey[500]
                          : Colors.black,
                      decoration: task.isCompleted 
                          ? TextDecoration.lineThrough 
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 재생 버튼
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      // 더보기 메뉴
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_horiz,
                          size: 20,
                          color: Colors.grey,
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TaskAddScreen(
                                  priority: task.priority,
                                  taskToEdit: task,
                                ),
                              ),
                            ).then((result) {
                              if (result == true) {
                                viewModel.refresh();
                              }
                            });
                          } else if (value == 'delete') {
                            _showDeleteConfirmDialog(context, task, viewModel);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('일정 수정'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('일정 삭제'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTaskIcon(TaskModel task) {
    // 우선순위에 따른 아이콘 반환
    switch (task.priority) {
      case TaskPriority.urgentImportant:
        return '🐰';
      case TaskPriority.important:
        return '👨‍💼';
      case TaskPriority.urgent:
        return '✏️';
      case TaskPriority.neither:
        return '⚫';
    }
  }



  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  void _showDeleteConfirmDialog(BuildContext context, TaskModel task, ScheduleViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('일정 삭제'),
          content: Text('\'${task.title}\' 일정을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                viewModel.deleteTask(task.id);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  String _getWeekdayText(int weekday) {
    switch (weekday) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '';
    }
  }

  String _getTimeRangeString(TaskModel task) {
    final startTime = task.startDate;
    final endTime = task.dueDate;
    
    if (startTime != null && endTime != null) {
      // 시작시간과 종료시간이 모두 있는 경우
      final duration = endTime.difference(startTime);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      
      String durationText = '';
      if (hours > 0 && minutes > 0) {
        durationText = '(${hours}시간 ${minutes}분)';
      } else if (hours > 0) {
        durationText = '(${hours}시간)';
      } else if (minutes > 0) {
        durationText = '(${minutes}분)';
      }
      
      return '${_getTimeString(startTime)} ~ ${_getTimeString(endTime)} $durationText';
    } else if (startTime != null) {
      // 시작시간만 있는 경우
      return '${_getTimeString(startTime)} ~';
    } else if (endTime != null) {
      // 종료시간만 있는 경우 (기존 데이터 호환)
      return '~ ${_getTimeString(endTime)}';
    } else {
      // 둘 다 없는 경우
      return '시간 미정';
    }
  }
}