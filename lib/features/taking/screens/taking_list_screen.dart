import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../view_models/taking_view_model.dart';
import '../../../common/theme/app_theme.dart';

class TakingListScreen extends StatelessWidget {
  const TakingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TakingViewModel>(
      create: (_) => TakingViewModel(),
      child: const _TakingListScreenBody(),
    );
  }
}

class _TakingListScreenBody extends StatefulWidget {
  const _TakingListScreenBody();

  @override
  State<_TakingListScreenBody> createState() => _TakingListScreenBodyState();
}

class _TakingListScreenBodyState extends State<_TakingListScreenBody> {

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
            child: Center(
              child: Text(
                '복용 체크리스트',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              child: Consumer<TakingViewModel>(
                builder: (context, takingVM, _) {
                  final takingList = takingVM.takingList;
                  return ListView.separated(
                    itemCount: takingList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, idx) {
                      final item = takingList[idx];
                      final times = item['times'] as List<String>;
                      final checks = item['checks'] as List<bool>? ?? List.generate(times.length, (_) => false);
                      
                      return Container(
                        height: 85 + 20.0 * (times.length - 1),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      // 수정 기능: set_taking.dart로 이동
                                      context.push('/taking-edit/$idx');
                                    } else if (value == 'delete') {
                                      // 삭제 확인 다이얼로그
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              side: BorderSide(color: Colors.black, width: 3),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            content: SizedBox(
                                              width: 200,
                                              height: 100,
                                              child: Center(child: Text(
                                                "'${item['name']}'을 삭제하시겠습니까?",
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),)
                                            ),
                                            actions: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  Expanded(
                                                    child: TextButton(
                                                      style: TextButton.styleFrom(
                                                        backgroundColor: AppTheme.buttonColor,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: const Text(
                                                        '아니오',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: TextButton(
                                                      style: TextButton.styleFrom(
                                                        backgroundColor: AppTheme.buttonColor,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                        takingVM.removeTaking(idx);
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text('${item['name']} 삭제됨')),
                                                        );
                                                      },
                                                      child: const Text(
                                                        '네',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('수정'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 20),
                                          SizedBox(width: 8),
                                          Text('삭제'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(times.length, (timeIdx) {
                                return Row(
                                  children: [
                                    Text(
                                      times[timeIdx],
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    const SizedBox(width: 4),
                                    Checkbox(
                                      value: checks[timeIdx],
                                      onChanged: (val) {
                                        takingVM.updateCheck(idx, timeIdx, val ?? false);
                                      },
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ],
                        ),
                      );
                    },
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