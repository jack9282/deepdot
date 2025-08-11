import 'package:flutter/material.dart';
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
                // 헤더
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
                
                const SizedBox(height: 20),
                
                // 진행률이 0인 경우 빈 상태 표시
                if (viewModel.dailyFocusMinutes == 0)
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
                  // 진행률 아크 차트
                  _buildProgressArc(viewModel),
                
                const SizedBox(height: 20),
                
                // 루틴 달성률 정보
                if (viewModel.dailyFocusMinutes > 0) ...[
                  Text(
                    '집중 루틴 달성률',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: '목표 ',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: '${viewModel.totalRoutines}',
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const TextSpan(
                          text: '개 중 ',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: '${viewModel.completedRoutines}',
                          style: const TextStyle(
                            color: Color(0xFF3A71FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(
                          text: '개 달성 (',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: '${(viewModel.getRoutineAchievementRate() * 100).toInt()}%',
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const TextSpan(
                          text: ')',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: '최장 집중 루틴 : \'',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: viewModel.longestRoutine,
                          style: const TextStyle(
                            color: Color(0xFF3A71FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(
                          text: '\'',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // 진행률 아크 차트
  Widget _buildProgressArc(StatisticsViewModel viewModel) {
    final progress = viewModel.getDailyProgress();
    final percentage = (progress * 100).toInt();
    
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
                      fontSize: 12,
                      color: Colors.grey[600],
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

// 아크 차트를 그리기 위한 CustomPainter
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
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // 아크 그리기 (왼쪽에서 시작하여 시계방향으로 오른쪽까지)
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -0.5, // 시작 각도 (왼쪽)
      1.0 * progress, // 진행률에 따른 각도 (0.5π = 90도)
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
} 