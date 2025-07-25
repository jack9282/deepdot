import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/theme/app_theme.dart';
import '../../../data/models/task_model.dart';
import '../view_models/home_view_model.dart';
import '../../schedule/screens/timeline_planner_screen.dart';
import '../../schedule/screens/task_add_screen.dart';
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
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeViewModel>(
      create: (_) => _viewModel,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              // 왼쪽 사이드 통계바
              GestureDetector(
                onTap: () {
                  // 통계 화면으로 이동
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
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'DeepDot',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                // 일정 추가 화면으로 이동
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TaskAddScreen(
                      priority: TaskPriority.urgentImportant,
                    ),
                  ),
                ).then((result) {
                  if (result == true) {
                    _viewModel.refresh();
                    // 성공 툴팁 표시
                    _showSuccessTooltip();
                  }
                });
              },
            ),
          ],
        ),
        body: Consumer<HomeViewModel>(
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

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // 중요 & 긴급 (좌상)
                        Expanded(
                          child: _buildMatrixCard(
                            context,
                            viewModel,
                            title: '중요 & 긴급',
                            subtitle: '지금 바로 해야해요',
                            color: AppTheme.urgentImportantColor,
                            icon: Icons.warning,
                            priority: TaskPriority.urgentImportant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 중요 (우상)
                        Expanded(
                          child: _buildMatrixCard(
                            context,
                            viewModel,
                            title: '중요',
                            subtitle: '미리 계획해서 준비해요',
                            color: AppTheme.importantColor,
                            icon: Icons.star,
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
                        // 긴급 (좌하)
                        Expanded(
                          child: _buildMatrixCard(
                            context,
                            viewModel,
                            title: '긴급',
                            subtitle: '급하면 부탁하거나 나중에 처리해요',
                            color: AppTheme.urgentColor,
                            icon: Icons.schedule,
                            priority: TaskPriority.urgent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 둘 다 아님 (우하)
                        Expanded(
                          child: _buildMatrixCard(
                            context,
                            viewModel,
                            title: '둘 다 아님',
                            subtitle: '시간 남을 때하거나 안 해도 돼요',
                            color: AppTheme.neitherColor,
                            icon: Icons.more_horiz,
                            priority: TaskPriority.neither,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToTimelinePlanner(BuildContext context, TaskPriority priority) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TimelinePlannerScreen(priority: priority),
      ),
    ).then((result) {
      // 돌아올 때 데이터 새로고침
      _viewModel.refresh();
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
  }) {
    final taskCount = viewModel.getTaskCountByPriority(priority);
    final tasks = viewModel.getTasksByPriority(priority);
    // 최대 3개까지만 표시
    final displayTasks = tasks.take(3).toList();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToTimelinePlanner(context, priority),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      taskCount.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const Spacer(),
                // 할일 미리보기 (최대 3개)
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: displayTasks.isEmpty
                      ? const Center(
                          child: Text(
                            '할일이 없습니다',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 첫 번째 할일만 미리보기
                              Expanded(
                                child: Text(
                                  displayTasks[0].title,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textPrimaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (tasks.length > 1)
                                Text(
                                  tasks.length > 3 
                                    ? '외 ${tasks.length - 1}개' 
                                    : '외 ${displayTasks.length - 1}개',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textSecondaryColor,
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