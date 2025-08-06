import 'package:flutter/material.dart';
import '../view_models/routine_view_model.dart';
// DayBubble 위젯을 이 파일 안에 포함시키므로 import 'day_bubble.dart'는 필요 없습니다.

class RoutineListItem extends StatefulWidget {
  final Map<String, dynamic> routine;
  final int index;
  final RoutineViewModel routineVM;
  final Function(int index)? onDelete;

  const RoutineListItem({
    super.key,
    required this.routine,
    required this.index,
    required this.routineVM,
    this.onDelete,
  });

  @override
  State<RoutineListItem> createState() => _RoutineListItemState();
}

class _RoutineListItemState extends State<RoutineListItem> {
  late List<List<bool>> checks;

  static const Color naverBlue = Color(0xFF3973F4);

  @override
  void initState() {
    super.initState();
    checks = List<List<bool>>.from(widget.routine['checks'] ?? []);
  }

  @override
  void didUpdateWidget(covariant RoutineListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routine['checks'] != widget.routine['checks']) {
      checks = List<List<bool>>.from(widget.routine['checks'] ?? []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = naverBlue;
    final List<dynamic> items = widget.routine['items'] ?? [];

    return Column(
      children: [
        for (int itemIdx = 0; itemIdx < items.length; itemIdx++)
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    items[itemIdx]['name'] ?? '',
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
                ...List.generate(7, (dayIndex) {
                  final bool isDayActive = (items[itemIdx]['days'] as List).contains(_dayString(dayIndex));
                  
                  return Expanded(
                    child: Center(
                      child: isDayActive
                          ? GestureDetector(
                              onTap: () {
                                setState(() {
                                  checks[itemIdx][dayIndex] = !checks[itemIdx][dayIndex];
                                });
                                widget.routineVM.updateCheck(widget.index, itemIdx, dayIndex, checks[itemIdx][dayIndex]);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                width: 28,
                                height: 28,
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  color: checks[itemIdx][dayIndex] ? mainColor : Colors.white,
                                  border: Border.all(
                                    color: checks[itemIdx][dayIndex] ? mainColor : const Color(0xFFD1D5DB),
                                    width: 1.7,
                                  ),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: checks[itemIdx][dayIndex]
                                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                                    : null,
                              ),
                            )
                          : const DayBubble(),
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  String _dayString(int index) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[index];
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
    if (_overlayEntry != null) return; // 이미 오버레이가 있다면 새로 띄우지 않음

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx - 100, // 좌측으로 이동하여 체크박스 중앙에 위치
        top: offset.dy + size.height + 4, // 체크박스 바로 아래
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

    // 2초 후에 오버레이 제거
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
    _removeOverlay(); // 위젯이 사라질 때 오버레이도 정리
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
          color: Colors.grey[200],
          border: Border.all(
            color: const Color(0xFFD1D5DB),
            width: 1.7,
          ),
          borderRadius: BorderRadius.circular(7),
        ),
      ),
    );
  }
}