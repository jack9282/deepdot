import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_config.dart';
import 'token_manager.dart';

class FocusAPI {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: Duration(seconds: ApiConfig.timeoutSeconds),
    receiveTimeout: Duration(seconds: ApiConfig.timeoutSeconds),
    headers: ApiConfig.defaultHeaders,
  ));

  /// 하루 집중시간 전송 (자정에 호출)
  static Future<Map<String, dynamic>> sendDailyFocusTime({
    required String localDate,
    required int totalMinutes,
    String zoneId = 'Asia/Seoul',
  }) async {
    try {
      final token = await TokenManager.instance.getAccessToken();
      
      if (token == null) {
        throw Exception('로그인이 필요합니다');
      }

      final headers = {
        ...ApiConfig.defaultHeaders,
        'Authorization': 'Bearer $token',
      };

      final body = {
        'localDate': localDate,
        'totalMinutes': totalMinutes,
        'zoneId': zoneId,
      };

      final response = await _dio.post(
        ApiConfig.focusDailyEndpoint,
        data: jsonEncode(body),
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to send daily focus time: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('인증 실패. 다시 로그인해주세요.');
      }
      throw Exception('집중시간 전송 실패: $e');
    }
  }

  /// 주간 집중시간 조회
  static Future<Map<String, dynamic>> getWeeklyFocusTime({
    required String anchorDate,
    String zoneId = 'Asia/Seoul',
  }) async {
    try {
      final token = await TokenManager.instance.getAccessToken();
      
      if (token == null) {
        // 비회원은 로컬 데이터만 사용
        return _generateEmptyWeeklyResponse(anchorDate);
      }

      final headers = {
        ...ApiConfig.defaultHeaders,
        'Authorization': 'Bearer $token',
      };

      final queryParams = {
        'anchorDate': anchorDate,
        'zoneId': zoneId,
      };

      final response = await _dio.get(
        ApiConfig.focusWeeklyEndpoint,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get weekly focus time: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // 인증 실패 시 빈 데이터 반환
        return _generateEmptyWeeklyResponse(anchorDate);
      }
      // 네트워크 오류 시 빈 데이터 반환
      return _generateEmptyWeeklyResponse(anchorDate);
    }
  }

  /// 빈 주간 응답 생성
  static Map<String, dynamic> _generateEmptyWeeklyResponse(String anchorDate) {
    final date = DateTime.parse(anchorDate);
    final weekday = date.weekday;
    final weekStart = date.subtract(Duration(days: weekday - 1));
    final weekEnd = weekStart.add(Duration(days: 6));
    
    final days = [];
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      days.add({
        'date': '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
        'weekday': i + 1,
        'minutes': 0,
        'hours': 0,
        'minutesPart': 0,
      });
    }
    
    return {
      'weekStart': '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}',
      'weekEnd': '${weekEnd.year}-${weekEnd.month.toString().padLeft(2, '0')}-${weekEnd.day.toString().padLeft(2, '0')}',
      'totalMinutes': 0,
      'totalHours': 0,
      'totalMinutesPart': 0,
      'days': days,
    };
  }
}