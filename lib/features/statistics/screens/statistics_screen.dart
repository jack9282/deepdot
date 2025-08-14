import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../view_models/statistics_view_model.dart';
import '../../../data/repositories/focus_session_repository.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 앱이 다시 활성화되었을 때 통계 데이터 새로고침
      final viewModel = Provider.of<StatisticsViewModel>(context, listen: false);
      viewModel.loadCurrentWeekData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StatisticsViewModel>(
      create: (_) => StatisticsViewModel()..loadCurrentWeekData(),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Column(
          children: [
            // 상단 헤더 (SafeArea 밖에 배치)
            _buildHeader(),
            
            // 메인 콘텐츠 (SafeArea 안에 배치)
            Expanded(
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 14),
                      
                      // 이번주 통계 카드
                      _buildWeeklyCard(),
                      
                      const SizedBox(height: 16),
                      
                      // 하루 집중시간 카드
                      _buildDailyCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 상단 헤더
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // 뒤로가기 버튼
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                  size: 20,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              
              // 제목 (중앙)
              Expanded(
                child: const Center(
                  child: Text(
                    '통계',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              // 새로고침 버튼
              Consumer<StatisticsViewModel>(
                builder: (context, viewModel, child) {
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    icon: viewModel.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                            ),
                          )
                        : const Icon(
                            Icons.refresh,
                            color: Colors.grey,
                            size: 24,
                          ),
                    onPressed: viewModel.isLoading
                        ? null
                        : () {
                            viewModel.loadCurrentWeekData();
                          },
                    onLongPress: viewModel.isLoading
                        ? null
                        : () {
                            _showClearDataDialog(context, viewModel);
                          },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 모든 집중시간 데이터 삭제 확인 다이얼로그
  void _showClearDataDialog(BuildContext context, StatisticsViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('데이터 초기화'),
          content: const Text('모든 집중시간 데이터를 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _clearAllFocusData(viewModel);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  // 모든 집중시간 데이터 삭제 실행
  Future<void> _clearAllFocusData(StatisticsViewModel viewModel) async {
    try {
      // FocusSessionRepository에서 모든 데이터 삭제
      final focusRepository = FocusSessionRepository();
      await focusRepository.loadSessionsFromStorage();
      final success = await focusRepository.clearAllSessions();
      
      if (success) {
        // 통계 데이터 새로고침
        await viewModel.loadCurrentWeekData();
        
        // 성공 메시지 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('모든 집중시간 데이터가 삭제되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 실패 메시지 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('데이터 삭제에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // 에러 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 이번주 통계 카드
  Widget _buildWeeklyCard() {
    return Consumer<StatisticsViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          children: [
            // 주간 네비게이션 (카드 위에 배치)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Color(0xFF799EFF),
                      size: 35,
                    ),
                    onPressed: () {
                      viewModel.goToPreviousWeek();
                    },
                  ),
                  
                  Column(
                    children: [
                      Text(
                        viewModel.getCurrentWeekText(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        viewModel.getWeekDateRange(),
                        style: TextStyle(
                          color: const Color(0xFFB4B5B6),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    icon: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF799EFF),
                      size: 35,
                    ),
                    onPressed: () {
                      viewModel.goToNextWeek();
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 이번주 통계 카드
            Container(
              width: double.infinity,
              height: 350, // 카드 높이 설정
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 동기부여 메시지 (조건부 표시)
                    if (viewModel.shouldShowWeeklyComparison())
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            viewModel.getWeeklyComparisonMessage() ?? '',
                            style: const TextStyle(
                              color: Color(0xFFB4B5B6),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            viewModel.getWeeklyComparisonEmoji() ?? '',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 4),
                    
                    // 주간 집중시간 (우측 정렬)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '주간 집중시간: ',
                                style: TextStyle(
                                  color: const Color(0xFFFB4B5B6),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: viewModel.getFormattedWeeklyTime(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // 주간 바 차트
                    _buildWeeklyBarChart(viewModel),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 주간 바 차트
  Widget _buildWeeklyBarChart(StatisticsViewModel viewModel) {
    final days = ['월', '화', '수', '목', '금', '토', '일'];
    // 비율 기반 게이지에서는 maxValue 불필요 (달성률이 이미 0.0~1.0)
    
    return Container(
      height: 200, // 높이 증가
      child: Stack(
        children: [
          // 점선 기준선
          Positioned(
            top: 110, // 중간 위치
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
            ),
          ),
          // 바 차트
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final achievementRate = viewModel.weeklyAchievementRates[index];
              final focusMinutes = viewModel.weeklyData[index];
              
              // 게이지 높이는 LayoutBuilder에서 동적으로 계산
              
              return Column(
                children: [
                  // 바 차트
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // 실제 사용 가능한 높이 계산
                        final maxHeight = constraints.maxHeight;
                        final displayHeight = achievementRate > 0 
                            ? (maxHeight * achievementRate).clamp(8.0, maxHeight)
                            : 0.0;
                        
                        return Container(
                          width: 13, // 막대 너비 더 줄임
                          child: Stack(
                            children: [
                              // 배경 바 (빈 게이지)
                              Container(
                                width: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF4FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              // 실제 값 바 (채워진 게이지) - 달성률 기반
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: displayHeight, // 동적으로 계산된 높이 사용
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF799EFF), // 단일색: 연한 파란색
                                    borderRadius: BorderRadius.circular(10),
                                    border: achievementRate > 0 && achievementRate < 0.2
                                        ? Border.all(color: const Color(0xFF799EFF), width: 1) // 20% 미만일 때 테두리
                                        : null,
                                  ),
                                  // 작은 게이지도 잘 보이게 내부에 컨테이너 추가
                                  child: achievementRate > 0 && achievementRate < 0.3 
                                      ? Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF799EFF).withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16), // 간격 더 늘림
                  // 요일 라벨
                  Text(
                    days[index],
                    style: TextStyle(
                      color: const Color(0xFFB4B5B6),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // 하루 집중시간 카드
  Widget _buildDailyCard() {
    return Consumer<StatisticsViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          width: double.infinity,
          // height: 350, // 카드 높이 설정 -> 내용에 맞게 자동 조절
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // 🔧 수정: 집중 기록이 없는 경우 빈 상태 표시
                if (!viewModel.hasDailyFocusRecord())
                  const Center(
                    child: Column(
                      children: [
                        SizedBox(height: 40),
                        Text(
                          '집중 기록이 없습니다',
                          style: TextStyle(
                            color: Color(0xFFA7A7A7),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 40),
                      ],
                    ),
                  )
                else
                  // 🔧 수정: 하루 집중시간 총합 표시 및 진행률 아크 차트 (집중 루틴 달성률 포함)
                  _buildDailyFocusContent(viewModel),
              ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 🆕 하루 집중시간 콘텐츠 위젯 (이미지 디자인에 맞게 수정)
  Widget _buildDailyFocusContent(StatisticsViewModel viewModel) {
    final progress = viewModel.dailyAchievementRate;
    final percentage = (progress * 100).round();
    
    return Column(
      children: [
        // 헤더 (아크차트 바로 위에 배치)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '하루 집중시간',
              style: TextStyle(
                color: Color(0xFF3A71FF),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${DateTime.now().month}월 ${DateTime.now().day}일',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 30), // 헤더와 아크 차트 사이 여백 추가
        
        // 스트로크 기반 아크 차트와 중앙 텍스트
        SizedBox(
          width: 180,
          height: 110,
          child: Stack(
            children: [
              // 배경 아크 (회색 스트로크)
              CustomPaint(
                size: const Size(180, 90),
                painter: StrokeArcPainter(
                  progress: 1.0,
                  color: const Color(0xFFEFF4FF),
                  strokeWidth: 16,
                ),
              ),
              // 진행률 아크 (그라데이션 스트로크)
              CustomPaint(
                size: const Size(180, 90),
                painter: StrokeArcPainter(
                  progress: progress,
                  color: const Color(0xFF1F5DFF),
                  strokeWidth: 16,
                  useGradient: true,
                ),
              ),
              // 중앙 퍼센트 텍스트
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Text(
                  '$percentage%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF74787B),
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        
        // 범례
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('진행률', const Color(0xFF377FF8)),
            const SizedBox(width: 24),
            _buildLegendItem('하루시간', const Color(0xFFEFF4FF)),
          ],
        ),
        
        const SizedBox(height: 16), // 범례와 집중 루틴 달성률 사이 여백
        
        // 집중 루틴 달성률 정보 (회색 카드 제거, 직접 배치)
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '집중 루틴 달성률',
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // 좌우 배치: 좌측에 목표 달성률, 우측에 최장 집중 루틴
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 좌측: 목표 달성률
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: '목표 ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: '${viewModel.completedTasksCount}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(
                      text: '개 중 ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: '${viewModel.completedTasksCount}',
                      style: const TextStyle(
                        color: Color(0xFF3A71FF),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(
                      text: '개 ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(
                      text: '달성 (',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: viewModel.getFormattedDailyAchievementRate(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(
                      text: ')',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // 우측: 최장 집중 루틴
            Flexible(
              child: RichText(
                textAlign: TextAlign.right,
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: '최장 집중 루틴: \'',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: viewModel.longestRoutine,
                      style: const TextStyle(
                        color: Color(0xFF3A71FF),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(
                      text: '\'',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 범례 아이템
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16, // 8에서 12로 크기 증가
          height: 16, // 8에서 12로 크기 증가
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black, 
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // 진행률 아크 차트 (사용하지 않음 - 대신 _buildDailyFocusContent 사용)
  Widget _buildProgressArc_unused(StatisticsViewModel viewModel) {
    final progress = viewModel.dailyAchievementRate;
    final percentage = (progress * 100).round();
    
    return Center(
      child: Column(
        children: [
          // 아크 차트
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              children: [
                // 배경 아크
                CustomPaint(
                  size: const Size(120, 120),
                  painter: ArcPainter(
                    progress: 1.0,
                    color: Colors.grey[300]!,
                    strokeWidth: 8,
                  ),
                ),
                // 진행률 아크
                CustomPaint(
                  size: const Size(120, 120),
                  painter: ArcPainter(
                    progress: progress,
                    color: const Color(0xFF3A71FF),
                    strokeWidth: 8,
                  ),
                ),
                // 중앙 텍스트
                Center(
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 범례
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 진행률
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3A71FF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '진행률',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // 하루시간
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '하루시간',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 스트로크 기반 아크를 그리는 CustomPainter
class StrokeArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool useGradient;

  StrokeArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.useGradient = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    Paint paint;
    
    if (useGradient) {
      // 그라데이션 생성 (#799EFF -> #1F5DFF)
      final gradient = SweepGradient(
        startAngle: math.pi, // 좌측 하단에서 시작 (180도)
        endAngle: 2 * math.pi, // 우측 하단에서 끝 (360도)
        colors: const [
          Color(0xFF799EFF), // 시작 색상
          Color(0xFF1F5DFF), // 끝 색상
        ],
        stops: const [0.0, 1.0],
      );
      
      paint = Paint()
        ..shader = gradient.createShader(rect)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
    } else {
      // 단색 사용
      paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
    }

    // 하단 반원 아크 그리기 (좌측 하단에서 시작하여 우측 하단으로)
    canvas.drawArc(
      rect,
      math.pi, // 시작 각도 (좌측 하단, 180도)
      math.pi * progress, // 진행률에 따른 각도 (π = 180도, 반원)
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is StrokeArcPainter && 
           (oldDelegate.progress != progress || 
            oldDelegate.color != color ||
            oldDelegate.strokeWidth != strokeWidth ||
            oldDelegate.useGradient != useGradient);
  }
}

// 아크 진행률을 위한 CustomClipper (간단한 버전)
class ArcProgressClipper extends CustomClipper<Path> {
  final double progress;

  ArcProgressClipper({required this.progress});

  @override
  Path getClip(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (progress <= 0) {
      return path; // 빈 패스 반환
    }

    // 하단 반원의 시작점 (좌측 하단, 180도)
    final startAngle = math.pi;
    // 진행률에 따른 끝 각도 (최대 180도까지)
    final sweepAngle = math.pi * progress;

    // 중심에서 시작점으로 선
    final startPoint = Offset(
      center.dx + radius * math.cos(startAngle),
      center.dy + radius * math.sin(startAngle),
    );

    // 패스 생성
    path.moveTo(center.dx, center.dy);
    path.lineTo(startPoint.dx, startPoint.dy);

    // 아크 그리기
    final rect = Rect.fromCircle(center: center, radius: radius);
    path.arcTo(rect, startAngle, sweepAngle, false);

    // 중심으로 돌아가기
    path.lineTo(center.dx, center.dy);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return oldClipper is ArcProgressClipper && oldClipper.progress != progress;
  }
}

// 반원 진행률을 위한 CustomClipper
class SemiCircleProgressClipper extends CustomClipper<Path> {
  final double progress;

  SemiCircleProgressClipper({required this.progress});

  @override
  Path getClip(Size size) {
    var path = Path(); // final을 var로 변경
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (progress <= 0) {
      return path; // 빈 패스 반환
    }

    // 하단 반원의 시작점 (좌측 하단, 180도)
    final startAngle = math.pi;
    // 진행률에 따른 끝 각도 (최대 180도까지)
    final endAngle = startAngle + (math.pi * progress);

    // 반원 영역만 클리핑
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    // 먼저 전체 반원 영역을 만들고
    path.addArc(rect, math.pi, math.pi);
    
    // 진행률에 따라 추가로 마스킹할 영역을 제거
    if (progress < 1.0) {
      final maskPath = Path();
      
      // 진행률 끝점에서 중심으로의 선
      final endPoint = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );
      
      // 우측 하단점 (360도/0도 지점)
      final rightPoint = Offset(
        center.dx + radius,
        center.dy,
      );
      
      // 마스킹할 영역 (진행률 이후 부분)
      maskPath.moveTo(center.dx, center.dy);
      maskPath.lineTo(endPoint.dx, endPoint.dy);
      maskPath.arcTo(rect, endAngle, math.pi * (1 - progress), false);
      maskPath.lineTo(center.dx, center.dy);
      maskPath.close();
      
      // 전체에서 마스킹 영역 제거
      path = Path.combine(PathOperation.difference, path, maskPath);
    }

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return oldClipper is SemiCircleProgressClipper && oldClipper.progress != progress;
  }
}

// 하단 반원 아크를 그리는 CustomPainter
class HalfArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool useGradient;

  HalfArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.useGradient = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    Paint paint;
    
    if (useGradient) {
      // 그라데이션 생성 (#799EFF -> #1F5DFF)
      final gradient = SweepGradient(
        startAngle: math.pi, // 좌측 하단에서 시작 (180도)
        endAngle: 2 * math.pi, // 우측 하단에서 끝 (360도)
        colors: const [
          Color(0xFF799EFF), // 시작 색상
          Color(0xFF1F5DFF), // 끝 색상
        ],
        stops: const [0.0, 1.0],
      );
      
      paint = Paint()
        ..shader = gradient.createShader(rect)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
    } else {
      // 단색 사용
      paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
    }

    // 하단 반원 아크 그리기 (좌측 하단에서 시작하여 우측 하단으로)
    canvas.drawArc(
      rect,
      math.pi, // 시작 각도 (좌측 하단, 180도)
      math.pi * progress, // 진행률에 따른 각도 (π = 180도, 반원)
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is HalfArcPainter && 
           (oldDelegate.progress != progress || 
            oldDelegate.color != color ||
            oldDelegate.strokeWidth != strokeWidth ||
            oldDelegate.useGradient != useGradient);
  }
}

// 아크 차트를 그리기 위한 CustomPainter (사용하지 않음 - SVG 사용)
class ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  ArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    Paint paint;
    
    // 진행률 아크인 경우 그라데이션 적용, 배경 아크인 경우 단색 사용
    if (color == const Color(0xFF3A71FF)) {
      // 그라데이션 생성 (#799EFF -> #1F5DFF)
      final gradient = SweepGradient(
        startAngle: math.pi, // 좌측 하단에서 시작
        endAngle: 2 * math.pi, // 우측 하단에서 끝
        colors: const [
          Color(0xFF799EFF), // 시작 색상
          Color(0xFF1F5DFF), // 끝 색상
        ],
        stops: const [0.0, 1.0],
      );
      
      paint = Paint()
        ..shader = gradient.createShader(rect)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
    } else {
      // 배경 아크는 단색 사용
      paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
    }

    // 하단 반원 아크 그리기 (좌측 하단에서 시작하여 우측 하단으로)
    canvas.drawArc(
      rect,
      math.pi, // 시작 각도 (좌측 하단, 180도)
      math.pi * progress, // 진행률에 따른 각도 (π = 180도, 반원)
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

 