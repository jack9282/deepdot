// day_bubble.dart

import 'package:flutter/material.dart';

class DayBubble extends StatelessWidget {
  const DayBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 탭 했을 때 메시지를 띄우는 로직 추가
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('이 요일에는 루틴이 설정되어 있지 않아요.'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: '닫기',
              onPressed: () {},
            ),
          ),
        );
      },
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(
            color: const Color(0xFFD1D5DB),
            width: 1.7,
          ),
          borderRadius: BorderRadius.circular(7),
        ),
      ),
    );
  }
}