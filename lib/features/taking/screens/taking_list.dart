import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../view_models/taking_view_model.dart';

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

class _TakingListScreenBody extends StatelessWidget {
  const _TakingListScreenBody();

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
                      return Container(
                        height: 80 + 20.0 * (times.length - 1),
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
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () {
                                    // 삭제 예시
                                    // takingVM.removeTaking(idx);
                                  },
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
                                      value: false,
                                      onChanged: (val) {},
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
