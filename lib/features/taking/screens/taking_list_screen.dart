import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../view_models/taking_view_model.dart';
import '../widgets/taking_list_item.dart';
import '../../../common/theme/app_theme.dart';

class TakingListScreen extends StatelessWidget {
  const TakingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TakingViewModel>(
      builder: (context, takingVM, child) {
        return const _TakingListScreenBody();
      },
    );
  }
}

class _TakingListScreenBody extends StatefulWidget {
  const _TakingListScreenBody();

  @override
  State<_TakingListScreenBody> createState() => _TakingListScreenBodyState();
}

class _TakingListScreenBodyState extends State<_TakingListScreenBody>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TakingViewModel>().initialize();
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
      context.read<TakingViewModel>().initialize();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when dependencies change (e.g., when navigating back)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TakingViewModel>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '복용 체크리스트',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox.shrink(),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black, size: 28),
            onPressed: () {
              context.push('/taking-add');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              child: Consumer<TakingViewModel>(
                builder: (context, takingVM, _) {
                  // 로딩 상태 표시
                  if (takingVM.isLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF2563EB),
                          ),
                          SizedBox(height: 16),
                          Text(
                            '데이터를 불러오는 중...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // 오류 상태 표시
                  if (takingVM.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 80,
                            color: Colors.red[300],
                          ),
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
                            takingVM.errorMessage!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              takingVM.clearError();
                              takingVM.refresh();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    );
                  }

                  final takingList = takingVM.takingList;

                  // 데이터가 없을 때 빈 상태 UI
                  if (takingList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '복용할 약이 없습니다',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '오른쪽 상단의 + 버튼을 눌러\n복용할 약을 추가해보세요',
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

                  return RefreshIndicator(
                    onRefresh: () async {
                      await takingVM.refresh();
                    },
                    color: const Color(0xFF2563EB),
                    child: ListView.separated(
                      itemCount: takingList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
                      itemBuilder: (context, idx) {
                        final item = takingList[idx];
                        final times = item.times;
                        final checks = takingVM.getChecksForItem(idx);

                        return TakingListItem(
                          name: item.name,
                          times: times,
                          checks: checks,
                          onCheckChanged: (timeIdx, val) {
                            takingVM.updateCheck(idx, timeIdx, val);
                          },
                          onEditPressed: () {
                            // 수정 화면으로 이동
                            context.push('/taking-edit/$idx');
                          },
                          onDeletePressed: () {
                            // 삭제 확인 다이얼로그
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    width: 280,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // 메시지 영역
                                        Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Text(
                                            "'${item.name}'를 삭제하시겠습니까?",
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        // 구분선
                                        Container(
                                          height: 1,
                                          color: const Color(0xFFE0E0E0),
                                        ),
                                        // 버튼 영역
                                        Row(
                                          children: [
                                            // 취소 버튼
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: Container(
                                                  height: 48,
                                                  decoration: const BoxDecoration(
                                                    border: Border(
                                                      right: BorderSide(
                                                        color: Color(0xFFE0E0E0),
                                                        width: 1,
                                                      ),
                                                    ),
                                                  ),
                                                  child: const Center(
                                                    child: Text(
                                                      '취소',
                                                      style: TextStyle(
                                                        color: Color(0xFF666666),
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w400,
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
                                                  Navigator.of(context).pop();
                                                  takingVM.removeTaking(idx);
                                                },
                                                child: Container(
                                                  height: 48,
                                                  child: const Center(
                                                    child: Text(
                                                      '삭제하기',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w400,
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
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
