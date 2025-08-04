import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../view_models/routine_view_model.dart';

class RoutineCompleteScreen extends StatelessWidget {
  const RoutineCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0, // Remove app bar space
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // "생성 완료!" button/text
            Container(
              width: 150,
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  '생성 완료!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Clover image
            Image.asset('assets/images/clover.png', width: 120, height: 120),
            const SizedBox(height: 40),
            // "확인" button
            TextButton(
              onPressed: () async {
                // 데이터 새로고침 후 루틴 화면으로 이동
                final routineVM = context.read<RoutineViewModel>();
                await routineVM.refresh();
                if (context.mounted) {
                  context.go('/routine');
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF232B3A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                minimumSize: const Size(110, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                '확인',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}