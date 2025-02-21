// 앱 내비게이션 드로어
// 앱 내 주요 화면으로 이동하는 네비게이션 메뉴

import 'package:driver_app/presentation/providers/auth_provider.dart';
import 'package:driver_app/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Drawer(
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;
          
          if (user == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          return Column(
            children: [
              // 헤더
              UserAccountsDrawerHeader(
                currentAccountPicture: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                accountName: Text(user.name),
                accountEmail: Text(user.email),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                ),
              ),
              
              // 메뉴 항목
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('홈'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('프로필'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(AppRoutes.profile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('운행 기록'),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: 운행 기록 화면으로 이동
                  _showFeatureNotImplemented(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('알림'),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: 알림 화면으로 이동
                  _showFeatureNotImplemented(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('설정'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(AppRoutes.settings);
                },
              ),
              
              const Divider(),
              
              // 버전 정보
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('앱 정보'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAboutDialog(context);
                },
              ),
              
              const Spacer(),
              
              // 로그아웃 버튼
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('로그아웃'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 구현되지 않은 기능 알림
  void _showFeatureNotImplemented(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('아직 구현되지 않은 기능입니다'),
      ),
    );
  }
  
  // 앱 정보 다이얼로그
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: '셔틀버스 기사용 앱',
        applicationVersion: '1.0.0',
        applicationIcon: const Icon(
          Icons.directions_bus,
          size: 48,
          color: Colors.blue,
        ),
        children: const [
          SizedBox(height: 16),
          Text('실시간 셔틀버스 위치 추적 시스템의 기사용 앱입니다.'),
          SizedBox(height: 8),
          Text('© 2025 셔틀버스 프로젝트'),
        ],
      ),
    );
  }
  
  // 로그아웃 확인 다이얼로그
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout(context);
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
  
  // 로그아웃 처리
  void _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }
}