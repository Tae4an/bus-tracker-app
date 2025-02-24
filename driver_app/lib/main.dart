// 앱의 진입점 파일
// Flutter 앱 초기화, 프로바이더 설정, 테마 적용을 담당

import 'package:driver_app/config/app_config.dart';
import 'package:driver_app/core/location/location_service.dart';
import 'package:driver_app/presentation/providers/auth_provider.dart';
import 'package:driver_app/presentation/providers/connection_provider.dart';
import 'package:driver_app/presentation/providers/driver_provider.dart';
import 'package:driver_app/presentation/themes/app_theme.dart';
import 'package:driver_app/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

void main() async {
  // Flutter 엔진 초기화 및 위젯 바인딩 보장
  WidgetsFlutterBinding.ensureInitialized();
  
  // 앱 환경 설정 로드
  await AppConfig.initialize();
  
  // 앱 실행
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 다중 프로바이더 설정으로 앱 전역 상태 관리
    return MultiProvider(
      providers: [
        // 인증 상태 관리
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // 네트워크 연결 상태 관리
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
        
        // 기사 상태 관리 (버스 정보, 운행 상태 등)
        ChangeNotifierProvider(create: (_) => DriverProvider()),
        
        // 위치 서비스 프로바이더 (백그라운드 위치 추적)
        Provider(create: (_) => LocationService()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: '기사용 앱',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system, // 시스템 테마 따르기
            
            // 라우팅 설정
            initialRoute: authProvider.isLoggedIn ? AppRoutes.home : AppRoutes.login,
            onGenerateRoute: AppRouter.generateRoute,
            
            // 다국어 지원 설정
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ko', 'KR'), // 한국어
              Locale('en', 'US'), // 영어
            ],
            locale: const Locale('ko', 'KR'), // 기본 언어
            
            // 디버그 배너 제거
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}