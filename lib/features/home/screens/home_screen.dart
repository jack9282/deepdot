import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/theme/app_theme.dart';
import '../../../data/models/task_model.dart';
import '../view_models/home_view_model.dart';
import '../../schedule/screens/schedule_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeViewModel _viewModel;
  bool _isMenuOpen = false;

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
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text('DeepDot'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _viewModel.refresh(),
                ),
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    // 햄버거 메뉴 동작
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
                                subtitle: '지금 해야 할 것들',
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
                                subtitle: '계획해서 해야 할 것들',
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
                                subtitle: '위임하거나 빠르게 처리',
                                color: AppTheme.urgentColor,
                                icon: Icons.schedule,
                                priority: TaskPriority.urgent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 중요하지 않음 (우하)
                            Expanded(
                              child: _buildMatrixCard(
                                context,
                                viewModel,
                                title: '중요하지 않음',
                                subtitle: '여유가 있을 때',
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
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isMenuOpen = !_isMenuOpen;
                });
              },
              backgroundColor: const Color(0xFF2D3748),
              child: AnimatedRotation(
                turns: _isMenuOpen ? 0.125 : 0.0, // 45도 회전
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          // 배경 오버레이 (메뉴가 열렸을 때)
          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isMenuOpen = false;
                  });
                },
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
          
          // 플로팅 메뉴들
          if (_isMenuOpen) ...[
            // 복용 체크리스트 메뉴
            Positioned(
              bottom: 140,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 텍스트 라벨
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '오늘의 복용 체크리스트',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '복용 이력 추가',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 아이콘 버튼
                  Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    color: Colors.white,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        setState(() {
                          _isMenuOpen = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('복용 체크리스트 기능은 곧 추가될 예정입니다!'),
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        );
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          size: 24,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 루틴 체크리스트 메뉴
            Positioned(
              bottom: 210,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 텍스트 라벨
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '오늘의 루틴 체크리스트',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '루틴 만들기',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 아이콘 버튼
                  Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    color: Colors.grey[200],
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        setState(() {
                          _isMenuOpen = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('루틴 체크리스트 기능은 곧 추가될 예정입니다!'),
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        );
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          size: 24,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToScheduleList(BuildContext context, TaskPriority priority) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScheduleListScreen(priority: priority),
      ),
    ).then((result) {
      // 돌아올 때 데이터 새로고침
      if (result == true) {
        _viewModel.refresh();
      }
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
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToScheduleList(context, priority),
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
                // 할일 미리보기
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: tasks.isEmpty
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
                                  tasks[0].title,
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
                                  '외 ${tasks.length - 1}개',
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
} 