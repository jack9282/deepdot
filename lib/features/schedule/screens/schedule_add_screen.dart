import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../common/theme/app_theme.dart';
import '../../../data/models/task_model.dart';
import '../view_models/schedule_view_model.dart';
import 'schedule_add_complete_screen.dart';

class ScheduleAddScreen extends StatefulWidget {
  final TaskPriority priority;
  final TaskModel? taskToEdit; // 수정할 일정 (null이면 새로 추가)

  const ScheduleAddScreen({
    super.key,
    required this.priority,
    this.taskToEdit,
  });

  @override
  State<ScheduleAddScreen> createState() => _ScheduleAddScreenState();
}

class _ScheduleAddScreenState extends State<ScheduleAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _memoController = TextEditingController();
  
  DateTime _startDateTime = DateTime.now();
  DateTime _endDateTime = DateTime.now().add(const Duration(hours: 1));

  bool _isLoading = false;
  
  // 인라인 선택기 표시 상태
  bool _isStartTimePickerVisible = false;
  bool _isEndTimePickerVisible = false;
  bool _isStartDatePickerVisible = false;
  bool _isEndDatePickerVisible = false;

  String _notificationTime = '알림 없음'; // 기본값
  
  // 알림 시간 옵션
  final List<String> _notificationOptions = [
    '알림 없음',
    '30분전',
    '1시간 전'
  ];
  
  // 아이콘 선택을 위한 변수
  String _selectedIcon = '🐰';
  
  // 사용 가능한 아이콘 목록
  final List<String> _availableIcons = [
    '🐰', '☕', '🎯', '🔴', '📊', '📁', '😊', '+'
  ];

  // 추천 태그 목록
  final List<String> _recommendedTags = [
    '지금바로 해야 해요',
    '미리 계획해서 준비해요',
    '나중에 처리해요',
    '시간이 날 때 해요'
  ];

  String? _selectedTag;

  // 태그에 따른 우선순위 매핑
  TaskPriority _getTaskPriorityFromTag(String? tag) {
    switch (tag) {
      case '지금바로 해야 해요':
        return TaskPriority.urgentImportant;  // 먼저 처리할 일
      case '미리 계획해서 준비해요':
        return TaskPriority.important;        // 미리 준비해주세요
      case '나중에 처리해요':
        return TaskPriority.urgent;           // 도움받아도 괜찮아요
      case '시간이 날 때 해요':
        return TaskPriority.neither;          // 나중에 봐도 괜찮아요
      default:
        return widget.priority; // 기본값은 전달받은 우선순위
    }
  }

  @override
  void initState() {
    super.initState();
    
    if (widget.taskToEdit != null) {
      // 수정 모드: 기존 일정 데이터로 초기화
      _initializeWithExistingTask(widget.taskToEdit!);
    } else {
      // 추가 모드: 기본값으로 초기화
      _startDateTime = DateTime.now();
      _endDateTime = _startDateTime.add(const Duration(hours: 1));
    }
  }

  void _initializeWithExistingTask(TaskModel task) {
    _titleController.text = task.title;
    _locationController.text = _extractLocationFromDescription(task.description);
    _memoController.text = _extractMemoFromDescription(task.description);
    
    _startDateTime = task.startDate ?? DateTime.now();
    _endDateTime = task.dueDate ?? _startDateTime.add(const Duration(hours: 1));
    
    _selectedIcon = _extractIconFromDescription(task.description);
    _notificationTime = _extractNotificationFromDescription(task.description);
    _selectedTag = _extractTagFromDescription(task.description);
  }

  String _extractLocationFromDescription(String? description) {
    if (description == null) return '';
    final match = RegExp(r'위치: (.+)').firstMatch(description);
    return match?.group(1) ?? '';
  }

  String _extractMemoFromDescription(String? description) {
    if (description == null) return '';
    final match = RegExp(r'메모: (.+)').firstMatch(description);
    return match?.group(1) ?? '';
  }

  String _extractIconFromDescription(String? description) {
    if (description == null) return '🐰';
    final match = RegExp(r'아이콘: (.+)').firstMatch(description);
    return match?.group(1) ?? '🐰';
  }

  String _extractNotificationFromDescription(String? description) {
    if (description == null) return '알림 없음';
    final match = RegExp(r'알림: (.+)').firstMatch(description);
    return match?.group(1) ?? '알림 없음';
  }

  String? _extractTagFromDescription(String? description) {
    if (description == null) return null;
    final match = RegExp(r'태그: (.+)').firstMatch(description);
    return match?.group(1);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _memoController.dispose();
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
          toolbarHeight: 50, // AppBar 높이 축소
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20), // 아이콘 크기 축소
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.taskToEdit != null ? '일정 수정' : '일정 추가',
            style: const TextStyle(
              fontSize: 16, // 제목 크기 축소: 18 → 16
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0), // 좌우 여백 추가
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
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: '일정 제목을 입력하세요',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
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
                
                const SizedBox(height: 24),
                
                // 시간 설정 (시작/종료 한 줄 배치)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 시작 시간
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isStartTimePickerVisible = !_isStartTimePickerVisible;
                            _isEndTimePickerVisible = false;
                            _isStartDatePickerVisible = false;
                            _isEndDatePickerVisible = false;
                          });
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.black, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '시작: ${DateFormat('HH:mm').format(_startDateTime)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 종료 시간
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isEndTimePickerVisible = !_isEndTimePickerVisible;
                            _isStartTimePickerVisible = false;
                            _isStartDatePickerVisible = false;
                            _isEndDatePickerVisible = false;
                          });
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled, color: Colors.black, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '종료: ${DateFormat('HH:mm').format(_endDateTime)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // 시간 선택기들 (인라인)
                if (_isStartTimePickerVisible)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: _startDateTime,
                      use24hFormat: false,
                      onDateTimeChanged: (DateTime newDateTime) {
                        setState(() {
                          _startDateTime = DateTime(
                            _startDateTime.year,
                            _startDateTime.month,
                            _startDateTime.day,
                            newDateTime.hour,
                            newDateTime.minute,
                          );
                          // 시작시간이 종료시간보다 늦으면 종료시간을 1시간 후로 자동 조정
                          if (_startDateTime.isAfter(_endDateTime)) {
                            _endDateTime = _startDateTime.add(const Duration(hours: 1));
                          }
                        });
                      },
                    ),
                  ),
                
                if (_isEndTimePickerVisible)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: _endDateTime,
                      use24hFormat: false,
                      onDateTimeChanged: (DateTime newDateTime) {
                        setState(() {
                          _endDateTime = DateTime(
                            _endDateTime.year,
                            _endDateTime.month,
                            _endDateTime.day,
                            newDateTime.hour,
                            newDateTime.minute,
                          );
                          // 종료시간이 시작시간보다 이전이거나 같으면 경고
                          if (_endDateTime.isBefore(_startDateTime) || _endDateTime.isAtSameMomentAs(_startDateTime)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('종료시간은 시작시간보다 늦어야 합니다'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        });
                      },
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // 날짜 설정 (시작/종료 한 줄 배치)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 시작 날짜
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isStartDatePickerVisible = !_isStartDatePickerVisible;
                            _isEndDatePickerVisible = false;
                            _isStartTimePickerVisible = false;
                            _isEndTimePickerVisible = false;
                          });
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.black, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '시작: ${DateFormat('M/d(E)', 'ko_KR').format(_startDateTime)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 종료 날짜
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isEndDatePickerVisible = !_isEndDatePickerVisible;
                            _isStartDatePickerVisible = false;
                            _isStartTimePickerVisible = false;
                            _isEndTimePickerVisible = false;
                          });
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.event, color: Colors.black, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '종료: ${DateFormat('M/d(E)', 'ko_KR').format(_endDateTime)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // 시작 날짜 선택기 (인라인)
                if (_isStartDatePickerVisible)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TableCalendar<dynamic>(
                      focusedDay: _startDateTime,
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      calendarFormat: CalendarFormat.month,
                      selectedDayPredicate: (day) {
                        return isSameDay(_startDateTime, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _startDateTime = DateTime(
                            selectedDay.year,
                            selectedDay.month,
                            selectedDay.day,
                            _startDateTime.hour,
                            _startDateTime.minute,
                          );
                          // 시작 날짜가 종료 날짜보다 늦으면 종료 날짜를 같은 날로 조정
                          if (_startDateTime.isAfter(DateTime(_endDateTime.year, _endDateTime.month, _endDateTime.day))) {
                            _endDateTime = DateTime(
                              selectedDay.year,
                              selectedDay.month,
                              selectedDay.day,
                              _endDateTime.hour,
                              _endDateTime.minute,
                            );
                          }
                          _isStartDatePickerVisible = false; // 선택 후 달력 닫기
                        });
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black),
                        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black),
                        titleTextStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        holidayTextStyle: const TextStyle(color: Colors.red),
                        selectedDecoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.blue[100],
                          shape: BoxShape.circle,
                        ),
                        defaultTextStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                        weekendTextStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        weekendStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),

                // 종료 날짜 선택기 (인라인)
                if (_isEndDatePickerVisible)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TableCalendar<dynamic>(
                      focusedDay: _endDateTime,
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      calendarFormat: CalendarFormat.month,
                      selectedDayPredicate: (day) {
                        return isSameDay(_endDateTime, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          // 종료 날짜가 시작 날짜보다 이전이면 경고
                          if (selectedDay.isBefore(DateTime(_startDateTime.year, _startDateTime.month, _startDateTime.day))) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('종료 날짜는 시작 날짜보다 늦어야 합니다'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          
                          _endDateTime = DateTime(
                            selectedDay.year,
                            selectedDay.month,
                            selectedDay.day,
                            _endDateTime.hour,
                            _endDateTime.minute,
                          );
                          _isEndDatePickerVisible = false; // 선택 후 달력 닫기
                        });
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black),
                        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black),
                        titleTextStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        holidayTextStyle: const TextStyle(color: Colors.red),
                        selectedDecoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.blue[100],
                          shape: BoxShape.circle,
                        ),
                        defaultTextStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                        weekendTextStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        weekendStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 8), // 간격 대폭 축소: 12 → 8
                
                // 추천 태그
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_box, color: Colors.black, size: 24),
                        const SizedBox(width: 16),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _recommendedTags.map((tag) {
                        final isSelected = tag == _selectedTag;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTag = isSelected ? null : tag;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: isSelected 
                                  ? Border.all(color: AppTheme.primaryColor)
                                  : null,
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? AppTheme.primaryColor : Colors.black,
                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // 알림 설정
                GestureDetector(
                  onTap: _showNotificationOptions,
                  child: Row(
                    children: [
                      const Icon(Icons.notifications, color: Colors.black, size: 24),
                      const SizedBox(width: 6),
                      Text(
                        _notificationTime,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 위치 입력
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.black, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          hintText: '위치',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // 메모 입력
                Row(
                  children: [
                    const Icon(Icons.label, color: Colors.black, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _memoController,
                        decoration: const InputDecoration(
                          hintText: '메모',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // 아이콘 선택
                const Text(
                  '아이콘 선택',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
                            final isAddButton = icon == '+';
                            
                            return GestureDetector(
                              onTap: () {
                                if (!isAddButton) {
                                  setState(() {
                                    _selectedIcon = icon;
                                  });
                                }
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                    ? AppTheme.primaryColor.withOpacity(0.2)
                                    : Colors.grey[100],
                                  shape: BoxShape.circle,
                                  border: isSelected 
                                    ? Border.all(color: AppTheme.primaryColor, width: 2)
                                    : null,
                                ),
                                child: Center(
                                  child: isAddButton
                                      ? const Icon(
                                          Icons.add,
                                          color: Colors.grey,
                                          size: 24,
                                        )
                                      : Text(
                                          icon,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12), // 간격 대폭 축소: 24 → 12 // 간격 축소: 60 → 40
              ],
            ),
          ),
        ),
        floatingActionButton: Consumer<ScheduleViewModel>(
          builder: (context, viewModel, child) {
            return FloatingActionButton(
              onPressed: _isLoading ? null : () => _saveTask(viewModel),
              backgroundColor: _isLoading ? Colors.grey[400] : Colors.black,
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
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  void _showNotificationOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '알림 설정',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _notificationOptions.map((option) => ListTile(
            title: Text(
              option,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
              ),
            ),
            trailing: _notificationTime == option 
                ? const Icon(Icons.check, color: AppTheme.primaryColor)
                : null,
            onTap: () {
              setState(() {
                _notificationTime = option;
              });
              Navigator.pop(context);
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(
                fontFamily: 'Pretendard',
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTask(ScheduleViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    // 시간 검증: 종료시간이 시작시간보다 이전이면 안됨
    if (_endDateTime.isBefore(_startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('종료시간은 시작시간보다 늦어야 합니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      
      if (widget.taskToEdit != null) {
        // 수정 모드: 기존 일정 업데이트
        final updatedTask = widget.taskToEdit!.copyWith(
          title: _titleController.text.trim(),
          description: _buildDescription(),
          startDate: _startDateTime,
          dueDate: _endDateTime,
          priority: _getTaskPriorityFromTag(_selectedTag),
        );
        success = await viewModel.updateTask(updatedTask);
      } else {
        // 추가 모드: 새 일정 추가
        success = await viewModel.addTask(
          title: _titleController.text.trim(),
          description: _buildDescription(),
          startDate: _startDateTime,
          dueDate: _endDateTime,
          priority: _getTaskPriorityFromTag(_selectedTag),
        );
      }

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
              content: Text(viewModel.errorMessage ?? 
                  (widget.taskToEdit != null ? '일정 수정에 실패했습니다' : '일정 추가에 실패했습니다')),
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
          SnackBar(
            content: Text(widget.taskToEdit != null ? 
                '일정 수정 중 오류가 발생했습니다' : '일정 추가 중 오류가 발생했습니다'),
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
    
    if (_memoController.text.trim().isNotEmpty) {
      descriptionParts.add('메모: ${_memoController.text.trim()}');
    }
    
    if (_selectedTag != null) {
      descriptionParts.add('태그: $_selectedTag');
    }
    
    descriptionParts.add('아이콘: $_selectedIcon');
    descriptionParts.add('알림: $_notificationTime');
    
    return descriptionParts.join('\n');
  }

  void _showSuccessDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScheduleAddCompleteScreen(
          isEditMode: widget.taskToEdit != null,
        ),
      ),
    );
  }
} 