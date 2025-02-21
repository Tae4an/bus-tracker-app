// 네트워크 연결 상태 관리 프로바이더
// 앱의 온라인/오프라인 상태를 추적하고 관리

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum ConnectionStatus {
  online,     // 온라인 상태
  offline,    // 오프라인 상태
  unknown     // 알 수 없는 상태
}

class ConnectionProvider with ChangeNotifier {
  // 연결 상태 관리
  ConnectionStatus _status = ConnectionStatus.unknown;
  StreamSubscription? _subscription;
  final Connectivity _connectivity = Connectivity();
  
  // 게터
  ConnectionStatus get status => _status;
  bool get isOnline => _status == ConnectionStatus.online;
  
  // 생성자
  ConnectionProvider() {
    // 초기 연결 상태 확인
    _checkConnectivity();
    
    // 연결 상태 변경 구독
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }
  
  // 초기 연결 상태 확인
  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateStatus(result);
    } catch (e) {
      _status = ConnectionStatus.unknown;
      notifyListeners();
    }
  }
  
  // 연결 상태 업데이트
  void _updateStatus(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      _status = ConnectionStatus.offline;
    } else {
      _status = ConnectionStatus.online;
    }
    notifyListeners();
    
    if (kDebugMode) {
      print('네트워크 연결 상태: $_status');
    }
  }
  
  // 리소스 정리
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
  
  // 수동으로 연결 확인
  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
    return isOnline;
  }
}