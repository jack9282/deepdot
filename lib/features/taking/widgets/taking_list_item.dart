import 'package:flutter/material.dart';
import '../../../common/theme/app_theme.dart';

class TakingListItem extends StatefulWidget {
  final String name;
  final List<bool> checks;
  final List<String> times;
  final VoidCallback? onEditPressed;
  final VoidCallback? onDeletePressed;
  final Function(int index, bool value)? onCheckChanged;

  const TakingListItem({
    super.key,
    required this.name,
    required this.checks,
    required this.times,
    this.onEditPressed,
    this.onDeletePressed,
    this.onCheckChanged,
  });

  @override
  State<TakingListItem> createState() => _TakingListItemState();
}

class _TakingListItemState extends State<TakingListItem> {
  late List<bool> _checks;

  @override
  void initState() {
    super.initState();
    _checks = List<bool>.from(widget.checks);
  }

  @override
  void didUpdateWidget(TakingListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checks != widget.checks) {
      _checks = List<bool>.from(widget.checks);
    }
  }

  void _onCheckChanged(int index, bool value) {
    setState(() {
      _checks[index] = value;
    });
    
    if (widget.onCheckChanged != null) {
      widget.onCheckChanged!(index, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 20,),
              Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor, // 파란색
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(0xFFB0B0B0),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                elevation: 4,
                onSelected: (value) {
                  if (value == 'edit') {
                    // 수정 기능
                    if (widget.onEditPressed != null) {
                      widget.onEditPressed!();
                    }
                  } else if (value == 'delete') {
                    // 삭제 기능
                    if (widget.onDeletePressed != null) {
                      widget.onDeletePressed!();
                    }
                  }
                },
                itemBuilder: (BuildContext context) => [
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
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(widget.times.length, (timeIdx) {
              return Row(
                children: [
                  Text(
                    _formatTime(widget.times[timeIdx]),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 1.1,
                    child: Checkbox(
                      value: _checks[timeIdx],
                      onChanged: (val) {
                        _onCheckChanged(timeIdx, val ?? false);
                      },
                      activeColor: Color(0xFF2563EB), // 파란 체크박스
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      side: const BorderSide(
                        color: Color(0xFFD1D5DB),
                        width: 1.5,
                      ),
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

  // 시간 형식을 "HH:MM"에서 "HH:MM" (24시간 형식)으로 변환
  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        
        // 24시간 형식으로 표시 (예: 08:00, 13:30, 23:45)
        return '${hour.toString().padLeft(2, '0')}:$minute';
      }
    } catch (e) {
      // 파싱 실패 시 원본 반환
    }
    return time;
  }
}