// 노선 정보 위젯
// 현재 운행 중인 노선의 정보와 정류장 목록 표시

import 'package:driver_app/presentation/providers/auth_provider.dart';
import 'package:driver_app/presentation/providers/driver_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/models/route.dart' as app_route;

class RouteInfoWidget extends StatefulWidget {
  final String routeId;

  const RouteInfoWidget({
    super.key,
    required this.routeId,
  });

  @override
  State<RouteInfoWidget> createState() => _RouteInfoWidgetState();
}

class _RouteInfoWidgetState extends State<RouteInfoWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<DriverProvider>(
      builder: (context, driverProvider, _) {
        final route = driverProvider.currentRoute;

        if (route == null) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text('노선 정보를 불러올 수 없습니다'),
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.all(12),
          child: Column(
            children: [
              // 노선 기본 정보 타일
              ListTile(
                title: Text(
                  route.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  route.description ?? '총 ${route.stops.length}개 정류장',
                ),
                trailing: IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
                leading: Container(
                  width: 8,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: _parseColor(route.color),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // 확장 시 정류장 목록 표시
              if (_isExpanded) _buildStopsList(route),
            ],
          ),
        );
      },
    );
  }

  // 정류장 목록 위젯
  Widget _buildStopsList(app_route.Route route) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getStopsInfo(route),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('정류장 정보를 불러오는데 실패했습니다')),
          );
        }

        final stops = snapshot.data!;
        if (stops.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('정류장 정보가 없습니다')),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              const Divider(),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stops.length,
                itemBuilder: (context, index) {
                  final stop = stops[index];
                  final isFirst = index == 0;
                  final isLast = index == stops.length - 1;

                  return ListTile(
                    dense: true,
                    leading: _buildStopIndicator(isFirst, isLast),
                    title: Text(stop['name'] ?? '정류장 ${index + 1}'),
                    subtitle: stop['arrivalTime'] != null
                        ? Text('도착: ${stop['arrivalTime']}')
                        : null,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 정류장 목록의 인디케이터 (선과 점)
  Widget _buildStopIndicator(bool isFirst, bool isLast) {
    return SizedBox(
      width: 24,
      height: double.infinity,
      child: Center(
        child: Column(
          children: [
            // 첫 번째 정류장이 아니면 위쪽 선 표시
            if (!isFirst)
              Expanded(
                flex: 1,
                child: Container(
                  width: 2,
                  color: Colors.grey,
                ),
              ),

            // 정류장 점
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isFirst || isLast ? Colors.red : Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),

            // 마지막 정류장이 아니면 아래쪽 선 표시
            if (!isLast)
              Expanded(
                flex: 1,
                child: Container(
                  width: 2,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 정류장 정보 가져오기
  Future<List<Map<String, dynamic>>> _getStopsInfo(app_route.Route route) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.token == null) return [];
      
      // TODO: API에서 정류장 상세 정보 가져오기
      // 현재는 더미 데이터 사용
      
      return List.generate(
        route.stops.length,
        (index) => {
          'id': route.stops[index],
          'name': '정류장 ${index + 1}',
          'arrivalTime': _getEstimatedArrivalTime(index),
        },
      );
    } catch (e) {
      return [];
    }
  }

  // 도착 예정 시간 계산 (임시 데이터)
  String? _getEstimatedArrivalTime(int index) {
    if (index == 0) return null; // 출발지는 도착 시간 없음
    
    final now = DateTime.now();
    final arrivalTime = now.add(Duration(minutes: 5 * (index + 1)));
    
    return '${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}';
  }

  // 색상 문자열 파싱
  Color _parseColor(String? colorHex) {
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
}