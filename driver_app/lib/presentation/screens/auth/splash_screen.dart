// 스플래시 화면
// 앱 시작 시 표시되는 화면, 초기화 및 인증 상태 확인

import 'package:driver_app/core/location/location_service.dart';
import 'package:driver_app/presentation/providers/auth_provider.dart';
import 'package:driver_app/presentation/widgets/app_logo.dart';
import 'package:driver_app/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // 앱 초기화 및 인증 상태 확인
    _initialize();
  }
  
  Future<void> _initialize() async {
    // 잠시 대기 (최소 스플래시 표시 시간)
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final locationService = Provider.of<LocationService>(context, listen: false);
    
    // 인증 상태에 따라 화면 전환
    if (authProvider.isLoggedIn) {
      // 로그인 상태인 경우, 이전 위치 추적 상태 복원 시도
      if (authProvider.token != null) {
        await locationService.restoreTrackingState(authProvider.token!);
      }
      
      // 홈 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      }
    } else {
      // 로그인 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 로고
            const AppLogo(size: 120),
            const SizedBox(height: 32),
            
            // 앱 이름
            Text(
              '셔틀버스 기사용 앱',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // 앱 설명
            Text(
              '실시간 위치 전송 서비스',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 64),
            
            // 로딩 인디케이터
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}