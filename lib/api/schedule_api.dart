import 'dart:convert';
import '../utils/http_client.dart';
import '../data/models/schedule_model.dart';

class ScheduleApi {
  static const String _baseEndpoint = '/api/schedule';

  /// 일정 등록 (POST)
  /// POST /api/schedule
  static Future<int> createSchedule(ScheduleModel schedule) async {
    try {
      final response = await HttpClient.post(
        _baseEndpoint,
        body: schedule.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // 서버가 직접 int를 반환하는 경우 처리
        if (responseData is int) {
          return responseData;
        } else if (responseData is Map<String, dynamic>) {
          return responseData['scheduleId'] as int;
        } else {
          throw Exception('예상치 못한 응답 형식: $responseData');
        }
      } else {
        throw _handleError(response, '일정 등록 실패');
      }
    } catch (e) {
      if (e is ScheduleApiException) rethrow;
      throw Exception('일정 등록 중 오류 발생: $e');
    }
  }

  /// 특정 일정 조회 (GET)
  /// GET /api/schedule/{scheduleId}
  static Future<ScheduleModel> getSchedule(int scheduleId) async {
    try {
      final response = await HttpClient.get('$_baseEndpoint/$scheduleId');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ScheduleModel.fromJson(responseData);
      } else {
        throw _handleError(response, '일정 조회 실패');
      }
    } catch (e) {
      if (e is ScheduleApiException) rethrow;
      throw Exception('일정 조회 중 오류 발생: $e');
    }
  }

  /// 사용자의 모든 일정 조회 (GET)
  /// GET /api/schedule
  static Future<List<ScheduleModel>> getAllSchedules() async {
    try {
      final response = await HttpClient.get(_baseEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData
            .map((json) => ScheduleModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw _handleError(response, '일정 목록 조회 실패');
      }
    } catch (e) {
      if (e is ScheduleApiException) rethrow;
      throw Exception('일정 목록 조회 중 오류 발생: $e');
    }
  }

  /// 특정 날짜 일정 조회 (GET)
  /// GET /api/schedule/date?date=<date>
  static Future<List<ScheduleModel>> getSchedulesByDate(String date) async {
    try {
      final response = await HttpClient.get('$_baseEndpoint/date?date=$date');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // 단일 객체 또는 배열 모두 처리
        if (responseData is List) {
          return responseData
              .map((json) => ScheduleModel.fromJson(json as Map<String, dynamic>))
              .toList();
        } else if (responseData is Map<String, dynamic>) {
          return [ScheduleModel.fromJson(responseData)];
        } else {
          return [];
        }
      } else {
        throw _handleError(response, '날짜별 일정 조회 실패');
      }
    } catch (e) {
      if (e is ScheduleApiException) rethrow;
      throw Exception('날짜별 일정 조회 중 오류 발생: $e');
    }
  }

  /// 기간 내 일정 조회 (GET)
  /// GET /api/schedule/range?from=<date>&to=<date>
  static Future<List<ScheduleModel>> getSchedulesByRange(String from, String to) async {
    try {
      final response = await HttpClient.get('$_baseEndpoint/range?from=$from&to=$to');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData
            .map((json) => ScheduleModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw _handleError(response, '기간별 일정 조회 실패');
      }
    } catch (e) {
      if (e is ScheduleApiException) rethrow;
      throw Exception('기간별 일정 조회 중 오류 발생: $e');
    }
  }

  /// 일정 배치 등록 (POST)
  /// POST /api/schedule/batch?from=<date>&to=<date>
  static Future<List<int>> createScheduleBatch(
    String from,
    String to,
    ScheduleModel schedule,
  ) async {
    try {
      final response = await HttpClient.post(
        '$_baseEndpoint/batch?from=$from&to=$to',
        body: schedule.toJson(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData.cast<int>();
      } else {
        throw _handleError(response, '일정 배치 등록 실패');
      }
    } catch (e) {
      if (e is ScheduleApiException) rethrow;
      throw Exception('일정 배치 등록 중 오류 발생: $e');
    }
  }

  /// 일정 수정 (PATCH)
  /// PATCH /api/schedule/{scheduleId}
  static Future<void> updateSchedule(int scheduleId, ScheduleModel schedule) async {
    try {
      final response = await HttpClient.patch(
        '$_baseEndpoint/$scheduleId',
        body: schedule.toJson(),
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw _handleError(response, '일정 수정 실패');
      }
    } catch (e) {
      if (e is ScheduleApiException) rethrow;
      throw Exception('일정 수정 중 오류 발생: $e');
    }
  }

  /// 일정 삭제 (DELETE)
  /// DELETE /api/schedule/{scheduleId}
  static Future<void> deleteSchedule(int scheduleId) async {
    try {
      final response = await HttpClient.delete('$_baseEndpoint/$scheduleId');

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw _handleError(response, '일정 삭제 실패');
      }
    } catch (e) {
      if (e is ScheduleApiException) rethrow;
      throw Exception('일정 삭제 중 오류 발생: $e');
    }
  }

  /// 에러 처리 헬퍼 메서드
  static Exception _handleError(dynamic response, String defaultMessage) {
    String errorMessage = '$defaultMessage: ${response.statusCode}';
    String errorCode = 'UNKNOWN_ERROR';
    
    if (response.body.isNotEmpty) {
      try {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        if (errorData.containsKey('errorCode') && errorData.containsKey('errorMessage')) {
          errorCode = errorData['errorCode'] as String;
          errorMessage = errorData['errorMessage'] as String;
        } else if (errorData.containsKey('message')) {
          errorMessage = errorData['message'] as String;
        }
      } catch (e) {
        errorMessage = '$errorMessage - ${response.body}';
      }
    }
    
    return ScheduleApiException(
      statusCode: response.statusCode,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }
}

/// 스케줄 API 전용 예외 클래스
class ScheduleApiException implements Exception {
  final int statusCode;
  final String errorCode;
  final String errorMessage;

  ScheduleApiException({
    required this.statusCode,
    required this.errorCode,
    required this.errorMessage,
  });

  @override
  String toString() {
    return 'ScheduleApiException(statusCode: $statusCode, errorCode: $errorCode, message: $errorMessage)';
  }
}