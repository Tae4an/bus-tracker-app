import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'auth_response.g.dart';

/// 인증 응답 정보를 나타내는 클래스
/// 로그인/회원가입 성공 시 서버에서 반환되는 데이터
@JsonSerializable()
class AuthResponse extends Equatable {
  /// JWT 인증 토큰
  final String token;
  
  /// 로그인한 사용자 정보
  final User user;
  
  /// 토큰 만료 시간
  final DateTime expiresAt;
  
  const AuthResponse({
    required this.token,
    required this.user,
    required this.expiresAt,
  });
  
  /// JSON에서 AuthResponse 객체 생성
  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  
  /// AuthResponse 객체를 JSON으로 변환
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
  
  @override
  List<Object> get props => [token, user, expiresAt];
}