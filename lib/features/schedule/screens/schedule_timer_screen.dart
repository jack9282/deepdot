import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/theme/app_theme.dart';
import '../../../data/models/task_model.dart';
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
      // 집중 시간 완료 -> 휴식 시간으로 전환
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
    });
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

  void _markTaskAsCompleted() {
    final viewModel = Provider.of<ScheduleViewModel>(context, listen: false);
    
    // 일정을 완료 상태로 변경
    final updatedTask = widget.task.copyWith(
      isCompleted: true, // 완료 상태로 변경
      completedAt: DateTime.now(),
    );
    
    viewModel.updateTask(updatedTask);
    
    // 통계 데이터 기록 (집중 시간)
    final completedFocusTime = _totalSeconds - _remainingSeconds;
    // TODO: 통계 데이터 저장 로직 구현
    print('완료된 집중 시간: ${completedFocusTime}초');
    
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
          '뽀모도로',
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
             Row(
               children: [
                 // 일정 제목
                 Expanded(
                   child: Text(
                     widget.task.title,
                     style: const TextStyle(
                       fontSize: 18,
                       fontWeight: FontWeight.w600,
                       color: Colors.black,
                     ),
                   ),
                 ),
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
                  height: 500,
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

