// 알림 서비스
// 앱 알림 관리 및 처리

import 'package:driver_app/core/utils/logger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  // 싱글톤 패턴 구현
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // 알림 서비스 초기화
  Future<void> initialize() async {
    // 타임존 초기화
    tz_data.initializeTimeZones();
    
    // 안드로이드 설정
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS 설정
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    // 초기화 설정
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    // 알림 플러그인 초기화
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // 알림 권한 요청
    await _requestPermissions();
  }
  
  // 알림 권한 요청
  Future<void> _requestPermissions() async {
    try {
      // 안드로이드에서는 기본적으로 권한이 있음
      // iOS에서 권한 요청
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } catch (e) {
      AppLogger.error('알림 권한 요청 오류: $e');
    }
  }
  
  // 알림 탭 이벤트 처리
  void _onNotificationTap(NotificationResponse response) {
    // payload가 있으면 처리
    if (response.payload != null) {
      // TODO: 페이로드에 따른 화면 이동 등의 처리
      AppLogger.info('알림 탭: ${response.payload}');
    }
  }
  
  // 즉시 알림 표시
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'driver_app_channel',
      '기사용 앱 알림',
      channelDescription: '셔틀버스 기사용 앱의 알림 채널',
      importance: Importance.high,
      priority: Priority.high,
      ticker: '셔틀버스 알림',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
  
  // 예약 알림 설정
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'driver_app_scheduled_channel',
      '기사용 앱 예약 알림',
      channelDescription: '셔틀버스 기사용 앱의 예약 알림 채널',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
  
  // 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
  
  // 특정 알림 취소
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
  
  // 운행 시작 알림
  Future<void> showDrivingStartNotification() async {
    await showNotification(
      id: 1,
      title: '운행 시작',
      body: '위치 정보 전송이 시작되었습니다.',
      payload: 'driving_start',
    );
  }
  
  // 운행 일시정지 알림
  Future<void> showDrivingPauseNotification() async {
    await showNotification(
      id: 2,
      title: '운행 일시정지',
      body: '위치 정보 전송이 일시중지 되었습니다.',
      payload: 'driving_pause',
    );
  }
  
  // 오프라인 모드 알림
  Future<void> showOfflineModeNotification() async {
    await showNotification(
      id: 3,
      title: '오프라인 모드',
      body: '인터넷 연결이 끊겼습니다. 위치 정보가 로컬에 저장됩니다.',
      payload: 'offline_mode',
    );
  }
  
  // 배터리 부족 알림
  Future<void> showLowBatteryNotification() async {
    await showNotification(
      id: 4,
      title: '배터리 부족 경고',
      body: '배터리가 15% 미만입니다. 충전이 필요합니다.',
      payload: 'low_battery',
    );
  }
}