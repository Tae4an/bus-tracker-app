// 기사 관련 상태 관리 프로바이더
// 운행 정보, 배차된 버스, 운행 상태 등을 관리

import 'package:driver_app/core/api/bus_api.dart';
import 'package:flutter/foundation.dart';
import 'package:shared/models/bus.dart';
import 'package:shared/models/bus_status.dart';
import 'package:shared/models/route.dart' as app_route;

enum DrivingStatus {
  notAssigned,   // 버스 미배정 상태
  readyToDrive,  // 운행 준비 상태 (버스 배정됨)
  driving,       // 운행 중
  paused,        // 운행 일시 중지
  completed      // 운행 완료
}

class DriverProvider with ChangeNotifier {
  // API 클라이언트
  final BusApi _busApi = BusApi();
  
  // 상태 변수
  Bus? _assignedBus;
  app_route.Route? _currentRoute;
  DrivingStatus _drivingStatus = DrivingStatus.notAssigned;
  bool _isLoading = false;
  String? _errorMessage;
  
  // 게터
  Bus? get assignedBus => _assignedBus;
  app_route.Route? get currentRoute => _currentRoute;
  DrivingStatus get drivingStatus => _drivingStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAssigned => _assignedBus != null;
  bool get isActivelyDriving => _drivingStatus == DrivingStatus.driving;
  
  // 배정된 버스 정보 로드
  Future<void> loadAssignedBus(String driverId, String token) async {
    _setLoading(true);
    
    try {
      // 기사에게 배정된 버스 조회
      final bus = await _busApi.getAssignedBus(driverId, token);
      if (bus != null) {
        _assignedBus = bus;
        
        // 버스가 배정되었으면 해당 노선 정보도 로드
        if (bus.routeId.isNotEmpty) {
          await loadRouteInfo(bus.routeId, token);
        }
        
        // 운행 상태 설정
        _updateDrivingStatus();
      } else {
        _drivingStatus = DrivingStatus.notAssigned;
        _assignedBus = null;
        _currentRoute = null;
      }
    } catch (e) {
      _errorMessage = '버스 정보를 불러오는 중 오류가 발생했습니다';
      if (kDebugMode) {
        print('버스 정보 로드 오류: $e');
      }
    } finally {
      _setLoading(false);
    }
  }
  
  // 노선 정보 로드
  Future<void> loadRouteInfo(String routeId, String token) async {
    try {
      final route = await _busApi.getRouteInfo(routeId, token);
      _currentRoute = route;
    } catch (e) {
      _errorMessage = '노선 정보를 불러오는 중 오류가 발생했습니다';
      if (kDebugMode) {
        print('노선 정보 로드 오류: $e');
      }
    }
  }
  
  // 버스 상태 업데이트
  Future<bool> updateBusStatus(String busId, BusStatus status, String token) async {
    _setLoading(true);
    
    try {
      final updatedBus = await _busApi.updateBusStatus(busId, status, token);
      _assignedBus = updatedBus;
      _updateDrivingStatus();
      return true;
    } catch (e) {
      _errorMessage = '버스 상태 업데이트 중 오류가 발생했습니다';
      if (kDebugMode) {
        print('버스 상태 업데이트 오류: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // 운행 시작
  Future<bool> startDriving(String token) async {
    if (_assignedBus == null) return false;
    
    return await updateBusStatus(
      _assignedBus!.id,
      BusStatus.ACTIVE,
      token
    );
  }
  
  // 운행 일시 중지
  Future<bool> pauseDriving(String token) async {
    if (_assignedBus == null) return false;
    
    return await updateBusStatus(
      _assignedBus!.id,
      BusStatus.IDLE,
      token
    );
  }
  
  // 운행 완료
  Future<bool> completeDriving(String token) async {
    if (_assignedBus == null) return false;
    
    final result = await updateBusStatus(
      _assignedBus!.id,
      BusStatus.IDLE,
      token
    );
    
    if (result) {
      _drivingStatus = DrivingStatus.completed;
      notifyListeners();
    }
    
    return result;
  }
  
  // 버스 상태에 따라 운행 상태 업데이트
  void _updateDrivingStatus() {
    if (_assignedBus == null) {
      _drivingStatus = DrivingStatus.notAssigned;
    } else {
      switch (_assignedBus!.status) {
        case BusStatus.ACTIVE:
          _drivingStatus = DrivingStatus.driving;
          break;
        case BusStatus.IDLE:
          _drivingStatus = _drivingStatus == DrivingStatus.driving
              ? DrivingStatus.paused
              : DrivingStatus.readyToDrive;
          break;
        case BusStatus.MAINTENANCE:
        case BusStatus.OUT_OF_SERVICE:
          _drivingStatus = DrivingStatus.notAssigned;
          break;
      }
    }
    notifyListeners();
  }
  
  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = null;
    }
    notifyListeners();
  }
  
  // 오류 메시지 초기화
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}