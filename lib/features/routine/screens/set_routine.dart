import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../view_models/routine_view_model.dart';
import '../../../data/models/routine_model.dart';

class SetRoutineScreen extends StatefulWidget {
  final Map<String, dynamic>? existingRoutine; // 기존 루틴 데이터 (수정 시 사용)
  final int? routineIndex; // 수정할 루틴의 인덱스

  const SetRoutineScreen({super.key, this.existingRoutine, this.routineIndex});

  @override
  State<SetRoutineScreen> createState() => _SetRoutineScreenState();
}

class _SetRoutineScreenState extends State<SetRoutineScreen> {
  final TextEditingController _routineNameController = TextEditingController();
  final List<_RoutineItemEdit> _routineItems = [
    _RoutineItemEdit(name: '명상 10분', days: [true, false, true, false, true, false, false]),
    _RoutineItemEdit(name: '일어나자마자 미지근한 물 한 잔 마시기', days: [true, false, true, false, true, false, false]),
  ];
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
  bool _showItemsError = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRoutine != null) {
      _routineNameController.text = widget.existingRoutine!['name'] ?? '';
      _routineItems.clear();
      final items = widget.existingRoutine!['items'] as List?;
      if (items != null) {
        for (final item in items) {
          _routineItems.add(_RoutineItemEdit(
            name: item['name'] ?? '',
            days: List.generate(7, (i) => (item['days'] as List).contains(_days[i])),
          ));
        }
      }
      _notificationEnabled = widget.existingRoutine!['notificationEnabled'] ?? false;
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
    final exampleChips = [
      '아침에 미지근한 물 한잔 마시기',
      '자기 전 스트레칭',
      '공복 유산소',
    ];
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
        title: const Text('루틴 생성', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // 루틴 이름
              const Text('목표 이름', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
              const SizedBox(height: 8),
              TextField(
                controller: _routineNameController,
                // 'enabled: false'를 'enabled: true'로 변경하여 텍스트 필드를 활성화합니다.
                enabled: true, 
                decoration: InputDecoration(
                  hintText: '아침루틴',
                  hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _showNameError ? Colors.red : Colors.transparent,
                      width: _showNameError ? 2 : 0,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: const TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.w500),
              ),
              if (_showNameError)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    '목표 이름을 입력해주세요',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[600],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              // 루틴 항목
              const Text('루틴에 포함할 항목', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
              const SizedBox(height: 8),
              ..._routineItems.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: item.controller,
                              decoration: InputDecoration(
                                hintText: '루틴 항목',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: _showItemsError && item.controller.text.trim().isEmpty ? Colors.red : Colors.transparent,
                                    width: _showItemsError && item.controller.text.trim().isEmpty ? 2 : 0,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              style: const TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.w500),
                            ),
                            if (_showItemsError && item.controller.text.trim().isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 4),
                                child: Text(
                                  '루틴 항목을 입력해주세요',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red[600],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(7, (i) => GestureDetector(
                                onTap: () {
                                  setState(() {
                                    item.days[i] = !item.days[i];
                                  });
                                },
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: item.days[i] ? const Color(0xFF3973F4) : Colors.white,
                                    border: Border.all(color: item.days[i] ? const Color(0xFF3973F4) : const Color(0xFFE0E0E0)),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Center(
                                    child: Text(_days[i], style: TextStyle(
                                      color: item.days[i] ? Colors.white : const Color(0xFFB0B0B0),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    )),
                                  ),
                                ),
                              )),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (idx == 0)
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFF3973F4)),
                          onPressed: () {
                            setState(() {
                              _routineItems.add(_RoutineItemEdit(name: '', days: List.filled(7, false)));
                            });
                          },
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Color(0xFFEA4335)),
                          onPressed: () {
                            setState(() {
                              _routineItems.removeAt(idx);
                            });
                          },
                        ),
                    ],
                  ),
                );
              }),
              // 예시 chips
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: exampleChips.map((e) => Chip(
                    label: Text(e, style: const TextStyle(fontSize: 13, color: Color(0xFFB0B0B0))),
                    backgroundColor: const Color(0xFFF5F6FA),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  )).toList(),
                ),
              ),
              // 빈 공간
              const SizedBox(height: 8),
              // 요일 선택
              const Text('얼마나 자주할 건가요?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(7, (i) => Padding(
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
                        color: _selectedDays[i] ? const Color(0xFF3973F4) : Colors.white,
                        border: Border.all(color: _selectedDays[i] ? const Color(0xFF3973F4) : const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(_days[i], style: TextStyle(
                          color: _selectedDays[i] ? Colors.white : const Color(0xFFB0B0B0),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        )),
                      ),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 24),
              // 알림 스위치
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('루틴 알림을 받을까요?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
                  Switch(
                    value: _notificationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationEnabled = value;
                      });
                    },
                    activeColor: const Color(0xFF3973F4),
                  ),
                ],
              ),
              const Spacer(),
              // 저장하기 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    // 루틴 이름 검증
                    if (_routineNameController.text.trim().isEmpty) {
                      setState(() {
                        _showNameError = true;
                        _showItemsError = true;
                      });
                      return;
                    }
                    // 루틴 항목 검증
                    final validItems = _routineItems.where((e) => e.controller.text.trim().isNotEmpty).toList();
                    if (validItems.isEmpty) {
                      setState(() {
                        _showItemsError = true;
                      });
                      return;
                    }
                    // 목표 이름 중복 체크
                    final exists = context.read<RoutineViewModel>().routineList.any((r) => r.name == _routineNameController.text.trim());
                    if (exists && widget.existingRoutine == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('이미 존재하는 목표 이름입니다.')),);
                      return;
                    }
                    setState(() {
                      _showNameError = false;
                      _showItemsError = false;
                    });
                    final routineVM = context.read<RoutineViewModel>();
                    final items = _routineItems
                        .where((e) => e.controller.text.trim().isNotEmpty)
                        .map((e) => RoutineItem(
                              name: e.controller.text.trim(),
                              days: [for (int i = 0; i < 7; i++) if (e.days[i]) _days[i]],
                            ))
                        .toList();
                    await routineVM.addRoutine(
                      _routineNameController.text,
                      items,
                      _notificationEnabled,
                      _selectedTime.hour,
                      _selectedTime.minute,
                      _isAM,
                    );
                    
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3973F4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('저장하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
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
            width: 36,
            height: 36,
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

class _RoutineItemEdit {
  final TextEditingController controller;
  final List<bool> days;
  _RoutineItemEdit({String name = '', List<bool>? days})
      : controller = TextEditingController(text: name),
        days = days ?? List.filled(7, false);
}
