import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/theme/app_theme.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/focus_session_model.dart';
import '../../../data/repositories/focus_session_repository.dart';
import '../view_models/schedule_view_model.dart';
import 'schedule_add_screen.dart';

class ScheduleTimerScreen extends StatefulWidget {
  final TaskModel task;

  const ScheduleTimerScreen({
    super.key,
    required this.task,
  });

  @override
  State<ScheduleTimerScreen> createState() => _ScheduleTimerScreenState();
}

class _ScheduleTimerScreenState extends State<ScheduleTimerScreen> {
  Timer? _timer;
  bool _isRunning = false;
  
  // 타이머 시간 (초 단위)
  int _focusTimeMinutes = 25; // 집중 시간 (분)
  int _breakTimeMinutes = 5;  // 휴식 시간 (분)
  int _remainingSeconds = 25 * 60; // 남은 시간 (초)
  int _totalSeconds = 25 * 60; // 총 시간 (초)
  
  bool _isFocusMode = true; // true: 집중 시간, false: 휴식 시간
  bool _showTimeEdit = false; // 시간 수정 UI 표시 여부
  
  // 집중시간 추적을 위한 변수들
  DateTime? _focusStartTime; // 집중 시작 시간
  final FocusSessionRepository _focusRepository = FocusSessionRepository();

  @override
  void initState() {
    super.initState();
    _initializeTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeTimer() {
    if (_isFocusMode) {
      _remainingSeconds = _focusTimeMinutes * 60;
      _totalSeconds = _focusTimeMinutes * 60;
    } else {
      _remainingSeconds = _breakTimeMinutes * 60;
      _totalSeconds = _breakTimeMinutes * 60;
    }
  }

  void _startTimer() {
    if (_timer != null) return;
    
    // 집중 모드일 때만 시작 시간 기록
    if (_isFocusMode && _focusStartTime == null) {
      _focusStartTime = DateTime.now();
    }
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _stopTimer();
          _onTimerComplete();
        }
      });
    });
    
    setState(() {
      _isRunning = true;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  void _onTimerComplete() {
    // 타이머 완료 시 처리
    if (_isFocusMode) {
      // 집중 시간 완료 -> 집중시간 저장
      _saveFocusSession(true); // 자연스럽게 완료됨
      _showCompletionDialog('집중 시간이 완료되었습니다!', '휴식 시간을 시작하시겠습니까?');
    } else {
      // 휴식 시간 완료 -> 집중 시간으로 전환
      _showCompletionDialog('휴식 시간이 완료되었습니다!', '다음 집중 시간을 시작하시겠습니까?');
    }
  }

  void _showCompletionDialog(String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _switchMode();
            },
            child: const Text('시작'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('나중에'),
          ),
        ],
      ),
    );
  }

  void _switchMode() {
    setState(() {
      _isFocusMode = !_isFocusMode;
      _initializeTimer();
      // 집중 모드로 전환 시 시작 시간 초기화
      if (_isFocusMode) {
        _focusStartTime = null;
      }
    });
  }

  // 집중 세션 저장
  Future<void> _saveFocusSession(bool completedNaturally) async {
    if (!_isFocusMode || _focusStartTime == null) return;

    final endTime = DateTime.now();
    final totalSeconds = endTime.difference(_focusStartTime!).inSeconds;
    final focusMinutes = (totalSeconds / 60).round();

    // 최소 1분 이상 집중한 경우만 저장
    if (focusMinutes < 1) return;

    // 일정의 실제 날짜 사용 (startDate 또는 dueDate)
    final taskDate = widget.task.startDate ?? widget.task.dueDate ?? DateTime.now();
    final targetDate = DateTime(taskDate.year, taskDate.month, taskDate.day);
    
    // 디버깅: 날짜 정보 출력
    print('Task info - startDate: ${widget.task.startDate}, dueDate: ${widget.task.dueDate}');
    print('Used taskDate: $taskDate');
    print('Target date: $targetDate');
    print('Target weekday: ${targetDate.weekday} (1=월, 2=화, 3=수, 4=목, 5=금, 6=토, 7=일)');
    
    // 집중 세션의 createdAt을 일정 날짜로 설정
    final sessionCreatedAt = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      endTime.hour,
      endTime.minute,
      endTime.second,
    );

    final session = FocusSessionModel(
      id: 'focus_${DateTime.now().millisecondsSinceEpoch}',
      taskTitle: widget.task.title,
      taskType: widget.task.priority.toString().split('.').last, // TaskPriority enum을 string으로 변환
      focusMinutes: focusMinutes,
      plannedMinutes: _focusTimeMinutes, // 설정된 집중시간
      startTime: _focusStartTime!,
      endTime: endTime,
      completedNaturally: completedNaturally,
      createdAt: sessionCreatedAt, // 일정의 날짜로 설정
    );

    try {
      await _focusRepository.loadSessionsFromStorage();
      final success = await _focusRepository.addFocusSession(session);
      
      if (success) {
        print('집중 세션 저장 완료: ${session.taskTitle} - ${session.focusMinutes}분 / ${session.plannedMinutes}분 (${(session.focusMinutes / session.plannedMinutes * 100).toInt()}%)');
      } else {
        print('집중 세션 저장 실패');
      }
    } catch (e) {
      print('집중 세션 저장 중 오류: $e');
    }

    // 시작 시간 초기화
    _focusStartTime = null;
  }

  void _toggleTimeEdit() {
    setState(() {
      _showTimeEdit = !_showTimeEdit;
    });
  }

  void _adjustTime(bool isFocus, bool isIncrease) {
    setState(() {
      if (isFocus) {
        if (isIncrease) {
          _focusTimeMinutes = (_focusTimeMinutes + 5).clamp(5, 60);
        } else {
          _focusTimeMinutes = (_focusTimeMinutes - 5).clamp(5, 60);
        }
      } else {
        if (isIncrease) {
          _breakTimeMinutes = (_breakTimeMinutes + 5).clamp(5, 30);
        } else {
          _breakTimeMinutes = (_breakTimeMinutes - 5).clamp(5, 30);
        }
      }
      _initializeTimer();
    });
  }

  void _completeTask() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 완료'),
        content: const Text('이 일정을 완료하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _markTaskAsCompleted();
            },
            child: const Text('완료'),
          ),
        ],
      ),
    );
  }

  void _markTaskAsCompleted() async {
    final viewModel = Provider.of<ScheduleViewModel>(context, listen: false);
    
    // 집중 모드이고 타이머가 진행 중이었다면 집중시간 저장
    if (_isFocusMode && _focusStartTime != null) {
      await _saveFocusSession(false); // 수동으로 완료됨
    }
    
    // 일정을 완료 상태로 변경
    final updatedTask = widget.task.copyWith(
      isCompleted: true, // 완료 상태로 변경
      completedAt: DateTime.now(),
    );
    
    viewModel.updateTask(updatedTask);
    
    // 이전 화면으로 돌아가기
    Navigator.pop(context, true); // 완료 상태를 전달
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  double _getProgress() {
    if (_totalSeconds == 0) return 0.0;
    return (_totalSeconds - _remainingSeconds) / _totalSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // 본문 뒷배경을 연한회색으로 변경
      appBar: AppBar(
        backgroundColor: Colors.white, // 상단바는 흰색 유지
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '포모도로',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 일정 정보 섹션
            LayoutBuilder(
              builder: (context, constraints) {
                // 텍스트 크기를 측정하여 필요한 너비 계산
                final textSpan = TextSpan(
                  text: widget.task.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                );
                final textPainter = TextPainter(
                  text: textSpan,
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                );
                textPainter.layout();
                
                final textWidth = textPainter.width;
                final availableWidth = constraints.maxWidth;
                final buttonWidth = 24.0; // 아이콘 크기
                final spacing = 8.0; // 간격
                
                // 텍스트가 너무 길면 줄임표 표시
                final shouldTruncate = textWidth > (availableWidth - buttonWidth - spacing);
                
                return Row(
                  children: [
                    // 일정 제목 (동적 너비)
                    Expanded(
                      child: Text(
                        widget.task.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        overflow: shouldTruncate ? TextOverflow.ellipsis : null,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 일정 수정 버튼
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScheduleAddScreen(
                              priority: widget.task.priority,
                              taskToEdit: widget.task,
                            ),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            
                         // Tip 문구와 시간 수정 버튼
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 // Tip 문구
                 Row(
                   children: [
                     Expanded(
                       child: RichText(
                         text: TextSpan(
                           children: [
                             TextSpan(
                               text: '[Tip] ',
                               style: const TextStyle(
                                 fontSize: 16,
                                 color: Color(0xFF1F5DFF), // 파란색
                                 fontWeight: FontWeight.w600,
                               ),
                             ),
                             TextSpan(
                               text: '집중이 끝나면 잠깐 쉬어가세요',
                               style: const TextStyle(
                                 fontSize: 15,
                                 color: Colors.black, // 검정색
                                 fontWeight: FontWeight.w600,
                               ),
                             ),
                           ],
                         ),
                       ),
                     ),
                     // 시간 수정 버튼
                     GestureDetector(
                       onTap: _toggleTimeEdit,
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                         decoration: BoxDecoration(
                           color: Colors.grey[200],
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: Text(
                           _showTimeEdit ? '완료' : '수정하기',
                           style: const TextStyle(
                             fontSize: 12,
                             color: Colors.black,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 8),
                 // 시간 정보
                 Text(
                   '+,-버튼을 시간을 설정할 수 있어요',
                   style: TextStyle(
                     fontSize: 13,
                     color: Colors.grey[500],
                   ),
                 ),
                 
                  
                  // 인라인 시간 수정 UI
                  if (_showTimeEdit) ...[
                    const SizedBox(height: 6),
                                         Container(
                       padding: const EdgeInsets.all(3),
                       decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: Colors.grey[300]!),
                       ),
                      child: Column(
                        children: [
                          // 집중 시간 설정
                                                     Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               const Text(
                                 '   집중시간',
                                 style: TextStyle(
                                   fontSize: 16,
                                   fontWeight: FontWeight.w500,
                                   color: Colors.black,
                                 ),
                               ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => _adjustTime(true, false),
                                    icon: const Icon(Icons.remove),
                                    color: Colors.black,
                                  ),
                                    Text(
                                     '${_focusTimeMinutes}분',
                                     style: const TextStyle(
                                       fontSize: 16,
                                       fontWeight: FontWeight.w600,
                                       color: Colors.black,
                                     ),
                                   ),
                                  IconButton(
                                    onPressed: () => _adjustTime(true, true),
                                    icon: const Icon(Icons.add),
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Divider(color: Colors.grey[300]),
                          const SizedBox(height: 2),
                          // 휴식 시간 설정
                                                     Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               const Text(
                                 '   휴식시간',
                                 style: TextStyle(
                                   fontSize: 16,
                                   fontWeight: FontWeight.w500,
                                   color: Colors.black,
                                 ),
                               ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => _adjustTime(false, false),
                                    icon: const Icon(Icons.remove),
                                    color: Colors.black,
                                  ),
                                                                     Text(
                                     '${_breakTimeMinutes}분',
                                     style: const TextStyle(
                                       fontSize: 16,
                                       fontWeight: FontWeight.w600,
                                       color: Colors.black,
                                     ),
                                   ),
                                  IconButton(
                                    onPressed: () => _adjustTime(false, true),
                                    icon: const Icon(Icons.add),
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            
            const SizedBox(height: 30),
            
              // 중앙 타이머 (흰색 카드에 담기)
              Center(
                                 child: Container(
                   width: 500,
                   height: 400,
                   padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                                     child: Column(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       // 타이머 시간만 표시 (중앙)
                       Expanded(
                         child: Center(
                           child: Text(
                             _formatTime(_remainingSeconds),
                             style: const TextStyle(
                               fontSize: 50,
                               fontWeight: FontWeight.w500,
                               color: Colors.black,
                             ),
                           ),
                         ),
                       ),
                       
                       // 재생/정지 버튼 (카드 하단)
                       Container(
                         width: 60,
                         height: 60,
                         decoration: BoxDecoration(
                           shape: BoxShape.circle,
                           color: const Color(0xFF3A71FF),
                         ),
                         child: IconButton(
                           onPressed: _toggleTimer,
                           icon: Icon(
                             _isRunning ? Icons.pause : Icons.play_arrow,
                             size: 30,
                             color: Colors.white,
                           ),
                         ),
                       ),
                     ],
                   ),
                 ),
               ),
              
              const SizedBox(height: 20),
              
              // 진행률 바 (별도 흰색 카드)
              Center(
                child: Container(
                  width: 500,
                  height: 50,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                                     child: Row(
                     children: [
                       const Text(
                         '진행률',
                         style: TextStyle(
                           fontSize: 16,
                           fontWeight: FontWeight.w500,
                           color: Colors.black,
                         ),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: Container(
                           height: 8,
                           decoration: BoxDecoration(
                             color: Colors.grey[300],
                             borderRadius: BorderRadius.circular(4),
                           ),
                           child: FractionallySizedBox(
                             alignment: Alignment.centerLeft,
                             widthFactor: _getProgress(),
                             child: Container(
                               decoration: BoxDecoration(
                                 color: AppTheme.primaryColor,
                                 borderRadius: BorderRadius.circular(4),
                               ),
                             ),
                           ),
                         ),
                       ),
                       const SizedBox(width: 16),
                       Text(
                         '${(_getProgress() * 100).toInt()}%',
                         style: TextStyle(
                           fontSize: 14,
                           color: Colors.grey[600],
                         ),
                       ),
                     ],
                   ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _completeTask,
        backgroundColor: const Color(0xFF3A71FF),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

