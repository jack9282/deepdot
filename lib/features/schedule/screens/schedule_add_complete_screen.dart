import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../common/theme/app_theme.dart';
import '../../home/view_models/home_view_model.dart';
import '../../../data/repositories/task_repository.dart';

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
            // 완료 이미지 (중앙 상단)
            SizedBox(
              width: 200,
              height: 150,
              child: Image.asset(
                'assets/images/schedule_complete.png',
                fit: BoxFit.contain,
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
                // 완료 화면과 일정 추가 화면을 모두 닫고 새로고침 결과와 함께 돌아가기
                Navigator.of(context).pop(); // 완료 화면 닫기
                Navigator.of(context).pop(true); // 일정 추가 화면 닫기 + 새로고침 신호
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