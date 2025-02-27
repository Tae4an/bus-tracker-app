// 앱 환경 설정 관리
// API URL, 상수 값, 환경별 설정 등을 관리

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 앱 환경 구분을 위한 열거형
enum Environment {
  development,
  staging,
  production
}

class AppConfig {
  // 싱글톤 패턴 구현
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // 현재 환경 설정
  static Environment environment = Environment.development;
  
  // SharedPreferences 인스턴스
  static late SharedPreferences prefs;
  
  // 초기화 메서드
  static Future<void> initialize() async {
    prefs = await SharedPreferences.getInstance();
    
    // 환경에 따른 설정 로드
    _loadEnvironmentConfig();
  }
  
  // 환경별 설정 로드
  static void _loadEnvironmentConfig() {
    // 개발 환경이 아닌 경우, 프로덕션으로 설정
    if (!kDebugMode) {
      environment = Environment.production;
    }
  }
  
  // API 기본 URL 설정
  static String get apiBaseUrl {
    switch (environment) {
      case Environment.development:
        return _isAndroid() ? 'http://10.0.2.2:8080/api' : 'http://localhost:8080/api';
      case Environment.staging:
        return 'https://staging-api.example.com/api';
      case Environment.production:
        return 'https://api.example.com/api';
    }
  }
 
  // 웹소켓 URL 설정
  static String get socketUrl {
    switch (environment) {
      case Environment.development:
        return _isAndroid() ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
      case Environment.staging:
        return 'https://staging-api.example.com';
      case Environment.production:
        return 'https://api.example.com';
    }
  }

  // 업로드용 이미지 URL (프로필 이미지 등)
  static String get imageBaseUrl {
    switch (environment) {
      case Environment.development:
        return _isAndroid() ? 'http://10.0.2.2:8080/uploads' : 'http://localhost:8080/uploads';
      case Environment.staging:
        return 'https://staging-api.example.com/uploads';
      case Environment.production:
        return 'https://api.example.com/uploads';
    }
  }

  // Android 플랫폼 확인
  static bool _isAndroid() {
    return defaultTargetPlatform == TargetPlatform.android;
  }

  // 위치 추적 설정
  static const locationUpdateIntervalSeconds = 10; // 위치 업데이트 간격(초)
  static const minimumDistanceChangeMeters = 10.0; // 최소 위치 변경 거리(미터)
  static const minimumTimeIntervalSeconds = 5;    // 최소 업데이트 시간 간격(초)
  
  // 토큰 저장소 키
  static const tokenKey = 'auth_token';
  static const refreshTokenKey = 'refresh_token';
  static const userIdKey = 'user_id';
  
  // 기타 상수
  static const connectionTimeoutSeconds = 30;
  static const socketReconnectIntervalSeconds = 5;
  static const maxOfflineLocationRecords = 1000; // 오프라인에서 저장할 최대 위치 기록 수
}