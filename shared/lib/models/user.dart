import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user_role.dart';

part 'user.g.dart';

/// 사용자 정보를 나타내는 클래스
@JsonSerializable()
class User extends Equatable {
  /// 사용자 고유 식별자
  @JsonKey(name: '_id')
  final String id;
  
  /// 사용자 이름
  final String name;
  
  /// 이메일 주소 (로그인 ID로 사용)
  final String email;
  
  /// 비밀번호 (API 응답에는 포함되지 않음)
  @JsonKey(includeIfNull: false, includeToJson: false)
  final String? password;
  
  /// 사용자 역할 (승객, 기사, 관리자)
  @JsonKey(
    fromJson: UserRoleExtension.fromJson,
    toJson: _userRoleToJson,
  )
  final UserRole role;
  
  /// 즐겨찾는 노선 ID 목록 (승객용)
  final List<String>? favoriteRoutes;
  
  /// 즐겨찾는 정류장 ID 목록 (승객용)
  final List<String>? favoriteStops;
  
  /// 운전면허 번호 (기사용)
  final String? licenseNumber;
  
  /// 전화번호
  final String? phoneNumber;
  
  /// 프로필 이미지 URL
  final String? profileImageUrl;
  
  /// 계정 활성화 상태
  @JsonKey(defaultValue: true)
  final bool isActive;

  /// 계정 생성 일시
  @JsonKey(defaultValue: null)
  final DateTime? createdAt;
    
  /// 마지막 로그인 일시
  final DateTime? lastLoginAt;
  
  /// UserRole을 JSON 문자열로 변환
  static String _userRoleToJson(UserRole role) => role.toJson();
  
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.password,
    required this.role,
    this.favoriteRoutes,
    this.favoriteStops,
    this.licenseNumber,
    this.phoneNumber,
    this.profileImageUrl,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
  });
  
  /// JSON에서 User 객체 생성
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '', // id와 _id 모두 체크
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'],
      role: UserRoleExtension.fromJson(json['role']),
      favoriteRoutes: (json['favoriteRoutes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      favoriteStops: (json['favoriteStops'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      licenseNumber: json['licenseNumber'],
      phoneNumber: json['phoneNumber'],
      profileImageUrl: json['profileImageUrl'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] == null
          ? null
          : DateTime.parse(json['lastLoginAt'] as String),
    );
  }  
  /// User 객체를 JSON으로 변환
  Map<String, dynamic> toJson() => _$UserToJson(this);
  
  @override
  List<Object?> get props => [
    id, 
    name, 
    email, 
    role, 
    favoriteRoutes,
    favoriteStops, 
    licenseNumber, 
    phoneNumber, 
    profileImageUrl,
    isActive, 
    createdAt, 
    lastLoginAt
  ];
  
  /// 새로운 속성으로 복사본 생성
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    UserRole? role,
    List<String>? favoriteRoutes,
    List<String>? favoriteStops,
    String? licenseNumber,
    String? phoneNumber,
    String? profileImageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      favoriteRoutes: favoriteRoutes ?? this.favoriteRoutes,
      favoriteStops: favoriteStops ?? this.favoriteStops,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}