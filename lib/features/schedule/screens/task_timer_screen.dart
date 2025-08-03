import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/theme/app_theme.dart';
import '../../../data/models/task_model.dart';
import '../view_models/schedule_view_model.dart';
import 'task_add_screen.dart';

class TaskTimerScreen extends StatefulWidget {
  final TaskModel task;

  const TaskTimerScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskTimerScreen> createState() => _TaskTimerScreenState();
}

class _TaskTimerScreenState extends State<TaskTimerScreen> {
  Timer? _timer;
  bool _isRunning = false;
  
  // 타이머 시간 (초 단위)
  int _focusTimeMinutes = 25; // 집중 시간 (분)
  int _breakTimeMinutes = 5;  // 휴식 시간 (분)
  int _remainingSeconds = 25 * 60; // 남은 시간 (초)
  int _totalSeconds = 25 * 60; // 총 시간 (초)
  
  bool _isFocusMode = true; // true: 집중 시간, false: 휴식 시간

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

  void _showTimeEditDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _TimeEditBottomSheet(
        focusTime: _focusTimeMinutes,
        breakTime: _breakTimeMinutes,
        onTimeChanged: (focusTime, breakTime) {
          setState(() {
            _focusTimeMinutes = focusTime;
            _breakTimeMinutes = breakTime;
            _initializeTimer();
          });
        },
      ),
    );
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '일정',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskAddScreen(
                    priority: widget.task.priority,
                    taskToEdit: widget.task,
                  ),
                ),
              );
            },
            child: const Text(
              '일정 수정',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: _showTimeEditDialog,
            child: const Text(
              '시간 수정',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 상단 정보
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.task.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Tip 문구
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '[Tip] 집중이 끝나면, 잠깐 쉬어가세요!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // 시간 정보
            Row(
              children: [
                Text(
                  '집중 시간 : ${_focusTimeMinutes}분',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '휴식 시간 : ${_breakTimeMinutes}분',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // 중앙 타이머
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 타이머 원형 디스플레이
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black,
                              width: 3,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(_remainingSeconds),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        // 상단 핸들
                        Positioned(
                          top: -10,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // 재생/정지 버튼
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        onPressed: _toggleTimer,
                        icon: Icon(
                          _isRunning ? Icons.pause : Icons.play_arrow,
                          size: 30,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 진행률 바
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '진행률',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '${(_getProgress() * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _getProgress(),
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  minHeight: 8,
                ),
              ],
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _completeTask,
        backgroundColor: Colors.black,
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

// 시간 수정 Bottom Sheet
class _TimeEditBottomSheet extends StatefulWidget {
  final int focusTime;
  final int breakTime;
  final Function(int focusTime, int breakTime) onTimeChanged;

  const _TimeEditBottomSheet({
    required this.focusTime,
    required this.breakTime,
    required this.onTimeChanged,
  });

  @override
  State<_TimeEditBottomSheet> createState() => _TimeEditBottomSheetState();
}

class _TimeEditBottomSheetState extends State<_TimeEditBottomSheet> {
  late int _focusTime;
  late int _breakTime;

  @override
  void initState() {
    super.initState();
    _focusTime = widget.focusTime;
    _breakTime = widget.breakTime;
  }

  void _adjustTime(bool isFocus, bool isIncrease) {
    setState(() {
      if (isFocus) {
        if (isIncrease) {
          _focusTime = (_focusTime + 5).clamp(5, 60);
        } else {
          _focusTime = (_focusTime - 5).clamp(5, 60);
        }
      } else {
        if (isIncrease) {
          _breakTime = (_breakTime + 5).clamp(5, 30);
        } else {
          _breakTime = (_breakTime - 5).clamp(5, 30);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // 제목
          const Text(
            '시간 설정',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 30),
          
          // 집중 시간 설정
          _buildTimeAdjuster(
            '집중 시간',
            _focusTime,
            () => _adjustTime(true, false),
            () => _adjustTime(true, true),
          ),
          const SizedBox(height: 20),
          
          // 휴식 시간 설정
          _buildTimeAdjuster(
            '휴식 시간',
            _breakTime,
            () => _adjustTime(false, false),
            () => _adjustTime(false, true),
          ),
          const SizedBox(height: 30),
          
          // 버튼들
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onTimeChanged(_focusTime, _breakTime);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
        ],
      ),
    );
  }

  Widget _buildTimeAdjuster(String label, int time, VoidCallback onDecrease, VoidCallback onIncrease) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: onDecrease,
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.grey[600],
            ),
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${time}분',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            IconButton(
              onPressed: onIncrease,
              icon: const Icon(Icons.add_circle_outline),
              color: Colors.grey[600],
            ),
          ],
        ),
      ],
    );
  }
}