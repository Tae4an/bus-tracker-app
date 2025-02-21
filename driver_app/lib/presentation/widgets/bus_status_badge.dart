// 버스 상태 표시 배지
// 버스의 현재 운행 상태를 시각적으로 표시

import 'package:flutter/material.dart';
import 'package:shared/models/bus_status.dart';

class BusStatusBadge extends StatelessWidget {
  final BusStatus status;
  final double? size;

  const BusStatusBadge({
    super.key,
    required this.status,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    // 상태별 색상 및 텍스트 설정
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case BusStatus.ACTIVE:
        color = Colors.green;
        text = '운행 중';
        icon = Icons.directions_bus;
        break;
      case BusStatus.IDLE:
        color = Colors.orange;
        text = '대기 중';
        icon = Icons.pause_circle_filled;
        break;
      case BusStatus.MAINTENANCE:
        color = Colors.blue;
        text = '정비 중';
        icon = Icons.build;
        break;
      case BusStatus.OUT_OF_SERVICE:
        color = Colors.red;
        text = '운행 중단';
        icon = Icons.not_interested;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: size ?? 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: size != null ? size! - 2 : 12,
            ),
          ),
        ],
      ),
    );
  }
}