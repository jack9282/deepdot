import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine_pattern_model.dart';
import '../models/schedule_model.dart';

/// 루틴 패턴을 분석하고 저장하는 Repository
class RoutinePatternRepository {
  static const String _patternsKey = 'routine_patterns';
  static const String _aiRoutineKey = 'ai_routine_recommendation';
  
  /// 루틴 추천 기능이 켜져있는지 확인
  Future<bool> isRoutineRecommendationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_aiRoutineKey) ?? false;
  }
  
  /// 저장된 패턴들 불러오기
  Future<List<RoutinePatternModel>> getPatterns() async {
    final prefs = await SharedPreferences.getInstance();
    final patternsString = prefs.getString(_patternsKey);
    
    if (patternsString == null) return [];
    
    try {
      final List<dynamic> patternsJson = jsonDecode(patternsString);
      return patternsJson
          .map((json) => RoutinePatternModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('패턴 불러오기 실패: $e');
      return [];
    }
  }
  
  /// 패턴들 저장하기
  Future<void> savePatterns(List<RoutinePatternModel> patterns) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patternsJson = patterns.map((p) => p.toJson()).toList();
      await prefs.setString(_patternsKey, jsonEncode(patternsJson));
    } catch (e) {
      print('패턴 저장 실패: $e');
    }
  }
  
  /// 일정 추가 시 패턴 기록
  Future<RoutinePatternModel?> recordSchedulePattern(ScheduleModel schedule) async {
    // 루틴 추천 기능이 꺼져있으면 기록하지 않음
    if (!await isRoutineRecommendationEnabled()) {
      return null;
    }
    
    final patterns = await getPatterns();
    final scheduledDate = DateTime.parse(schedule.startDate);
    final weekday = scheduledDate.weekday; // 1 = 월요일, 7 = 일요일
    
    // 같은 제목과 시간의 패턴 찾기
    final existingPatternIndex = patterns.indexWhere(
      (p) => p.matchesPattern(schedule.title, schedule.time),
    );
    
    RoutinePatternModel updatedPattern;
    
    if (existingPatternIndex != -1) {
      // 기존 패턴 업데이트
      final existingPattern = patterns[existingPatternIndex];
      updatedPattern = existingPattern
          .addWeekday(weekday)
          .copyWithNewCount(existingPattern.count + 1);
      patterns[existingPatternIndex] = updatedPattern;
    } else {
      // 새로운 패턴 생성
      updatedPattern = RoutinePatternModel(
        title: schedule.title,
        time: schedule.time,
        weekdays: [weekday],
        count: 1,
        lastAdded: DateTime.now(),
      );
      patterns.add(updatedPattern);
    }
    
    // 패턴 저장
    await savePatterns(patterns);
    
    // 5번 이상 반복되었으면 추천 대상
    if (updatedPattern.isRecommendable) {
      return updatedPattern;
    }
    
    return null;
  }
  
  /// 특정 패턴 가져오기
  Future<RoutinePatternModel?> getPattern(String title, String? time) async {
    final patterns = await getPatterns();
    try {
      return patterns.firstWhere(
        (p) => p.matchesPattern(title, time),
      );
    } catch (e) {
      return null;
    }
  }
  
  /// 추천 가능한 패턴들 가져오기
  Future<List<RoutinePatternModel>> getRecommendablePatterns() async {
    final patterns = await getPatterns();
    return patterns.where((p) => p.isRecommendable).toList();
  }
  
  /// 패턴 초기화
  Future<void> clearPatterns() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_patternsKey);
  }
  
  /// 특정 패턴 삭제
  Future<void> removePattern(String title, String? time) async {
    final patterns = await getPatterns();
    patterns.removeWhere((p) => p.matchesPattern(title, time));
    await savePatterns(patterns);
  }
  
  /// 패턴 카운트 리셋 (루틴 생성 후)
  Future<void> resetPatternCount(String title, String? time) async {
    final patterns = await getPatterns();
    final patternIndex = patterns.indexWhere(
      (p) => p.matchesPattern(title, time),
    );
    
    if (patternIndex != -1) {
      patterns[patternIndex] = patterns[patternIndex].copyWithNewCount(0);
      await savePatterns(patterns);
    }
  }
  
  /// 패턴 분석 요약 정보
  Future<Map<String, dynamic>> getPatternSummary() async {
    final patterns = await getPatterns();
    final recommendable = patterns.where((p) => p.isRecommendable).toList();
    
    return {
      'totalPatterns': patterns.length,
      'recommendablePatterns': recommendable.length,
      'mostFrequent': patterns.isEmpty ? null : patterns.reduce((a, b) => a.count > b.count ? a : b),
    };
  }
}