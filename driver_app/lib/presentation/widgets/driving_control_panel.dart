// 운행 제어 패널
// 운행 일시정지, 재개, 종료 등의 컨트롤 제공

import 'package:driver_app/presentation/providers/connection_provider.dart';
import 'package:driver_app/presentation/providers/driver_provider.dart';
import 'package:driver_app/presentation/widgets/status_update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DrivingControlPanel extends StatelessWidget {
  final VoidCallback onPauseResume;
  final VoidCallback onFinish;

  const DrivingControlPanel({
    super.key,
    required this.onPauseResume,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 패널 제목
            Text(
              '운행 제어',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 운행 상태 표시
            Consumer<DriverProvider>(
              builder: (context, driverProvider, _) {
                final isActive = driverProvider.isActivelyDriving;
                final bus = driverProvider.assignedBus;
                
                return Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isActive ? '운행 중' : '일시 정지됨',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (bus != null) ...[
                      const Spacer(),
                      Text(
                        bus.displayName ?? bus.plateNumber,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            
            // 제어 버튼 행
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 일시정지/재개 버튼
                Expanded(
                  child: Consumer2<DriverProvider, ConnectionProvider>(
                    builder: (context, driverProvider, connectionProvider, _) {
                      final isActive = driverProvider.isActivelyDriving;
                      final isOffline = !connectionProvider.isOnline;
                      
                      return ElevatedButton.icon(
                        onPressed: isOffline ? null : onPauseResume,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive ? Colors.orange : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        icon: Icon(isActive ? Icons.pause : Icons.play_arrow),
                        label: Text(isActive ? '일시정지' : '재개'),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // 운행 종료 버튼
                Expanded(
                  child: Consumer<ConnectionProvider>(
                    builder: (context, connectionProvider, _) {
                      final isOffline = !connectionProvider.isOnline;
                      
                      return ElevatedButton.icon(
                        onPressed: isOffline ? null : onFinish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.stop),
                        label: const Text('운행 종료'),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 상태 변경 버튼
            Center(
              child: Consumer<ConnectionProvider>(
                builder: (context, connectionProvider, _) {
                  final isOffline = !connectionProvider.isOnline;
                  
                  return TextButton.icon(
                    onPressed: isOffline 
                        ? null 
                        : () => _showStatusUpdateDialog(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('상태 변경'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 상태 변경 다이얼로그 표시
  void _showStatusUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const StatusUpdateDialog(),
    );
  }
}