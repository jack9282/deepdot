import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../common/theme/app_theme.dart';
import '../../../data/models/task_model.dart';
import '../view_models/schedule_view_model.dart';
import '../widgets/task_list_item.dart';
import 'task_add_screen.dart';
import 'task_edit_screen.dart';

class ScheduleListScreen extends StatefulWidget {
  final TaskPriority priority;

  const ScheduleListScreen({
    super.key,
    required this.priority,
  });

  @override
  State<ScheduleListScreen> createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ScheduleViewModel>(
      create: (_) => _viewModel,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: Consumer<ScheduleViewModel>(
            builder: (context, viewModel, child) {
              return Text(viewModel.getPriorityTitle(widget.priority));
            },
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

            final incompleteTasks = viewModel.incompleteTasks;
            final completedTasks = viewModel.completedTasks;

            return RefreshIndicator(
              onRefresh: () => viewModel.refresh(),
              child: CustomScrollView(
                slivers: [
                  // 헤더 정보
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: viewModel.getPriorityColor(widget.priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: viewModel.getPriorityColor(widget.priority).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: viewModel.getPriorityColor(widget.priority).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getPriorityIcon(widget.priority),
                                  color: viewModel.getPriorityColor(widget.priority),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      viewModel.getPriorityTitle(widget.priority),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      viewModel.getPriorityDescription(widget.priority),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildStatItem('미완료', incompleteTasks.length.toString(), Colors.orange),
                              const SizedBox(width: 24),
                              _buildStatItem('완료', completedTasks.length.toString(), Colors.green),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 미완료 할일 목록
                  if (incompleteTasks.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(
                          '할 일',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = incompleteTasks[index];
                          return TaskListItem(
                            task: task,
                            onToggleComplete: () => _toggleTaskCompletion(task.id),
                            onEdit: () => _editTask(task),
                            onDelete: () => _deleteTask(task.id),
                          );
                        },
                        childCount: incompleteTasks.length,
                      ),
                    ),
                  ],

                  // 완료된 할일 목록
                  if (completedTasks.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          '완료된 할 일',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = completedTasks[index];
                          return TaskListItem(
                            task: task,
                            onToggleComplete: () => _toggleTaskCompletion(task.id),
                            onEdit: () => _editTask(task),
                            onDelete: () => _deleteTask(task.id),
                          );
                        },
                        childCount: completedTasks.length,
                      ),
                    ),
                  ],

                  // 빈 상태 메시지
                  if (incompleteTasks.isEmpty && completedTasks.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '아직 할 일이 없습니다\n+ 버튼을 눌러 새로운 할 일을 추가해보세요',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 하단 패딩
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addTask,
          backgroundColor: _viewModel.getPriorityColor(widget.priority),
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
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

  void _addTask() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskAddScreen(priority: widget.priority),
      ),
    ).then((result) {
      if (result == true) {
        _viewModel.refresh();
      }
    });
  }

  void _editTask(TaskModel task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskEditScreen(task: task),
      ),
    ).then((result) {
      if (result == true) {
        _viewModel.refresh();
      }
    });
  }

  void _toggleTaskCompletion(String taskId) {
    _viewModel.toggleTaskCompletion(taskId);
  }

  void _deleteTask(String taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할 일 삭제'),
        content: const Text('이 할 일을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _viewModel.deleteTask(taskId);
            },
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 