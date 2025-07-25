import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../view_models/taking_view_model.dart';

class AddTakingScreen extends StatelessWidget {
  const AddTakingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TakingViewModel>(
      create: (_) => TakingViewModel(),
      child: const _AddTakingScreenBody(),
    );
  }
}

class _AddTakingScreenBody extends StatefulWidget {
  const _AddTakingScreenBody();

  @override
  State<_AddTakingScreenBody> createState() => _AddTakingScreenBodyState();
}

class _AddTakingScreenBodyState extends State<_AddTakingScreenBody> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedHour = '08';
  String _selectedMinute = '00';
  bool _alarmOn = false;
  final List<String> _hourOptions = [
    '00', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11',
    '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23',
  ];
  final List<String> _minuteOptions = [
    '00', '30',
  ];

  // 시간 리스트 (최대 3개)
  List<String> _takingTimes = ['08:00'];

  final List<String> _medicationTemplates = [
    '타이레놀',
    '이지엔6',
    '게보린',
    '판콜에이',
    '아스피린',
    '부루펜',
    '후시딘',
    '마데카솔',
    '인사돌',
    '이가탄',
  ];

  List<String> _filteredMedications = [];
  FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onSearchChanged);
    _nameController.dispose();
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    String query = _nameController.text.toLowerCase();
    setState(() {
      _filteredMedications = query.isEmpty
          ? []
          : _medicationTemplates
              .where((med) => med.toLowerCase().contains(query))
              .toList();
    });
  }

  void _onFocusChange() {
    if (!_searchFocusNode.hasFocus && _nameController.text.isEmpty) {
      setState(() {
        _filteredMedications = [];
      });
    }
  }

  void _selectMedication(String medication) {
    setState(() {
      _nameController.text = medication;
      _filteredMedications = [];
      _searchFocusNode.unfocus();
    });
  }

  void _addTime() {
    if (_takingTimes.length < 3) {
      setState(() {
        _takingTimes.add('${_selectedHour.padLeft(2, '0')}:${_selectedMinute.padLeft(2, '0')}');
      });
    }
  }

  void _removeTime(int idx) {
    if (_takingTimes.length > 1) {
      setState(() {
        _takingTimes.removeAt(idx);
      });
    }
  }

  void _onComplete() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('약 이름을 입력해주세요')),
      );
      return;
    }
    if (_takingTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('복용 시간을 1개 이상 추가해주세요')),
      );
      return;
    }
    context.read<TakingViewModel>().addTaking(
      _nameController.text.trim(),
      List<String>.from(_takingTimes),
    );
    context.push('/taking-complete');
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
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        toolbarHeight: 56,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    '복용 이력',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '어떤 약을 복용하고 계신가요?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _nameController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(fontSize: 18, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: '예시) 타이레놀, 이지엔6',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search, color: Colors.black),
                        onPressed: () {
                          _searchFocusNode.unfocus();
                        },
                      ),
                    ),
                  ),
                ),
                if (_filteredMedications.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: LimitedBox(
                      maxHeight: 200,
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _filteredMedications.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              _filteredMedications[index],
                              style: const TextStyle(color: Colors.black),
                            ),
                            onTap: () => _selectMedication(_filteredMedications[index]),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 48),
                const Text(
                  '하루 중 언제 먹나요?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                // 시간 리스트 표시
                Column(
                  children: List.generate(_takingTimes.length, (idx) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.black, width: 1.5),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: Text(
                              _takingTimes[idx],
                              style: const TextStyle(color: Colors.black, fontSize: 18),
                            ),
                          ),
                          if (_takingTimes.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _removeTime(idx),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
                // 시간 추가
                if (_takingTimes.length < 3)
                  Row(
                    children: [
                      const Text('시간 추가', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 12),
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.black, width: 1.5),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedHour,
                            dropdownColor: Colors.white,
                            iconEnabledColor: Colors.black,
                            style: const TextStyle(color: Colors.black, fontSize: 18),
                            items: _hourOptions.map((hour) => DropdownMenuItem(
                              value: hour,
                              child: Text(hour, style: const TextStyle(color: Colors.black)),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedHour = val);
                            },
                          ),
                        ),
                      ),
                      const Text('시', style: TextStyle(color: Colors.black, fontSize: 18)),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.black, width: 1.5),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedMinute,
                            dropdownColor: Colors.white,
                            iconEnabledColor: Colors.black,
                            style: const TextStyle(color: Colors.black, fontSize: 18),
                            items: _minuteOptions.map((minute) => DropdownMenuItem(
                              value: minute,
                              child: Text(minute, style: const TextStyle(color: Colors.black)),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedMinute = val);
                            },
                          ),
                        ),
                      ),
                      const Text('분', style: TextStyle(color: Colors.black, fontSize: 18)),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE0E0E0),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.black, size: 20),
                          onPressed: _addTime,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                const Text(
                  '시간은 0~23시 사이, 분은 30분 단위로 입력할 수 있어요',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const Text(
                  '먹는 시간은 + 버튼을 눌러 3개까지 설정할 수 있어요',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 48),
                const Text(
                  '복용 전 알림을 받을까요?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '알림',
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ),
                    Transform.scale(
                      scale: 1.2,
                      child: Switch(
                        value: _alarmOn,
                        onChanged: (val) => setState(() => _alarmOn = val),
                        activeColor: Colors.black,
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _onComplete,
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
          ),
        ],
      ),
    );
  }
}