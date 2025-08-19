import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'token_manager.dart';

class RoutineApi {
  static const String baseUrl = ApiConfig.baseUrl;

  // 루틴 생성
  static Future<Map<String, dynamic>> createRoutine({
    required String name,
    required int goalId,
    required bool mon,
    required bool tue,
    required bool wed,
    required bool thu,
    required bool fri,
    required bool sat,
    required bool sun,
    required bool active,
    String? memo,
    required Map<String, int> startTime,
  }) async {
    final token = await TokenManager.instance.getAccessToken();
    
    if (!mon && !tue && !wed && !thu && !fri && !sat && !sun) {
      throw Exception('최소 하나의 요일을 선택해야 합니다.');
    }
    
    final requestBody = {
      'name': name.trim(),
      'goalId': goalId,
      'mon': mon,
      'tue': tue,
      'wed': wed,
      'thu': thu,
      'fri': fri,
      'sat': sat,
      'sun': sun,
      'active': active,
      'memo': memo?.trim() ?? '',
      'start_time': '${(startTime['hour'] ?? 8).toString().padLeft(2, '0')}:${(startTime['minute'] ?? 0).toString().padLeft(2, '0')}',
    };
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/routine'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : '응답 본문 없음';
        
        if (response.statusCode == 401) {
          final refreshSuccess = await TokenManager.instance.refreshToken();
          if (refreshSuccess) {
            final newToken = await TokenManager.instance.getAccessToken();
            final retryResponse = await http.post(
              Uri.parse('$baseUrl/api/routine'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                if (newToken != null) 'Authorization': 'Bearer $newToken',
              },
              body: jsonEncode(requestBody),
            );
            
            if (retryResponse.statusCode == 200) {
              return jsonDecode(retryResponse.body);
            }
          } else {
            throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
          }
        }
        
        if (response.statusCode == 400) {
          try {
            final errorJson = jsonDecode(errorBody);
            if (errorJson['message'] != null) {
              // 서버 오류 메시지 존재 시 사용할 수 있음
            }
          } catch (_) {}
        }
        
        if (response.statusCode == 500) {
          // 서버 내부 오류 케이스
        }
        
        throw Exception('루틴 생성 실패: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('네트워크 오류: $e');
      }
    }
  }

  // 목표 목록 조회
  static Future<Map<String, dynamic>> getGoals() async {
    final token = await TokenManager.instance.getAccessToken();
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/routine/goals'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : '응답 본문 없음';
        throw Exception('목표 목록 조회 실패: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('네트워크 오류: $e');
      }
    }
  }

  // 목표 생성
  static Future<Map<String, dynamic>> createGoal({
    required String name,
  }) async {
    final token = await TokenManager.instance.getAccessToken();
    
    final requestBody = {
      'name': name.trim(),
    };
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/routine/goals'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : '응답 본문 없음';
        throw Exception('목표 생성 실패: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('네트워크 오류: $e');
      }
    }
  }

  // 루틴 삭제
  static Future<void> deleteRoutine({
    required int routineId,
  }) async {
    final token = await TokenManager.instance.getAccessToken();
    
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/routine/$routineId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorBody = response.body.isNotEmpty ? response.body : '응답 본문 없음';
        throw Exception('루틴 삭제 실패: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 루틴 수정
  static Future<Map<String, dynamic>> updateRoutine({
    required int routineId,
    required String name,
    required int goalId,
    required bool mon,
    required bool tue,
    required bool wed,
    required bool thu,
    required bool fri,
    required bool sat,
    required bool sun,
    required bool active,
    String? memo,
    required Map<String, int> startTime,
  }) async {
    final token = await TokenManager.instance.getAccessToken();
    
    final requestBody = {
      'name': name.trim(),
      'goalId': goalId,
      'mon': mon,
      'tue': tue,
      'wed': wed,
      'thu': thu,
      'fri': fri,
      'sat': sat,
      'sun': sun,
      'active': active,
      'memo': memo?.trim() ?? '',
      'start_time': '${(startTime['hour'] ?? 8).toString().padLeft(2, '0')}:${(startTime['minute'] ?? 0).toString().padLeft(2, '0')}',
    };
    
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/routine/$routineId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : '응답 본문 없음';
        throw Exception('루틴 수정 실패: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('네트워크 오류: $e');
      }
    }
  }

  // 목표 삭제
  static Future<void> deleteGoal({
    required int goalId,
  }) async {
    final token = await TokenManager.instance.getAccessToken();
    
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/routine/goals/$goalId'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return;
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : '응답 본문 없음';
        
        if (response.statusCode == 401) {
          final refreshSuccess = await TokenManager.instance.refreshToken();
          if (refreshSuccess) {
            final newToken = await TokenManager.instance.getAccessToken();
            final retryResponse = await http.delete(
              Uri.parse('$baseUrl/api/routine/goals/$goalId'),
              headers: {
                'Accept': 'application/json',
                if (newToken != null) 'Authorization': 'Bearer $newToken',
              },
            );
            
            if (retryResponse.statusCode == 200) {
              return;
            }
          } else {
            throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
          }
        }
        
        if (response.statusCode == 400) {
          try {
            final errorJson = jsonDecode(errorBody);
            if (errorJson['message'] != null) {
              // 서버 오류 메시지 존재 시 사용할 수 있음
            }
          } catch (_) {}
        }
        
        if (response.statusCode == 404) {
          // 리소스 없음 케이스
        }
        
        throw Exception('목표 삭제 실패: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('네트워크 오류: $e');
      }
    }
  }

  // 목표 수정
  static Future<Map<String, dynamic>> updateGoal({
    required int goalId,
    required String name,
  }) async {
    final token = await TokenManager.instance.getAccessToken();
    
    final requestBody = {
      'name': name.trim(),
    };
    
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/routine/goals/$goalId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : '응답 본문 없음';
        
        if (response.statusCode == 401) {
          final refreshSuccess = await TokenManager.instance.refreshToken();
          if (refreshSuccess) {
            final newToken = await TokenManager.instance.getAccessToken();
            final retryResponse = await http.patch(
              Uri.parse('$baseUrl/api/routine/goals/$goalId'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                if (newToken != null) 'Authorization': 'Bearer $newToken',
              },
              body: jsonEncode(requestBody),
            );
            
            if (retryResponse.statusCode == 200) {
              return jsonDecode(retryResponse.body);
            }
          } else {
            throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
          }
        }
        
        if (response.statusCode == 400) {
          try {
            final errorJson = jsonDecode(errorBody);
            if (errorJson['message'] != null) {
              // 서버 오류 메시지 존재 시 사용할 수 있음
            }
          } catch (_) {}
        }
        
        throw Exception('목표 수정 실패: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('네트워크 오류: $e');
      }
    }
  }

  // 특정 목표의 루틴 목록 조회
  static Future<Map<String, dynamic>> getRoutinesByGoal({
    required int goalId,
  }) async {
    final token = await TokenManager.instance.getAccessToken();
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/routine/goals/$goalId/routines'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : '응답 본문 없음';
        
        if (response.statusCode == 401) {
          final refreshSuccess = await TokenManager.instance.refreshToken();
          if (refreshSuccess) {
            final newToken = await TokenManager.instance.getAccessToken();
            final retryResponse = await http.get(
              Uri.parse('$baseUrl/api/routine/goals/$goalId/routines'),
              headers: {
                'Authorization': 'Bearer $newToken',
              },
            );
            
            if (retryResponse.statusCode == 200) {
              return jsonDecode(retryResponse.body);
            }
          } else {
            throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
          }
        }
        
        throw Exception('루틴 목록 조회 실패: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      rethrow;
    }
  }
}
