import 'package:flutter/material.dart';
import '../../../common/theme/app_theme.dart';

class TakingListItem extends StatelessWidget {
  final String name;
  final List<bool> checks;
  final List<String> times;
  final VoidCallback? onMorePressed;

  const TakingListItem({
    super.key,
    required this.name,
    required this.checks,
    required this.times,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE0E0E0),
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
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.black54),
                  onPressed: onMorePressed,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(times.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Row(
                    children: [
                      Text(
                        times[i],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        checks[i]
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: AppTheme.textPrimaryColor,
                        size: 22,
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
