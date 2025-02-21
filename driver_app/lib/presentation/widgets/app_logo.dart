// 앱 로고 위젯
// 앱 로고를 표시하는 재사용 가능한 위젯

import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  
  const AppLogo({
    super.key,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.directions_bus_rounded,
            color: theme.colorScheme.onPrimary,
            size: size * 0.6,
          ),
        ),
      ),
    );
  }
}