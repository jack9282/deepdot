import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/routine_view_model.dart';
import '../widgets/routine_list_item.dart';
import 'set_routine.dart';
import '../../../common/theme/app_theme.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  @override
  Widget build(BuildContext context) {
    return const _RoutineScreenBody();
  }
}

class _RoutineScreenBody extends StatefulWidget {
  const _RoutineScreenBody();

  @override
  State<_RoutineScreenBody> createState() => _RoutineScreenBodyState();
}

class _RoutineScreenBodyState extends State<_RoutineScreenBody>
    with WidgetsBindingObserver {
  String _selectedGoal = '';
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 앱이 재개될 때만 초기화 (중복 방지)
      final routineVM = context.read<RoutineViewModel>();
      if (routineVM.isInitialized && !_isInitializing) {
        _isInitializing = true;
        routineVM.refresh().then((_) {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 한 번만 초기화 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final routineVM = context.read<RoutineViewModel>();
      if (!routineVM.isInitialized && !_isInitializing) {
        _isInitializing = true;
        routineVM.initialize().then((_) {
          _isInitializing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final routineVM = context.watch<RoutineViewModel>();
    final List<String> goals = routineVM.availableGoalNames;

    // 목표 목록이 비어있을 때 기본 목표 설정
    if (_selectedGoal.isEmpty) {
      if (goals.isNotEmpty) {
        _selectedGoal = goals.first;
        // 초기 목표의 루틴 불러오기
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final routineVM = context.read<RoutineViewModel>();
          await routineVM.loadRoutinesForGoal(_selectedGoal);
        });
      } else {
        // 목표가 없을 때는 빈 문자열로 설정
        _selectedGoal = '';
      }
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 250, 255),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            title: const Text(
              '루틴 체크리스트',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const SizedBox.shrink(),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: IconButton(
                  icon: const Icon(Icons.add, color: AppTheme.greyPrimaryColor),
                  iconSize: 25,
                  alignment: Alignment.center,
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
              ),
            ],
          ),
        ),
      ),
      body: routineVM.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2563EB)),
                  SizedBox(height: 16),
                  Text(
                    '데이터를 불러오는 중...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : routineVM.errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    '오류가 발생했습니다',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.red[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    routineVM.errorMessage!,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: routineVM.isLoading
                        ? null
                        : () async {
                            routineVM.clearError();
                            await routineVM.refresh();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: routineVM.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('다시 시도'),
                  ),
                ],
              ),
            )
          : routineVM.routineList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '루틴이 없습니다',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '오른쪽 상단의 + 버튼을 눌러\n루틴을 추가해보세요',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await routineVM.refresh();
              },
              color: const Color(0xFF2563EB),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 24,
                      right: 24,
                      bottom: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '목표',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              '|',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 18,
                                color: AppTheme.textGreyColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (goals.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: const Text(
                                  '사용 가능한 목표가 없습니다',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            else
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: goals.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final goal = entry.value;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _GoalTabButton(
                                        text: goal,
                                        selected: _selectedGoal == goal,
                                        colorIndex: index,
                                        onTap: () async {
                                          if (_selectedGoal == goal)
                                            return; // 같은 목표 선택 시 무시

                                          setState(() {
                                            _selectedGoal = goal;
                                          });

                                          // 선택된 목표의 루틴을 서버에서 새로 불러오기
                                          final routineVM = context
                                              .read<RoutineViewModel>();
                                          await routineVM.loadRoutinesForGoal(
                                            goal,
                                          );
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  if (goals.isNotEmpty)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Consumer<RoutineViewModel>(
                                  builder: (context, routineVM, _) {
                                    final routineList = routineVM.routineList
                                        .where(
                                          (routine) =>
                                              routine.goalName == _selectedGoal,
                                        )
                                        .toList();
                                    
                                    final goalIndex = goals.indexOf(_selectedGoal);

                                    if (routineList.isEmpty) {
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.assignment_outlined,
                                              size: 80,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              '루틴이 없습니다',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '오른쪽 상단의 + 버튼을 눌러\n루틴을 추가해보세요',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[500],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return Stack(
                                      children: [
                                        Column(
                                          children: [
                                            _buildDaysHeader(),
                                            const SizedBox(height: 8),
                                            Expanded(
                                              child: ListView.separated(
                                                itemCount: routineList.length,
                                                separatorBuilder: (_, __) =>
                                                    const SizedBox(height: 8),
                                                itemBuilder: (context, index) {
                                                  final routine =
                                                      routineList[index];
                                                  final routineMap = {
                                                    'routineId':
                                                        routine.routineId,
                                                    'name': routine.name,
                                                    'goalId': routine.goalId,
                                                    'goalName':
                                                        routine.goalName,
                                                    'mon': routine.mon,
                                                    'tue': routine.tue,
                                                    'wed': routine.wed,
                                                    'thu': routine.thu,
                                                    'fri': routine.fri,
                                                    'sat': routine.sat,
                                                    'sun': routine.sun,
                                                    'active': routine.active,
                                                    'memo': routine.memo,
                                                    'startTime':
                                                        routine.startTime,
                                                    'createdAt':
                                                        routine.createdAt,
                                                    'updatedAt':
                                                        routine.updatedAt,
                                                  };
                                                  return RoutineListItem(
                                                    routine: routineMap,
                                                    index: index,
                                                    routineVM: routineVM,
                                                    goalIndex: goalIndex,
                                                    onDelete: (routineIdOrIndex) {
                                                      showDialog(
                                                        context: context,
                                                        builder: (BuildContext context) {
                                                          return Dialog(
                                                            backgroundColor:
                                                                Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            child: Container(
                                                              width: 280,
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  // 메시지 영역
                                                                  Padding(
                                                                    padding:
                                                                        const EdgeInsets.all(
                                                                          24,
                                                                        ),
                                                                    child: Text(
                                                                      "'${routine.name}'를 삭제하시겠습니까?",
                                                                      style: const TextStyle(
                                                                        color: Colors
                                                                            .black,
                                                                        fontSize:
                                                                            16,
                                                                        fontWeight:
                                                                            FontWeight.w400,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                  ),
                                                                  // 구분선
                                                                  Container(
                                                                    height: 1,
                                                                    color: const Color(
                                                                      0xFFE0E0E0,
                                                                    ),
                                                                  ),
                                                                  // 버튼 영역
                                                                  Row(
                                                                    children: [
                                                                      // 취소 버튼
                                                                      Expanded(
                                                                        child: GestureDetector(
                                                                          onTap: () {
                                                                            Navigator.of(
                                                                              context,
                                                                            ).pop();
                                                                          },
                                                                          child: Container(
                                                                            height:
                                                                                48,
                                                                            decoration: const BoxDecoration(
                                                                              border: Border(
                                                                                right: BorderSide(
                                                                                  color: Color(
                                                                                    0xFFE0E0E0,
                                                                                  ),
                                                                                  width: 1,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            child: const Center(
                                                                              child: Text(
                                                                                '취소',
                                                                                style: TextStyle(
                                                                                  color: Color(
                                                                                    0xFF666666,
                                                                                  ),
                                                                                  fontSize: 16,
                                                                                  fontWeight: FontWeight.w400,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      // 삭제 버튼
                                                                      Expanded(
                                                                        child: GestureDetector(
                                                                          onTap: () {
                                                                            Navigator.of(
                                                                              context,
                                                                            ).pop();
                                                                            // routineIdOrIndex가 int인 경우 routineId로 처리
                                                                            if (routineIdOrIndex
                                                                                is int) {
                                                                              routineVM.removeRoutine(
                                                                                routineIdOrIndex,
                                                                              );
                                                                            }
                                                                          },
                                                                          child: Container(
                                                                            height:
                                                                                48,
                                                                            child: const Center(
                                                                              child: Text(
                                                                                '삭제하기',
                                                                                style: TextStyle(
                                                                                  color: Colors.red,
                                                                                  fontSize: 16,
                                                                                  fontWeight: FontWeight.w400,
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
                                                          );
                                                        },
                                                      );
                                                    },
                                                    onEditPressed: () {
                                                      Navigator.of(
                                                        context,
                                                      ).push(
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              SetRoutineScreen(
                                                                existingRoutine:
                                                                    routineMap,
                                                                routineIndex: routineVM
                                                                    .routineList
                                                                    .indexOf(
                                                                      routine,
                                                                    ),
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildDaysHeader() {
    final List<String> days = ['월', '화', '수', '목', '금', '토', '일'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 100),
          ...List.generate(
            days.length,
            (i) => Expanded(
              child: Center(
                child: Text(
                  days[i],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: i == 6
                        ? Colors.red
                        : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalTabButton extends StatelessWidget {
  final String text;
  final bool selected;
  final int colorIndex;
  final VoidCallback? onTap;

  const _GoalTabButton({
    required this.text, 
    this.selected = false, 
    required this.colorIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.checkListColor[colorIndex % AppTheme.checkListColor.length];
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.2)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: selected
              ? Border.all(color: color, width: 1.5)
              : Border.all(color: AppTheme.textGreyColor, width: 1.5),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected
                ? color
                : AppTheme.textGreyColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
