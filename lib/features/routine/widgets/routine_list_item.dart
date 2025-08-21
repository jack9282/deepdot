import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/routine_view_model.dart';
import '../../../common/theme/app_theme.dart';

class RoutineListItem extends StatefulWidget {
  final Map<String, dynamic> routine;
  final int index;
  final RoutineViewModel routineVM;
  final Function(int routineIdOrIndex)? onDelete;
  final VoidCallback? onEditPressed;
  final int goalIndex;

  const RoutineListItem({
    super.key,
    required this.routine,
    required this.index,
    required this.routineVM,
    this.onDelete,
    this.onEditPressed,
    required this.goalIndex,
  });

  @override
  State<RoutineListItem> createState() => _RoutineListItemState();
}

class _RoutineListItemState extends State<RoutineListItem> {
  // 게스트 모드에서 사용할 임시 체크 상태
  List<bool> _guestCheckStates = List.generate(7, (_) => false);
  
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final String routineName = widget.routine['name'] ?? '';
    final bool mon = widget.routine['mon'] ?? false;
    final bool tue = widget.routine['tue'] ?? false;
    final bool wed = widget.routine['wed'] ?? false;
    final bool thu = widget.routine['thu'] ?? false;
    final bool fri = widget.routine['fri'] ?? false;
    final bool sat = widget.routine['sat'] ?? false;
    final bool sun = widget.routine['sun'] ?? false;

    return Consumer<RoutineViewModel>(
      builder: (context, routineVM, child) {
        return Container(
          height: 44,
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  _showPopupMenu(context);
                },
                child: SizedBox(
                  width: 100,
                  child: Text(
                    routineName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF222222),
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              ...List.generate(7, (dayIndex) {
                final bool isDayActive = _isDayActive(dayIndex, mon, tue, wed, thu, fri, sat, sun);
                final routineId = widget.routine['routineId'] as int?;
                
                // routineId가 null인 경우 widget.index를 대신 사용
                final bool isChecked = routineId != null 
                    ? widget.routineVM.getRoutineCheckState(routineId, dayIndex)
                    : _guestCheckStates[dayIndex]; // 게스트 모드에서는 로컬 상태 사용
                
                return Expanded(
                  child: Center(
                    child: isDayActive
                        ? GestureDetector(
                            onTap: () async {
                              // routineId가 있는 경우에만 체크 상태 업데이트
                              if (routineId != null) {
                                await widget.routineVM.updateRoutineCheckState(routineId, dayIndex, !isChecked);
                              } else {
                                // 게스트 모드에서는 로컬 상태 업데이트
                                setState(() {
                                  _guestCheckStates[dayIndex] = !isChecked;
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              width: 28,
                              height: 28,
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: isChecked ? AppTheme.checkListColor[widget.goalIndex % AppTheme.checkListColor.length] : Colors.white,
                                border: Border.all(
                                  color: isChecked ? AppTheme.checkListColor[widget.goalIndex % AppTheme.checkListColor.length] : AppTheme.textGreyColor,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 150),
                                child: isChecked
                                    ? const Icon(
                                        Icons.check,
                                        key: ValueKey('checked'),
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : const SizedBox.shrink(key: ValueKey('unchecked')),
                              ),
                            ),
                          )
                        : const DayBubble(),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  bool _isDayActive(int dayIndex, bool mon, bool tue, bool wed, bool thu, bool fri, bool sat, bool sun) {
    switch (dayIndex) {
      case 0: return mon;
      case 1: return tue;
      case 2: return wed;
      case 3: return thu;
      case 4: return fri;
      case 5: return sat;
      case 6: return sun;
      default: return false;
    }
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
        if (widget.onEditPressed != null) {
          widget.onEditPressed!();
        }
      } else if (value == 'delete') {
        if (widget.onDelete != null) {
          // routineId가 있으면 routineId를, 없으면 index를 전달
          final routineId = widget.routine['routineId'] as int?;
          print('삭제할 루틴 정보: routineId=$routineId, name=${widget.routine['name']}');
          if (routineId != null) {
            widget.onDelete!(routineId);
          } else {
            print('routineId가 null이므로 index 사용: ${widget.index}');
            widget.onDelete!(widget.index);
          }
        }
      }
    });
  }
}

class DayBubble extends StatefulWidget {
  const DayBubble({Key? key}) : super(key: key);

  @override
  State<DayBubble> createState() => _DayBubbleState();
}

class _DayBubbleState extends State<DayBubble> {
  OverlayEntry? _overlayEntry;

  void _showOverlay(BuildContext context) {
    if (_overlayEntry != null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx - 100,
        top: offset.dy + size.height + 4,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColorBright,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              '이 요일엔 루틴이 설정되어 있지 않아요',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    Future.delayed(const Duration(seconds: 2), () {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showOverlay(context);
      },
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: CustomPaint(
          painter: DashedBorderPainter(),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.5;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(7)));

    // 점선 패턴 생성
    final dashPattern = <double>[dashWidth, dashSpace];
    final dashedPath = Path();
    
    // 경로를 따라 점선 그리기
    final pathMetrics = path.computeMetrics().first;
    double distance = 0;
    bool draw = true;
    
    while (distance < pathMetrics.length) {
      final length = dashPattern[draw ? 0 : 1];
      if (draw) {
        final start = pathMetrics.getTangentForOffset(distance)?.position ?? Offset.zero;
        final end = pathMetrics.getTangentForOffset(distance + length)?.position ?? Offset.zero;
        dashedPath.moveTo(start.dx, start.dy);
        dashedPath.lineTo(end.dx, end.dy);
      }
      distance += length;
      draw = !draw;
    }
    
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}