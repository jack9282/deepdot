import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/routine_view_model.dart';
import '../widgets/routine_list_item.dart';
import 'set_routine.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutineViewModel>().initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<RoutineViewModel>().initialize();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutineViewModel>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final routineVM = context.watch<RoutineViewModel>();
    final List<String> goals = routineVM.routineList
        .map((r) => r.name)
        .toList();
    if (_selectedGoal.isEmpty && goals.isNotEmpty) {
      _selectedGoal = goals.first;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Center(
          child: Text(
            '루틴 체크리스트',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox.shrink(),
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
      body: goals.isEmpty
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
          : Column(
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
                      const Row(
                        children: [
                          Text(
                            '목표',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: goals.map((goal) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _GoalTabButton(
                                text: goal,
                                selected: _selectedGoal == goal,
                                onTap: () {
                                  setState(() {
                                    _selectedGoal = goal;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
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
                                          routine.name == _selectedGoal,
                                    )
                                    .toList();

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
                                              final checks = routineVM
                                                  .getChecksForRoutine(
                                                    routineVM.routineList
                                                        .indexOf(routine),
                                                  );
                                              final routineMap = {
                                                'id': routine.id,
                                                'name': routine.name,
                                                'items': routine.items
                                                    .map((e) => e.toJson())
                                                    .toList(),
                                                'notificationEnabled':
                                                    routine.notificationEnabled,
                                                'hour': routine.hour,
                                                'minute': routine.minute,
                                                'isAM': routine.isAM,
                                                'createdAt': routine.createdAt,
                                                'updatedAt': routine.updatedAt,
                                                'checks': checks,
                                              };
                                              return RoutineListItem(
                                                routine: routineMap,
                                                index: routineVM.routineList
                                                    .indexOf(routine),
                                                routineVM: routineVM,
                                                onDelete: (originalIndex) {
                                                  routineVM.removeRoutine(
                                                    originalIndex,
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
    );
  }

  Widget _buildDaysHeader() {
    final List<String> days = ['월', '화', '수', '목', '금', '토', '일'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 120),
          ...List.generate(
            days.length,
            (i) => Expanded(
              child: Center(
                child: Text(
                  days[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: i == 6
                        ? const Color(0xFFFF5A5A)
                        : const Color(0xFFB0B0B0),
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
  final VoidCallback? onTap;

  const _GoalTabButton({required this.text, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color.fromARGB(255, 210, 225, 255)
              : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(18),
          border: selected
              ? Border.all(color: const Color(0xFF3973F4))
              : Border.all(color: const Color(0xFF888888)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? const Color(0xFF3973F4) : const Color(0xFF888888),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
