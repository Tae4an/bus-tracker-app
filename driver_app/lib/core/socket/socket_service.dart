// 소켓 통신 서비스
// 실시간 위치 데이터 전송을 위한 Socket.IO 클라이언트 관리

import 'dart:async';
import 'package:driver_app/config/app_config.dart';
import 'package:driver_app/core/utils/logger.dart';
import 'package:driver_app/data/models/location_data.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  // 싱글톤 패턴 구현
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();
  
  // Socket.IO 클라이언트
  io.Socket? _socket;
  
  // 상태 변수
  bool _isConnected = false;
  Timer? _reconnectTimer;
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  
  // 게터
  bool get isConnected => _isConnected;
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  
  // 소켓 연결
  Future<void> connect(String token) async {
    // 이미 연결된 경우
    if (_socket != null && _isConnected) {
      return;
    }
    
    try {
      // 소켓 클라이언트 초기화
      _socket = io.io(
        AppConfig.socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableForceNew()
            .setAuth({'token': token})
            .setReconnectionAttempts(5)
            .setReconnectionDelay(3000)
            .build(),
      );
      
      // 연결 이벤트 핸들러 등록
      _registerEventHandlers();
      
      // 소켓 연결 시작
      _socket!.connect();
      
      // 연결 타임아웃 설정
      final completer = Completer<bool>();
      
      // 연결 성공 시 완료
      _socket!.once('connect', (_) {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      });
      
      // 연결 오류 시 완료
      _socket!.once('connect_error', (error) {
        AppLogger.error('소켓 연결 오류: $error');
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });
      
      // 타임아웃 설정
      Timer(Duration(seconds: AppConfig.connectionTimeoutSeconds), () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });
      
      // 연결 결과 대기
      final result = await completer.future;
      _isConnected = result;
      _connectionStatusController.add(_isConnected);
    } catch (e) {
      AppLogger.error('소켓 초기화 오류: $e');
      _isConnected = false;
      _connectionStatusController.add(false);
    }
  }
  
  // 소켓 연결 해제
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    
    _isConnected = false;
    _connectionStatusController.add(false);
  }
  
  // 이벤트 핸들러 등록
  void _registerEventHandlers() {
    _socket!.on('connect', (_) {
      AppLogger.info('소켓 연결 성공');
      _isConnected = true;
      _connectionStatusController.add(true);
      _resetReconnectTimer();
    });
    
    _socket!.on('disconnect', (reason) {
      AppLogger.warn('소켓 연결 해제: $reason');
      _isConnected = false;
      _connectionStatusController.add(false);
      _setupReconnectTimer();
    });
    
    _socket!.on('connect_error', (error) {
      AppLogger.error('소켓 연결 오류: $error');
      _isConnected = false;
      _connectionStatusController.add(false);
      _setupReconnectTimer();
    });
    
    _socket!.on('reconnect_attempt', (attemptNumber) {
      AppLogger.info('소켓 재연결 시도: $attemptNumber');
    });
    
    _socket!.on('reconnect', (_) {
      AppLogger.info('소켓 재연결 성공');
      _isConnected = true;
      _connectionStatusController.add(true);
      _resetReconnectTimer();
    });
    
    _socket!.on('locationUpdateSuccess', (data) {
      AppLogger.debug('위치 업데이트 성공: ${data['busId']}');
    });
    
    _socket!.on('error', (error) {
      AppLogger.error('소켓 오류: $error');
    });
  }
  
  // 위치 업데이트 전송
  void sendLocationUpdate(LocationData locationData) {
    if (!_isConnected || _socket == null) {
      AppLogger.warn('소켓 연결이 활성화되지 않아 위치 전송 불가');
      return;
    }
    
    try {
      _socket!.emit('updateBusLocation', {
        'busId': locationData.busId,
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
        'speed': locationData.speed,
        'heading': locationData.heading,
        'accuracy': locationData.accuracy,
      });
    } catch (e) {
      AppLogger.error('위치 업데이트 전송 오류: $e');
    }
  }
  
  // 재연결 타이머 설정
  void _setupReconnectTimer() {
    _reconnectTimer?.cancel();
    
    _reconnectTimer = Timer.periodic(
      Duration(seconds: AppConfig.socketReconnectIntervalSeconds),
      (timer) {
        if (!_isConnected && _socket != null) {
          AppLogger.info('재연결 시도 중...');
          _socket!.connect();
        } else if (_isConnected) {
          _resetReconnectTimer();
        }
      },
    );
  }
  
  // 재연결 타이머 리셋
  void _resetReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
  
  // 리소스 정리
  void dispose() {
    disconnect();
    _connectionStatusController.close();
  }
}