import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/theme/app_theme.dart';
import '../view_models/statistics_view_model.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late StatisticsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StatisticsViewModel();
    _viewModel.loadCurrentWeekData();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StatisticsViewModel>(
      create: (_) => _viewModel,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // 상단 헤더 (중앙 정렬)
              Container(
                width: double.infinity,
                height: 119,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    // 뒤로가기 버튼 (좌측)
                    Positioned(
                      left: 0,
                      top: 2,
                      child: Container(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.black,
                            size: 16,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ),
                    
                    Positioned(
                      left: 33,
                      top: 6,
                      child: const Text(
                        '4',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 0.80,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    
                    // 통계 제목 (중앙)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 22,
                      child: const Center(
                        child: Text(
                          '통계',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            height: 1.29,
                          ),
                        ),
                      ),
                    ),
                    
                    // 주간 네비게이션 (중앙 정렬)
                    Consumer<StatisticsViewModel>(
                      builder: (context, viewModel, child) {
                        return Positioned(
                          left: 0,
                          right: 0,
                          top: 71,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 왼쪽 화살표 버튼
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                                onPressed: () {
                                  viewModel.goToPreviousWeek();
                                },
                                icon: const Icon(
                                  Icons.chevron_left,
                                  color: Colors.black,
                                  size: 20,
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // 이번주 텍스트
                              Text(
                                viewModel.getCurrentWeekText(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  height: 1.47,
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // 오른쪽 화살표 버튼
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                                onPressed: () {
                                  viewModel.goToNextWeek();
                                },
                                icon: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.black,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // 주간 집중 시간 (첫번째 박스 - 중앙 정렬)
                      Consumer<StatisticsViewModel>(
                        builder: (context, viewModel, child) {
                          return Container(
                            width: double.infinity,
                            height: 284,
                            clipBehavior: Clip.antiAlias,
                            decoration: const BoxDecoration(),
                            child: Stack(
                              children: [
                                // 메인 컨테이너 (중앙 정렬)
                                Center(
                                  child: Container(
                                    width: MediaQuery.of(context).size.width - 42,
                                    height: 256,
                                    decoration: ShapeDecoration(
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        side: const BorderSide(width: 1, color: AppTheme.borderColor),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // 요일 표시
                                ..._buildWeekDays(),
                                
                                // 주간 집중 시간 텍스트 (우상단)
                                Positioned(
                                  right: 20,
                                  top: 23,
                                  child: Text(
                                    '주간 집중 시간: ${viewModel.getFormattedWeeklyTime()}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      color: Color(0xFFA7A7A7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w300,
                                      height: 2.20,
                                    ),
                                  ),
                                ),
                                
                                // 빨간 원형 아이콘과 숫자 (기록이 있을 때만 표시)
                                if (viewModel.weeklyFocusMinutes > 0) ...[
                                  Positioned(
                                    left: 90,
                                    top: 32,
                                    child: Container(
                                      width: 26,
                                      height: 27,
                                      decoration: const ShapeDecoration(
                                        color: Color(0xFFFF5050),
                                        shape: OvalBorder(),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 97,
                                    top: 37,
                                    child: const Text(
                                      '2',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        height: 0.80,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 하루 집중 시간 (두번째 박스 - 중앙 정렬)
                      Consumer<StatisticsViewModel>(
                        builder: (context, viewModel, child) {
                          return Container(
                            width: double.infinity,
                            height: 347,
                            clipBehavior: Clip.antiAlias,
                            decoration: const BoxDecoration(),
                            child: Stack(
                              children: [
                                // 메인 컨테이너 (중앙 정렬)
                                Center(
                                  child: Container(
                                    width: MediaQuery.of(context).size.width - 44,
                                    height: 332,
                                    decoration: ShapeDecoration(
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        side: const BorderSide(width: 1, color: AppTheme.borderColor),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // 집중 기록 없음 텍스트 (기록이 없을 때) - 중앙 정렬
                                if (viewModel.dailyFocusMinutes == 0)
                                  const Center(
                                    child: Text(
                                      '집중 기록 없음',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFFA7A7A7),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w300,
                                        height: 1.10,
                                      ),
                                    ),
                                  ),
                                
                                // 빨간 원형 아이콘과 숫자 (기록이 있을 때) - 중앙 정렬
                                if (viewModel.dailyFocusMinutes > 0) ...[
                                  Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '오늘 집중 시간',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.textSecondaryColor,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              viewModel.getFormattedDailyTime(),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textPrimaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 20),
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 26,
                                              height: 27,
                                              decoration: const ShapeDecoration(
                                                color: Color(0xFFFF5050),
                                                shape: OvalBorder(),
                                              ),
                                            ),
                                            const Text(
                                              '3',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                height: 0.80,
                                                letterSpacing: -1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 요일 표시를 위한 헬퍼 메서드 (중앙 정렬 조정)
  List<Widget> _buildWeekDays() {
    final days = ['월', '화', '수', '목', '금', '토', '일'];
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth - 42;
    final startX = (screenWidth - containerWidth) / 2;
    
    return List.generate(days.length, (index) {
      final dayWidth = containerWidth / 7;
      final leftPosition = startX + (dayWidth * index) + (dayWidth / 2) - 8; // 중앙 정렬 조정
      
      return Positioned(
        left: leftPosition,
        top: 239,
        child: Text(
          days[index],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w300,
            height: 1.47,
          ),
        ),
      );
    });
  }
} 