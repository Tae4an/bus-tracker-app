// 사용자 관련 API 호출 클래스
// 프로필 조회, 수정 등 사용자 관련 API 요청 처리

import 'package:dio/dio.dart';
import 'package:driver_app/core/api/dio_client.dart';
import 'package:driver_app/core/utils/logger.dart';
import 'package:driver_app/data/models/user_model.dart';
import 'package:shared/models/user.dart';

class UserApi {
  final DioClient _dioClient = DioClient();
  
  // 사용자 프로필 조회
  Future<UserModel?> getUserProfile(String token) async {
    try {
      final response = await _dioClient.dio.get(
        '/users/profile',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['success']) {
        final userData = response.data['data'];
        return UserModel.fromJson(userData);
      }
      return null;
    } on DioException catch (e) {
      AppLogger.error('사용자 프로필 조회 오류: ${e.message}');
      return null;
    } catch (e) {
      AppLogger.error('사용자 프로필 조회 중 예상치 못한 오류: $e');
      return null;
    }
  }
  
  // 사용자 프로필 업데이트
  Future<bool> updateUserProfile(UserModel user, String token) async {
    try {
      // 업데이트 가능한 필드만 포함
      final updateData = {
        'name': user.name,
        'phoneNumber': user.phoneNumber,
        'profileImageUrl': user.profileImageUrl,
      };
      
      final response = await _dioClient.dio.put(
        '/users/profile',
        data: updateData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      return response.statusCode == 200 && response.data['success'];
    } on DioException catch (e) {
      AppLogger.error('프로필 업데이트 오류: ${e.message}');
      return false;
    } catch (e) {
      AppLogger.error('프로필 업데이트 중 예상치 못한 오류: $e');
      return false;
    }
  }
  
  // 비밀번호 변경
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String token,
  }) async {
    try {
      final response = await _dioClient.dio.put(
        '/users/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      return response.statusCode == 200 && response.data['success'];
    } on DioException catch (e) {
      AppLogger.error('비밀번호 변경 오류: ${e.message}');
      return false;
    } catch (e) {
      AppLogger.error('비밀번호 변경 중 예상치 못한 오류: $e');
      return false;
    }
  }
  
  // 즐겨찾기 업데이트
  Future<bool> updateFavorites({
    required List<String> favoriteRoutes,
    required List<String> favoriteStops,
    required String token,
  }) async {
    try {
      final response = await _dioClient.dio.put(
        '/users/favorites',
        data: {
          'favoriteRoutes': favoriteRoutes,
          'favoriteStops': favoriteStops,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      return response.statusCode == 200 && response.data['success'];
    } on DioException catch (e) {
      AppLogger.error('즐겨찾기 업데이트 오류: ${e.message}');
      return false;
    } catch (e) {
      AppLogger.error('즐겨찾기 업데이트 중 예상치 못한 오류: $e');
      return false;
    }
  }
}