// 배터리 최적화 헬퍼
// 배터리 최적화 제외 요청 및 권한 관리

import 'package:driver_app/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BatteryOptimizationHelper {
  // 배터리 최적화 기능 끄기 요청
  static Future<bool> requestDisableBatteryOptimization() async {
    try {
      // 네이티브 플랫폼 채널
      const platform = MethodChannel('com.example.driver_app/battery_optimization');
      
      // 네이티브 코드 호출
      final result = await platform.invokeMethod<bool>('requestDisableBatteryOptimization');
      return result ?? false;
    } on PlatformException catch (e) {
      AppLogger.error('배터리 최적화 요청 오류: ${e.message}');
      return false;
    } catch (e) {
      AppLogger.error('배터리 최적화 요청 중 예상치 못한 오류: $e');
      return false;
    }
  }
  
  // 배터리 최적화 제외 상태 확인
  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      const platform = MethodChannel('com.example.driver_app/battery_optimization');
      final result = await platform.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? false;
    } on PlatformException catch (e) {
      AppLogger.error('배터리 최적화 상태 확인 오류: ${e.message}');
      return false;
    } catch (e) {
      AppLogger.error('배터리 최적화 상태 확인 중 예상치 못한 오류: $e');
      return false;
    }
  }
  
  // 배터리 최적화 설정 안내 다이얼로그 표시
  static Future<void> showBatteryOptimizationDialog(BuildContext context) async {
    final isIgnoring = await isIgnoringBatteryOptimizations();
    
    if (isIgnoring) {
      return; // 이미 배터리 최적화 제외 중이면 표시하지 않음
    }
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('더 정확한 위치 추적을 위해'),
          content: const Text(
            '앱이 백그라운드에 있을 때도 정확한 위치 추적을 위해 '
            '배터리 최적화 제외 설정이 필요합니다.\n\n'
            '설정하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('나중에'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                requestDisableBatteryOptimization();
              },
              child: const Text('설정하기'),
            ),
          ],
        ),
      );
    }
  }
}