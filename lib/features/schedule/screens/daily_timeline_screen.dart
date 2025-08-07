import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/theme/app_theme.dart';
import '../../../data/models/task_model.dart';
import '../view_models/schedule_view_model.dart';
import 'schedule_add_screen.dart';
import 'schedule_timer_screen.dart';

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
  DateTime _selectedDate = DateTime.now();
  DateTime _baseDate = DateTime.now(); // 7일 주간 표시의 기준 날짜
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadTasks(ScheduleViewModel viewModel) {
    if (widget.priority != null) {
      viewModel.loadTasksByPriority(widget.priority!);
    } else {
      viewModel.loadAllTasks();
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgentImportant:
        return const Color(0xFFFF4C4C); // 홈화면과 동일한 빨간색
      case TaskPriority.important:
        return const Color(0xFF1F5DFF); // 홈화면과 동일한 파란색
      case TaskPriority.urgent:
        return const Color(0xFFFFBC4C); // 홈화면과 동일한 주황색
      case TaskPriority.neither:
        return const Color(0xFF74787B); // 홈화면과 동일한 회색
    }
  }

  Color _getPriorityBackgroundColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgentImportant:
        return const Color(0xFFFFD6D6); // 홈화면과 동일한 연한 빨간색
      case TaskPriority.important:
        return const Color(0xFFE0E9FF); // 홈화면과 동일한 연한 파란색
      case TaskPriority.urgent:
        return const Color(0xFFFFF6C4); // 홈화면과 동일한 연한 노란색
      case TaskPriority.neither:
        return const Color(0xFFFFFFFF); // 홈화면과 동일한 흰색
    }
  }

  String _getTimeString(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getTimeStringWithAmPm(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    String amPm = hour < 12 ? '오전' : '오후';
    int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '$amPm ${displayHour.toString().padLeft(2, '0')}:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    builder: (context) => ScheduleAddScreen(
                      priority: TaskPriority.urgentImportant, // 기본 우선순위
                    ),
                  ),
                ).then((result) {
                  if (result == true) {
                    // 일정 추가 성공 시 화면 새로고침
                    final viewModel = Provider.of<ScheduleViewModel>(context, listen: false);
                    viewModel.refresh();
                  }
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
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
            
            // 날짜 선택 영역과 타임라인 사이의 구분선
            Container(
              height: 1,
              color: Colors.grey.withOpacity(0.1),
            ),
            
            // 타임라인 뷰
            Expanded(
              child: Consumer<ScheduleViewModel>(
                builder: (context, viewModel, child) {
                  // 초기 로딩 (빌드 완료 후 수행)
                  if (viewModel.tasks.isEmpty && !viewModel.isLoading) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _loadTasks(viewModel);
                    });
                  }
                  
                  if (viewModel.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    );
                  }

                  final tasks = viewModel.filteredTasks
                      .where((task) {
                        // 반복 일정인 경우 해당 날짜에 맞는 일정만 표시
                        if (task.isRecurring && task.startDateRange != null && task.endDateRange != null) {
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
                          final selectedDate = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
                          );
                          
                          // 선택된 날짜가 범위 내에 있는지 확인
                          if (!selectedDate.isBefore(startRange) && !selectedDate.isAfter(endRange)) {
                            // 반복 일정의 실제 시작 시간이 선택된 날짜와 일치하는지 확인
                            if (task.startDate != null) {
                              final taskDate = DateTime(
                                task.startDate!.year,
                                task.startDate!.month,
                                task.startDate!.day,
                              );
                              return _isSameDay(taskDate, _selectedDate);
                            }
                            return false;
                          }
                          return false;
                        }
                        
                        // 일반 일정인 경우 시작시간이 있으면 시작시간 기준, 없으면 종료시간 기준으로 필터링
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
                       
                       return _buildTimelineItem(task, isLast, viewModel, tasks);
                     },
                   );
                },
              ),
            ),
          ],
        ),
      );
  }

     Widget _buildTimelineItem(TaskModel task, bool isLast, ScheduleViewModel viewModel, List<TaskModel> allTasks) {
     final priorityColor = _getPriorityColor(task.priority);
     
           return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // 중앙 정렬로 변경
          children: [
                         // 타임라인 라인과 아이콘
             SizedBox(
               width: 70,
               child: Column(
                 children: [
                                       // 상단 연결선 (첫 번째 아이템이 아닌 경우)
                    if (allTasks.indexOf(task) > 0)
                      Container(
                        width: 2,
                        height: 20, // 연결선 길이 줄임
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: Colors.grey[300]!,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                        ),
                      ),
                   // 아이콘이 포함된 타임라인 점 (세로 타원형 배경)
                   Container(
                     width: 40,  // 가로 크기
                     height: 80, // 세로 크기
                     decoration: BoxDecoration(
                       color: _getPriorityBackgroundColor(task.priority),
                       borderRadius: BorderRadius.circular(30), // 세로 타원형 모양
                       border: Border.all(
                         color: priorityColor,
                         width: 0,
                       ),
                     ),
                     child: Center(
                       child: Icon(
                         _getTaskIcon(task),
                         size: 24,
                         color: priorityColor,
                       ),
                     ),
                   ),
                                       // 하단 연결선 (마지막 아이템이 아닌 경우)
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 20, // 연결선 길이 줄임
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: Colors.grey[300]!,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                        ),
                      ),
                 ],
               ),
             ),
          
          const SizedBox(width: 20),
          
                     // 일정 카드
           Expanded(
             child: Container(
               margin: const EdgeInsets.only(top: 0), // 상단 마진 제거하여 타임라인 아이콘과 일정 카드 정확히 중앙 정렬
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
                   // 첫 번째 줄: 시간 범위와 더보기 메뉴
                   Row(
                     children: [
                       // 시간 범위 (시작시간 ~ 종료시간)
                       Text(
                         _getTimeRangeString(task),
                         style: TextStyle(
                           fontSize: 16,
                           color: Colors.black,
                         ),
                       ),
                       const Spacer(),
                       // 더보기 메뉴
                       PopupMenuButton<String>(
                         icon: const Icon(
                           Icons.more_vert,
                           size: 24,
                           color: Colors.grey,
                         ),
                         onSelected: (value) {
                           if (value == 'edit') {
                             Navigator.of(context).push(
                               MaterialPageRoute(
                                 builder: (context) => ScheduleAddScreen(
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
                           PopupMenuItem(
                             value: 'edit',
                             child: const Text(
                               '수정하기',
                               style: TextStyle(
                                 color: Color(0xFF1F5DFF), // 파란색
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                           ),
                           PopupMenuItem(
                             value: 'delete',
                             child: const Text(
                               '삭제하기',
                               style: TextStyle(
                                 color: Colors.red, // 빨간색
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                           ),
                         ],
                       ),
                     ],
                   ),
                   const SizedBox(height: 8),
                   // 두 번째 줄: 아이콘, 제목, 재생 버튼, 반복 일정, 완료 체크박스
                   Row(
                     children: [
                       // 아이콘
                       Container(
                         width: 20,
                         height: 20,
                         margin: const EdgeInsets.only(right: 8),
                         child: task.emoji != null
                             ? Text(
                                 task.emoji!,
                                 style: const TextStyle(fontSize: 16),
                               )
                             : Icon(
                                 _getTaskIcon(task),
                                 size: 14,
                                 color: priorityColor,
                               ),
                       ),
                       // 제목
                       Flexible(
                         child: Text(
                           task.title,
                           style: TextStyle(
                             fontSize: 18,
                             fontWeight: FontWeight.w600,
                             color: task.isCompleted 
                                 ? Colors.grey[500]
                                 : Colors.black,
                             decoration: task.isCompleted 
                                 ? TextDecoration.lineThrough 
                                 : null,
                           ),
                         ),
                       ),
                                               // 재생 버튼
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ScheduleTimerScreen(
                                  task: task,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(left: 12),
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
                        ),
                       // 반복 일정 표시
                       if (task.isRecurring)
                         Container(
                           margin: const EdgeInsets.only(left: 8),
                           child: const Icon(
                             Icons.repeat,
                             size: 16,
                             color: Color(0xFF1F5DFF),
                           ),
                         ),
                       const Spacer(flex: 3),
                       // 완료 체크박스 (우측 끝)
                       GestureDetector(
                         onTap: () {
                           viewModel.toggleTaskCompletion(task.id);
                         },
                         child: Container(
                           width: 24,
                           height: 24,
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
                                   size: 14,
                                   color: Colors.white,
                                 )
                               : null,
                         ),
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

  IconData _getTaskIcon(TaskModel task) {
    // 우선순위에 따른 아이콘 반환 (홈화면과 동일하게)
    switch (task.priority) {
      case TaskPriority.urgentImportant:
        return Icons.warning_amber_rounded; // 경고 아이콘
      case TaskPriority.important:
        return Icons.check_box_outlined; // 체크박스 아이콘
      case TaskPriority.urgent:
        return Icons.refresh_rounded; // 새로고침 아이콘
      case TaskPriority.neither:
        return Icons.edit_outlined; // 편집 아이콘
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
                // 빌드 완료 후 삭제 작업 수행
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  viewModel.deleteTask(task.id);
                });
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
      
      // 오전/오후 형식으로 변경
      String startTimeStr = _getTimeStringWithAmPm(startTime);
      String endTimeStr = _getTimeStringWithAmPm(endTime);
      
      return '$startTimeStr ~ $endTimeStr $durationText';
    } else if (startTime != null) {
      // 시작시간만 있는 경우
      return '${_getTimeStringWithAmPm(startTime)} ~';
    } else if (endTime != null) {
      // 종료시간만 있는 경우 (기존 데이터 호환)
      return '~ ${_getTimeStringWithAmPm(endTime)}';
    } else {
      // 둘 다 없는 경우
      return '시간 미정';
    }
  }
}