import 'dart:convert';
import '../utils/http_client.dart';
import '../data/models/taking_model.dart';

class TakingApi {
  static const String _baseEndpoint = '/api/medication';

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

      print('약물 생성 응답: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // API 응답이 정수 ID만 반환하는 경우 처리
        final responseData = jsonDecode(response.body);
        TakingModel takingModel;
        
        if (responseData is int) {
          // ID만 반환되는 경우 (201 응답)
          takingModel = TakingModel(
            id: responseData.toString(),
            name: name,
            times: [], // 빈 배열로 시작 (나중에 시간 추가)
            timeIds: [], // 빈 배열
            alarmEnabled: alarm,
            alarmTime: '08:00', // 기본값
            createdAt: DateTime.now(),
          );
        } else if (responseData is Map<String, dynamic>) {
          // 전체 객체가 반환되는 경우 (200 응답)
          takingModel = TakingModel.fromJson(responseData);
        } else {
          throw Exception('예상치 못한 응답 형식: $responseData');
        }
        
        return takingModel;
      } else if (response.statusCode == 400) {
        throw Exception('잘못된 요청입니다. 입력값을 확인해주세요.');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다');
      } else if (response.statusCode == 409) {
        throw Exception('이미 존재하는 약물명입니다');
      } else if (response.statusCode == 500) {
        throw Exception('서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
      } else {
        throw Exception('약물 생성 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('약물 생성 중 상세 오류: $e');
      throw Exception('약물 생성 중 오류 발생: $e');
    }
  }

  /// 복용 시간 추가
  /// URL: /api/medication/{medicationId}/times
  /// 설명: 복용약 시간 등록. 최대 3개까지 가능. 성공 시 timeId 반환.
  static Future<int?> addMedicationTime(int medicationId, String time) async {
    try {
      // 먼저 현재 약물의 시간 개수 확인
      try {
        final medicationResponse = await HttpClient.get('$_baseEndpoint/$medicationId');
        if (medicationResponse.statusCode == 200) {
          final medicationData = jsonDecode(medicationResponse.body);
          final times = medicationData['times'] as List<dynamic>?;
          if (times != null && times.length >= 3) {
            print('복용 시간 추가 실패: 이미 최대 3개의 시간이 존재합니다 (현재: ${times.length}개)');
            throw Exception('최대 3개까지 등록 가능합니다.');
          }
        }
      } catch (e) {
        print('약물 상태 확인 실패, 계속 진행: $e');
      }

      // 시간 형식 정규화: 다양한 형식 지원
      String normalizedTime;
      if (time.contains(':')) {
        final parts = time.split(':');
        if (parts.length >= 2) {
          final hour = parts[0].padLeft(2, '0');
          final minute = parts[1].padLeft(2, '0');
          // 서버에서 HH:mm 형식을 선호하는지 확인
          normalizedTime = '$hour:$minute';
        } else {
          normalizedTime = time;
        }
      } else {
        normalizedTime = time;
      }
      
      print('복용 시간 추가 시도: medicationId=$medicationId, 원본시간=$time, 정규화시간=$normalizedTime');
      
      final response = await HttpClient.post(
        '$_baseEndpoint/$medicationId/times',
        body: {
          'time': normalizedTime,
        },
      );

      print('복용 시간 추가 응답: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('복용 시간 추가 성공: ID = $medicationId, 시간 = $time');
        
        // 응답 본문에서 timeId 추출 시도
        if (response.body.isNotEmpty) {
          try {
            final responseData = jsonDecode(response.body);
            if (responseData is Map<String, dynamic> && responseData.containsKey('timeId')) {
              return responseData['timeId'] as int?;
            } else if (responseData is int) {
              return responseData;
            }
          } catch (e) {
            print('응답 본문 파싱 실패: $e');
          }
        }
        return null; // timeId를 추출할 수 없는 경우
      } else if (response.statusCode == 400) {
        throw Exception('잘못된 시간 형식입니다.');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다');
      } else if (response.statusCode == 404) {
        throw Exception('약물을 찾을 수 없습니다 (ID: $medicationId)');
      } else if (response.statusCode == 409) {
        throw Exception('최대 3개까지 등록 가능합니다.');
      } else if (response.statusCode == 500) {
        // 서버 오류 시 더 자세한 정보 출력
        print('서버 오류 발생 - 상세 정보:');
        print('  - medicationId: $medicationId');
        print('  - 요청 시간: $normalizedTime');
        print('  - 응답 본문: ${response.body}');
        
        // 500 에러가 최대 개수 초과로 인한 것인지 확인
        try {
          final medicationResponse = await HttpClient.get('$_baseEndpoint/$medicationId');
          if (medicationResponse.statusCode == 200) {
            final medicationData = jsonDecode(medicationResponse.body);
            final times = medicationData['times'] as List<dynamic>?;
            if (times != null && times.length >= 3) {
              print('500 에러 원인: 이미 최대 3개의 시간이 존재합니다 (현재: ${times.length}개)');
              throw Exception('최대 3개까지 등록 가능합니다.');
            }
          }
        } catch (e) {
          if (e.toString().contains('최대 3개까지')) {
            rethrow; // 409 에러로 재던지기
          }
        }
        
        // 서버 오류 시 다른 시간 형식으로 재시도
        print('서버 오류 발생, 다른 시간 형식으로 재시도...');
        
        // HH:mm:ss 형식으로 재시도
        if (!normalizedTime.contains(':')) {
          throw Exception('서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
        }
        
        final parts = normalizedTime.split(':');
        if (parts.length == 2) {
          final retryTime = '${parts[0]}:${parts[1]}:00';
          print('재시도: $retryTime 형식으로 시도');
          
          final retryResponse = await HttpClient.post(
            '$_baseEndpoint/$medicationId/times',
            body: {
              'time': retryTime,
            },
          );
          
          print('복용 시간 추가 재시도 응답: ${retryResponse.statusCode} - ${retryResponse.body}');
          
          if (retryResponse.statusCode == 200 || retryResponse.statusCode == 201) {
            print('복용 시간 추가 재시도 성공: ID = $medicationId, 시간 = $retryTime');
            return null; // 성공했지만 timeId는 추출하지 못함
          }
        }
        
        // 약물 상태 확인 시도
        try {
          print('약물 상태 확인 시도...');
          final medicationResponse = await HttpClient.get('$_baseEndpoint/$medicationId');
          print('약물 상태 확인 응답: ${medicationResponse.statusCode} - ${medicationResponse.body}');
        } catch (e) {
          print('약물 상태 확인 실패: $e');
        }
        
        throw Exception('서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
      } else {
        throw Exception('복용 시간 추가 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('복용 시간 추가 중 상세 오류: $e');
      throw Exception('복용 시간 추가 중 오류 발생: $e');
    }
  }

  /// 복용 시간 수정
  /// URL: /api/medication/{medicationId}/times (기본), 성공 시 204
  /// 설명: timeId로 특정 복용 시간을 수정합니다. 서버 구현에 따라 /times/{timeId} 또는 /times + body.timeId 형태를 모두 시도합니다.
  static Future<void> updateMedicationTime({
    required int medicationId,
    required int timeId,
    required String time,
  }) async {
    try {
      // 서버 스펙: "09:00:00" 형식 요구 → HH:mm이면 초를 보강
      final String normalizedTime = time.length == 5 ? '$time:00' : time;

      // 1차 시도: /times/{timeId}
      final primaryResponse = await HttpClient.patch(
        '$_baseEndpoint/$medicationId/times/$timeId',
        body: {
          'time': normalizedTime,
        },
      );

      print('복용 시간 수정 응답: ${primaryResponse.statusCode} - ${primaryResponse.body}');

      if (primaryResponse.statusCode == 200 || primaryResponse.statusCode == 204) {
        return;
      }

      // 404/405 등 경로 미지원 시 대체 경로 시도: /times + body에 timeId 포함
      if (primaryResponse.statusCode == 404 || primaryResponse.statusCode == 405) {
        final fallbackResponse = await HttpClient.patch(
          '$_baseEndpoint/$medicationId/times',
          body: {
            'timeId': timeId,
            'time': normalizedTime,
          },
        );

        print('복용 시간 수정(대체 경로) 응답: ${fallbackResponse.statusCode} - ${fallbackResponse.body}');

        if (fallbackResponse.statusCode == 200 || fallbackResponse.statusCode == 204) {
          return;
        } else if (fallbackResponse.statusCode == 400) {
          throw Exception('잘못된 시간 형식입니다. 예: 09:00:00');
        } else if (fallbackResponse.statusCode == 401) {
          throw Exception('인증이 필요합니다');
        } else if (fallbackResponse.statusCode == 403) {
          throw Exception('수정 권한이 없습니다');
        } else if (fallbackResponse.statusCode == 404) {
          throw Exception('약물 또는 시간 항목을 찾을 수 없습니다 (ID: $medicationId, timeId: $timeId)');
        } else if (fallbackResponse.statusCode == 500) {
          throw Exception('서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
        } else {
          throw Exception('복용 시간 수정 실패: ${fallbackResponse.statusCode}');
        }
      } else if (primaryResponse.statusCode == 400) {
        throw Exception('잘못된 시간 형식입니다. 예: 09:00:00');
      } else if (primaryResponse.statusCode == 401) {
        throw Exception('인증이 필요합니다');
      } else if (primaryResponse.statusCode == 403) {
        throw Exception('수정 권한이 없습니다');
      } else if (primaryResponse.statusCode == 500) {
        throw Exception('서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
      } else {
        throw Exception('복용 시간 수정 실패: ${primaryResponse.statusCode}');
      }
    } catch (e) {
      print('복용 시간 수정 중 상세 오류: $e');
      throw Exception('복용 시간 수정 중 오류 발생: $e');
    }
  }

  /// 복용 시간 전체 삭제
  /// URL: /api/medication/{medicationId}/times
  /// 설명: 복용약 시간 전체 삭제. 성공 시 204 반환.
  static Future<void> deleteAllMedicationTimes(int medicationId) async {
    try {
      print('약물의 모든 복용 시간 삭제 시도: medicationId=$medicationId');
      
      final response = await HttpClient.delete('$_baseEndpoint/$medicationId/times');

      print('복용 시간 전체 삭제 응답: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('복용 시간 전체 삭제 성공: medicationId=$medicationId');
        return;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다');
      } else if (response.statusCode == 403) {
        throw Exception('삭제 권한이 없습니다');
      } else if (response.statusCode == 404) {
        throw Exception('약물을 찾을 수 없습니다 (ID: $medicationId)');
      } else if (response.statusCode == 500) {
        throw Exception('서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
      } else {
        throw Exception('복용 시간 전체 삭제 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('복용 시간 전체 삭제 중 상세 오류: $e');
      throw Exception('복용 시간 전체 삭제 중 오류 발생: $e');
    }
  }

  /// 복용 시간 삭제
  /// URL: /api/medication/times/{timeId}
  /// 설명: timeId로 특정 복용 시간을 삭제합니다. 성공 시 204 반환.
  static Future<void> deleteMedicationTime(int timeId) async {
    try {
      print('복용 시간 삭제 시도: timeId=$timeId, URL: $_baseEndpoint/times/$timeId');
      
      final response = await HttpClient.delete('$_baseEndpoint/times/$timeId');

      print('복용 시간 삭제 응답: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('복용 시간 삭제 성공: timeId=$timeId');
        return;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다');
      } else if (response.statusCode == 403) {
        throw Exception('삭제 권한이 없습니다');
      } else if (response.statusCode == 404) {
        throw Exception('시간 항목을 찾을 수 없습니다 (timeId: $timeId)');
      } else if (response.statusCode == 500) {
        throw Exception('서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
      } else {
        throw Exception('복용 시간 삭제 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('복용 시간 삭제 중 상세 오류: $e');
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
        throw Exception('약물 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('약물 조회 중 오류 발생: $e');
    }
  }

  /// 모든 약물 조회
  static Future<List<TakingModel>> getAllMedications() async {
    try {
      final response = await HttpClient.get('$_baseEndpoint/all');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        print('API 응답 데이터: $responseData');
        
        final List<TakingModel> medications = [];
        for (int i = 0; i < responseData.length; i++) {
          try {
            final medication = TakingModel.fromJson(responseData[i]);
            medications.add(medication);
          } catch (itemError) {
            print('약물 데이터 파싱 실패 (인덱스 $i): $itemError');
            print('문제가 된 데이터: ${responseData[i]}');
            // 개별 항목 실패 시 건너뛰기
            continue;
          }
        }
        return medications;
      } else {
        throw Exception('약물 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('약물 목록 조회 중 오류 발생: $e');
    }
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

      print('약물 수정 응답: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 204 응답 시 body가 비어있으므로 로컬 데이터로 모델 생성
        if (response.statusCode == 204) {
          return TakingModel(
            id: medicationId.toString(),
            name: name,
            times: [], // API에서 times를 반환하지 않으므로 빈 배열
            timeIds: [], // 빈 배열
            alarmEnabled: alarm,
            alarmTime: '08:00', // 기본값
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
        
        // 200 응답 시 body 파싱 시도
        if (response.body.isNotEmpty) {
          final responseData = jsonDecode(response.body);
          TakingModel takingModel;
          
          if (responseData is int) {
            // ID만 반환되는 경우
            takingModel = TakingModel(
              id: responseData.toString(),
              name: name,
              times: [], // 빈 배열로 시작 (나중에 시간 추가)
              timeIds: [], // 빈 배열
              alarmEnabled: alarm,
              alarmTime: '08:00', // 기본값
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          } else if (responseData is Map<String, dynamic>) {
            // 전체 객체가 반환되는 경우
            takingModel = TakingModel.fromJson(responseData);
          } else {
            throw Exception('예상치 못한 응답 형식: $responseData');
          }
          
          return takingModel;
        } else {
          // 200이지만 body가 비어있는 경우
          return TakingModel(
            id: medicationId.toString(),
            name: name,
            times: [], // API에서 times를 반환하지 않으므로 빈 배열
            timeIds: [], // 빈 배열
            alarmEnabled: alarm,
            alarmTime: '08:00', // 기본값
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      } else if (response.statusCode == 400) {
        throw Exception('잘못된 요청입니다. 입력값을 확인해주세요.');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다');
      } else if (response.statusCode == 404) {
        throw Exception('약물을 찾을 수 없습니다 (ID: $medicationId)');
      } else if (response.statusCode == 409) {
        throw Exception('이미 존재하는 약물명입니다');
      } else if (response.statusCode == 500) {
        throw Exception('서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
      } else {
        throw Exception('약물 수정 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('약물 수정 중 상세 오류: $e');
      throw Exception('약물 수정 중 오류 발생: $e');
    }
  }

  /// 약물 삭제
  static Future<void> deleteMedication(int medicationId) async {
    try {
      print('약물 삭제 시도: ID = $medicationId');
      final response = await HttpClient.delete('$_baseEndpoint/$medicationId');

      print('약물 삭제 응답: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('약물 삭제 성공: ID = $medicationId');
      } else if (response.statusCode == 404) {
        throw Exception('약물을 찾을 수 없습니다 (ID: $medicationId)');
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다');
      } else if (response.statusCode == 403) {
        throw Exception('삭제 권한이 없습니다');
      } else if (response.statusCode == 500) {
        throw Exception('서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
      } else {
        throw Exception('약물 삭제 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('약물 삭제 중 상세 오류: $e');
      throw Exception('약물 삭제 중 오류 발생: $e');
    }
  }
}
