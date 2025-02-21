// 프로필 편집 폼
// 사용자 정보 수정을 위한 양식 위젯

import 'package:driver_app/data/models/user_model.dart';
import 'package:flutter/material.dart';

class ProfileEditForm extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onSaved;
  final VoidCallback onCancel;

  const ProfileEditForm({
    super.key,
    required this.user,
    required this.onSaved,
    required this.onCancel,
  });

  @override
  State<ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends State<ProfileEditForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  
  @override
  void initState() {
    super.initState();
    // 컨트롤러 초기화
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
  }
  
  @override
  void dispose() {
    // 컨트롤러 해제
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  // 변경사항 저장
  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      // 업데이트된 사용자 모델 생성
      final updatedUser = widget.user.copyWith(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
      );
      
      // 저장 콜백 호출
      widget.onSaved(updatedUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 프로필 이미지 (편집 불가)
            _buildProfileImage(),
            const SizedBox(height: 32),
            
            // 폼 필드
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이름 필드
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '이름',
                        hintText: '이름을 입력하세요',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '이름을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 전화번호 필드
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: '전화번호',
                        hintText: '전화번호를 입력하세요',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          // 간단한 전화번호 형식 검증
                          if (!RegExp(r'^\d{2,3}-?\d{3,4}-?\d{4}$').hasMatch(value)) {
                            return '유효한 전화번호 형식이 아닙니다';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 수정 불가능한 정보 섹션
                    const Divider(height: 32),
                    Text(
                      '수정할 수 없는 정보',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 이메일 (수정 불가)
                    _buildReadOnlyField(
                      label: '이메일',
                      value: widget.user.email,
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),
                    
                    // 면허번호 (수정 불가)
                    _buildReadOnlyField(
                      label: '면허번호',
                      value: widget.user.licenseNumber ?? '등록되지 않음',
                      icon: Icons.badge_outlined,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // 저장/취소 버튼
            Row(
              children: [
                // 취소 버튼
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 16),
                
                // 저장 버튼
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: const Text('저장'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 프로필 이미지 위젯
  Widget _buildProfileImage() {
    final theme = Theme.of(context);
    final size = 120.0;
    
    return Stack(
      children: [
        // 이미지
        CircleAvatar(
          radius: size / 2,
          backgroundColor: theme.colorScheme.primary,
          backgroundImage: widget.user.profileImageUrl != null
              ? NetworkImage(widget.user.profileImageUrl!)
              : null,
          child: widget.user.profileImageUrl == null
              ? Text(
                  widget.user.initials,
                  style: TextStyle(
                    fontSize: size / 3,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : null,
        ),
        
        // 이미지 변경 버튼 (현재 구현은 디자인만 - 실제 기능 없음)
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.background,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.photo_camera,
              size: 20,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
  
  // 읽기 전용 필드 위젯
  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
        ),
      ),
      style: TextStyle(
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),
    );
  }
}