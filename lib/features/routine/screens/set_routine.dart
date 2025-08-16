import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../view_models/routine_view_model.dart';
import '../../../data/models/routine_model.dart';
import '../../../common/theme/app_theme.dart';
import '../../../utils/alarm.dart';

class SetRoutineScreen extends StatefulWidget {
  final Map<String, dynamic>? existingRoutine;
  final int? routineIndex;

  const SetRoutineScreen({super.key, this.existingRoutine, this.routineIndex});

  @override
  State<SetRoutineScreen> createState() => _SetRoutineScreenState();
}

class _SetRoutineScreenState extends State<SetRoutineScreen> {
  final TextEditingController _routineNameController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final List<String> _selectedGoals = [];
  final List<bool> _selectedDays = List.filled(7, false);
  bool _notificationEnabled = true;
  bool _showTimePicker = false;

  final List<String> _availableGoals = ['아침루틴', '개강까지 -5KG', '정돈된 일상'];
  final List<String> _days = ['월', '화', '수', '목', '금', '토', '일'];

  bool _showNameError = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 20);

  @override
  void initState() {
    super.initState();
    if (widget.existingRoutine != null) {
      _routineNameController.text = widget.existingRoutine!['name'] ?? '';
      _memoController.text = widget.existingRoutine!['memo'] ?? '';
      _notificationEnabled =
          widget.existingRoutine!['notificationEnabled'] ?? true;

      final existingTime = widget.existingRoutine!['notificationTime'] as String?;
      if (existingTime != null) {
        final parts = existingTime.split(':');
        if (parts.length == 2) {
          _selectedTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      }

      final existingGoals = widget.existingRoutine!['goals'] as List?;
      if (existingGoals != null) {
        _selectedGoals.addAll(existingGoals.cast<String>());
      }

      final existingDays = widget.existingRoutine!['days'] as List?;
      if (existingDays != null) {
        for (int i = 0; i < _days.length; i++) {
          _selectedDays[i] = existingDays.contains(_days[i]);
        }
      }
    }
  }

  @override
  void dispose() {
    _routineNameController.dispose();
    _memoController.dispose();
    super.dispose();
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          '루틴 생성',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    
                    // 루틴 이름
                    const Text(
                      '루틴이름',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _routineNameController,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (value) {
                        FocusScope.of(context).nextFocus();
                      },
                      decoration: InputDecoration(
                        hintText: '아침 물 마시기',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _showNameError ? Colors.red : Colors.grey[300]!,
                            width: _showNameError ? 2 : 1,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _showNameError ? Colors.red : Colors.grey[300]!,
                            width: _showNameError ? 2 : 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_showNameError)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          '루틴 이름을 입력해주세요',
                          style: TextStyle(fontSize: 12, color: Colors.red[600]),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '예시 : 자기 전 스트레칭, 공복유산소, 이거 보면 목 스트레칭 등',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 24),

                    // 목표 설정
                    const Text(
                      '목표설정',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._availableGoals.map((goal) => _buildGoalChip(goal)),
                        _buildAddGoalChip(),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 알림 설정
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '루틴 알림을 받을까요?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Switch(
                          value: _notificationEnabled,
                          onChanged: (value) {
                            setState(() {
                              _notificationEnabled = value;
                              if (value) {
                                _showTimePicker = true;
                              }
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                      ],
                    ),

                    // 시간 설정 표시
                    if (_notificationEnabled && _selectedTime != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '알림 시간: ${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showTimePicker = true;
                                });
                              },
                              child: Icon(
                                Icons.edit,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_notificationEnabled && _selectedTime != null)
                      const SizedBox(height: 16),

                    const SizedBox(height: 24),

                    // 요일 선택
                    const Text(
                      '얼마나 자주할 건가요?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        7,
                        (i) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDays[i] = !_selectedDays[i];
                              });
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _selectedDays[i]
                                    ? AppTheme.primaryColor
                                    : Colors.white,
                                border: Border.all(
                                  color: _selectedDays[i]
                                      ? AppTheme.primaryColor
                                      : const Color(0xFFE0E0E0),
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Center(
                                child: Text(
                                  _days[i],
                                  style: TextStyle(
                                    color: _selectedDays[i]
                                        ? Colors.white
                                        : const Color(0xFFB0B0B0),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 메모
                    const Text(
                      '메모',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _memoController,
                        maxLines: 4,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (value) {
                          FocusScope.of(context).unfocus();
                        },
                        decoration: InputDecoration(
                          hintText: '메모를 작성해주세요',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: Icon(
                            Icons.edit,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            // 저장하기 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  if (_routineNameController.text.trim().isEmpty) {
                    setState(() {
                      _showNameError = true;
                    });
                    return;
                  }
                  
                  setState(() {
                    _showNameError = false;
                  });
                  
                  final routineVM = context.read<RoutineViewModel>();
                  final selectedDaysList = [
                    for (int i = 0; i < _days.length; i++)
                      if (_selectedDays[i]) _days[i],
                  ];
                  
                  await routineVM.addRoutine(
                    _routineNameController.text.trim(),
                    _selectedGoals,
                    selectedDaysList,
                    _notificationEnabled,
                    '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                    _memoController.text.trim(),
                  );

                  if (_notificationEnabled && selectedDaysList.isNotEmpty) {
                    final alarmId = DateTime.now().millisecondsSinceEpoch;
                    final scheduledTime = DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                      _selectedTime.hour,
                      _selectedTime.minute,
                    );
                    
                    final weekdays = selectedDaysList.map((day) {
                      switch (day) {
                        case '월': return 1;
                        case '화': return 2;
                        case '수': return 3;
                        case '목': return 4;
                        case '금': return 5;
                        case '토': return 6;
                        case '일': return 7;
                        default: return 1;
                      }
                    }).toList();

                    await AlarmUtility.setWeeklyAlarm(
                      id: alarmId,
                      scheduledTime: scheduledTime,
                      title: '루틴 알림',
                      body: '${_routineNameController.text.trim()} 시간입니다!',
                      weekdays: weekdays,
                    );
                  }

                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '저장하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
      bottomSheet: _showTimePicker
          ? TimePickerBottomSheet(
              initialTime: _selectedTime,
              onTimeSelected: (time) {
                setState(() {
                  _selectedTime = time;
                });
              },
              onClose: () {
                setState(() {
                  _showTimePicker = false;
                });
              },
            )
          : null,
    );
  }

  Widget _buildGoalChip(String goal) {
    final isSelected = _selectedGoals.contains(goal);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedGoals.remove(goal);
          } else {
            _selectedGoals.add(goal);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 210, 225, 255)
              : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(18),
          border: isSelected
              ? Border.all(color: AppTheme.primaryColor)
              : Border.all(color: const Color(0xFF888888)),
        ),
        child: Text(
          goal,
          style: TextStyle(
            color: isSelected
                ? AppTheme.primaryColor
                : const Color(0xFF888888),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAddGoalChip() {
    return GestureDetector(
      onTap: () {
        // 목표 추가 기능 (나중에 구현)
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF888888)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: const Color(0xFF888888), size: 16),
            const SizedBox(width: 4),
            Text(
              '목표 추가하기',
              style: const TextStyle(
                color: Color(0xFF888888),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimePickerBottomSheet extends StatefulWidget {
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onTimeSelected;
  final VoidCallback onClose;

  const TimePickerBottomSheet({
    super.key,
    required this.initialTime,
    required this.onTimeSelected,
    required this.onClose,
  });

  @override
  State<TimePickerBottomSheet> createState() => _TimePickerBottomSheetState();
}

class _TimePickerBottomSheetState extends State<TimePickerBottomSheet> {
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
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
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '루틴 알람시간을 설정해주세요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: DateTime(
                2024,
                1,
                1,
                _selectedTime.hour,
                _selectedTime.minute,
              ),
              onDateTimeChanged: (DateTime newDateTime) {
                setState(() {
                  _selectedTime = TimeOfDay(
                    hour: newDateTime.hour,
                    minute: newDateTime.minute,
                  );
                });
              },
              use24hFormat: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  widget.onTimeSelected(_selectedTime);
                  widget.onClose();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
