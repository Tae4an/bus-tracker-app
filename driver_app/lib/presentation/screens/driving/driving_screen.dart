// 실시간 운행 화면
// 지도 표시, 위치 추적, 운행 제어 기능 제공

import 'dart:async';
import 'package:driver_app/core/location/location_service.dart';
import 'package:driver_app/presentation/providers/auth_provider.dart';
import 'package:driver_app/presentation/providers/connection_provider.dart';
import 'package:driver_app/presentation/providers/driver_provider.dart';
import 'package:driver_app/presentation/widgets/driving_control_panel.dart';
import 'package:driver_app/presentation/widgets/map_widget.dart';
import 'package:driver_app/presentation/widgets/offline_indicator.dart';
import 'package:driver_app/presentation/widgets/route_info_widget.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';

class DrivingScreen extends StatefulWidget {
  final String busId;
  final String routeId;

  const DrivingScreen({
    super.key,
    required this.busId,
    required this.routeId,
  });

  @override
  State<DrivingScreen> createState() => _DrivingScreenState();
}

class _DrivingScreenState extends State<DrivingScreen> with WidgetsBindingObserver {
  bool _isTrackingActive = false;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  final LocationService _locationService = LocationService();
  final ValueNotifier<bool> _isMapExpanded = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isFollowingCurrentLocation = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 화면 꺼짐 방지
    Wakelock.enable();
    
    // 위치 추적 시작
    _startLocationTracking();
  }

  @override
  void dispose() {
    // 리소스 정리
    WidgetsBinding.instance.removeObserver(this);
    _positionStreamSubscription?.cancel();
    Wakelock.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱 라이프사이클 상태 변화 처리
    switch (state) {
      case AppLifecycleState.resumed:
        // 앱이 포그라운드로 돌아왔을 때 위치 추적 재개
        if (_isTrackingActive && _positionStreamSubscription == null) {
          _startLocationTracking();
        }
        Wakelock.enable();
        break;
      case AppLifecycleState.paused:
        // 앱이 백그라운드로 갔을 때 위치 추적 상태 저장
        _locationService.saveTrackingState();
        break;
      default:
        break;
    }
  }

  // 위치 추적 시작
  Future<void> _startLocationTracking() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.token == null) {
      _showErrorSnackBar('인증 토큰이 없습니다. 다시 로그인해주세요.');
      return;
    }

    try {
      // 위치 권한 확인
      final hasPermission = await _locationService.requestLocationPermission();
      if (!hasPermission) {
        _showErrorSnackBar('위치 권한이 필요합니다.');
        return;
      }

      // 위치 추적 시작
      final success = await _locationService.startTracking(
        widget.busId,
        authProvider.token!,
      );

      if (success) {
        setState(() {
          _isTrackingActive = true;
        });
      } else {
        _showErrorSnackBar('위치 추적을 시작할 수 없습니다.');
      }
    } catch (e) {
      _showErrorSnackBar('위치 추적 초기화 중 오류가 발생했습니다.');
    }
  }

  // 위치 추적 중지
  Future<void> _stopLocationTracking() async {
    await _locationService.stopTracking();
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    
    if (mounted) {
      setState(() {
        _isTrackingActive = false;
      });
    }
  }

  // 운행 종료
  Future<void> _finishDriving() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    
    if (authProvider.token == null) return;

    try {
      // 위치 추적 중지
      await _stopLocationTracking();
      
      // 버스 상태 업데이트
      await driverProvider.completeDriving(authProvider.token!);
      
      if (mounted) {
        // 이전 화면으로 돌아가기
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackBar('운행 종료 중 오류가 발생했습니다.');
    }
  }

  // 일시 정지/재개
  Future<void> _togglePause() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    
    if (authProvider.token == null) return;

    try {
      if (driverProvider.isActivelyDriving) {
        // 일시 정지
        await driverProvider.pauseDriving(authProvider.token!);
        await _stopLocationTracking();
      } else {
        // 재개
        await driverProvider.startDriving(authProvider.token!);
        await _startLocationTracking();
      }
    } catch (e) {
      _showErrorSnackBar('상태 변경 중 오류가 발생했습니다.');
    }
  }

  // 오류 스낵바 표시
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('실시간 운행'),
        centerTitle: true,
        leading: BackButton(
          onPressed: () => _showExitConfirmDialog(),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder<bool>(
              valueListenable: _isFollowingCurrentLocation,
              builder: (context, isFollowing, _) {
                return Icon(
                  isFollowing ? Icons.gps_fixed : Icons.gps_not_fixed,
                );
              },
            ),
            onPressed: () {
              _isFollowingCurrentLocation.value = !_isFollowingCurrentLocation.value;
            },
            tooltip: '현재 위치 추적',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 지도 영역
              Expanded(
                flex: _isMapExpanded.value ? 2 : 1,
                child: MapWidget(
                  busId: widget.busId,
                  routeId: widget.routeId,
                  isFollowingCurrentLocation: _isFollowingCurrentLocation,
                ),
              ),
              
              // 지도 크기 조절 버튼
              InkWell(
                onTap: () {
                  _isMapExpanded.value = !_isMapExpanded.value;
                },
                child: Container(
                  height: 24,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: Center(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _isMapExpanded,
                      builder: (context, isExpanded, _) {
                        return Icon(
                          isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                          size: 20,
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              // 노선 정보 및 제어 패널
              Expanded(
                flex: 1,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isMapExpanded,
                  builder: (context, isExpanded, _) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          // 노선 정보
                          RouteInfoWidget(routeId: widget.routeId),
                          
                          // 운행 제어 패널
                          DrivingControlPanel(
                            onPauseResume: _togglePause,
                            onFinish: _finishDriving,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          
          // 오프라인 표시기
          Consumer<ConnectionProvider>(
            builder: (context, connectionProvider, _) {
              return !connectionProvider.isOnline
                  ? const OfflineIndicator()
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  // 종료 확인 다이얼로그
  Future<void> _showExitConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('운행 종료'),
        content: const Text('운행을 종료하시겠습니까?\n위치 추적이 중지됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result ?? false) {
      await _finishDriving();
    }
  }
}