import 'package:flutter/material.dart';
import '../../../common/theme/app_theme.dart';
import '../view_models/routine_view_model.dart';

class RoutineListItem extends StatelessWidget {
  final Map<String, dynamic> routine;
  final int index;
  final RoutineViewModel routineVM;
  final List<Map<String, dynamic>> routines;

  const RoutineListItem({
    super.key,
    required this.routine,
    required this.index,
    required this.routineVM,
    required this.routines,
  });

  @override
  Widget build(BuildContext context) {
    final List<bool> checks = routine['checks'] as List<bool>;

    return Container(
      child: Row(
        children: [
          // 루틴 이름
          SizedBox(
            width: 120,
            child: Text(
              routine['name'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
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
}
