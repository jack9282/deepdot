import 'dart:convert';
import '../utils/http_client.dart';

/// 스케줄 등록 요청 모델
class ScheduleCreateRequest {
  final int userId;
  final String title;
  final String memo;
  final String location;
  final bool alarm;
  final String calendarDate; // yyyy-MM-dd
  final String startTime;    // HH:mm:ss
  final String endTime;      // HH:mm:ss
  final String type;
  final String icon;

  ScheduleCreateRequest({
    required this.userId,
    required this.title,
    required this.memo,
    required this.location,
    required this.alarm,
    required this.calendarDate,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.icon,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'memo': memo,
      'location': location,
      'alarm': alarm,
      'calendarDate': calendarDate,
      'startTime': startTime,
      'endTime': endTime,
      'type': type,
      'icon': icon,
    };
  }
}

/// 스케줄 등록 성공 응답 모델
class ScheduleCreateResponse {
  final int scheduleId;
  final String message;

  ScheduleCreateResponse({
    required this.scheduleId,
    required this.message,
  });

  factory ScheduleCreateResponse.fromJson(Map<String, dynamic> json) {
    return ScheduleCreateResponse(
      scheduleId: json['scheduleId'] as int,
      message: json['message'] as String,
    );
  }
}

/// 스케줄 수정 요청 모델
class ScheduleUpdateRequest {
  final int userId;
  final String title;
  final String memo;
  final String location;
  final bool alarm;
  final String calendarDate; // yyyy-MM-dd
  final String startTime;    // HH:mm:ss
  final String endTime;      // HH:mm:ss
  final String type;
  final String icon;

  ScheduleUpdateRequest({
    required this.userId,
    required this.title,
    required this.memo,
    required this.location,
    required this.alarm,
    required this.calendarDate,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.icon,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'memo': memo,
      'location': location,
      'alarm': alarm,
      'calendarDate': calendarDate,
      'startTime': startTime,
      'endTime': endTime,
      'type': type,
      'icon': icon,
    };
  }
}

/// 스케줄 수정 성공 응답 모델
class ScheduleUpdateResponse {
  final String message;

  ScheduleUpdateResponse({
    required this.message,
  });

  factory ScheduleUpdateResponse.fromJson(Map<String, dynamic> json) {
    return ScheduleUpdateResponse(
      message: json['message'] as String,
    );
  }
}

/// 스케줄 삭제 성공 응답 모델
class ScheduleDeleteResponse {
  final String message;

  ScheduleDeleteResponse({
    required this.message,
  });

  factory ScheduleDeleteResponse.fromJson(Map<String, dynamic> json) {
    return ScheduleDeleteResponse(
      message: json['message'] as String,
    );
  }
}

/// 스케줄 단일 조회 응답 모델
class ScheduleDetailResponse {
  final int scheduleId;
  final int userId;
  final String title;
  final String memo;
  final String location;
  final bool alarm;
  final String calendarDate;
  final String startTime;
  final String endTime;
  final String type;
  final String modifiedDate;
  final String timeModified;
  final String icon;

  ScheduleDetailResponse({
    required this.scheduleId,
    required this.userId,
    required this.title,
    required this.memo,
    required this.location,
    required this.alarm,
    required this.calendarDate,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.modifiedDate,
    required this.timeModified,
    required this.icon,
  });

  factory ScheduleDetailResponse.fromJson(Map<String, dynamic> json) {
    return ScheduleDetailResponse(
      scheduleId: json['scheduleId'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
      memo: json['memo'] as String,
      location: json['location'] as String,
      alarm: json['alarm'] as bool,
      calendarDate: json['calendarDate'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      type: json['type'] as String,
      modifiedDate: json['modifiedDate'] as String,
      timeModified: json['timeModified'] as String,
      icon: json['icon'] as String,
    );
  }
}

/// API 에러 응답 모델
class ScheduleApiError {
  final String errorCode;
  final String errorMessage;

  ScheduleApiError({
    required this.errorCode,
    required this.errorMessage,
  });

  factory ScheduleApiError.fromJson(Map<String, dynamic> json) {
    return ScheduleApiError(
      errorCode: json['errorCode'] as String,
      errorMessage: json['errorMessage'] as String,
    );
  }
}

/// 스케줄 API 서비스 클래스
class ScheduleApi {
  static const String _baseEndpoint = '/api/schedule';

  /// 일정 등록 (POST)
  /// POST /api/schedule
  static Future<ScheduleCreateResponse> createSchedule(ScheduleCreateRequest request) async {
    try {
      print('=== 스케줄 등록 API 호출 ===');
      print('Endpoint: $_baseEndpoint');
      print('Request body: ${jsonEncode(request.toJson())}');

      final response = await HttpClient.post(
        _baseEndpoint,
        body: request.toJson(),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ScheduleCreateResponse.fromJson(responseData);
      } else if (response.statusCode >= 400) {
        // 에러 응답 처리
        String errorMessage = '일정 등록 실패: ${response.statusCode}';
        String errorCode = 'UNKNOWN_ERROR';
        
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            if (errorData.containsKey('errorCode') && errorData.containsKey('errorMessage')) {
              final apiError = ScheduleApiError.fromJson(errorData);
              errorCode = apiError.errorCode;
              errorMessage = apiError.errorMessage;
            } else if (errorData.containsKey('message')) {
              errorMessage = errorData['message'] as String;
            }
          } catch (e) {
            errorMessage = '${errorMessage} - ${response.body}';
          }
        }
        
        throw ScheduleApiException(
          statusCode: response.statusCode,
          errorCode: errorCode,
          errorMessage: errorMessage,
        );
      } else {
        throw Exception('예상치 못한 응답 코드: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ScheduleApiException) {
        rethrow;
      }
      print('스케줄 등록 API 오류: $e');
      throw Exception('일정 등록 중 오류 발생: $e');
    }
  }

  /// 특정 일정 조회 (GET)
  /// GET /api/schedule/{schedule_id}
  static Future<ScheduleDetailResponse> getSchedule(int scheduleId) async {
    try {
      print('=== 일정 조회 API 호출 ===');
      print('Endpoint: $_baseEndpoint/$scheduleId');

      final response = await HttpClient.get('$_baseEndpoint/$scheduleId');

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ScheduleDetailResponse.fromJson(responseData);
      } else if (response.statusCode >= 400) {
        // 에러 응답 처리
        String errorMessage = '일정 조회 실패: ${response.statusCode}';
        String errorCode = 'UNKNOWN_ERROR';
        
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            if (errorData.containsKey('errorCode') && errorData.containsKey('errorMessage')) {
              final apiError = ScheduleApiError.fromJson(errorData);
              errorCode = apiError.errorCode;
              errorMessage = apiError.errorMessage;
            }
          } catch (e) {
            errorMessage = '${errorMessage} - ${response.body}';
          }
        }
        
        throw ScheduleApiException(
          statusCode: response.statusCode,
          errorCode: errorCode,
          errorMessage: errorMessage,
        );
      } else {
        throw Exception('예상치 못한 응답 코드: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ScheduleApiException) {
        rethrow;
      }
      print('일정 조회 API 오류: $e');
      throw Exception('일정 조회 중 오류 발생: $e');
    }
  }

  /// 사용자의 모든 일정 조회 (GET)
  /// GET /api/schedule/user/{userId}
  static Future<List<Map<String, dynamic>>> getUserSchedules(int userId) async {
    try {
      final response = await HttpClient.get('$_baseEndpoint/user/$userId');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData.cast<Map<String, dynamic>>();
      } else {
        throw Exception('사용자 일정 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('사용자 일정 목록 조회 중 오류 발생: $e');
    }
  }

  /// 일정 수정 (PATCH)
  /// PATCH /api/schedule/{scheduleId}
  static Future<ScheduleUpdateResponse> updateSchedule(int scheduleId, ScheduleUpdateRequest request) async {
    try {
      print('=== 일정 수정 API 호출 ===');
      print('Endpoint: $_baseEndpoint/$scheduleId');
      print('Request body: ${jsonEncode(request.toJson())}');

      final response = await HttpClient.patch(
        '$_baseEndpoint/$scheduleId',
        body: request.toJson(),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ScheduleUpdateResponse.fromJson(responseData);
      } else if (response.statusCode >= 400) {
        // 에러 응답 처리
        String errorMessage = '일정 수정 실패: ${response.statusCode}';
        String errorCode = 'UNKNOWN_ERROR';
        
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            if (errorData.containsKey('errorCode') && errorData.containsKey('errorMessage')) {
              final apiError = ScheduleApiError.fromJson(errorData);
              errorCode = apiError.errorCode;
              errorMessage = apiError.errorMessage;
            }
          } catch (e) {
            errorMessage = '${errorMessage} - ${response.body}';
          }
        }
        
        throw ScheduleApiException(
          statusCode: response.statusCode,
          errorCode: errorCode,
          errorMessage: errorMessage,
        );
      } else {
        throw Exception('예상치 못한 응답 코드: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ScheduleApiException) {
        rethrow;
      }
      print('일정 수정 API 오류: $e');
      throw Exception('일정 수정 중 오류 발생: $e');
    }
  }

  /// 일정 삭제 (DELETE)
  /// DELETE /api/schedule/{scheduleId}
  static Future<ScheduleDeleteResponse> deleteSchedule(int scheduleId) async {
    try {
      print('=== 일정 삭제 API 호출 ===');
      print('Endpoint: $_baseEndpoint/$scheduleId');

      final response = await HttpClient.delete('$_baseEndpoint/$scheduleId');

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return ScheduleDeleteResponse.fromJson(responseData);
      } else if (response.statusCode >= 400) {
        // 에러 응답 처리
        String errorMessage = '일정 삭제 실패: ${response.statusCode}';
        String errorCode = 'UNKNOWN_ERROR';
        
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            if (errorData.containsKey('errorCode') && errorData.containsKey('errorMessage')) {
              final apiError = ScheduleApiError.fromJson(errorData);
              errorCode = apiError.errorCode;
              errorMessage = apiError.errorMessage;
            }
          } catch (e) {
            errorMessage = '${errorMessage} - ${response.body}';
          }
        }
        
        throw ScheduleApiException(
          statusCode: response.statusCode,
          errorCode: errorCode,
          errorMessage: errorMessage,
        );
      } else {
        throw Exception('예상치 못한 응답 코드: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ScheduleApiException) {
        rethrow;
      }
      print('일정 삭제 API 오류: $e');
      throw Exception('일정 삭제 중 오류 발생: $e');
    }
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
