import 'dart:convert';
import '../utils/http_client.dart';
import '../data/models/taking_model.dart';

class TakingApi {
  static const String _baseEndpoint = '/api/medication';

  static void _handleHttpError(int statusCode, String operation) {
    switch (statusCode) {
      case 400:
        throw Exception('잘못된 요청입니다. 입력값을 확인해주세요.');
      case 401:
        throw Exception('인증이 필요합니다');
      case 403:
        throw Exception('권한이 없습니다');
      case 404:
        throw Exception('데이터를 찾을 수 없습니다');
      case 409:
        throw Exception('이미 존재하거나 최대 개수를 초과했습니다');
      case 500:
        throw Exception('서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
      default:
        throw Exception('$operation 실패: $statusCode');
    }
  }

  /// 약물 생성
  static Future<TakingModel> createMedication({
    required String name,
    required bool alarm,
  }) async {
    try {
      final response = await HttpClient.post(
        _baseEndpoint,
        body: {
          'name': name,
          'alarm': alarm,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        if (responseData is int) {
          return TakingModel(
            id: responseData.toString(),
            name: name,
            times: [],
            timeIds: [],
            alarmEnabled: alarm,
            alarmTime: '08:00',
            createdAt: DateTime.now(),
          );
        } else if (responseData is Map<String, dynamic>) {
          return TakingModel.fromJson(responseData);
        } else {
          throw Exception('예상치 못한 응답 형식');
        }
      } else {
        _handleHttpError(response.statusCode, '약물 생성');
      }
    } catch (e) {
      throw Exception('약물 생성 중 오류 발생: $e');
    }
    throw Exception('약물 생성 실패');
  }

  /// 복용 시간 추가
  static Future<int?> addMedicationTime(int medicationId, String time) async {
    try {
      // 시간 형식 정규화
      String normalizedTime = time;
      if (time.contains(':')) {
        final parts = time.split(':');
        if (parts.length >= 2) {
          final hour = parts[0].padLeft(2, '0');
          final minute = parts[1].padLeft(2, '0');
          normalizedTime = '$hour:$minute';
        }
      }
      
      final response = await HttpClient.post(
        '$_baseEndpoint/$medicationId/times',
        body: {'time': normalizedTime},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isNotEmpty) {
          try {
            final responseData = jsonDecode(response.body);
            if (responseData is Map<String, dynamic> && responseData.containsKey('timeId')) {
              return responseData['timeId'] as int?;
            } else if (responseData is int) {
              return responseData;
            }
          } catch (e) {
            // 파싱 실패 시 null 반환
          }
        }
        return null;
      } else if (response.statusCode == 500) {
        // 서버 오류 시 HH:mm:ss 형식으로 재시도
        final parts = normalizedTime.split(':');
        if (parts.length == 2) {
          final retryTime = '${parts[0]}:${parts[1]}:00';
          final retryResponse = await HttpClient.post(
            '$_baseEndpoint/$medicationId/times',
            body: {'time': retryTime},
          );
          
          if (retryResponse.statusCode == 200 || retryResponse.statusCode == 201) {
            return null;
          }
        }
        _handleHttpError(response.statusCode, '복용 시간 추가');
      } else {
        _handleHttpError(response.statusCode, '복용 시간 추가');
      }
    } catch (e) {
      throw Exception('복용 시간 추가 중 오류 발생: $e');
    }
    throw Exception('복용 시간 추가 실패');
  }

  /// 복용 시간 수정
  static Future<void> updateMedicationTime({
    required int medicationId,
    required int timeId,
    required String time,
  }) async {
    try {
      final String normalizedTime = time.length == 5 ? '$time:00' : time;

      final primaryResponse = await HttpClient.patch(
        '$_baseEndpoint/$medicationId/times/$timeId',
        body: {'time': normalizedTime},
      );

      if (primaryResponse.statusCode == 200 || primaryResponse.statusCode == 204) {
        return;
      }

      // 404/405 시 대체 경로 시도
      if (primaryResponse.statusCode == 404 || primaryResponse.statusCode == 405) {
        final fallbackResponse = await HttpClient.patch(
          '$_baseEndpoint/$medicationId/times',
          body: {
            'timeId': timeId,
            'time': normalizedTime,
          },
        );

        if (fallbackResponse.statusCode == 200 || fallbackResponse.statusCode == 204) {
          return;
        } else {
          _handleHttpError(fallbackResponse.statusCode, '복용 시간 수정');
        }
      } else {
        _handleHttpError(primaryResponse.statusCode, '복용 시간 수정');
      }
    } catch (e) {
      throw Exception('복용 시간 수정 중 오류 발생: $e');
    }
  }

  /// 복용 시간 전체 삭제
  static Future<void> deleteAllMedicationTimes(int medicationId) async {
    try {
      final response = await HttpClient.delete('$_baseEndpoint/$medicationId/times');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else {
        _handleHttpError(response.statusCode, '복용 시간 전체 삭제');
      }
    } catch (e) {
      throw Exception('복용 시간 전체 삭제 중 오류 발생: $e');
    }
  }

  /// 복용 시간 삭제
  static Future<void> deleteMedicationTime(int timeId) async {
    try {
      final response = await HttpClient.delete('$_baseEndpoint/times/$timeId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else {
        _handleHttpError(response.statusCode, '복용 시간 삭제');
      }
    } catch (e) {
      throw Exception('복용 시간 삭제 중 오류 발생: $e');
    }
  }

  /// 특정 약물 조회
  static Future<TakingModel> getMedication(int medicationId) async {
    try {
      final response = await HttpClient.get('$_baseEndpoint/$medicationId');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return TakingModel.fromJson(responseData);
      } else {
        _handleHttpError(response.statusCode, '약물 조회');
      }
    } catch (e) {
      throw Exception('약물 조회 중 오류 발생: $e');
    }
    throw Exception('약물 조회 실패');
  }

  /// 모든 약물 조회
  static Future<List<TakingModel>> getAllMedications() async {
    try {
      final response = await HttpClient.get('$_baseEndpoint/all');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        
        final List<TakingModel> medications = [];
        for (int i = 0; i < responseData.length; i++) {
          try {
            final medication = TakingModel.fromJson(responseData[i]);
            medications.add(medication);
          } catch (itemError) {
            // 개별 항목 실패 시 건너뛰기
            continue;
          }
        }
        return medications;
      } else {
        _handleHttpError(response.statusCode, '약물 목록 조회');
      }
    } catch (e) {
      throw Exception('약물 목록 조회 중 오류 발생: $e');
    }
    throw Exception('약물 목록 조회 실패');
  }

  /// 약물 수정
  static Future<TakingModel> updateMedication({
    required int medicationId,
    required String name,
    required bool alarm,
  }) async {
    try {
      final response = await HttpClient.patch(
        '$_baseEndpoint/$medicationId',
        body: {
          'name': name,
          'alarm': alarm,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 응답 파싱 시도
        if (response.body.isNotEmpty) {
          final responseData = jsonDecode(response.body);
          
          if (responseData is int) {
            return TakingModel(
              id: responseData.toString(),
              name: name,
              times: [],
              timeIds: [],
              alarmEnabled: alarm,
              alarmTime: '08:00',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          } else if (responseData is Map<String, dynamic>) {
            return TakingModel.fromJson(responseData);
          }
        }
        
        // 기본 모델 반환
        return TakingModel(
          id: medicationId.toString(),
          name: name,
          times: [],
          timeIds: [],
          alarmEnabled: alarm,
          alarmTime: '08:00',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        _handleHttpError(response.statusCode, '약물 수정');
      }
    } catch (e) {
      throw Exception('약물 수정 중 오류 발생: $e');
    }
    throw Exception('약물 수정 실패');
  }

  /// 약물 삭제
  static Future<void> deleteMedication(int medicationId) async {
    try {
      final response = await HttpClient.delete('$_baseEndpoint/$medicationId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else {
        _handleHttpError(response.statusCode, '약물 삭제');
      }
    } catch (e) {
      throw Exception('약물 삭제 중 오류 발생: $e');
    }
  }
}
