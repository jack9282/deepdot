import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../common/theme/app_theme.dart';
import '../../../data/models/task_model.dart';
import '../view_models/home_view_model.dart';

import '../../schedule/screens/daily_timeline_screen.dart';
import '../../schedule/screens/task_add_screen.dart';
import '../../schedule/screens/task_timer_screen.dart';
import '../../statistics/screens/statistics_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
    _viewModel.loadTasks();
    _setStatusBarStyle();
  }

  void _setStatusBarStyle() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white, // 상태바 배경색을 흰색으로 설정
        statusBarIconBrightness: Brightness.dark, // 상태바 아이콘을 어둡게 (흰 배경에 맞게)
        statusBarBrightness: Brightness.light, // iOS용 설정
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override 
  Widget build(BuildContext context) {
    // 화면이 빌드될 때마다 상태바 스타일 설정
    _setStatusBarStyle();
    
    return ChangeNotifierProvider<HomeViewModel>(
      create: (_) => _viewModel,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // 커스텀 상단바
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SizedBox(
                    height: 48, // Stack의 높이를 고정
                    child: Stack(
                      children: [
                      // 왼쪽 통계 아이콘
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const StatisticsScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.bar_chart,
                              size: 24,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      // 제목 (정중앙)
                      const Center(
                        child: Text(
                          '일정 관리',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor, // 파란색으로 변경
                          ),
                        ),
                      ),
                      // 오른쪽 아이콘들
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Row(
                          children: [
                            // 전체 일정 보기 버튼
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const DailyTimelineScreen(
                                      title: '전체 일정',
                                    ),
                                  ),
                                                              ).then((result) {
                                _viewModel.refresh();
                                _setStatusBarStyle(); // 돌아올 때 상태바 스타일 재설정
                              });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.calendar_today,
                                  size: 24,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 일정 추가 버튼
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => TaskAddScreen(
                                      priority: TaskPriority.urgentImportant,
                                    ),
                                  ),
                                ).then((result) {
                                  if (result == true) {
                                    _viewModel.refresh();
                                    _showSuccessTooltip();
                                  }
                                  _setStatusBarStyle(); // 돌아올 때 상태바 스타일 재설정
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.add,
                                  size: 24,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 메인 콘텐츠
            Expanded(
              child: Consumer<HomeViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    );
                  }

                  if (viewModel.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            viewModel.errorMessage!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => viewModel.refresh(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                            ),
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    color: AppTheme.backgroundColor,
                    child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // 먼저 처리할 일 (좌상) - 파란색
                        Expanded(
                          child: _buildMatrixCard(
                            context,
                            viewModel,
                            title: '먼저 처리할 일',
                            subtitle: '오늘 안에 마무리해보세요',
                            headerColor: const Color(0xFF3A71FF), // 헤더 색상 (진한 파란색)
                            color: const Color(0xFF5886FF), // 본문 색상 (연한 파란색)
                            icon: Icons.warning_amber_outlined,
                            rightIcon: Icons.bookmark_border,
                            priority: TaskPriority.urgentImportant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 미리 준비해주세요 (우상) - 주황색
                        Expanded(
                          child: _buildMatrixCard(
                            context,
                            viewModel,
                            title: '미리 준비해주세요',
                            subtitle: '시간 여유 있을 때 하면 좋아요',
                            headerColor: const Color(0xFFFFBC4C), // 헤더 색상 (진한 주황색)
                            color: const Color(0xFFFFDE63), // 본문 색상 (연한 주황색)
                            icon: Icons.star_border,
                            rightIcon: Icons.push_pin_outlined,
                            priority: TaskPriority.important,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      children: [
                        // 도움받아도 괜찮아요 (좌하) - 연한 노란색
                        Expanded(
                          child: _buildMatrixCard(
                            context,
                            viewModel,
                            title: '도움받아도 괜찮아요',
                            subtitle: '빠르게 처리하거나 위임해보세요',
                            headerColor: const Color(0xFFFFBC4C), // 헤더 색상 (주황색)
                            color: const Color(0xFFFFF6C4), // 본문 색상 (연한 노란색)
                            icon: Icons.access_time,
                            rightIcon: Icons.location_on_outlined,
                            priority: TaskPriority.urgent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 나중에 봐도 괜찮아요 (우하) - 연한 파란색
                        Expanded(
                          child: _buildMatrixCard(
                            context,
                            viewModel,
                            title: '나중에 봐도 괜찮아요',
                            subtitle: '지금 안해도 괜찮아요',
                            color: const Color(0xFFE0E9FF), // 단색 연하늘색
                            icon: Icons.edit_outlined,
                            rightIcon: Icons.circle_outlined,
                            priority: TaskPriority.neither,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTimelinePlanner(BuildContext context, TaskPriority priority) {
    // 모든 4분할 버튼은 전체 일정 화면으로 이동
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DailyTimelineScreen(
          title: '전체 일정',
        ),
      ),
    ).then((result) {
      // 돌아올 때 데이터 새로고침
      _viewModel.refresh();
      _setStatusBarStyle(); // 돌아올 때 상태바 스타일 재설정
    });
  }

  Widget _buildMatrixCard(
    BuildContext context,
    HomeViewModel viewModel, {
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required TaskPriority priority,
    Color? headerColor,
    IconData? rightIcon,
  }) {
    final tasks = viewModel.getTasksByPriority(priority);
    // 최대 5개까지만 표시
    final displayTasks = tasks.take(5).toList();
    
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToTimelinePlanner(context, priority),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // 헤더 부분
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: headerColor ?? color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단 아이콘 행
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          icon,
                          color: Colors.black,
                          size: 20,
                        ),
                        if (rightIcon != null)
                          Icon(
                            rightIcon,
                            color: Colors.black,
                            size: 20,
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 제목
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // 부제목
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 10,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 본문 부분
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 할일 목록 (5개까지)
                      ...displayTasks.map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TaskTimerScreen(task: task),
                              ),
                            );
                          },
                          child: Text(
                            task.title,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )).toList(),
                      
                      // 빈 공간을 채우기 위한 더미 아이템들 (5개까지 맞추기)
                      ...List.generate(
                        5 - displayTasks.length,
                        (index) => const Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: SizedBox(height: 15),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // 하단 정보
                      if (tasks.length > 5)
                        Text(
                          '외 ${tasks.length - 5}개 더',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 12,
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
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

  void _showSuccessTooltip() {
    // 잠시 후 툴팁 표시
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final overlay = Overlay.of(context);
        late OverlayEntry overlayEntry;
        
        overlayEntry = OverlayEntry(
          builder: (context) => Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '일정이 추가되었습니다!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 화살표 모양 추가
                    CustomPaint(
                      size: const Size(12, 8),
                      painter: _ArrowPainter(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        
        overlay.insert(overlayEntry);
        
        // 3초 후 툴팁 제거
        Future.delayed(const Duration(seconds: 3), () {
          overlayEntry.remove();
        });
      }
    });
  }
}

// 화살표 그리기를 위한 CustomPainter
class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.7, size.height * 0.5);
    path.lineTo(0, size.height);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 