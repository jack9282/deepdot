import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../common/theme/app_theme.dart';
import '../../../data/models/task_model.dart';
import '../view_models/schedule_view_model.dart';

class TaskAddScreen extends StatefulWidget {
  final TaskPriority priority;

  const TaskAddScreen({
    super.key,
    required this.priority,
  });

  @override
  State<TaskAddScreen> createState() => _TaskAddScreenState();
}

class _TaskAddScreenState extends State<TaskAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _participantsController = TextEditingController();
  
  DateTime _startDateTime = DateTime.now();
  DateTime _endDateTime = DateTime.now().add(const Duration(hours: 1));
  bool _isAllDay = false;
  bool _isLoading = false;
  
  // 아이콘 선택을 위한 변수
  String _selectedIcon = '📚';
  
  // 사용 가능한 아이콘 목록
  final List<String> _availableIcons = [
    '📚', '📝', '💻', '🏃', '🍽️', '🎵', '🎨', '💼'
  ];

  @override
  void initState() {
    super.initState();
    // 시작 시간을 현재 시간으로, 종료 시간을 1시간 후로 설정
    _startDateTime = DateTime.now();
    _endDateTime = _startDateTime.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScheduleViewModel(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            '일정 추가',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목 입력
                const Text(
                  '제목',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: '일정 제목을 입력하세요',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '일정 제목을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 시간 설정
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeRange(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _showDateTimePicker,
                      child: const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 날짜 표시
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('M월 d일(E)', 'ko_KR').format(_startDateTime),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _showDateTimePicker,
                      child: const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 하루 종일 토글
                Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '하루 종일',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isAllDay,
                      onChanged: (value) {
                        setState(() {
                          _isAllDay = value;
                          if (value) {
                            // 하루 종일인 경우 시간을 00:00 ~ 23:59로 설정
                            _startDateTime = DateTime(
                              _startDateTime.year,
                              _startDateTime.month,
                              _startDateTime.day,
                              0,
                              0,
                            );
                            _endDateTime = DateTime(
                              _startDateTime.year,
                              _startDateTime.month,
                              _startDateTime.day,
                              23,
                              59,
                            );
                          }
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // 위치 입력
                const Text(
                  '위치',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      hintText: '위치를 입력하세요',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 참여 인원
                const Text(
                  '참여 인원',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    controller: _participantsController,
                    decoration: const InputDecoration(
                      hintText: '참여 인원을 입력하세요',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 아이콘 선택
                const Text(
                  '아이콘 선택',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 60,
                  child: Row(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _availableIcons.length,
                          itemBuilder: (context, index) {
                            final icon = _availableIcons[index];
                            final isSelected = icon == _selectedIcon;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIcon = icon;
                                });
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                    ? AppTheme.primaryColor.withOpacity(0.2)
                                    : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected 
                                    ? Border.all(color: AppTheme.primaryColor, width: 2)
                                    : null,
                                ),
                                child: Center(
                                  child: Text(
                                    icon,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // 더 많은 아이콘 선택 기능 (추후 구현)
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.grey,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(20),
          child: Consumer<ScheduleViewModel>(
            builder: (context, viewModel, child) {
              return GestureDetector(
                onTap: _isLoading ? null : () => _saveTask(viewModel),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _isLoading ? Colors.grey[400] : Colors.black,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatTimeRange() {
    if (_isAllDay) {
      return '하루 종일';
    }
    final startTime = DateFormat('HH:mm').format(_startDateTime);
    final endTime = DateFormat('HH:mm').format(_endDateTime);
    return '$startTime - $endTime';
  }

  void _showDateTimePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DateTimePickerBottomSheet(
        startDateTime: _startDateTime,
        endDateTime: _endDateTime,
        isAllDay: _isAllDay,
        onDateTimeChanged: (start, end) {
          setState(() {
            _startDateTime = start;
            _endDateTime = end;
          });
        },
      ),
    );
  }

  Future<void> _saveTask(ScheduleViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await viewModel.addTask(
        title: _titleController.text.trim(),
        description: _buildDescription(),
        dueDate: _endDateTime,
        priority: widget.priority,
      );

      if (success && mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // 성공 팝업 표시
        _showSuccessDialog();
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.errorMessage ?? '일정 추가에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('일정 추가 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _buildDescription() {
    List<String> descriptionParts = [];
    
    if (_locationController.text.trim().isNotEmpty) {
      descriptionParts.add('위치: ${_locationController.text.trim()}');
    }
    
    if (_participantsController.text.trim().isNotEmpty) {
      descriptionParts.add('참여 인원: ${_participantsController.text.trim()}');
    }
    
    descriptionParts.add('아이콘: $_selectedIcon');
    
    return descriptionParts.join('\n');
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '일정이 추가되었습니다',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // 다이얼로그 닫기
                      Navigator.of(context).pop(true); // 일정 추가 화면 닫기 (성공 결과 전달)
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 날짜/시간 피커 Bottom Sheet
class _DateTimePickerBottomSheet extends StatefulWidget {
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool isAllDay;
  final Function(DateTime start, DateTime end) onDateTimeChanged;

  const _DateTimePickerBottomSheet({
    required this.startDateTime,
    required this.endDateTime,
    required this.isAllDay,
    required this.onDateTimeChanged,
  });

  @override
  State<_DateTimePickerBottomSheet> createState() => __DateTimePickerBottomSheetState();
}

class __DateTimePickerBottomSheetState extends State<_DateTimePickerBottomSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.startDateTime;
    _startTime = TimeOfDay.fromDateTime(widget.startDateTime);
    _endTime = TimeOfDay.fromDateTime(widget.endDateTime);
    _selectedMonth = _selectedDate.month;
    _selectedYear = _selectedDate.year;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 핸들
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '취소',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                Text(
                  '$_selectedYear년 $_selectedMonth월',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final newStart = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      _startTime.hour,
                      _startTime.minute,
                    );
                    final newEnd = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      _endTime.hour,
                      _endTime.minute,
                    );
                    widget.onDateTimeChanged(newStart, newEnd);
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    '완료',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // 캘린더
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 월 네비게이션
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (_selectedMonth == 1) {
                              _selectedMonth = 12;
                              _selectedYear--;
                            } else {
                              _selectedMonth--;
                            }
                          });
                        },
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        '$_selectedYear년 $_selectedMonth월',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (_selectedMonth == 12) {
                              _selectedMonth = 1;
                              _selectedYear++;
                            } else {
                              _selectedMonth++;
                            }
                          });
                        },
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 요일 헤더
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['일', '월', '화', '수', '목', '금', '토']
                        .map((day) => SizedBox(
                              width: 40,
                              child: Text(
                                day,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 캘린더 그리드
                  _buildCalendarGrid(),
                  
                  const SizedBox(height: 24),
                  
                  // 시간 선택 (하루 종일이 아닌 경우만)
                  if (!widget.isAllDay) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // 시작 시간
                    Row(
                      children: [
                        const Text(
                          '시작 시간',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _startTime,
                            );
                            if (time != null) {
                              setState(() {
                                _startTime = time;
                                // 시작 시간이 종료 시간보다 늦으면 종료 시간을 1시간 후로 설정
                                if (_startTime.hour >= _endTime.hour && 
                                    _startTime.minute >= _endTime.minute) {
                                  _endTime = TimeOfDay(
                                    hour: (_startTime.hour + 1) % 24,
                                    minute: _startTime.minute,
                                  );
                                }
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _startTime.format(context),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 종료 시간
                    Row(
                      children: [
                        const Text(
                          '종료 시간',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _endTime,
                            );
                            if (time != null) {
                              setState(() {
                                _endTime = time;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _endTime.format(context),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
    final lastDayOfMonth = DateTime(_selectedYear, _selectedMonth + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 일요일을 0으로 만들기
    final daysInMonth = lastDayOfMonth.day;
    
    List<Widget> dayWidgets = [];
    
    // 빈 공간 추가 (이전 달의 마지막 날들)
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox(width: 40, height: 40));
    }
    
    // 현재 달의 날짜들
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedYear, _selectedMonth, day);
      final isSelected = date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      final isToday = date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;
      
      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : null,
              borderRadius: BorderRadius.circular(20),
              border: isToday && !isSelected 
                  ? Border.all(color: AppTheme.primaryColor)
                  : null,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white 
                      : isToday 
                          ? AppTheme.primaryColor 
                          : Colors.black,
                  fontWeight: isSelected || isToday 
                      ? FontWeight.w600 
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }
} 