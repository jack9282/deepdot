import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../common/theme/app_theme.dart';
import '../widgets/taking_list_item.dart';

class TakingList extends StatefulWidget {
  const TakingList({super.key});

  @override
  State<TakingList> createState() => _TakingListState();
}

class _TakingListState extends State<TakingList> {
  // 더미 데이터
  final List<Map<String, dynamic>> _takingList = [
    {
      'name': '약 이름1',
      'checks': [true, true, true],
    },
    {
      'name': '약 이름2',
      'checks': [true, true, true],
    },
    {
      'name': '약 이름3',
      'checks': [true, true, true],
    },
  ];

  final List<String> _times = ['아침', '점심', '저녁'];

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
              context.push('/taking/add');
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _takingList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, idx) {
                  final item = _takingList[idx];
                  return TakingListItem(
                    name: item['name'],
                    checks: List<bool>.from(item['checks']),
                    times: _times,
                    onMorePressed: () {},
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
