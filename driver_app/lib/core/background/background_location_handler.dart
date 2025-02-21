// 백그라운드 위치 처리 핸들러
// 앱이 백그라운드에 있을 때 위치 추적 관리

import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:driver_app/core/notification/notification_service.dart';
import 'package:driver_app/core/utils/logger.dart';
import 'package:driver_app/data/local/location_database.dart';
import 'package:driver_app/data/models/location_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 포그라운드-백그라운드 통신용 포트 이름
const String _locationPortName = 'location_update_port';

class BackgroundLocationHandler {
  // 싱글톤 패턴 구현
  static final BackgroundLocationHandler _instance = BackgroundLocationHandler._internal();
  factory BackgroundLocationHandler() => _instance;
  BackgroundLocationHandler._internal();
  
  final FlutterBackgroundService _service = FlutterBackgroundService();
  final NotificationService _notificationService = NotificationService();
  final LocationDatabase _locationDb = LocationDatabase();
  
  bool _isInitialized = false;
  ReceivePort? _receivePort;
  
  // 백그라운드 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // 백그라운드 서비스 설정
      await _service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: _onStart,
          autoStart: false,
          isForegroundMode: true,
          foregroundServiceNotificationId: 888,
          initialNotificationTitle: '위치 추적 서비스',
          initialNotificationContent: '위치 정보를 전송하는 중...',
          notificationChannelId: 'driver_app_background_channel',
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: _onStart,
          onBackground: _onIosBackground,
        ),
      );
      
      // 통신용 포트 설정
      _receivePort = ReceivePort();
      IsolateNameServer.registerPortWithName(
        _receivePort!.sendPort,
        _locationPortName,
      );
      
      _receivePort!.listen(_handleLocationUpdate);
      
      _isInitialized = true;
    } catch (e) {
      AppLogger.error('백그라운드 서비스 초기화 실패: $e');
    }
  }
  
  // 서비스 시작
  Future<bool> startService(String busId) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // 버스 ID 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tracking_bus_id', busId);
      
      // 서비스 시작
      _service.startService();
      
      // 알림 표시
      await _notificationService.showDrivingStartNotification();
      
      return true;
    } catch (e) {
      AppLogger.error('백그라운드 서비스 시작 실패: $e');
      return false;
    }
  }
  
  // 서비스 중지
  Future<bool> stopService() async {
    try {
      // invoke 메서드를 사용하여 중지 메시지 전송
      _service.invoke('stopService');
      return true;
    } catch (e) {
      AppLogger.error('백그라운드 서비스 중지 실패: $e');
      return false;
    }
  }
  
  // 위치 업데이트 처리
  void _handleLocationUpdate(dynamic message) {
    if (message is Map) {
      try {
        final locationData = LocationData(
          busId: message['busId'] as String,
          latitude: message['latitude'] as double,
          longitude: message['longitude'] as double,
          speed: message['speed'] as double?,
          heading: message['heading'] as double?,
          accuracy: message['accuracy'] as double?,
          timestamp: DateTime.now(),
        );
        
        // TODO: 소켓 서비스에 전달하거나 필요한 처리 수행
      } catch (e) {
        AppLogger.error('위치 데이터 처리 오류: $e');
      }
    }
  }
  
  // 리소스 정리
  void dispose() {
    IsolateNameServer.removePortNameMapping(_locationPortName);
    _receivePort?.close();
  }
}

// 백그라운드 작업 시작 핸들러
@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  // 백그라운드 격리에서 DartPluginRegistrant 등록
  DartPluginRegistrant.ensureInitialized();
  
  // 설정 로드
  final prefs = await SharedPreferences.getInstance();
  final busId = prefs.getString('tracking_bus_id') ?? '';
  final updateInterval = prefs.getInt('locationUpdateInterval') ?? 10;
  
  if (busId.isEmpty) {
    service.stopSelf();
    return;
  }
  
  // 위치 업데이트 구독
  final locationDb = LocationDatabase();
  StreamSubscription<Position>? positionStream;
  
  // 포트 가져오기
  final sendPort = IsolateNameServer.lookupPortByName(_locationPortName);
  
  // 위치 서비스 활성화 확인
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    service.stopSelf();
    return;
  }
  
  // 위치 권한 확인
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied || 
      permission == LocationPermission.deniedForever) {
    service.stopSelf();
    return;
  }
  
  // 서비스 상태 갱신
  service.on('stopService').listen((event) {
    positionStream?.cancel();
    service.stopSelf();
  });
  
  // 위치 추적 시작
  positionStream = Geolocator.getPositionStream(
    locationSettings: LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      timeLimit: Duration(seconds: updateInterval),
    ),
  ).listen((Position position) async {
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
    
    // 로컬 DB에 저장
    await locationDb.saveLocation(locationData);
    
    // 메인 앱으로 전달
    if (sendPort != null) {
      sendPort.send(locationData.toMap());
    }
    
    // 서비스 상태 갱신 (포그라운드 서비스 알림 업데이트)
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: '위치 추적 활성화',
        content: '위도: ${position.latitude.toStringAsFixed(6)}, '
                 '경도: ${position.longitude.toStringAsFixed(6)}',
      );
    }
  });
}

// iOS 백그라운드 모드 핸들러
@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  // Flutter 바인딩 초기화
  DartPluginRegistrant.ensureInitialized();
  
  return true;
}