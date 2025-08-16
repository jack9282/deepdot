import 'package:deepdot/common/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../view_models/taking_view_model.dart';
import '../../../utils/alarm.dart';

class SetTakingScreen extends StatelessWidget {
  final int? editIndex;

  const SetTakingScreen({super.key, this.editIndex});

  @override
  Widget build(BuildContext context) {
    return _AddTakingScreenBody(editIndex: editIndex);
  }
}

class _AddTakingScreenBody extends StatefulWidget {
  final int? editIndex;

  const _AddTakingScreenBody({this.editIndex});

  @override
  State<_AddTakingScreenBody> createState() => _AddTakingScreenBodyState();
}

class _AddTakingScreenBodyState extends State<_AddTakingScreenBody> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedHour = '08';
  String _selectedMinute = '00';
  bool _alarmOn = false;
  final List<String> _hourOptions = [
    '00',
    '01',
    '02',
    '03',
    '04',
    '05',
    '06',
    '07',
    '08',
    '09',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20',
    '21',
    '22',
    '23',
  ];
  final List<String> _minuteOptions = ['00', '30'];

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

  // 최근 검색어: [{name: '콘서타', date: '07.28'}]
  List<Map<String, String>> _recentSearches = [
    {'name': '콘서타', 'date': '07.28'},
    {'name': '캄베이서', 'date': '07.26'},
    {'name': '페니드', 'date': '07.24'},
    {'name': '페로스핀', 'date': '07.20'},
  ];

  // 추가: 약 이름 에러 상태
  bool _showNameError = false;

  void _addRecentSearch(String name) {
    final now = DateTime.now();
    final date =
        now.month.toString().padLeft(2, '0') +
        '.' +
        now.day.toString().padLeft(2, '0');
    setState(() {
      _recentSearches.removeWhere((item) => item['name'] == name);
      _recentSearches.insert(0, {'name': name, 'date': date});
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.sublist(0, 10);
      }
    });
  }

  void _removeRecentSearch(int idx) {
    setState(() {
      _recentSearches.removeAt(idx);
    });
  }

  void _clearAllRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChange);

    // 수정 모드일 때 기존 데이터 불러오기
    if (widget.editIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingData();
      });
    }
  }

  void _loadExistingData() {
    final takingVM = context.read<TakingViewModel>();
    if (widget.editIndex! < takingVM.takingList.length) {
      final item = takingVM.takingList[widget.editIndex!];
      setState(() {
        _nameController.text = item.name;
        _takingTimes = List<String>.from(item.times);
        _alarmOn = item.alarmEnabled;
        final timeParts = item.alarmTime.split(':');
        _selectedHour = timeParts[0];
        _selectedMinute = timeParts[1];
      });
    }
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
    _addRecentSearch(medication);
  }

  void _addTime() {
    if (_takingTimes.length < 3) {
      setState(() {
        _takingTimes.add(
          '${_selectedHour.padLeft(2, '0')}:${_selectedMinute.padLeft(2, '0')}',
        );
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

  void _onComplete() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _showNameError = true;
      });
      return;
    }
    setState(() {
      _showNameError = false;
    });
    if (_takingTimes.isEmpty) {
      return;
    }

    final takingVM = context.read<TakingViewModel>();

    try {
      if (widget.editIndex != null) {
        await takingVM.updateTaking(
          widget.editIndex!,
          _nameController.text.trim(),
          List<String>.from(_takingTimes),
          _alarmOn,
          '${_selectedHour}:${_selectedMinute}',
        );
      } else {
        await takingVM.addTaking(
          _nameController.text.trim(),
          List<String>.from(_takingTimes),
          _alarmOn,
          '${_selectedHour}:${_selectedMinute}',
        );
      }

      if (_alarmOn) {
        final alarmId = DateTime.now().millisecondsSinceEpoch;
        
        for (final time in _takingTimes) {
          final timeParts = time.split(':');
          final scheduledTime = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );

          await AlarmUtility.setAlarm(
            id: alarmId + _takingTimes.indexOf(time),
            scheduledTime: scheduledTime,
            title: '복용 알림',
            body: '${_nameController.text.trim()} 복용 시간입니다!',
          );
        }
      }
      
      context.push('/taking-complete');
    } catch (e) {
      print('Error saving data: $e');
    }
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
        title: Text(
          widget.editIndex != null ? '복용이력 수정' : '복용이력 작성',
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        toolbarHeight: 56,
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
                border: Border.all(
                  color: _showNameError ? Colors.red : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _nameController,
                focusNode: _searchFocusNode,
                style: const TextStyle(fontSize: 18, color: Colors.black),
                decoration: InputDecoration(
                  hintText: '예시) 타이레놀, 이지엔6',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Colors.black),
                    onPressed: () {
                      _searchFocusNode.unfocus();
                      if (_nameController.text.trim().isNotEmpty) {
                        _addRecentSearch(_nameController.text.trim());
                      }
                    },
                  ),
                ),
              ),
            ),
            if (_showNameError)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Text(
                  '약 이름을 입력해주세요',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            // 최근 검색어 UI
            if (_recentSearches.isNotEmpty && _searchFocusNode.hasFocus) ...[
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '최근 검색어',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearAllRecentSearches,
                    child: const Text(
                      '전체삭제',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentSearches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (context, idx) {
                  final item = _recentSearches[idx];
                  return Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _selectMedication(item['name']!);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              item['name']!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        item['date'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeRecentSearch(idx),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
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
                        onTap: () =>
                            _selectMedication(_filteredMedications[index]),
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
            const Text(
              '먹는시간',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 12),
            // 시간 추가
            if (_takingTimes.length < 3)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          bottom: BorderSide(color: AppTheme.primaryColor, width: 1),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedHour,
                          dropdownColor: Colors.white,
                          iconEnabledColor: Colors.black,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          items: _hourOptions
                              .map(
                                (hour) => DropdownMenuItem(
                                  value: hour,
                                  child: Text(
                                    '${hour}시',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedHour = val);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          bottom: BorderSide(color: AppTheme.primaryColor, width: 1),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMinute,
                          dropdownColor: Colors.white,
                          iconEnabledColor: Colors.black,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          items: _minuteOptions
                              .map(
                                (minute) => DropdownMenuItem(
                                  value: minute,
                                  child: Text(
                                    '${minute}분',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _selectedMinute = val);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _addTime,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            const Text(
              '시간은 0~23시 사이, 분은 30분 단위로 입력할 수 있어요',
              style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
            const Text(
              '먹는 시간은 +버튼을 눌러 3개까지 설정할 수 있어요',
              style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 20),
            // 시간 리스트 표시 (카드 형태)
            Column(
              children: List.generate(_takingTimes.length, (idx) {
                final timeParts = _takingTimes[idx].split(':');
                final hour = timeParts[0];
                final minute = timeParts[1];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    children: [
                                             Text(
                         '${hour}시 ${minute}분',
                         style: TextStyle(
                           color: AppTheme.primaryColor,
                           fontSize: 16,
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                      const Spacer(),
                                             if (_takingTimes.length > 1)
                         GestureDetector(
                           onTap: () => _removeTime(idx),
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                             decoration: BoxDecoration(
                               color: Colors.white,
                               borderRadius: BorderRadius.circular(16),
                               border: Border.all(color: Colors.red),
                             ),
                             child: const Text(
                               '삭제',
                               style: TextStyle(
                                 color: Colors.red,
                                 fontSize: 14,
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                           ),
                         ),
                    ],
                  ),
                );
              }),
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
                Switch(
                  value: _alarmOn,
                  onChanged: (val) {
                    setState(() {
                      _alarmOn = val;
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
                  ],
                ),
              ),
            ),
            // 저장하기 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _onComplete,
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
    );
  }
}
