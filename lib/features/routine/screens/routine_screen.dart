import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../common/theme/app_theme.dart';
import '../view_models/routine_view_model.dart';
import '../widgets/routine_list_item.dart';
import 'set_routine.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  int _selectedTabIndex = 2; // 루틴 탭이므로 2번 인덱스

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RoutineViewModel>(
      create: (_) => RoutineViewModel(),
      child: const _RoutineScreenBody(),
    );
  }
}

class _RoutineScreenBody extends StatefulWidget {
  const _RoutineScreenBody();

  @override
  State<_RoutineScreenBody> createState() => _RoutineScreenBodyState();
}

class _RoutineScreenBodyState extends State<_RoutineScreenBody> {
  // 루틴 데이터
  List<Map<String, dynamic>> _routines = [
    {
      'name': '아침에 물 한 잔',
      'checks': List.generate(7, (_) => false),
      'items': ['아침에 물 한 잔'],
      'days': ['월', '화', '수', '목', '금', '토', '일'],
      'notificationEnabled': false,
      'hour': 7,
      'minute': 0,
      'isAM': true,
    },
    {
      'name': '매일 5천 보 이상 걷기',
      'checks': List.generate(7, (_) => false),
      'items': ['매일 5천 보 이상 걷기'],
      'days': ['월', '화', '수', '목', '금', '토', '일'],
      'notificationEnabled': false,
      'hour': 18,
      'minute': 0,
      'isAM': false,
    },
    {
      'name': '선크림 꼭 바르기',
      'checks': List.generate(7, (_) => false),
      'items': ['선크림 꼭 바르기'],
      'days': ['월', '화', '수', '목', '금', '토', '일'],
      'notificationEnabled': false,
      'hour': 8,
      'minute': 0,
      'isAM': true,
    },
    {
      'name': '공복 유산소',
      'checks': List.generate(7, (_) => false),
      'items': ['공복 유산소'],
      'days': ['월', '화', '수', '목', '금', '토', '일'],
      'notificationEnabled': false,
      'hour': 6,
      'minute': 0,
      'isAM': true,
    },
  ];

  // 루틴 수정 메서드
  void _updateRoutine(int index, String newName) {
    setState(() {
      _routines[index]['name'] = newName;
    });
  }

  // 전체 루틴 데이터 수정 메서드
  void _updateRoutineData(int index, Map<String, dynamic> updatedRoutine) {
    setState(() {
      _routines[index] = updatedRoutine;
    });
  }

  // 루틴 삭제 메서드
  void _deleteRoutine(int index) {
    setState(() {
      _routines.removeAt(index);
    });
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
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black, size: 28),
            onPressed: () async {
              await Future.delayed(const Duration(milliseconds: 100));
              if (context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SetRoutineScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Center(
            child: Text(
              '루틴 체크리스트',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: [
                  // 요일 헤더
                  _buildDaysHeader(),
                  const SizedBox(height: 8),
                  // 루틴 목록
                  Expanded(
                    child: Consumer<RoutineViewModel>(
                      builder: (context, routineVM, _) {
                        return ListView.separated(
                          itemCount: _routines.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final routine = _routines[index];
                            return RoutineListItem(
                              routine: routine,
                              index: index,
                              routineVM: routineVM,
                              routines: _routines,
                              onUpdate: (index, newName) =>
                                  _updateRoutine(index, newName),
                              onUpdateData: (index, updatedRoutine) =>
                                  _updateRoutineData(index, updatedRoutine),
                              onDelete: (index) => _deleteRoutine(index),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 요일 헤더 위젯
  Widget _buildDaysHeader() {
    final List<String> days = ['월', '화', '수', '목', '금', '토', '일'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // 빈 공간 (루틴 이름이 들어갈 자리)
          const SizedBox(width: 120),
          // 요일들
          ...days
              .map(
                (day) => Expanded(
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
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}
