import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api/api_config.dart';
import '../api/token_manager.dart';

class HttpClient {
  static Future<bool> checkNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static Future<bool> checkServerConnection() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/health'),
        headers: ApiConfig.defaultHeaders,
      ).timeout(Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('서버 연결 확인 실패: $e');
      }
      return false;
    }
  }

  static Future<http.Response> get(String endpoint) async {
    return await _handleTokenExpiry(() async {
      final headers = await _getAuthHeaders();
      final url = '${ApiConfig.baseUrl}$endpoint';
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));
      
      return response;
    });
  }

  static Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    return await _handleTokenExpiry(() async {
      final headers = await _getAuthHeaders();
      final url = '${ApiConfig.baseUrl}$endpoint';
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));
      
      return response;
    });
  }

  static Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    return await _handleTokenExpiry(() async {
      final headers = await _getAuthHeaders();
      return await http.put(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));
    });
  }

  static Future<http.Response> patch(String endpoint, {Map<String, dynamic>? body}) async {
    return await _handleTokenExpiry(() async {
      final headers = await _getAuthHeaders();
      return await http.patch(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));
    });
  }

  static Future<http.Response> delete(String endpoint) async {
    return await _handleTokenExpiry(() async {
      final headers = await _getAuthHeaders();
      return await http.delete(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: headers,
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));
    });
  }

  static Future<Map<String, String>> _getAuthHeaders() async {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    final accessToken = await TokenManager.instance.getAccessToken();
    
    if (accessToken != null && TokenManager.instance.isTokenValid(accessToken)) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    
    return headers;
  }

  static Future<http.Response> _handleTokenExpiry(Future<http.Response> Function() request) async {
    try {
      final response = await request();
      
      if (response.statusCode == 401) {
        try {
          await _refreshToken();
          return await request();
        } catch (e) {
          await TokenManager.instance.clearAuthData();
          throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
        }
      }
      
      return response;
    } on SocketException catch (e) {
      throw Exception('네트워크 연결을 확인해주세요: ${e.message}');
    } on TimeoutException catch (e) {
      throw Exception('요청 시간이 초과되었습니다. 다시 시도해주세요.');
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> _refreshToken() async {
    final refreshToken = await TokenManager.instance.getRefreshToken();
    
    if (refreshToken == null || !TokenManager.instance.isTokenValid(refreshToken)) {
      throw Exception('리프레시 토큰이 유효하지 않습니다');
    }
    
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/user/refresh'),
      headers: ApiConfig.defaultHeaders,
      body: jsonEncode({
        'refreshToken': refreshToken,
      }),
    ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      await TokenManager.instance.saveAuthData(
        accessToken: responseData['accessToken'] ?? '',
        refreshToken: responseData['refreshToken'] ?? '',
        username: responseData['username'] ?? '',
      );
    } else {
      throw Exception('토큰 갱신 실패');
    }
  }
} 