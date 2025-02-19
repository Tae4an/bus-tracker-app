/// 사용자 역할을 나타내는 열거형
enum UserRole {
  /// 일반 승객 - 기본 앱 사용자
  PASSENGER,
  
  /// 버스 기사 - 버스 운행 및 위치 전송 권한
  DRIVER,
  
  /// 관리자 - 시스템 전체 관리 권한
  ADMIN,
}

/// UserRole 열거형에 확장 기능 추가
extension UserRoleExtension on UserRole {
  /// 사용자에게 표시할 한글 역할명 반환
  String get name {
    switch (this) {
      case UserRole.PASSENGER:
        return '승객';
      case UserRole.DRIVER:
        return '기사';
      case UserRole.ADMIN:
        return '관리자';
    }
  }

  /// JSON 직렬화를 위한 문자열 반환
  String toJson() => toString().split('.').last;

  /// 문자열에서 UserRole 열거형으로 변환
  static UserRole fromJson(String json) {
    return UserRole.values.firstWhere(
      (role) => role.toString().split('.').last == json,
      orElse: () => UserRole.PASSENGER, // 기본값으로 PASSENGER 반환
    );
  }
}