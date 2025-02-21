// 앱 설정 화면
// 앱 설정 및 환경설정 관리 UI

import 'package:driver_app/core/utils/battery_optimization_helper.dart';
import 'package:driver_app/presentation/providers/auth_provider.dart';
import 'package:driver_app/presentation/screens/settings/change_password_screen.dart';
import 'package:driver_app/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 설정 상태 변수
  bool _enableNotifications = true;
  bool _enableBackgroundTracking = true;
  bool _enableDataSaving = false;
  int _locationUpdateInterval = 10; // 초 단위
  String _mapType = 'standard';
  bool _isDarkMode = false;
  
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    // 저장된 설정 로드
    _loadSettings();
  }
  
  // 설정 로드
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _enableNotifications = prefs.getBool('enableNotifications') ?? true;
        _enableBackgroundTracking = prefs.getBool('enableBackgroundTracking') ?? true;
        _enableDataSaving = prefs.getBool('enableDataSaving') ?? false;
        _locationUpdateInterval = prefs.getInt('locationUpdateInterval') ?? 10;
        _mapType = prefs.getString('mapType') ?? 'standard';
        _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      });
    } catch (e) {
      // 오류 발생 시 기본값 사용
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 설정 저장
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('enableNotifications', _enableNotifications);
      await prefs.setBool('enableBackgroundTracking', _enableBackgroundTracking);
      await prefs.setBool('enableDataSaving', _enableDataSaving);
      await prefs.setInt('locationUpdateInterval', _locationUpdateInterval);
      await prefs.setString('mapType', _mapType);
      await prefs.setBool('isDarkMode', _isDarkMode);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정이 저장되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('설정 저장 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  
  if (_isLoading) {
    return Scaffold( // const 키워드 제거
      appBar: AppBar(title: Text('설정')),
      body: Center(child: CircularProgressIndicator()),
    );
  }
  
  return Scaffold(
    appBar: AppBar(
      title: const Text('설정'),
    ),
    body: ListView(
      children: [
        // 알림 설정 섹션
        _buildSectionHeader('알림 설정'),
        SwitchListTile(
          title: const Text('알림 사용'),
          subtitle: const Text('앱 알림을 받습니다'),
          value: _enableNotifications,
          onChanged: (value) {
            setState(() {
              _enableNotifications = value;
            });
            _saveSettings();
          },
        ),
        
        // 위치 추적 설정 섹션
        _buildSectionHeader('위치 추적 설정'),
        SwitchListTile(
          title: const Text('백그라운드 위치 추적'),
          subtitle: const Text('앱이 백그라운드에 있을 때도 위치를 전송합니다'),
          value: _enableBackgroundTracking,
          onChanged: (value) {
            setState(() {
              _enableBackgroundTracking = value;
            });
            _saveSettings();
          },
        ),
        ListTile(
          title: const Text('위치 업데이트 간격'),
          subtitle: Text('$_locationUpdateInterval초마다 위치 정보를 전송합니다'),
          trailing: DropdownButton<int>(
            value: _locationUpdateInterval,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 5, child: Text('5초')),
              DropdownMenuItem(value: 10, child: Text('10초')),
              DropdownMenuItem(value: 15, child: Text('15초')),
              DropdownMenuItem(value: 30, child: Text('30초')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _locationUpdateInterval = value;
                });
                _saveSettings();
              }
            },
          ),
        ),
        ListTile(
          title: const Text('배터리 최적화 제외'),
          subtitle: const Text('더 정확한 위치 추적을 위해 배터리 최적화에서 제외'),
          trailing: ElevatedButton(
            onPressed: () async {
              final result = await BatteryOptimizationHelper.requestDisableBatteryOptimization();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result
                          ? '배터리 최적화 제외 설정됨'
                          : '배터리 최적화 제외 설정 실패',
                    ),
                  ),
                );
              }
            },
            child: const Text('설정'),
          ),
        ),
        
        // 데이터 설정 섹션
        _buildSectionHeader('데이터 설정'),
        SwitchListTile(
          title: const Text('데이터 절약 모드'),
          subtitle: const Text('모바일 데이터 사용량을 줄입니다'),
          value: _enableDataSaving,
          onChanged: (value) {
            setState(() {
              _enableDataSaving = value;
            });
            _saveSettings();
          },
        ),
        
        // 지도 설정 섹션
        _buildSectionHeader('지도 설정'),
        ListTile(
          title: const Text('지도 유형'),
          subtitle: Text(_getMapTypeLabel(_mapType)),
          trailing: DropdownButton<String>(
            value: _mapType,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'standard', child: Text('기본')),
              DropdownMenuItem(value: 'satellite', child: Text('위성')),
              DropdownMenuItem(value: 'terrain', child: Text('지형')),
              DropdownMenuItem(value: 'hybrid', child: Text('하이브리드')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _mapType = value;
                });
                _saveSettings();
              }
            },
          ),
        ),
        
        // 앱 설정 섹션
        _buildSectionHeader('앱 설정'),
        SwitchListTile(
          title: const Text('다크 모드'),
          subtitle: const Text('어두운 테마로 변경합니다'),
          value: _isDarkMode,
          onChanged: (value) {
            setState(() {
              _isDarkMode = value;
            });
            _saveSettings();
            // TODO: 테마 변경 적용
          },
        ),
        
        // 계정 설정 섹션
        _buildSectionHeader('계정 설정'),
        ListTile(
          title: const Text('비밀번호 변경'),
          leading: const Icon(Icons.lock_outline),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ChangePasswordScreen(),
              ),
            );
          },
        ),
        ListTile(
          title: const Text('로그아웃'),
          leading: const Icon(Icons.logout),
          onTap: () => _confirmLogout(context),
        ),
        
        // 앱 정보 섹션
        _buildSectionHeader('앱 정보'),
        ListTile(
          title: const Text('버전'),
          subtitle: const Text('1.0.0'),
          leading: const Icon(Icons.info_outline),
        ),
        ListTile(
          title: const Text('이용약관'),
          leading: const Icon(Icons.description_outlined),
          onTap: () {
            // TODO: 이용약관 페이지로 이동
            _showFeatureNotImplemented();
          },
        ),
        ListTile(
          title: const Text('개인정보처리방침'),
          leading: const Icon(Icons.privacy_tip_outlined),
          onTap: () {
            // TODO: 개인정보처리방침 페이지로 이동
            _showFeatureNotImplemented();
          },
        ),
        ListTile(
          title: const Text('오픈소스 라이선스'),
          leading: const Icon(Icons.source_outlined),
          onTap: () {
            // 라이선스 페이지 표시
            showLicensePage(
              context: context,
              applicationName: '셔틀버스 기사용 앱',
              applicationVersion: '1.0.0',
            );
          },
        ),
        
        const SizedBox(height: 32),
      ],
    ),
    );
  }
  
  // 섹션 헤더 위젯
  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Divider(
            color: theme.colorScheme.outline.withOpacity(0.3),
            thickness: 1,
          ),
        ],
      ),
    );
  }
  
  // 지도 유형 레이블 반환
  String _getMapTypeLabel(String type) {
    switch (type) {
      case 'standard':
        return '기본';
      case 'satellite':
        return '위성';
      case 'terrain':
        return '지형';
      case 'hybrid':
        return '하이브리드';
      default:
        return '기본';
    }
  }
  
  // 구현되지 않은 기능 알림
  void _showFeatureNotImplemented() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('아직 구현되지 않은 기능입니다'),
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
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    }
  }
}