import 'package:flutter/material.dart';
import '../../../common/theme/app_theme.dart';
import '../../../data/models/task_model.dart';
import 'package:intl/intl.dart';

class TaskListItem extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 체크박스
                GestureDetector(
                  onTap: onToggleComplete,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted 
                            ? _getPriorityColor(task.priority)
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                      color: task.isCompleted 
                          ? _getPriorityColor(task.priority)
                          : Colors.transparent,
                    ),
                    child: task.isCompleted
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 할일 내용
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: task.isCompleted 
                              ? AppTheme.textSecondaryColor
                              : AppTheme.textPrimaryColor,
                          decoration: task.isCompleted 
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      
                      // 설명 (있을 경우)
                      if (task.description != null && task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: task.isCompleted 
                                ? AppTheme.textSecondaryColor.withOpacity(0.7)
                                : AppTheme.textSecondaryColor,
                            decoration: task.isCompleted 
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      // 마감일 및 생성일
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // 마감일
                          if (task.dueDate != null) ...[
                            Icon(
                              Icons.schedule,
                              size: 12,
                              color: _getDueDateColor(),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MM/dd HH:mm').format(task.dueDate!),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getDueDateColor(),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else ...[
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MM/dd HH:mm').format(task.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                          
                          const Spacer(),
                          
                          // 우선순위 표시
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(task.priority).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getPriorityColor(task.priority).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getPriorityName(task.priority),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _getPriorityColor(task.priority),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // 옵션 메뉴
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          const Text('편집'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            task.isCompleted ? Icons.undo : Icons.check,
                            size: 16,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(task.isCompleted ? '미완료로 변경' : '완료'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete,
                            size: 16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '삭제',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'toggle':
                        onToggleComplete();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgentImportant:
        return const Color(0xFFE53E3E); // 빨간색
      case TaskPriority.important:
        return const Color(0xFFD69E2E); // 노란색
      case TaskPriority.urgent:
        return const Color(0xFF3182CE); // 파란색
      case TaskPriority.neither:
        return const Color(0xFF38A169); // 초록색
    }
  }

  String _getPriorityName(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgentImportant:
        return '긴급중요';
      case TaskPriority.important:
        return '중요';
      case TaskPriority.urgent:
        return '긴급';
      case TaskPriority.neither:
        return '일반';
    }
  }

  Color _getDueDateColor() {
    if (task.dueDate == null) return Colors.grey[500]!;
    
    final now = DateTime.now();
    final difference = task.dueDate!.difference(now);
    
    if (difference.inDays < 0) {
      return Colors.red; // 지난 마감일
    } else if (difference.inDays == 0) {
      return Colors.orange; // 오늘 마감
    } else if (difference.inDays <= 3) {
      return Colors.amber; // 3일 이내
    } else {
      return Colors.grey[600]!; // 여유 있음
    }
  }
} 