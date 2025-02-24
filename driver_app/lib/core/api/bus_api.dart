// 버스 관련 API 호출 클래스
// 버스 정보 조회, 상태 업데이트 등 버스 관련 API 요청 처리

import 'package:dio/dio.dart';
import 'package:driver_app/core/api/dio_client.dart';
import 'package:shared/models/bus.dart';
import 'package:shared/models/bus_status.dart';
import 'package:shared/models/route.dart' as app_route;

class BusApi {
  final DioClient _dioClient = DioClient();
  
  // 기사에게 배정된 버스 조회
  Future<Bus?> getAssignedBus(String driverId, String token) async {
    try {
      final response = await _dioClient.dio.get(
        '/buses/assigned/driver',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      if (response.data['success'] && response.data['data'] != null) {
        // 중첩된 routeId 객체 처리
        final data = Map<String, dynamic>.from(response.data['data']);
        if (data['routeId'] is Map) {
          // routeId가 객체인 경우 id 값만 추출
          data['routeId'] = data['routeId']['id'];
        }
        return Bus.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting assigned bus: $e');
      return null;
    }
  }
  
  // 버스 상태 업데이트
  Future<Bus> updateBusStatus(String busId, BusStatus status, String token) async {
    try {
      final response = await _dioClient.dio.patch(
        '/buses/$busId/status',
        data: {'status': status.toString().split('.').last},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      print('Server response success: ${response.data}');
      return Bus.fromJson(response.data['data']);
    } on DioException catch (e) {
      // 서버 에러 메시지가 있다면 그대로 사용
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      throw Exception('버스 상태 업데이트 중 오류가 발생했습니다');
    }
  }
  
  // 노선 정보 조회
  Future<app_route.Route> getRouteInfo(String routeId, String token) async {
    try {
      final response = await _dioClient.dio.get(
        '/routes/$routeId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      return app_route.Route.fromJson(response.data);
    } catch (e) {
      throw Exception('노선 정보 조회 중 오류가 발생했습니다: ${e.toString()}');
    }
  }
  
  // 특정 버스 정보 조회
  Future<Bus> getBusInfo(String busId, String token) async {
    try {
      final response = await _dioClient.dio.get(
        '/buses/$busId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      return Bus.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('버스 정보 조회 중 오류가 발생했습니다');
    }
  }
}