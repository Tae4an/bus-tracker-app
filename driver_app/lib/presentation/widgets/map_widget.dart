// 지도 표시 위젯
// 버스 위치 및 노선 정보를 지도에 표시

import 'dart:async';
import 'dart:math';
import 'package:driver_app/core/utils/logger.dart';
import 'package:driver_app/presentation/providers/auth_provider.dart';
import 'package:driver_app/presentation/providers/driver_provider.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared/models/location.dart';
import 'package:shared/models/route.dart' as app_route;
import 'package:shared/models/stop.dart';

class MapWidget extends StatefulWidget {
  final String busId;
  final String routeId;
  final ValueNotifier<bool> isFollowingCurrentLocation;

  const MapWidget({
    super.key,
    required this.busId,
    required this.routeId,
    required this.isFollowingCurrentLocation,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;
  Timer? _routeRefreshTimer;
  
  // 지도 초기 위치
  static const _defaultLocation = LatLng(37.5665, 126.9780); // 서울시청
  static const _defaultZoom = 14.0;

  @override
  void initState() {
    super.initState();
    
    // 위치 추적 시작
    _startPositionTracking();
    
    // 노선 정보 로드
    _loadRouteData();
    
    // 주기적 노선 정보 갱신
    _routeRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _loadRouteData(),
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _routeRefreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // 위치 추적 시작
  void _startPositionTracking() {
    // 이전 구독 취소
    _positionStreamSubscription?.cancel();
    
    // 새 위치 스트림 구독
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // 10미터마다 업데이트
      ),
    ).listen(
      _updatePosition,
      onError: (error) {
        AppLogger.error('위치 추적 오류: $error');
      },
    );
  }

  // 위치 업데이트 처리
  void _updatePosition(Position position) {
    setState(() {
      _currentPosition = position;
      
      // 버스 위치 마커 업데이트
      _updateBusMarker(position);
    });
    
    // 현재 위치 자동 추적 설정이 켜져 있다면 카메라 이동
    if (widget.isFollowingCurrentLocation.value && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    }
  }

  // 버스 위치 마커 업데이트
  void _updateBusMarker(Position position) {
    final busMarker = Marker(
      markerId: const MarkerId('currentBus'),
      position: LatLng(position.latitude, position.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(
        title: '현재 버스 위치',
        snippet: Provider.of<DriverProvider>(context, listen: false)
            .assignedBus
            ?.displayName,
      ),
    );
    
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'currentBus');
      _markers.add(busMarker);
    });
  }

  // 노선 데이터 로드
  Future<void> _loadRouteData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
      
      if (authProvider.token == null) return;
      
      // 노선 정보가 이미 있는지 확인
      if (driverProvider.currentRoute == null) {
        await driverProvider.loadRouteInfo(widget.routeId, authProvider.token!);
      }
      
      final route = driverProvider.currentRoute;
      if (route != null && mounted) {
        _updateRouteDisplay(route);
      }
    } catch (e) {
      AppLogger.error('노선 데이터 로드 오류: $e');
    }
  }

  // 노선 정보 지도에 표시
  void _updateRouteDisplay(app_route.Route route) async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final stops = await _getStopsForRoute(route);
    
    // 정류장에 대한 마커 생성
    final stopMarkers = stops.map((stop) {
      return Marker(
        markerId: MarkerId('stop_${stop.id}'),
        position: LatLng(
          stop.location.latitude,
          stop.location.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: stop.name,
          snippet: stop.description,
        ),
      );
    }).toSet();
    
    // 노선 경로 폴리라인 생성
    final List<LatLng> routePoints = stops.map((stop) {
      return LatLng(
        stop.location.latitude,
        stop.location.longitude,
      );
    }).toList();
    
    final routePolyline = Polyline(
      polylineId: PolylineId('route_${route.id}'),
      points: routePoints,
      color: _getRouteColor(route.color),
      width: 5,
    );
    
    setState(() {
      // 정류장 마커 업데이트
      _markers.removeWhere((marker) => marker.markerId.value.startsWith('stop_'));
      _markers.addAll(stopMarkers);
      
      // 노선 폴리라인 업데이트
      _polylines.clear();
      _polylines.add(routePolyline);
    });
    
    // 카메라 이동 (초기 1회만)
    if (_mapController != null && routePoints.isNotEmpty && _currentPosition == null) {
      _fitMapToBounds(routePoints);
    }
  }
  
  // 노선 색상 파싱
  Color _getRouteColor(String? colorHex) {
    if (colorHex == null || !colorHex.startsWith('#')) {
      return Colors.blue;
    }
    
    try {
      final hexColor = colorHex.replaceFirst('#', '0xFF');
      return Color(int.parse(hexColor));
    } catch (e) {
      return Colors.blue;
    }
  }
  
  // 노선의 정류장 정보 가져오기
  Future<List<Stop>> _getStopsForRoute(app_route.Route route) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
      
      if (authProvider.token == null) return [];
      
      // 정류장 정보를 API에서 가져오기
      // 현재는 더미 데이터 사용 (실제 구현 시 API 호출 필요)
      final List<Stop> stops = [];
      
      // TODO: 실제 API 호출로 정류장 정보 가져오기
      
      return stops;
    } catch (e) {
      AppLogger.error('정류장 정보 가져오기 오류: $e');
      return [];
    }
  }
  
  // 지도를 노선 전체가 보이도록 조정
  void _fitMapToBounds(List<LatLng> points) {
    if (points.isEmpty || _mapController == null) return;
    
    final bounds = _calculateBounds(points);
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50), // 50은 패딩(px)
    );
  }
  
  // 좌표 목록의 경계 계산
  LatLngBounds _calculateBounds(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;
    
    for (final point in points) {
      minLat = minLat == null ? point.latitude : min(minLat, point.latitude);
      maxLat = maxLat == null ? point.latitude : max(maxLat, point.latitude);
      minLng = minLng == null ? point.longitude : min(minLng, point.longitude);
      maxLng = maxLng == null ? point.longitude : max(maxLng, point.longitude);
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 구글 맵
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _defaultLocation,
            zoom: _defaultZoom,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          markers: _markers,
          polylines: _polylines,
          onMapCreated: (controller) {
            _mapController = controller;
            _loadRouteData(); // 지도 생성 후 노선 정보 로드
          },
          onCameraMove: (_) {
            // 카메라가 수동으로 이동하면 추적 모드 해제
            if (widget.isFollowingCurrentLocation.value) {
              widget.isFollowingCurrentLocation.value = false;
            }
          },
        ),
        
        // 운행 상태 표시
        Positioned(
          top: 16,
          left: 16,
          child: Consumer<DriverProvider>(
            builder: (context, driverProvider, _) {
              final isActive = driverProvider.isActivelyDriving;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? Icons.play_circle_filled : Icons.pause_circle_filled,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isActive ? '운행 중' : '일시 정지',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        // 줌 버튼
        Positioned(
          right: 16,
          bottom: 60,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'zoomIn',
                onPressed: () {
                  _mapController?.animateCamera(CameraUpdate.zoomIn());
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'zoomOut',
                onPressed: () {
                  _mapController?.animateCamera(CameraUpdate.zoomOut());
                },
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
        
        // 현재 위치 버튼
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'currentLocation',
            onPressed: () {
              if (_currentPosition != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  ),
                );
                widget.isFollowingCurrentLocation.value = true;
              }
            },
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}