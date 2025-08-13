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

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return TakingModel.fromJson(responseData);
      } else {
        throw Exception('약물 생성 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('약물 생성 중 오류 발생: $e');
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
        return responseData.map((item) => TakingModel.fromJson(item)).toList();
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
      final response = await HttpClient.put(
        '$_baseEndpoint/$medicationId',
        body: {
          'name': name,
          'alarm': alarm,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return TakingModel.fromJson(responseData);
      } else {
        throw Exception('약물 수정 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('약물 수정 중 오류 발생: $e');
    }
  }

  /// 약물 삭제
  static Future<void> deleteMedication(int medicationId) async {
    try {
      final response = await HttpClient.delete('$_baseEndpoint/$medicationId');

      if (response.statusCode != 200) {
        throw Exception('약물 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('약물 삭제 중 오류 발생: $e');
    }
  }
}
