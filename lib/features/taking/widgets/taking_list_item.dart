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
    if (oldWidget.checks != widget.checks || oldWidget.times.length != widget.times.length) {
      // times 길이가 변경되었거나 checks가 변경된 경우
      if (widget.checks.length != widget.times.length) {
        // checks 길이를 times 길이에 맞춰 조정
        _checks = List.generate(widget.times.length, (index) {
          return index < widget.checks.length ? widget.checks[index] : false;
        });
      } else {
        _checks = List<bool>.from(widget.checks);
      }
    }
  }

  void _onCheckChanged(int index, bool value) {
    // 인덱스 범위 체크
    if (index >= 0 && index < _checks.length) {
      setState(() {
        _checks[index] = value;
      });
      
      if (widget.onCheckChanged != null) {
        widget.onCheckChanged!(index, value);
      }
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
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(0xFF2563EB),
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 7),
                  GestureDetector(
                    onTap: () {
                      if (timeIdx < _checks.length) {
                        _onCheckChanged(timeIdx, !_checks[timeIdx]);
                      }
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: (timeIdx < _checks.length && _checks[timeIdx]) ? const Color(0xFF2563EB) : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: (timeIdx < _checks.length && _checks[timeIdx]) ? const Color(0xFF2563EB) : const Color(0xFFE8E8E8),
                          width: 1,
                        ),
                      ),
                      child: (timeIdx < _checks.length && _checks[timeIdx])
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
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

  // 시간 형식을 "HH:MM" 또는 "HH:MM:SS"에서 "HH:MM" (24시간 형식)으로 변환
  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        
        // 24시간 형식으로 표시 (예: 08:00, 13:30, 23:45) - 초는 제거
        return '${hour.toString().padLeft(2, '0')}:$minute';
      }
    } catch (e) {
      // 파싱 실패 시 원본 반환
    }
    return time;
  }
}