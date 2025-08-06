import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../common/theme/app_theme.dart';

class ScheduleAddCompleteScreen extends StatelessWidget {
  final bool isEditMode;
  
  const ScheduleAddCompleteScreen({
    super.key,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return _AddCompleteScreenBody(isEditMode: isEditMode);
  }
}

class _AddCompleteScreenBody extends StatelessWidget {
  final bool isEditMode;
  
  const _AddCompleteScreenBody({
    required this.isEditMode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0, // Remove app bar space
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(),
            // 성공 아이콘 (중앙 상단)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 60,
                weight: 900,
              ),
            ),
            const SizedBox(height: 45),
            // 메인 메시지
            Text(
              isEditMode ? '일정이 수정되었습니다!' : '일정이 추가되었습니다!',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // 서브 메시지
            Text(
              isEditMode 
                ? '수정된 일정을 확인하고 체계적으로 관리해요'
                : '일정을 확인하고 체계적으로 관리해요',
              style: const TextStyle(
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
                Navigator.of(context).pop();
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