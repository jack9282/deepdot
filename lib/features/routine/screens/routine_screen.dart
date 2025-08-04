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

class _RoutineScreenBodyState extends State<_RoutineScreenBody> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 초기 데이터 로드
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
      // App came back to foreground, refresh data
      context.read<RoutineViewModel>().initialize();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when dependencies change (e.g., when navigating back)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutineViewModel>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Center(
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: [
                  // 루틴 목록
                  Expanded(
                    child: Consumer<RoutineViewModel>(
                      builder: (context, routineVM, _) {
                        final routineList = routineVM.routineList;
                        
                        // 데이터가 없을 때 빈 상태 UI
                        if (routineList.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                        
                        return Column(
                          children: [
                            // 요일 헤더 (루틴이 있을 때만 표시)
                            _buildDaysHeader(),
                            const SizedBox(height: 8),
                            // 루틴 목록
                            Expanded(
                              child: ListView.separated(
                                itemCount: routineList.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final routine = routineList[index];
                                  final checks = routineVM.getChecksForItem(index);
                                  
                                  // 체크 상태를 루틴 데이터에 추가
                                  final routineWithChecks = Map<String, dynamic>.from(routine);
                                  routineWithChecks['checks'] = checks;
                                  
                                  return RoutineListItem(
                                    routine: routineWithChecks,
                                    index: index,
                                    routineVM: routineVM,
                                    onDelete: (index) {
                                      routineVM.removeRoutine(index);
                                    },
                                  );
                                },
                              ),
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
