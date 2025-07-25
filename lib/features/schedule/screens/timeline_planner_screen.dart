import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/theme/app_theme.dart';
import '../../../data/models/task_model.dart';
import '../view_models/schedule_view_model.dart';
import '../widgets/task_list_item.dart';
import 'task_edit_screen.dart';

class TimelinePlannerScreen extends StatefulWidget {
  final TaskPriority priority;

  const TimelinePlannerScreen({
    super.key,
    required this.priority,
  });

  @override
  State<TimelinePlannerScreen> createState() => _TimelinePlannerScreenState();
}

class _TimelinePlannerScreenState extends State<TimelinePlannerScreen> {
  late ScheduleViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ScheduleViewModel();
    _loadTasks();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _loadTasks() {
    _viewModel.loadTasksByPriority(widget.priority);
  }

  String _getPriorityTitle(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgentImportant:
        return '중요 & 긴급';
      case TaskPriority.important:
        return '중요';
      case TaskPriority.urgent:
        return '긴급';
      case TaskPriority.neither:
        return '둘 다 아님';
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgentImportant:
        return AppTheme.urgentImportantColor;
      case TaskPriority.important:
        return AppTheme.importantColor;
      case TaskPriority.urgent:
        return AppTheme.urgentColor;
      case TaskPriority.neither:
        return AppTheme.neitherColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ScheduleViewModel>(
      create: (_) => _viewModel,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getPriorityColor(widget.priority).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getPriorityIcon(widget.priority),
                  color: _getPriorityColor(widget.priority),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getPriorityTitle(widget.priority),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _viewModel.refresh(),
            ),
          ],
        ),
        body: Consumer<ScheduleViewModel>(
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

            final tasks = viewModel.filteredTasks;
            
            if (tasks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '등록된 일정이 없습니다',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '새로운 일정을 추가해보세요',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // 상단 카운트 정보
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(widget.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getPriorityColor(widget.priority).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '총 ${tasks.length}개의 일정',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _getPriorityColor(widget.priority),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '완료: ${tasks.where((task) => task.isCompleted).length}개',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 타임라인 리스트
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskListItem(
                        task: task,
                        onEdit: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TaskEditScreen(task: task),
                            ),
                          ).then((result) {
                            if (result == true) {
                              _viewModel.refresh();
                            }
                          });
                        },
                        onToggleComplete: () {
                          _viewModel.toggleTaskCompletion(task.id);
                        },
                        onDelete: () {
                          _showDeleteConfirmDialog(context, task);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgentImportant:
        return Icons.warning;
      case TaskPriority.important:
        return Icons.star;
      case TaskPriority.urgent:
        return Icons.schedule;
      case TaskPriority.neither:
        return Icons.more_horiz;
    }
  }

  void _showDeleteConfirmDialog(BuildContext context, TaskModel task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('일정 삭제'),
          content: Text('\'${task.title}\' 일정을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _viewModel.deleteTask(task.id);
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
} 