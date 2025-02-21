// 기사 프로필 화면
// 사용자 정보 표시 및 편집 기능 제공

import 'package:driver_app/core/api/user_api.dart';
import 'package:driver_app/data/models/user_model.dart';
import 'package:driver_app/presentation/providers/auth_provider.dart';
import 'package:driver_app/presentation/widgets/profile/profile_edit_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  bool _isEditing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        actions: [
          // 편집 모드 토글 버튼
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (_isEditing) {
                return IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: '편집 취소',
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                    });
                  },
                );
              }
              
              return IconButton(
                icon: const Icon(Icons.edit),
                tooltip: '프로필 편집',
                onPressed: auth.user != null ? () {
                  setState(() {
                    _isEditing = true;
                  });
                } : null,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final user = auth.user;
                
                if (user == null) {
                  return const Center(
                    child: Text('사용자 정보를 불러올 수 없습니다.'),
                  );
                }
                
                return _isEditing
                    ? ProfileEditForm(
                        user: user,
                        onSaved: (updatedUser) {
                          _updateUserProfile(updatedUser);
                          setState(() {
                            _isEditing = false;
                          });
                        },
                        onCancel: () {
                          setState(() {
                            _isEditing = false;
                          });
                        },
                      )
                    : _buildProfileView(user);
              },
            ),
    );
  }
  
  // 프로필 정보 표시 위젯
  Widget _buildProfileView(UserModel user) {
    final theme = Theme.of(context);
    
    return RefreshIndicator(
      onRefresh: _refreshUserProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 프로필 이미지
            _buildProfileImage(user),
            const SizedBox(height: 24),
            
            // 사용자 이름
            Text(
              user.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            
            // 역할
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '기사',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // 오류 메시지
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // 정보 카드
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 이메일
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      title: '이메일',
                      value: user.email,
                    ),
                    const Divider(height: 32),
                    
                    // 전화번호
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      title: '전화번호',
                      value: user.phoneNumber ?? '등록된 번호가 없습니다',
                      valueColor: user.phoneNumber == null
                          ? theme.colorScheme.onSurface.withOpacity(0.5)
                          : null,
                    ),
                    const Divider(height: 32),
                    
                    // 면허번호
                    _buildInfoRow(
                      icon: Icons.badge_outlined,
                      title: '면허번호',
                      value: user.licenseNumber ?? '등록된 면허번호가 없습니다',
                      valueColor: user.licenseNumber == null
                          ? theme.colorScheme.onSurface.withOpacity(0.5)
                          : null,
                    ),
                    const Divider(height: 32),
                    
                    // 가입일
                    _buildInfoRow(
                      icon: Icons.calendar_today_outlined,
                      title: '가입일',
                      value: _formatDate(user.createdAt ?? DateTime.now()),
                    ),
                    if (user.lastLoginAt != null) ...[
                      const Divider(height: 32),
                      // 마지막 로그인
                      _buildInfoRow(
                        icon: Icons.login_outlined,
                        title: '마지막 로그인',
                        value: _formatDate(user.lastLoginAt!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 프로필 이미지 위젯
  Widget _buildProfileImage(UserModel user) {
    final theme = Theme.of(context);
    final size = 120.0;
    
    // 프로필 이미지가 있는 경우
    if (user.profileImageUrl != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(user.profileImageUrl!),
      );
    }
    
    // 프로필 이미지가 없는 경우 이니셜 표시
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.primary,
      child: Text(
        user.initials,
        style: TextStyle(
          fontSize: size / 3,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
  
  // 정보 행 위젯
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
  
  // 프로필 새로고침
  Future<void> _refreshUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userApi = UserApi();
      
      if (authProvider.token != null) {
        final user = await userApi.getUserProfile(authProvider.token!);
        
        // 프로필 업데이트
        if (user != null) {
          authProvider.updateUserProfile(user);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '프로필 정보를 새로고침하는데 실패했습니다';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // 사용자 프로필 업데이트
  Future<void> _updateUserProfile(UserModel updatedUser) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userApi = UserApi();
      
      if (authProvider.token != null) {
        final success = await userApi.updateUserProfile(
          updatedUser,
          authProvider.token!,
        );
        
        if (success) {
          authProvider.updateUserProfile(updatedUser);
        } else {
          setState(() {
            _errorMessage = '프로필 업데이트에 실패했습니다';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '프로필 업데이트 중 오류가 발생했습니다';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}