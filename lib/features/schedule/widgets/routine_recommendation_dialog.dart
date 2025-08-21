import 'package:flutter/material.dart';
import '../../../data/models/routine_pattern_model.dart';
import '../../../data/models/routine_model.dart';
import '../../../data/repositories/routine_repository.dart';
import '../../../data/repositories/routine_pattern_repository.dart';
import '../../../common/theme/app_theme.dart';

/// 루틴 추천 다이얼로그
class RoutineRecommendationDialog extends StatefulWidget {
  final RoutinePatternModel pattern;
  
  const RoutineRecommendationDialog({
    super.key,
    required this.pattern,
  });
  
  static Future<bool?> show(BuildContext context, RoutinePatternModel pattern) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RoutineRecommendationDialog(pattern: pattern),
    );
  }
  
  @override
  State<RoutineRecommendationDialog> createState() => _RoutineRecommendationDialogState();
}

class _RoutineRecommendationDialogState extends State<RoutineRecommendationDialog> {
  final RoutineRepository _routineRepository = RoutineRepository();
  final RoutinePatternRepository _patternRepository = RoutinePatternRepository();
  bool _isCreating = false;
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppTheme.primaryColor,
                size: 30,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 제목
            const Text(
              '루틴을 발견했어요!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 설명
            Text(
              '"${widget.pattern.title}"를\n${widget.pattern.weekdayPattern}${widget.pattern.time != null ? " ${widget.pattern.time}" : ""}에\n${widget.pattern.count}번 반복하셨네요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey[700],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 루틴 정보 카드
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildInfoRow('제목', widget.pattern.title),
                  const SizedBox(height: 8),
                  if (widget.pattern.time != null) ...[
                    _buildInfoRow('시간', widget.pattern.time!),
                    const SizedBox(height: 8),
                  ],
                  _buildInfoRow('요일', widget.pattern.weekdayPattern),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 버튼들
            Row(
              children: [
                // 나중에 버튼
                Expanded(
                  child: TextButton(
                    onPressed: _isCreating ? null : () {
                      Navigator.of(context).pop(false);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Text(
                      '나중에',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 루틴 만들기 버튼
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _createRoutine,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            '루틴 만들기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
  
  Map<String, int> _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        return {
          'hour': int.parse(parts[0]),
          'minute': int.parse(parts[1]),
        };
      }
    } catch (e) {
      print('시간 파싱 실패: $e');
    }
    return {'hour': 9, 'minute': 0}; // 기본값
  }
  
  Future<void> _createRoutine() async {
    setState(() {
      _isCreating = true;
    });
    
    try {
      // 루틴 생성
      final success = await _routineRepository.addRoutine(
        name: widget.pattern.title,
        goalId: 1, // 기본 목표 ID 사용
        mon: widget.pattern.weekdays.contains(1),
        tue: widget.pattern.weekdays.contains(2),
        wed: widget.pattern.weekdays.contains(3),
        thu: widget.pattern.weekdays.contains(4),
        fri: widget.pattern.weekdays.contains(5),
        sat: widget.pattern.weekdays.contains(6),
        sun: widget.pattern.weekdays.contains(7),
        active: true,
        memo: '',
        startTime: _parseTimeString(widget.pattern.time ?? '09:00'),
      );
      
      if (!success) {
        throw Exception('Failed to create routine');
      }
      
      // 패턴 카운트 리셋
      await _patternRepository.resetPatternCount(
        widget.pattern.title,
        widget.pattern.time,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('루틴 "${widget.pattern.title}"이 생성되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('루틴 생성 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('루틴 생성에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}