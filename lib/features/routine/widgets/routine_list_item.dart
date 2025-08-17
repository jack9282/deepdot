import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/routine_view_model.dart';
import '../../../common/theme/app_theme.dart';

class RoutineListItem extends StatefulWidget {
  final Map<String, dynamic> routine;
  final int index;
  final RoutineViewModel routineVM;
  final Function(int index)? onDelete;
  final VoidCallback? onEditPressed;

  const RoutineListItem({
    super.key,
    required this.routine,
    required this.index,
    required this.routineVM,
    this.onDelete,
    this.onEditPressed,
  });

  @override
  State<RoutineListItem> createState() => _RoutineListItemState();
}

class _RoutineListItemState extends State<RoutineListItem> {
  static const Color naverBlue = Color(0xFF3973F4);

  @override
  Widget build(BuildContext context) {
    final String routineName = widget.routine['name'] ?? '';
    final List<String> days = List<String>.from(widget.routine['days'] ?? []);

    return Consumer<RoutineViewModel>(
      builder: (context, routineVM, child) {
        final List<bool> checks = routineVM.getRoutineChecks(widget.index);
        
        return Container(
          height: 44,
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  _showActionMenu(context);
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
                final bool isDayActive = days.contains(_dayString(dayIndex));
                final bool isChecked = checks[dayIndex];
                
                return Expanded(
                  child: Center(
                    child: isDayActive
                        ? GestureDetector(
                            onTap: () {
                              routineVM.updateRoutineCheck(
                                widget.index,
                                dayIndex,
                                !isChecked,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              width: 28,
                              height: 28,
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: isChecked ? naverBlue : Colors.white,
                                border: Border.all(
                                  color: isChecked ? naverBlue : Colors.grey[400]!,
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

  String _dayString(int index) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[index];
  }

  void _showActionMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 메시지 영역
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    "'${widget.routine['name']}' 루틴",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // 구분선
                Container(
                  height: 1,
                  color: const Color(0xFFE0E0E0),
                ),
                // 수정 버튼
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    if (widget.onEditPressed != null) {
                      widget.onEditPressed!();
                    }
                  },
                  child: Container(
                    height: 48,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                    ),
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
                ),
                // 삭제 버튼
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    if (widget.onDelete != null) {
                      widget.onDelete!(widget.index);
                    }
                  },
                  child: Container(
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
                ),
              ],
            ),
          ),
        );
      },
    );
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
              color: const Color(0xFF3973F4),
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