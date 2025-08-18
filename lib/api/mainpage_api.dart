import 'package:dio/dio.dart';
import 'api_config.dart';
import 'token_manager.dart';

class MainPageAPI {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: Duration(seconds: ApiConfig.timeoutSeconds),
    receiveTimeout: Duration(seconds: ApiConfig.timeoutSeconds),
    headers: ApiConfig.defaultHeaders,
  ));

  /// 우선순위별 일정 조회
  /// type: 지금_바로_해야해요, 미리_계획해서_준비해요, 시간이_남을_때_해요, 나중에_처리해요
  static Future<List<Map<String, dynamic>>> getSchedulesByType(String type) async {
    try {
      final token = await TokenManager.instance.getAccessToken();
      
      if (token == null) {
        // 비회원은 빈 배열 반환
        return [];
      }
      
      final headers = {
        ...ApiConfig.defaultHeaders,
        'Authorization': 'Bearer $token',
      };

      // URL 인코딩 처리
      final encodedType = Uri.encodeComponent(type);
      final response = await _dio.get(
        '${ApiConfig.mainPageTypeEndpoint}/$encodedType',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to get schedules by type: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // 인증 실패 - 비회원으로 처리
        return [];
      } else if (e.response?.statusCode == 404) {
        // 잘못된 타입
        throw Exception('잘못된 일정 타입입니다');
      }
      // 네트워크 오류 시 빈 배열 반환
      return [];
    } catch (e) {
      print('일정 조회 실패: $e');
      return [];
    }
  }

  /// ScheduleType enum을 API 타입 문자열로 변환
  static String scheduleTypeToApiString(String scheduleType) {
    switch (scheduleType) {
      case 'urgentNow':
        return '지금_바로_해야해요';
      case 'planAhead':
        return '미리_계획해서_준비해요';
      case 'whenFree':
        return '시간이_남을_때_해요';
      case 'laterProcessing':
        return '나중에_처리해요';
      default:
        return '나중에_처리해요';
    }
  }
}