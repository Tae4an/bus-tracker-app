// 버스 상태 변경 다이얼로그
// 버스의 운행 상태를 변경할 수 있는 UI 제공

import 'package:driver_app/presentation/providers/auth_provider.dart';
import 'package:driver_app/presentation/providers/driver_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/models/bus_status.dart';

class StatusUpdateDialog extends StatefulWidget {
  const StatusUpdateDialog({super.key});

  @override
  State<StatusUpdateDialog> createState() => _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends State<StatusUpdateDialog> {
  late BusStatus _selectedStatus;
  bool _isUpdating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 현재 버스 상태로 초기화
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    _selectedStatus = driverProvider.assignedBus?.status ?? BusStatus.IDLE;
  }

  // 상태 업데이트 요청
  Future<void> _updateStatus() async {
    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
      
      if (authProvider.token == null || driverProvider.assignedBus == null) {
        throw Exception('인증 정보 또는 버스 정보가 없습니다');
      }
      
      final success = await driverProvider.updateBusStatus(
        driverProvider.assignedBus!.id,
        _selectedStatus,
        authProvider.token!,
      );
      
      if (success && mounted) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _errorMessage = '상태 업데이트에 실패했습니다';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '상태 업데이트 중 오류가 발생했습니다';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('버스 상태 변경'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상태 선택 라디오 버튼
          RadioListTile<BusStatus>(
            title: const Text('운행 중'),
            subtitle: const Text('승객이 탑승 가능한 상태'),
            value: BusStatus.ACTIVE,
            groupValue: _selectedStatus,
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
              });
            },
          ),
          RadioListTile<BusStatus>(
            title: const Text('대기 중'),
            subtitle: const Text('일시적으로 운행 중단 상태'),
            value: BusStatus.IDLE,
            groupValue: _selectedStatus,
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
              });
            },
          ),
          RadioListTile<BusStatus>(
            title: const Text('정비 중'),
            subtitle: const Text('차량 점검 중으로 운행 불가'),
            value: BusStatus.MAINTENANCE,
            groupValue: _selectedStatus,
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
              });
            },
          ),
          RadioListTile<BusStatus>(
            title: const Text('운행 중단'),
            subtitle: const Text('고장/사고 등으로 장기 운행 불가'),
            value: BusStatus.OUT_OF_SERVICE,
            groupValue: _selectedStatus,
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
              });
            },
          ),
          
          // 오류 메시지
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _isUpdating ? null : _updateStatus,
          child: _isUpdating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('변경하기'),
        ),
      ],
    );
  }
}