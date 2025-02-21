// 앱 내부에서 사용할 사용자 모델
// shared 패키지의 User 모델을 확장하여 앱에 필요한 추가 기능 제공

import 'package:shared/models/user.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? licenseNumber;
  final String? phoneNumber;
  final String? profileImageUrl;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  
  // 파생 속성
  bool get isDriver => role == 'DRIVER';
  String get displayName => name;
  String get initials => name.isNotEmpty 
      ? name.split(' ').map((part) => part.isNotEmpty ? part[0] : '').join()
      : '';
  
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.licenseNumber,
    this.phoneNumber,
    this.profileImageUrl,
    required this.isActive,
    this.lastLoginAt,
    this.createdAt,
  });
  
  // shared 패키지의 User 모델로부터 변환
  factory UserModel.fromUser(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role.toString().split('.').last,
      licenseNumber: user.licenseNumber,
      phoneNumber: user.phoneNumber,
      profileImageUrl: user.profileImageUrl,
      isActive: user.isActive,
      lastLoginAt: user.lastLoginAt,
      createdAt: user.createdAt,
    );
  }
  
  // JSON에서 변환
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      licenseNumber: json['licenseNumber'],
      phoneNumber: json['phoneNumber'],
      profileImageUrl: json['profileImageUrl'],
      isActive: json['isActive'] ?? true,
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt']) 
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
  
  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'licenseNumber': licenseNumber,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'isActive': isActive,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
  
  // 새 속성으로 복사본 생성
  UserModel copyWith({
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      licenseNumber: licenseNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive,
      lastLoginAt: lastLoginAt,
      createdAt: createdAt,
    );
  }
}