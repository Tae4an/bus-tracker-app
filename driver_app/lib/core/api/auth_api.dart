// 인증 관련 API 호출 클래스
// 로그인, 회원가입, 토큰 갱신 등 인증 관련 API 요청 처리

import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:driver_app/config/app_config.dart';
import 'package:driver_app/core/utils/logger.dart';
import 'package:driver_app/core/api/dio_client.dart';
import 'package:shared/models/auth_response.dart';
import 'package:shared/models/user.dart';

class AuthApi {
  final DioClient _dioClient = DioClient();
  
  // 로그인 API 호출
  Future<AuthResponse> login(String email, String password) async {
  try {
    print('로그인 시도 -- 이메일: $email');

    final response = await _dioClient.dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    print('로그인 응답 데이터: ${response.data}');
    print('응답 상태 코드: ${response.statusCode}');

    try {
      // 응답 데이터의 각 부분을 개별적으로 로깅하며 확인
      final userData = response.data['user'] as Map<String, dynamic>;
      print('유저 데이터 raw: $userData');
      print('유저 데이터 타입: ${userData.runtimeType}');
      print('id: ${userData['id']} (${userData['id'].runtimeType})');
      print('name: ${userData['name']} (${userData['name'].runtimeType})');
      print('email: ${userData['email']} (${userData['email'].runtimeType})');
      print('role: ${userData['role']} (${userData['role'].runtimeType})');

      // User 객체 생성
      final user = User.fromJson(userData);
      print('생성된 User 객체: $user');

      final token = response.data['token'] as String;
      final jwt = token.split('.');
      if (jwt.length > 1) {
        final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(jwt[1])))
        );
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);

        return AuthResponse(
          token: token,
          user: user,
          expiresAt: expiresAt,
        );
      } else {
        return AuthResponse(
          token: token,
          user: user,
          expiresAt: DateTime.now().add(const Duration(minutes: 30)),
        );
      }
    } catch (parseError, stackTrace) {
      print('파싱 오류 상세');
      print('오류 타입: ${parseError.runtimeType}');
      print('오류 메시지: $parseError');
      print('스택 트레이스: $stackTrace');
      throw Exception('응답 데이터 파싱 중 오류가 발생했습니다');
      }
    } on DioException catch (e) {
      print('DioException 발생: ${e.type}');
      print('에러 응답 데이터: ${e.response?.data}');
      print('에러 상태 코드: ${e.response?.statusCode}');

      if (e.response?.statusCode == 401) {
        throw Exception('이메일 또는 비밀번호가 올바르지 않습니다.');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('서버 연결 시간이 초과되었습니다.');
      }
      throw Exception('로그인 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      print('기타 예외 발생: $e');
      throw Exception('로그인 처리 중 예상치 못한 오류가 발생했습니다');
    }
  }
  
  // 로그아웃 API 호출
  Future<void> logout(String token) async {
    try {
      await _dioClient.dio.get(
        '/auth/logout',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      // 로그아웃 오류는 무시하고 진행
      rethrow;
    }
  }
  
  // 토큰 갱신 API 호출
  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _dioClient.dio.post(
        '/auth/refresh-token',
        data: {
          'refreshToken': refreshToken,
        },
      );
      
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('토큰 갱신 중 오류가 발생했습니다');
    }
  }

 // 사용자 정보 조회 API 호출
  Future<User> getUserProfile(String token) async {
    try {
      final response = await _dioClient.dio.get(
        '/auth/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      return User.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('사용자 정보 조회 중 오류가 발생했습니다');
    }
  }
}