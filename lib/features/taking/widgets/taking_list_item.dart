import 'package:flutter/material.dart';
import '../../../common/theme/app_theme.dart';

class TakingListItem extends StatefulWidget {
  final String name;
  final List<bool> checks;
  final List<String> times;
  final VoidCallback? onMorePressed;
  final Function(int index, bool value)? onCheckChanged;

  const TakingListItem({
    super.key,
    required this.name,
    required this.checks,
    required this.times,
    this.onMorePressed,
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
    return Card(
      color: AppTheme.buttonColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.black54),
                  onPressed: widget.onMorePressed,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(widget.times.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Row(
                    children: [
                      Text(
                        widget.times[i],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Checkbox(
                        value: _checks[i],
                        onChanged: (value) {
                          _onCheckChanged(i, value ?? false);
                        },
                        activeColor: AppTheme.textPrimaryColor,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}