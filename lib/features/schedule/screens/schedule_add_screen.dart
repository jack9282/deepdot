import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../common/theme/app_theme.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/schedule_model.dart';
import '../view_models/schedule_view_model.dart';
import '../../home/view_models/home_view_model.dart';
import '../../statistics/view_models/statistics_view_model.dart';

import 'schedule_add_complete_screen.dart';
import '../../../utils/date_time_formatter.dart';

class ScheduleAddScreen extends StatefulWidget {
  final TaskPriority priority;
  final TaskModel? taskToEdit;

  const ScheduleAddScreen({
    super.key,
    required this.priority,
    this.taskToEdit,
  });

  @override
  State<ScheduleAddScreen> createState() => _ScheduleAddScreenState();
}

class _ScheduleAddScreenState extends State<ScheduleAddScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _memoController = TextEditingController();
  final _focusNode = FocusNode(); // 포커스 관리를 위한 FocusNode 추가
  
  // 주어진 시간을 분 단위로 반올림하는 static 함수
  static DateTime _roundToNearestInterval(DateTime dateTime, int minuteInterval) {
    final roundedMinute = (dateTime.minute / minuteInterval).round() * minuteInterval;
    
    // 60분 이상인 경우 시간을 1 증가시키고 분을 0으로 설정
    if (roundedMinute >= 60) {
      return DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour + 1,
        0,
      );
    }
    
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      roundedMinute,
    );
  }
  
  DateTime _startDateTime = _roundToNearestInterval(DateTime.now(), 5);
  DateTime _endDateTime = _roundToNearestInterval(DateTime.now().add(const Duration(hours: 1)), 5);
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  bool _isNotificationEnabled = false;
  String _selectedEmoji = '😊';
  String? _selectedPriority;
  String? _selectedNotificationTime;
  bool _isStartTimeSelected = false;
  bool _isEndTimeSelected = false;
  bool _isStartDateSelected = false;
  bool _isEndDateSelected = false;

  // 우선순위 옵션
  final List<String> _priorityOptions = [
    '지금 바로 해야해요',
    '미리 계획해서 준비해요',
    '나중에 처리해요',
    '시간이 남을 때 해요'
  ];

  // 이모지 목록
  final List<String> _emojis = [
    '😀', '😃', '😄', '😁', '😆', '🥹', '😅',
    '😂', '🤣', '🥲', '☺️', '😊', '🙂', '😍',
    '🥰', '😘', '😙', '😚', '😋', '😝', '🤨',
    '🤓', '😎', '😏', '🙂', '🥳', '😟', '😖',
    '😫', '🥺', '😝', '😡', '🤒', '🫠', '😱',
    '🫢', '😪', '😮', '👍', '👎', '🙏', '🫵',
    '⚽', '🎨', '🎟️', '🧩', '🎤', '🎬', '🖥️',
    '💡', '⏰', '💊', '🛁', '🧻', '🚴‍♂️', '🎮',
    '🍎', '🥗', '❤️', '💣', '🎉', '🍀', '🌙',
    '🐶', '💪', '🎾', '🏃', '🚩', '🧶', '🔥',
    '💼', '🍽️', '☕', '🪥', '🚗', '🏥', '📱',
  ];

  @override
  void initState() {
    super.initState();
    
    // 기본 우선순위 설정
    _selectedPriority = _priorityOptions[3]; // '시간이 남을 때 해요'를 기본값으로 설정
    
    if (widget.taskToEdit != null) {
      _initializeWithExistingTask(widget.taskToEdit!);
    }
  }

  void _initializeWithExistingTask(TaskModel task) {
    _titleController.text = task.title;
    
    // description에서 장소와 메모를 분리 (첫 번째 줄은 장소, 나머지는 메모)
    if (task.description != null && task.description!.isNotEmpty) {
      final lines = task.description!.split('\n');
      if (lines.isNotEmpty) {
        // 첫 번째 줄이 비어있지 않을 때만 장소에 설정
        if (lines[0].trim().isNotEmpty) {
          _locationController.text = lines[0];
        }
        // 두 번째 줄 이후가 있을 때만 메모에 설정
        if (lines.length > 1) {
          final memoLines = lines.skip(1).where((line) => line.trim().isNotEmpty).toList();
          if (memoLines.isNotEmpty) {
            _memoController.text = memoLines.join('\n');
          }
        }
      }
    }
    
    _startDateTime = task.startDate ?? DateTime.now();
    _selectedEmoji = task.emoji ?? '😊';
    _endDateTime = task.dueDate ?? DateTime.now().add(const Duration(hours: 1));
    _startDate = task.startDate ?? DateTime.now();
    _endDate = task.dueDate ?? DateTime.now();
    
    // 우선순위 설정
    _selectedPriority = _getPriorityStringFromEnum(task.priority);
    
    // 선택 상태 플래그 설정
    _isStartTimeSelected = task.startDate != null;
    _isEndTimeSelected = task.dueDate != null;
    _isStartDateSelected = task.startDate != null;
    _isEndDateSelected = task.dueDate != null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _memoController.dispose();
    _focusNode.dispose(); // FocusNode 해제
    super.dispose();
  }

  TaskPriority _getTaskPriorityFromString(String? priority) {
    switch (priority) {
      case '지금 바로 해야해요':
        return TaskPriority.urgentImportant;
      case '미리 계획해서 준비해요':
        return TaskPriority.important;
      case '나중에 처리해요':
        return TaskPriority.urgent;
      case '시간이 남을 때 해요':
        return TaskPriority.neither;
      default:
        // 우선순위가 선택되지 않았을 때는 기본값으로 '시간이 남을 때 해요' 설정
        return TaskPriority.neither;
    }
  }

  String? _getPriorityStringFromEnum(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgentImportant:
        return '지금 바로 해야해요';
      case TaskPriority.important:
        return '미리 계획해서 준비해요';
      case TaskPriority.urgent:
        return '나중에 처리해요';
      case TaskPriority.neither:
        return '시간이 남을 때 해요';
    }
  }

  /// 우선순위를 API에서 요구하는 형식으로 변환
  String _convertPriorityForApi(String? priority) {
    switch (priority) {
      case '지금 바로 해야해요':
        return '긴급';
      case '미리 계획해서 준비해요':
        return '중요';
      case '나중에 처리해요':
        return '보통';
      case '시간이 남을 때 해요':
        return '낮음';
      default:
        return '보통';
    }
  }

  /// 이모지를 API에서 요구하는 아이콘 코드로 변환
  String _convertEmojiToIconCode(String emoji) {
    // 이모지별 아이콘 코드 매핑
    final emojiToIconMap = {
      '😀': 'SMILE',
      '😃': 'HAPPY',
      '😄': 'JOY',
      '😁': 'GRIN',
      '😆': 'LAUGH',
      '🥹': 'TOUCHED',
      '😅': 'SWEAT',
      '😂': 'CRY_LAUGH',
      '🤣': 'ROFL',
      '🥲': 'TEAR_JOY',
      '☺️': 'BLUSH',
      '😊': 'HAPPY_EYES',
      '🙂': 'SLIGHT_SMILE',
      '😍': 'HEART_EYES',
      '🥰': 'LOVE',
      '😘': 'KISS',
      '😙': 'KISS_SMILE',
      '😚': 'KISS_EYES',
      '😋': 'YUM',
      '😝': 'TONGUE',
      '🤨': 'RAISED_EYEBROW',
      '🤓': 'NERD',
      '😎': 'COOL',
      '😏': 'SMIRK',
      '🥳': 'PARTY',
      '😟': 'WORRIED',
      '😖': 'CONFOUNDED',
      '😫': 'TIRED',
      '🥺': 'PLEADING',
      '😡': 'ANGRY',
      '🤒': 'SICK',
      '🫠': 'MELT',
      '😱': 'SCREAM',
      '🫢': 'GASP',
      '😪': 'SLEEPY',
      '😮': 'SURPRISE',
      '👍': 'THUMBS_UP',
      '👎': 'THUMBS_DOWN',
      '🙏': 'PRAY',
      '🫵': 'POINT',
      '⚽': 'SOCCER',
      '🎨': 'ART',
      '🎟️': 'TICKET',
      '🧩': 'PUZZLE',
      '🎤': 'MIC',
      '🎬': 'MOVIE',
      '🖥️': 'COMPUTER',
      '💡': 'IDEA',
      '⏰': 'ALARM',
      '💊': 'PILL',
      '🛁': 'BATH',
      '🧻': 'TISSUE',
      '🚴‍♂️': 'BIKE',
      '🎮': 'GAME',
      '🍎': 'APPLE',
      '🥗': 'SALAD',
      '❤️': 'HEART',
      '💣': 'BOMB',
      '🎉': 'PARTY_POPPER',
      '🍀': 'CLOVER',
      '🌙': 'MOON',
      '🐶': 'DOG',
      '💪': 'MUSCLE',
      '🎾': 'TENNIS',
      '🏃': 'RUN',
      '🚩': 'FLAG',
      '🧶': 'YARN',
      '🔥': 'FIRE',
      '💼': 'BRIEFCASE',
      '🍽️': 'DINNER',
      '☕': 'COFFEE',
      '🪥': 'TOOTHBRUSH',
      '🚗': 'CAR',
      '🏥': 'HOSPITAL',
      '📱': 'PHONE',
    };

    return emojiToIconMap[emoji] ?? 'NOTE'; // 기본값은 NOTE
  }

  // API 요청용 데이터 생성 함수 (더 이상 사용하지 않음 - ViewModel에서 처리)
  // Future<Map<String, dynamic>> _createApiRequestData() async {
  //   try {
  //     final userId = await TokenManager.instance.getCurrentUserId();
  //     
  //     return {
  //       'userId': userId,
  //       'title': _titleController.text.trim(),
  //       'memo': _memoController.text.trim(),
  //       'location': _locationController.text.trim(),
  //       'alarm': _isNotificationEnabled,
  //       'calendarDate': DateTimeFormatter.toDateString(_startDate),
  //       'startTime': DateTimeFormatter.toTimeString(_startDateTime),
  //       'endTime': DateTimeFormatter.toTimeString(_endDateTime),
  //       'type': _convertPriorityForApi(_selectedPriority),
  //       'icon': _convertEmojiToIconCode(_selectedEmoji),
  //     };
  //   } catch (e) {
  //     throw Exception('API 요청 데이터 생성 실패: $e');
  //   }
  // }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$period ${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    // Flutter의 weekday: 월요일=1, 화요일=2, ..., 일요일=7
    // 헤더가 ['일', '월', '화', '수', '목', '금', '토'] 순서이므로 일요일=0이 되도록 조정
    final weekdayIndex = date.weekday % 7; // 일요일=0, 월요일=1, ..., 토요일=6
    final weekday = ['일', '월', '화', '수', '목', '금', '토'][weekdayIndex];
    return '${month}월 $day일 ($weekday)';
  }

  // 포커스 해제 메서드
  void _unfocusAll() {
    _focusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  // 저장 버튼 활성화 여부 확인
  bool _canSave() {
    return _titleController.text.trim().isNotEmpty &&
           _isStartTimeSelected &&
           _isEndTimeSelected &&
           _isStartDateSelected &&
           _isEndDateSelected &&
           _selectedPriority != null;
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
                     child: GridView.builder(
             padding: const EdgeInsets.all(16),
             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
               crossAxisCount: 7,
               crossAxisSpacing: 8,
               mainAxisSpacing: 8,
             ),
             itemCount: _emojis.length,
             itemBuilder: (context, index) {
               return GestureDetector(
                 onTap: () {
                   setState(() {
                     _selectedEmoji = _emojis[index];
                   });
                   Navigator.pop(context);
                 },
                 child: Container(
                   decoration: BoxDecoration(
                     color: _selectedEmoji == _emojis[index] 
                         ? const Color(0xFF1F5DFF).withOpacity(0.1)
                         : Colors.transparent,
                     borderRadius: BorderRadius.circular(8),
                     border: _selectedEmoji == _emojis[index]
                         ? Border.all(color: const Color(0xFF1F5DFF))
                         : null,
                   ),
                   child: Center(
                     child: Text(
                       _emojis[index],
                       style: const TextStyle(fontSize: 20),
                     ),
                   ),
                 ),
               );
             },
           ),
        );
      },
    );
  }

  void _showTimePicker(bool isStartTime) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // 시간 선택기
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: isStartTime ? _startDateTime : _endDateTime,
                  minuteInterval: 5, // 5분 단위로 설정
                  onDateTimeChanged: (DateTime newTime) {
                    setState(() {
                      if (isStartTime) {
                        _startDateTime = DateTime(
                          _startDateTime.year,
                          _startDateTime.month,
                          _startDateTime.day,
                          newTime.hour,
                          newTime.minute,
                        );
                      } else {
                        _endDateTime = DateTime(
                          _endDateTime.year,
                          _endDateTime.month,
                          _endDateTime.day,
                          newTime.hour,
                          newTime.minute,
                        );
                      }
                    });
                  },
                ),
              ),
              // 하단 확인 버튼
              Container(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                                         onPressed: () {
                       setState(() {
                         if (isStartTime) {
                           _isStartTimeSelected = true;
                         } else {
                           _isEndTimeSelected = true;
                         }
                       });
                       _unfocusAll(); // 포커스 해제
                       Navigator.pop(context);
                     },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDateRangePicker() {
    DateTime? selectedStartDate;
    DateTime? selectedEndDate;
    DateTime currentMonth = DateTime.now();
    
    showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 450,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // 커스텀 달력
                  Expanded(
                    child: _buildCustomCalendar(
                      currentMonth: currentMonth,
                      selectedStartDate: selectedStartDate,
                      selectedEndDate: selectedEndDate,
                      onDateSelected: (date) {
                        setModalState(() {
                          if (selectedStartDate == null) {
                            selectedStartDate = date;
                          } else if (selectedEndDate == null) {
                            if (date.isBefore(selectedStartDate!)) {
                              selectedEndDate = selectedStartDate;
                              selectedStartDate = date;
                            } else {
                              selectedEndDate = date;
                            }
                          } else {
                            selectedStartDate = date;
                            selectedEndDate = null;
                          }
                        });
                      },
                      onMonthChanged: (newMonth) {
                        setModalState(() {
                          currentMonth = newMonth;
                        });
                      },
                    ),
                  ),
                  // 하단 확인 버튼
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: selectedStartDate != null && selectedEndDate != null
                                                         ? () {
                                                                setState(() {
                                 _startDate = selectedStartDate!;
                                 _endDate = selectedEndDate!;
                                 _isStartDateSelected = true;
                                 _isEndDateSelected = true;
                                 
                                 // 🔧 수정: startDateTime과 endDateTime도 선택된 날짜로 업데이트
                                 _startDateTime = DateTime(
                                   selectedStartDate!.year,
                                   selectedStartDate!.month,
                                   selectedStartDate!.day,
                                   _startDateTime.hour,
                                   _startDateTime.minute,
                                 );
                                 _endDateTime = DateTime(
                                   selectedEndDate!.year,
                                   selectedEndDate!.month,
                                   selectedEndDate!.day,
                                   _endDateTime.hour,
                                   _endDateTime.minute,
                                 );
                               });
                                 _unfocusAll(); // 포커스 해제
                                 Navigator.pop(context);
                               }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedStartDate != null && selectedEndDate != null
                              ? AppTheme.primaryColor
                              : Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '확인',
                          style: TextStyle(
                            color: selectedStartDate != null && selectedEndDate != null
                                ? Colors.white
                                : Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomCalendar({
    required DateTime currentMonth,
    required DateTime? selectedStartDate,
    required DateTime? selectedEndDate,
    required Function(DateTime) onDateSelected,
    required Function(DateTime) onMonthChanged,
  }) {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    // Flutter의 weekday를 일요일=0 기준으로 변환 (일요일=0, 월요일=1, ..., 토요일=6)
    final firstDayOfWeek = firstDayOfMonth.weekday % 7;
    
    final daysInMonth = lastDayOfMonth.day;
    final totalDays = firstDayOfWeek + daysInMonth;
    final weeks = (totalDays / 7).ceil();
    
    return Column(
      children: [
        // 월/년도 헤더
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Text(
                '${currentMonth.month}월 ${currentMonth.year}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F5DFF),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  final previousMonth = DateTime(currentMonth.year, currentMonth.month - 1);
                  onMonthChanged(previousMonth);
                },
                icon: const Icon(Icons.chevron_left, color: Color(0xFF1F5DFF)),
              ),
              IconButton(
                onPressed: () {
                  final nextMonth = DateTime(currentMonth.year, currentMonth.month + 1);
                  onMonthChanged(nextMonth);
                },
                icon: const Icon(Icons.chevron_right, color: Color(0xFF1F5DFF)),
              ),
            ],
          ),
        ),
        // 요일 헤더
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: ['일', '월', '화', '수', '목', '금', '토'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        // 달력 그리드
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: weeks,
            itemBuilder: (context, weekIndex) {
              return Row(
                children: List.generate(7, (dayIndex) {
                  final dayNumber = weekIndex * 7 + dayIndex - firstDayOfWeek + 1;
                  
                  if (dayNumber <= 0 || dayNumber > daysInMonth) {
                    // 이전/다음 달의 날짜
                    return Expanded(
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.all(2),
                        child: const Center(
                          child: Text(
                            '',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  }
                  
                  final date = DateTime(currentMonth.year, currentMonth.month, dayNumber);
                  final isSelected = selectedStartDate != null && 
                      selectedEndDate != null &&
                      (date.isAtSameMomentAs(selectedStartDate) || 
                       date.isAtSameMomentAs(selectedEndDate) ||
                       (date.isAfter(selectedStartDate) && date.isBefore(selectedEndDate)));
                  
                  final isStartDate = selectedStartDate != null && 
                      date.isAtSameMomentAs(selectedStartDate);
                  final isEndDate = selectedEndDate != null && 
                      date.isAtSameMomentAs(selectedEndDate);
                  
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onDateSelected(date),
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE0EDFF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: isStartDate || isEndDate
                              ? Border.all(color: const Color(0xFF1F5DFF), width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            dayNumber.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected 
                                  ? const Color(0xFF1F5DFF)
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _saveTask() async {
    // 필수 항목 검증
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정 제목을 입력해주세요')),
      );
      return;
    }

    if (!_isStartTimeSelected || !_isEndTimeSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시작 시간과 종료 시간을 선택해주세요')),
      );
      return;
    }
    
    if (!_isStartDateSelected || !_isEndDateSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시작 날짜와 종료 날짜를 선택해주세요')),
      );
      return;
    }
    
    if (_selectedPriority == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('우선순위를 선택해주세요')),
      );
      return;
    }

    // 수정 모드일 때도 API 형식에 맞게 데이터 변환
    if (widget.taskToEdit != null) {
      final viewModel = Provider.of<ScheduleViewModel>(context, listen: false);
      final isRecurring = !_isSameDay(_startDate, _endDate);
      
      // API 형식에 맞게 데이터 변환
      final updatedTask = widget.taskToEdit!.copyWith(
        title: _titleController.text.trim(),
        memo: _memoController.text.trim(),
        location: _locationController.text.trim(),
        priority: _getTaskPriorityFromString(_selectedPriority),
        alarm: _isNotificationEnabled,
        calendarDate: DateTimeFormatter.toDateString(_startDate),
        startTime: DateTimeFormatter.toTimeString(_startDateTime),
        endTime: DateTimeFormatter.toTimeString(_endDateTime),
        icon: _convertEmojiToIconCode(_selectedEmoji),
        // 기존 필드들도 업데이트 (하위 호환성)
        description: '${_locationController.text.trim()}\n${_memoController.text.trim()}',
        startDate: _startDateTime,
        dueDate: _endDateTime,
        startDateRange: isRecurring ? _startDate : null,
        endDateRange: isRecurring ? _endDate : null,
        isRecurring: isRecurring,
        emoji: _selectedEmoji,
      );
      
      final success = await viewModel.updateTaskWithAlarms(
        updatedTask: updatedTask,
        alarm30Before: _isNotificationEnabled && _selectedNotificationTime == '30분전',
        alarm60Before: _isNotificationEnabled && _selectedNotificationTime == '1시간전',
        alarm120Before: _isNotificationEnabled && _selectedNotificationTime == '2시간전',
      );
      if (success) {
        await viewModel.refresh();
        
        // HomeViewModel과 StatisticsViewModel도 업데이트
        final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
        await homeViewModel.refresh();
        
        final statisticsViewModel = Provider.of<StatisticsViewModel>(context, listen: false);
        await statisticsViewModel.loadCurrentWeekData();
        
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(viewModel.errorMessage ?? '일정 수정에 실패했습니다')),
        );
      }
      return;
    }

    // 새로운 일정 추가 - ViewModel을 통해 처리 (비회원 지원)
    final viewModel = Provider.of<ScheduleViewModel>(context, listen: false);
    final isRecurring = !_isSameDay(_startDate, _endDate);
    
    // ScheduleType으로 변환
    ScheduleType scheduleType;
    switch (_selectedPriority) {
      case '지금 바로 해야해요':
        scheduleType = ScheduleType.urgentNow;
        break;
      case '미리 계획해서 준비해요':
        scheduleType = ScheduleType.planAhead;
        break;
      case '나중에 처리해요':
        scheduleType = ScheduleType.laterProcessing;
        break;
      case '시간이 남을 때 해요':
        scheduleType = ScheduleType.whenFree;
        break;
      default:
        scheduleType = ScheduleType.whenFree;
    }
    
    final success = await viewModel.addSchedule(
      title: _titleController.text.trim(),
      time: DateTimeFormatter.toTimeString(_startDateTime),
      startDate: _startDateTime,
      endDate: _endDateTime,
      type: scheduleType,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
      image: _convertEmojiToIconCode(_selectedEmoji),
      alarm30Before: _isNotificationEnabled && _selectedNotificationTime == '30분전',
      alarm60Before: _isNotificationEnabled && _selectedNotificationTime == '1시간전',
      alarm120Before: _isNotificationEnabled && _selectedNotificationTime == '2시간전',
      isRecurring: isRecurring,
    );
    
    if (success) {
      await viewModel.refresh();
      
      // HomeViewModel과 StatisticsViewModel도 업데이트
      final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
      await homeViewModel.refresh();
      
      final statisticsViewModel = Provider.of<StatisticsViewModel>(context, listen: false);
      await statisticsViewModel.loadCurrentWeekData();
      
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? '일정 등록에 실패했습니다'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  void _showSuccessDialog() {
    // 성공 후 완료 화면으로 이동
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScheduleAddCompleteScreen(
          isEditMode: widget.taskToEdit != null,
        ),
      ),
    );
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
                 title: Text(
           widget.taskToEdit != null ? '일정 수정' : '일정 추가',
           style: const TextStyle(
             color: Colors.black,
             fontSize: 18,
             fontWeight: FontWeight.w600,
           ),
         ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 입력과 이모지 선택을 가로로 배치
            Row(
              children: [
                // 제목 입력 필드
                Expanded(
                  child: Container(
                    height: 54, // 고정 높이 설정
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                                         child: TextField(
                       controller: _titleController,
                       focusNode: _focusNode, // FocusNode 연결
                       autofocus: false, // 자동 포커스 비활성화
                       decoration: const InputDecoration(
                         hintText: '일정의 제목을 작성해주세요',
                         hintStyle: TextStyle(
                           color: Color(0xFFB4B5B6),
                           fontSize: 16,
                         ),
                         border: InputBorder.none,
                       ),
                     ),
                  ),
                ),
                const SizedBox(width: 12),
                // 이모지 선택 버튼
                GestureDetector(
                  onTap: _showEmojiPicker,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _selectedEmoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 시간 선택
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.black87, size: 20),
                const SizedBox(width: 12),
                                 GestureDetector(
                   onTap: () {
                     _unfocusAll(); // 포커스 해제
                     _showTimePicker(true);
                   },
                   child: Text(
                    _formatTime(_startDateTime),
                    style: TextStyle(
                      color: _isStartTimeSelected ? const Color(0xFF1F5DFF) : Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('>', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 12),
                                 GestureDetector(
                   onTap: () {
                     _unfocusAll(); // 포커스 해제
                     _showTimePicker(false);
                   },
                   child: Text(
                    _formatTime(_endDateTime),
                    style: TextStyle(
                      color: _isEndTimeSelected ? const Color(0xFF1F5DFF) : Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 날짜 선택
            Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.black, size: 20),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    _unfocusAll(); // 포커스 해제
                    _showDateRangePicker();
                  },
                  child: Text(
                    _formatDate(_startDate),
                    style: TextStyle(
                      color: _isStartDateSelected ? const Color(0xFF1F5DFF) : Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('>', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    _unfocusAll(); // 포커스 해제
                    _showDateRangePicker();
                  },
                  child: Text(
                    _formatDate(_endDate),
                    style: TextStyle(
                      color: _isEndDateSelected ? const Color(0xFF1F5DFF) : Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            // 반복 일정 안내 메시지
            if (_isStartDateSelected && _isEndDateSelected && !_isSameDay(_startDate, _endDate))
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0EDFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.repeat,
                      color: Color(0xFF1F5DFF),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '선택한 날짜 범위 동안 매일 반복되는 일정으로 등록됩니다',
                        style: const TextStyle(
                          color: Color(0xFF1F5DFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // 우선순위 선택 
            Row(
              children: [
                const Icon(Icons.event_available, color: Colors.black, size: 20),
                const SizedBox(width: 12),
                // 2x2 그리드로 우선순위 버튼 배치
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPriority = _priorityOptions[0];
                                });
                              },
                              child: Container(
                                height: 40,
                                margin: const EdgeInsets.only(right: 8, bottom: 8),
                                decoration: BoxDecoration(
                                  color: _selectedPriority == _priorityOptions[0] 
                                      ? const Color(0xFFE0EDFF) 
                                      : const Color(0xFFF5F5F5),
                                  border: Border.all(
                                    color: _selectedPriority == _priorityOptions[0] 
                                        ? const Color(0xFF5886FF) 
                                        : const Color(0xFFE5E5E5),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    _priorityOptions[0],
                                    style: TextStyle(
                                      color: _selectedPriority == _priorityOptions[0] 
                                          ? const Color(0xFF1F5DFF) 
                                          : const Color(0xFF74787B),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPriority = _priorityOptions[1];
                                });
                              },
                              child: Container(
                                height: 40,
                                margin: const EdgeInsets.only(left: 8, bottom: 8),
                                decoration: BoxDecoration(
                                  color: _selectedPriority == _priorityOptions[1] 
                                      ? const Color(0xFFE0EDFF) 
                                      : const Color(0xFFF5F5F5),
                                  border: Border.all(
                                    color: _selectedPriority == _priorityOptions[1] 
                                        ? const Color(0xFF5886FF) 
                                        : const Color(0xFFE5E5E5),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    _priorityOptions[1],
                                    style: TextStyle(
                                      color: _selectedPriority == _priorityOptions[1] 
                                          ? const Color(0xFF1F5DFF) 
                                          : const Color(0xFF74787B),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPriority = _priorityOptions[2];
                                });
                              },
                              child: Container(
                                height: 40,
                                margin: const EdgeInsets.only(right: 8, top: 8),
                                decoration: BoxDecoration(
                                  color: _selectedPriority == _priorityOptions[2] 
                                      ? const Color(0xFFE0EDFF) 
                                      : const Color(0xFFF5F5F5),
                                  border: Border.all(
                                    color: _selectedPriority == _priorityOptions[2] 
                                        ? const Color(0xFF5886FF) 
                                        : const Color(0xFFE5E5E5),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    _priorityOptions[2],
                                    style: TextStyle(
                                      color: _selectedPriority == _priorityOptions[2] 
                                          ? const Color(0xFF1F5DFF) 
                                          : const Color(0xFF74787B),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPriority = _priorityOptions[3];
                                });
                              },
                              child: Container(
                                height: 40,
                                margin: const EdgeInsets.only(left: 8, top: 8),
                                decoration: BoxDecoration(
                                  color: _selectedPriority == _priorityOptions[3] 
                                      ? const Color(0xFFE0EDFF) 
                                      : const Color(0xFFF5F5F5),
                                  border: Border.all(
                                    color: _selectedPriority == _priorityOptions[3] 
                                        ? const Color(0xFF5886FF) 
                                        : const Color(0xFFE5E5E5),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    _priorityOptions[3],
                                    style: TextStyle(
                                      color: _selectedPriority == _priorityOptions[3] 
                                          ? const Color(0xFF1F5DFF) 
                                          : const Color(0xFF74787B),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 알림 설정
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications, color: Colors.black, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      '일정 알림 설정',
                      style: TextStyle(
                        color: Color(0xFFB4B5B6),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isNotificationEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isNotificationEnabled = value;
                          if (!value) {
                            _selectedNotificationTime = null;
                          }
                        });
                      },
                      activeColor: const Color(0xFFFFFFFF),
                      activeTrackColor: const Color(0xFF5886FF),
                      inactiveThumbColor: const Color(0xFFFFFFFF),
                      inactiveTrackColor: const Color(0xFFD9D9D9),
                    ),
                  ],
                ),
                // 알림 시간 선택 컨테이너 (알림이 활성화된 경우에만 표시)
                if (_isNotificationEnabled) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // 30분전
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedNotificationTime = '30분전';
                              });
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: _selectedNotificationTime == '30분전' 
                                        ? const Color(0xFF1F5DFF) 
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: _selectedNotificationTime == '30분전' 
                                          ? const Color(0xFF1F5DFF) 
                                          : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: _selectedNotificationTime == '30분전'
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '30분전',
                                  style: TextStyle(
                                    color: _selectedNotificationTime == '30분전' 
                                        ? const Color(0xFF1F5DFF) 
                                        : Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 1시간전
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedNotificationTime = '1시간전';
                              });
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: _selectedNotificationTime == '1시간전' 
                                        ? const Color(0xFF1F5DFF) 
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: _selectedNotificationTime == '1시간전' 
                                          ? const Color(0xFF1F5DFF) 
                                          : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: _selectedNotificationTime == '1시간전'
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '1시간전',
                                  style: TextStyle(
                                    color: _selectedNotificationTime == '1시간전' 
                                        ? const Color(0xFF1F5DFF) 
                                        : Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 2시간전
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedNotificationTime = '2시간전';
                              });
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: _selectedNotificationTime == '2시간전' 
                                        ? const Color(0xFF1F5DFF) 
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: _selectedNotificationTime == '2시간전' 
                                          ? const Color(0xFF1F5DFF) 
                                          : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: _selectedNotificationTime == '2시간전'
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '2시간전',
                                  style: TextStyle(
                                    color: _selectedNotificationTime == '2시간전' 
                                        ? const Color(0xFF1F5DFF) 
                                        : Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // 장소 입력
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        hintText: '장소를 입력해주세요',
                        hintStyle: TextStyle(
                          color: Color(0xFFB4B5B6),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 메모 입력
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.grey, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _memoController,
                      decoration: const InputDecoration(
                        hintText: '메모를 작성해주세요',
                        hintStyle: TextStyle(
                          color: Color(0xFFB4B5B6),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

                         // 저장 버튼
             SizedBox(
               width: double.infinity,
               height: 50,
               child: ElevatedButton(
                 onPressed: _canSave() ? _saveTask : null,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: _canSave() ? AppTheme.primaryColor : Colors.grey[300],
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(12),
                   ),
                 ),
                 child: Text(
                   '저장하기',
                   style: TextStyle(
                     color: _canSave() ? Colors.white : Colors.grey[600],
                     fontSize: 16,
                     fontWeight: FontWeight.w600,
                   ),
                 ),
               ),
             ),
          ],
        ),
      ),
    );
  }
} 