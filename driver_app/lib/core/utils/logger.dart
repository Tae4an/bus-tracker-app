// 앱 로깅 유틸리티
// 개발 및 디버깅을 위한 통합 로깅 기능 제공

import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

enum LogLevel {
  debug,
  info,
  warn,
  error,
  network,
}

class AppLogger {
  // 로그 수준에 따른 색상
  static const Map<LogLevel, String> _logColors = {
    LogLevel.debug: '\x1B[37m', // 회색
    LogLevel.info: '\x1B[32m',  // 녹색
    LogLevel.warn: '\x1B[33m',  // 노란색
    LogLevel.error: '\x1B[31m', // 빨간색
    LogLevel.network: '\x1B[36m', // 청록색
  };
  
  static const String _resetColor = '\x1B[0m';
  
  // 디버그 로그
  static void debug(String message) {
    _log(LogLevel.debug, message);
  }
  
  // 정보 로그
  static void info(String message) {
    _log(LogLevel.info, message);
  }
  
  // 경고 로그
  static void warn(String message) {
    _log(LogLevel.warn, message);
  }
  
  // 오류 로그
  static void error(String message, [StackTrace? stackTrace]) {
    _log(LogLevel.error, message);
    if (stackTrace != null && kDebugMode) {
      print('$stackTrace');
    }
  }
  
  // 네트워크 로그
  static void network(String message) {
    _log(LogLevel.network, message);
  }
  
  // 로그 출력
  static void _log(LogLevel level, String message) {
    if (kDebugMode) {
      final now = DateTime.now();
      final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      final color = _logColors[level] ?? '';
      
      // 콘솔에 출력
      print('$color[${level.name.toUpperCase()}][$timeString] $message$_resetColor');
      
      // 개발자 콘솔에도 로깅
      developer.log(
        message,
        name: 'DriverApp',
        time: now,
        level: _getLevelValue(level),
      );
    }
  }
  
  // 로그 레벨 값 반환
  static int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warn:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.network:
        return 700;
    }
  }
}