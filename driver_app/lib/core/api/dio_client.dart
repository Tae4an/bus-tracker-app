// Dio HTTP 클라이언트 구성
// API 요청에 공통적으로 사용되는 설정, 인터셉터, 타임아웃 등 관리

import 'package:dio/dio.dart';
import 'package:driver_app/config/app_config.dart';
import 'package:driver_app/core/utils/logger.dart';
import 'package:flutter/foundation.dart';

class DioClient {
  // 싱글톤 패턴 구현
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  
  late Dio dio;
  
  // 내부 생성자
  DioClient._internal() {
    dio = Dio();
    _configDio();
  }
  
  // Dio 설정
  void _configDio() {
    dio.options = BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: Duration(seconds: AppConfig.connectionTimeoutSeconds),
      receiveTimeout: Duration(seconds: AppConfig.connectionTimeoutSeconds),
      contentType: 'application/json',
      responseType: ResponseType.json,
    );
    
    // 인터셉터 추가
    dio.interceptors.add(_createLogInterceptor());
    dio.interceptors.add(_createRetryInterceptor());
  }
  
  // 로깅 인터셉터
  Interceptor _createLogInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          AppLogger.network('REQUEST[${options.method}] => PATH: ${options.path}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          AppLogger.network('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        AppLogger.error('DIO ERROR[${e.response?.statusCode}] => ${e.message}');
        return handler.next(e);
      },
    );
  }
  
  // 재시도 인터셉터
  Interceptor _createRetryInterceptor() {
    return InterceptorsWrapper(
      onError: (DioException error, handler) async {
        // 네트워크 오류나 타임아웃 시 최대 3번 재시도
        if (_shouldRetry(error) && error.requestOptions.extra['retryCount'] == null) {
          final options = error.requestOptions;
          options.extra['retryCount'] = 1;
          
          try {
            AppLogger.warn('재시도 중... (1/3)');
            final response = await dio.fetch(options);
            return handler.resolve(response);
          } catch (e) {
            if (e is DioException && _shouldRetry(e) && e.requestOptions.extra['retryCount'] < 3) {
              final retryOptions = e.requestOptions;
              retryOptions.extra['retryCount'] = retryOptions.extra['retryCount'] + 1;
              
              AppLogger.warn('재시도 중... (${retryOptions.extra['retryCount']}/3)');
              try {
                final response = await dio.fetch(retryOptions);
                return handler.resolve(response);
              } catch (retryError) {
                return handler.next(retryError as DioException);
              }
            }
            return handler.next(e as DioException);
          }
        }
        return handler.next(error);
      }
    );
  }
  
  // 재시도 여부 결정 함수
  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.connectionError;
  }
}