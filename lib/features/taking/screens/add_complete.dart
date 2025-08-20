import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../common/theme/app_theme.dart';

class TakingAddCompleteScreen extends StatelessWidget {
  const TakingAddCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AddCompleteScreenBody();
  }
}

class _AddCompleteScreenBody extends StatelessWidget {
  const _AddCompleteScreenBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(),
            // 완료 이미지 (중앙 상단)
            SizedBox(
              width: 250,
              height: 150,
              child: Image.asset(
                'assets/images/taking_complete.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 45),
            // 메인 메시지
            const Text(
              '복용이력이 생성되었습니다!',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // 서브 메시지
            const Text(
              '매번 체크해서 잊지말고 복용해요',
              style: TextStyle(
                color: Color(0xFF999999),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            // 완료 버튼
            GestureDetector(
              onTap: () {
                context.go('/taking-list');
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    '완료',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}