// 위치 추적 서비스
// 실시간 위치 추적 및 백그라운드 작업 관리

import 'dart:async';
import 'dart:convert';
import 'package:driver_app/config/app_config.dart';
import 'package:driver_app/core/socket/socket_service.dart';
import 'package:driver_app/core/utils/logger.dart';
import 'package:driver_app/data/local/location_database.dart';
import 'package:driver_app/data/models/location_data.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  // 소켓 서비스
  final SocketService _socketService = SocketService();
  
  // 위치 데이터베이스
  final LocationDatabase _locationDb = LocationDatabase();
  
  // 위치 스트림 구독
  StreamSubscription<Position>? _positionStreamSubscription;
  
  // 상태 변수
  bool _isTracking = false;
  String? _currentBusId;
  Timer? _offlineSync;
  
  // 게터
  bool get isTracking => _isTracking;
  
  // 위치 권한 요청
  Future<bool> requestLocationPermission() async {
    // 위치 권한 확인 및 요청
    final status = await Permission.location.request();
    
    if (status.isGranted) {
      // 백그라운드 위치 권한이 필요한 경우
      final backgroundStatus = await Permission.locationAlways.request();
      return backgroundStatus.isGranted;
    }
    
    return status.isGranted;
  }
  
  // 위치 추적 시작
  Future<bool> startTracking(String busId, String token) async {
    // 이미 추적 중인 경우
    if (_isTracking) {
      return true;
    }
    
    try {
      // 위치 권한 확인
      bool hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        return false;
      }
      
      // 이전 저장된 오프라인 위치 데이터 전송 시도
      _syncOfflineLocations(busId, token);
      
      // 소켓 연결
      await _socketService.connect(token);
      
      // 위치 추적 시작
      _currentBusId = busId;
      _isTracking = true;
      
      // 위치 스트림 구독
      _startLocationUpdates(busId);
      
      // 오프라인 동기화 타이머 설정
      _setupOfflineSync(busId, token);
      
      return true;
    } catch (e) {
      AppLogger.error('위치 추적 시작 오류: $e');
      return false;
    }
  }
  
  // 위치 추적 중지
  Future<void> stopTracking() async {
    _isTracking = false;
    _currentBusId = null;
    
    // 위치 스트림 구독 취소
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    
    // 오프라인 동기화 타이머 정리
    _offlineSync?.cancel();
    _offlineSync = null;
    
    // 소켓 연결 해제
    _socketService.disconnect();
  }
  
  // 위치 권한 확인
  Future<bool> _checkLocationPermission() async {
    // 서비스 활성화 확인
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 사용자에게 위치 서비스 활성화 요청
      return false;
    }
    
    // 권한 확인
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return true;
  }
  
  // 위치 업데이트 시작
  void _startLocationUpdates(String busId) {
    // 이전 구독 취소
    _positionStreamSubscription?.cancel();
    
    // 새 위치 스트림 구독
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: AppConfig.minimumDistanceChangeMeters.toInt(),
        timeLimit: Duration(seconds: AppConfig.locationUpdateIntervalSeconds),
      ),
    ).listen(
      (Position position) => _handleLocationUpdate(position, busId),
      onError: (error) => AppLogger.error('위치 업데이트 오류: $error'),
    );
  }
  
  // 위치 업데이트 처리
  Future<void> _handleLocationUpdate(Position position, String busId) async {
    if (!_isTracking || busId != _currentBusId) return;
    
    // 위치 데이터 생성
    final locationData = LocationData(
      busId: busId,
      latitude: position.latitude,
      longitude: position.longitude,
      speed: position.speed,
      heading: position.heading,
      accuracy: position.accuracy,
      timestamp: DateTime.now(),
    );
    
    // 소켓 연결 상태 확인
    if (_socketService.isConnected) {
      // 실시간으로 서버에 위치 전송
      _socketService.sendLocationUpdate(locationData);
    } else {
      // 오프라인 상태면 로컬에 저장
      await _saveLocationOffline(locationData);
    }
  }
  
  // 오프라인 위치 저장
  Future<void> _saveLocationOffline(LocationData locationData) async {
    try {
      // 데이터베이스에 위치 저장
      await _locationDb.saveLocation(locationData);
      
      // 최대 저장 개수 제한
      await _locationDb.limitStoredLocations(AppConfig.maxOfflineLocationRecords);
    } catch (e) {
      AppLogger.error('오프라인 위치 저장 오류: $e');
    }
  }
  
  // 오프라인에서 저장된 위치 동기화
  Future<void> _syncOfflineLocations(String busId, String token) async {
    try {
      // 저장된 위치 데이터 가져오기
      final storedLocations = await _locationDb.getLocations(busId);
      
      if (storedLocations.isEmpty) {
        return;
      }
      
      // 소켓 연결 확인 및 연결
      if (!_socketService.isConnected) {
        await _socketService.connect(token);
      }
      
      if (_socketService.isConnected) {
        // 저장된 위치 데이터 일괄 전송
        for (final location in storedLocations) {
          _socketService.sendLocationUpdate(location);
          // 서버 부하 방지를 위한 약간의 지연
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        // 전송 성공 시 로컬 데이터 삭제
        await _locationDb.deleteLocations(busId);
      }
    } catch (e) {
      AppLogger.error('오프라인 위치 동기화 오류: $e');
    }
  }
  
  // 오프라인 동기화 타이머 설정
  void _setupOfflineSync(String busId, String token) {
    _offlineSync?.cancel();
    
    // 주기적으로 오프라인 데이터 동기화 시도
    _offlineSync = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _syncOfflineLocations(busId, token),
    );
  }
  
  // 위치 추적 상태 저장
  Future<void> saveTrackingState() async {
    if (_currentBusId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTracking', _isTracking);
    await prefs.setString('trackingBusId', _currentBusId!);
  }
  
  // 저장된 위치 추적 상태 복원
  Future<bool> restoreTrackingState(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasTracking = prefs.getBool('isTracking') ?? false;
      final busId = prefs.getString('trackingBusId');
      
      if (wasTracking && busId != null) {
        return await startTracking(busId, token);
      }
      
      return false;
    } catch (e) {
      AppLogger.error('추적 상태 복원 오류: $e');
      return false;
    }
  }
}