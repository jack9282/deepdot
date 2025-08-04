import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../view_models/routine_view_model.dart';

class SetRoutineScreen extends StatefulWidget {
  final Map<String, dynamic>? existingRoutine; // 기존 루틴 데이터 (수정 시 사용)
  final int? routineIndex; // 수정할 루틴의 인덱스

  const SetRoutineScreen({super.key, this.existingRoutine, this.routineIndex});

  @override
  State<SetRoutineScreen> createState() => _SetRoutineScreenState();
}

class _SetRoutineScreenState extends State<SetRoutineScreen> {
  final TextEditingController _routineNameController = TextEditingController();
  final List<String> _routineItems = ['명상 10분', '일어나자마자 미지근한 물 한 잔 마시기'];
  final List<bool> _selectedDays = [
    true,
    false,
    true,
    false,
    true,
    false,
    false,
  ]; // 월, 수, 금 선택
  bool _notificationEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  bool _isAM = true;

  final List<String> _days = ['월', '화', '수', '목', '금', '토', '일'];
  
  // 추가: 루틴 이름 에러 상태
  bool _showNameError = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRoutine != null) {
      _routineNameController.text = widget.existingRoutine!['name'] ?? '';
      _routineItems.clear();
      _routineItems.addAll(widget.existingRoutine!['items'] ?? []);
      _selectedDays.fillRange(0, 7, false); // 기존 데이터의 요일 선택 상태로 초기화
      for (int i = 0; i < _selectedDays.length; i++) {
        if (widget.existingRoutine!['days']?.contains(_days[i]) ?? false) {
          _selectedDays[i] = true;
        }
      }
      _notificationEnabled =
          widget.existingRoutine!['notificationEnabled'] ?? false;
      _selectedTime = TimeOfDay(
        hour: widget.existingRoutine!['hour'] ?? 7,
        minute: widget.existingRoutine!['minute'] ?? 0,
      );
      _isAM = widget.existingRoutine!['isAM'] ?? true;
    }
  }

  @override
  void dispose() {
    _routineNameController.dispose();
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                widget.existingRoutine != null ? '루틴 수정' : '루틴 생성',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 루틴 이름 입력
            Row(
              children: [
                const Text(
                  '루틴 이름',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _showNameError ? Colors.red : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _routineNameController,
                          decoration: InputDecoration(
                            hintText: '아침 루틴',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.transparent,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      if (_showNameError)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 4),
                          child: Text(
                            '루틴 이름을 입력해주세요',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 루틴 항목
            const Text(
              '루틴에 포함할 항목',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              _routineItems.length,
              (index) => _buildRoutineItem(_routineItems[index], index),
            ),
            const SizedBox(height: 8),
            _buildAddItemButton(),
            const SizedBox(height: 24),

            // 루틴 빈도 설정
            const Text(
              '얼마나 자주 할건가요?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '요일 선택',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            _buildDaysSelector(),
            const SizedBox(height: 24),

            // 알림 설정
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '알림을 받으시겠어요?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Switch(
                  value: _notificationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationEnabled = value;
                    });
                  },
                  activeColor: Colors.black,
                ),
              ],
            ),
            if (_notificationEnabled) ...[
              const SizedBox(height: 12),
              const Text(
                '시간 선택',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              _buildTimeSelector(),
            ],
            const SizedBox(height: 24),

            // 요약 텍스트
            Center(
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _buildSummaryText(),
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 확인 버튼
            Center(
              child: GestureDetector(
                onTap: () async {
                  // 루틴 이름 검증
                  if (_routineNameController.text.trim().isEmpty) {
                    setState(() {
                      _showNameError = true;
                    });
                    return;
                  }
                  setState(() {
                    _showNameError = false;
                  });

                  // 수정된 루틴 데이터 생성
                  final updatedRoutine = {
                    'name': _routineNameController.text,
                    'items': List<String>.from(_routineItems),
                    'days': _days
                        .where((day) => _selectedDays[_days.indexOf(day)])
                        .toList(),
                    'notificationEnabled': _notificationEnabled,
                    'hour': _selectedTime.hour,
                    'minute': _selectedTime.minute,
                    'isAM': _isAM,
                  };

                  final routineVM = context.read<RoutineViewModel>();

                  // 수정 모드인 경우 이전 화면으로 결과 반환
                  if (widget.existingRoutine != null) {
                    Navigator.of(context).pop({
                      'routine': updatedRoutine,
                      'index': widget.routineIndex,
                    });
                  } else {
                    // 새 루틴 생성인 경우 DataManager에 저장
                    await routineVM.addRoutine(
                      _routineNameController.text,
                      List<String>.from(_routineItems),
                      _days.where((day) => _selectedDays[_days.indexOf(day)]).toList(),
                      _notificationEnabled,
                      _selectedTime.hour,
                      _selectedTime.minute,
                      _isAM,
                    );
                    // 완료 화면으로 이동
                    context.go('/routine-complete');
                  }
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF232B3A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineItem(String item, int index) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ),
          IconButton(
            icon: Icon(
              index == 0 ? Icons.add : Icons.remove,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                if (index == 0) {
                  // 첫 번째 항목은 추가 버튼 (실제로는 아무것도 하지 않음)
                } else {
                  // 두 번째 항목은 삭제 버튼
                  _routineItems.removeAt(index);
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          '+ 항목 추가',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildDaysSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        7,
        (index) => GestureDetector(
          onTap: () {
            setState(() {
              _selectedDays[index] = !_selectedDays[index];
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _selectedDays[index] ? Colors.black : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _days[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _selectedDays[index] ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // AM/PM 선택
          Expanded(
            child: CupertinoPicker(
              itemExtent: 30,
              onSelectedItemChanged: (index) {
                setState(() {
                  _isAM = index == 0;
                });
              },
              children: const [
                Center(child: Text('오전')),
                Center(child: Text('오후')),
              ],
            ),
          ),
          // 시간 선택
          Expanded(
            child: CupertinoPicker(
              itemExtent: 30,
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedTime = TimeOfDay(
                    hour: _isAM ? index + 1 : index + 13,
                    minute: _selectedTime.minute,
                  );
                });
              },
              children: List.generate(
                12,
                (index) => Center(child: Text('${index + 1}')),
              ),
            ),
          ),
          // 분 선택
          Expanded(
            child: CupertinoPicker(
              itemExtent: 30,
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedTime = TimeOfDay(
                    hour: _selectedTime.hour,
                    minute: index * 5,
                  );
                });
              },
              children: List.generate(
                12,
                (index) => Center(
                  child: Text('${(index * 5).toString().padLeft(2, '0')}'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildSummaryText() {
    final selectedDayNames = <String>[];
    for (int i = 0; i < _selectedDays.length; i++) {
      if (_selectedDays[i]) {
        selectedDayNames.add(_days[i]);
      }
    }

    final timeText = _isAM ? '오전' : '오후';
    final hourText = _selectedTime.hour > 12
        ? _selectedTime.hour - 12
        : _selectedTime.hour;
    final minuteText = _selectedTime.minute.toString().padLeft(2, '0');

    return '${selectedDayNames.join(', ')} $timeText ${hourText}시 ${minuteText}분에 알림을 받을게요';
  }
}
