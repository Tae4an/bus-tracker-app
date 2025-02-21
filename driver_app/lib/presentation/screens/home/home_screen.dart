// 기사 메인 홈 화면
// 버스 배정 정보, 운행 상태 요약 및 빠른 액션 제공

import 'package:driver_app/core/utils/logger.dart';
import 'package:driver_app/presentation/providers/auth_provider.dart';
import 'package:driver_app/presentation/providers/connection_provider.dart';
import 'package:driver_app/presentation/providers/driver_provider.dart';
import 'package:driver_app/presentation/screens/driving/driving_screen.dart';
import 'package:driver_app/presentation/widgets/app_drawer.dart';
import 'package:driver_app/presentation/widgets/bus_status_badge.dart';
import 'package:driver_app/presentation/widgets/offline_indicator.dart';
import 'package:driver_app/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/models/bus_status.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  // 기사 데이터 로드
  Future<void> _loadDriverData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);

      if (authProvider.user != null && authProvider.token != null) {
        await driverProvider.loadAssignedBus(
          authProvider.user!.id,
          authProvider.token!,
        );
      }
    } catch (e) {
      AppLogger.error('기사 데이터 로드 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 운행 시작 핸들러
  Future<void> _handleStartDriving() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);

    if (authProvider.token == null) return;

    final success = await driverProvider.startDriving(authProvider.token!);

    if (success && mounted) {
      // 운행 화면으로 이동
      final bus = driverProvider.assignedBus;
      if (bus != null) {
        Navigator.of(context).pushNamed(
          AppRoutes.driving,
          arguments: {
            'busId': bus.id,
            'routeId': bus.routeId,
          },
        );
      }
    }
  }

  // 새로고침 핸들러
  Future<void> _handleRefresh() async {
    return _loadDriverData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connectionProvider = Provider.of<ConnectionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('기사 홈'),
        actions: [
          // 새로고침 버튼
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _handleRefresh,
            tooltip: '정보 새로고침',
          ),
        ],
      ),
      drawer: const AppDrawer(), // 앱 드로어
      body: Stack(
        children: [
          // 오프라인 표시기
          if (!connectionProvider.isOnline) const OfflineIndicator(),

          // 메인 콘텐츠
          RefreshIndicator(
            onRefresh: _handleRefresh,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMainContent(),
          ),
        ],
      ),
    );
  }

  // 메인 콘텐츠 빌드
  Widget _buildMainContent() {
    return Consumer2<AuthProvider, DriverProvider>(
      builder: (context, authProvider, driverProvider, _) {
        final user = authProvider.user;
        final bus = driverProvider.assignedBus;
        final route = driverProvider.currentRoute;

        if (user == null) {
          return const Center(
            child: Text('사용자 정보를 불러올 수 없습니다.'),
          );
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 기사 정보 카드
              _buildDriverInfoCard(user.name, user.licenseNumber),
              const SizedBox(height: 24),

              // 버스 배정 상태
              _buildBusAssignmentSection(bus, route),
              const SizedBox(height: 24),

              // 운행 액션 버튼
              if (bus != null && driverProvider.drivingStatus != DrivingStatus.driving)
                _buildActionButton(driverProvider),
            ],
          ),
        );
      },
    );
  }

  // 기사 정보 카드 위젯
  Widget _buildDriverInfoCard(String name, String? licenseNumber) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 기사 아바타
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(
                Icons.person,
                size: 36,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 16),

            // 기사 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleLarge,
                  ),
                  if (licenseNumber != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '면허번호: $licenseNumber',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '기사',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 버스 배정 섹션 위젯
  Widget _buildBusAssignmentSection(bus, route) {
    final theme = Theme.of(context);

    if (bus == null) {
      return Card(
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_bus_outlined,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                '배정된 버스가 없습니다',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '관리자에게 문의하여 버스를 배정받으세요',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목
        Text(
          '배정된 버스',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // 버스 정보 카드
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 버스 기본 정보
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bus.displayName ?? bus.plateNumber,
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            bus.plateNumber,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    BusStatusBadge(status: bus.status),
                  ],
                ),
                const Divider(height: 24),

                // 노선 정보
                if (route != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.route,
                        color: theme.colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '노선 정보',
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    route.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (route.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      route.description!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '총 ${route.stops.length}개 정류장',
                    style: theme.textTheme.bodySmall,
                  ),
                ],

                // 노선 정보가 없을 때
                if (route == null)
                  Text(
                    '노선 정보를 불러올 수 없습니다',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 운행 액션 버튼
  Widget _buildActionButton(DriverProvider driverProvider) {
    final theme = Theme.of(context);
    final bus = driverProvider.assignedBus;

    if (bus == null) return const SizedBox.shrink();

    // 버스 상태에 따른 버튼 설정
    String buttonText;
    IconData buttonIcon;
    bool isEnabled;

    switch (bus.status) {
      case BusStatus.ACTIVE:
        buttonText = '운행 계속하기';
        buttonIcon = Icons.play_arrow;
        isEnabled = true;
        break;
      case BusStatus.IDLE:
        buttonText = '운행 시작하기';
        buttonIcon = Icons.play_arrow;
        isEnabled = true;
        break;
      case BusStatus.MAINTENANCE:
        buttonText = '정비 중';
        buttonIcon = Icons.build;
        isEnabled = false;
        break;
      case BusStatus.OUT_OF_SERVICE:
        buttonText = '운행 불가';
        buttonIcon = Icons.not_interested;
        isEnabled = false;
        break;
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: isEnabled ? _handleStartDriving : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          disabledBackgroundColor: theme.colorScheme.onSurface.withOpacity(0.12),
          disabledForegroundColor: theme.colorScheme.onSurface.withOpacity(0.38),
        ),
        icon: Icon(buttonIcon),
        label: Text(
          buttonText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}