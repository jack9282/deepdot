import 'package:flutter/material.dart';
import '../../../common/theme/app_theme.dart';
import '../view_models/routine_view_model.dart';
import '../screens/set_routine.dart';

class RoutineListItem extends StatelessWidget {
  final Map<String, dynamic> routine;
  final int index;
  final RoutineViewModel routineVM;
  final List<Map<String, dynamic>> routines;
  final Function(int index, String newName)? onUpdate;
  final Function(int index, Map<String, dynamic> updatedRoutine)? onUpdateData;
  final Function(int index)? onDelete;

  const RoutineListItem({
    super.key,
    required this.routine,
    required this.index,
    required this.routineVM,
    required this.routines,
    this.onUpdate,
    this.onUpdateData,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final List<bool> checks = routine['checks'] as List<bool>;

    return Container(
      child: Row(
        children: [
          // 루틴 이름 (클릭 가능)
          SizedBox(
            width: 120,
            child: PopupMenuButton<String>(
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18, color: Colors.black54),
                      SizedBox(width: 8),
                      Text(
                        '수정',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        '삭제',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (String value) async {
                if (value == 'edit') {
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (context.mounted) {
                    _navigateToEditScreen(context);
                  }
                } else if (value == 'delete') {
                  _showDeleteDialog(context);
                }
              },
              child: Text(
                routine['name'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          // 체크박스들
          ...List.generate(7, (dayIndex) => Expanded(
            child: Center(
              child: Checkbox(
                value: checks[dayIndex],
                onChanged: (value) {
                  routineVM.updateCheck(routines, index, dayIndex, value ?? false);
                },
                activeColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  // 수정 화면으로 이동
  void _navigateToEditScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SetRoutineScreen(
          existingRoutine: routine,
          routineIndex: index,
        ),
      ),
    ).then((result) {
      if (result != null && result['routine'] != null) {
        // 수정된 루틴 데이터로 업데이트
        final updatedRoutine = result['routine'] as Map<String, dynamic>;
        final routineIndex = result['index'] as int;
        // 기존 체크 상태 유지
        updatedRoutine['checks'] = routine['checks'];
        onUpdateData?.call(routineIndex, updatedRoutine);
      }
    });
  }

  // 삭제 확인 다이얼로그
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.black, width: 3),
            borderRadius: BorderRadius.circular(12),
          ),
          content: SizedBox(
            width: 200,
            height: 100,
            child: Center(
              child: Text(
                "'${routine['name']}'을 삭제하시겠습니까?",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.buttonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      '아니오',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.buttonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDelete?.call(index);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${routine['name']} 삭제됨')),
                      );
                    },
                    child: const Text(
                      '네',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
