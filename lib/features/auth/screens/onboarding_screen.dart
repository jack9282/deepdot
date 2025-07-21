import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../common/theme/app_theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 제목
              const SizedBox(height: 40),
              const Text(
                'DeepDot은 당신의 하루를\n더 체계적으로 만들어줍니다',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 40),

              // 기능 소개 리스트
              _buildFeatureItem(
                '아이젠하워 매트릭스',
                '중요도와 긴급도로 일정을 체계적으로 관리',
                Icons.grid_view,
              ),
              const SizedBox(height: 20),
              _buildFeatureItem(
                '포모도로 타이머',
                '집중 시간과 휴식 시간을 적절히 배분',
                Icons.timer,
              ),
              const SizedBox(height: 20),
              _buildFeatureItem(
                '복약 관리',
                '약 복용 시간을 놓치지 않도록 알림',
                Icons.medication,
              ),
              const SizedBox(height: 20),
              _buildFeatureItem(
                '루틴 체크리스트',
                '매일 반복할 습관들을 체크하고 관리',
                Icons.checklist,
              ),

              const Spacer(),

              // 일러스트레이션 영역 (간단한 아이콘들로 구현)
              Center(
                child: SizedBox(
                  height: 150,
                  child: Image.asset(
                    'assets/images/onboarding_screen_image.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 시작하기 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '시작하기',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description, IconData icon) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppTheme.secondaryColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
