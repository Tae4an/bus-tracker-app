// 앱 라우팅 설정
// 네비게이션 라우트 및 화면 전환 로직 관리

import 'package:driver_app/presentation/screens/auth/login_screen.dart';
import 'package:driver_app/presentation/screens/auth/splash_screen.dart';
import 'package:driver_app/presentation/screens/home/home_screen.dart';
import 'package:driver_app/presentation/screens/driving/driving_screen.dart';
import 'package:driver_app/presentation/screens/profile/profile_screen.dart';
import 'package:driver_app/presentation/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  // 라우트 이름 상수
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String driving = '/driving';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

class AppRouter {
  // 라우트 생성 함수
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
        
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
        
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
        
      case AppRoutes.driving:
        final arguments = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => DrivingScreen(
            busId: arguments?['busId'] as String? ?? '',
            routeId: arguments?['routeId'] as String? ?? '',
          ),
        );
        
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
        
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
        
      default:
        // 알 수 없는 라우트는 404 페이지로 이동
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route ${settings.name} not found'),
            ),
          ),
        );
    }
  }
}