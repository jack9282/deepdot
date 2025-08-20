import 'package:flutter/material.dart';
import '../../../common/theme/app_theme.dart';

class GoalItem extends StatelessWidget {
  final String goal;
  final bool isSelected;
  final int colorIndex;
  final VoidCallback onTap;
  final VoidCallback? onEditPressed;
  final VoidCallback? onDeletePressed;

  const GoalItem({
    super.key,
    required this.goal,
    required this.isSelected,
    required this.colorIndex,
    required this.onTap,
    this.onEditPressed,
    this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.checkListColor[colorIndex % AppTheme.checkListColor.length];
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        _showPopupMenu(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isSelected
              ? Border.all(color: color, width: 2)
              : Border.all(color: AppTheme.textGreyColor),
        ),
        child: Text(
          goal,
          style: TextStyle(
            color: isSelected
                ? color
                : AppTheme.textGreyColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showPopupMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      items: [
        PopupMenuItem<String>(
          value: 'edit',
          height: 48,
          child: const Center(
            child: Text(
              '수정하기',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          height: 48,
          child: const Center(
            child: Text(
              '삭제하기',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') {
        if (onEditPressed != null) {
          onEditPressed!();
        }
      } else if (value == 'delete') {
        if (onDeletePressed != null) {
          onDeletePressed!();
        }
      }
    });
  }


}
