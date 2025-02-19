/// 버스 운행 상태를 나타내는 열거형
enum BusStatus {
  /// 운행 중 - 정상적으로 노선을 운행하는 상태
  ACTIVE,
  
  /// 대기 중 - 운행 시작 전이거나 일시적으로 운행을 중단한 상태
  IDLE,
  
  /// 정비 중 - 차량 점검이나 수리로 인해 운행할 수 없는 상태
  MAINTENANCE,
  
  /// 운행 중단 - 고장이나 사고 등으로 장기간 운행이 불가능한 상태
  OUT_OF_SERVICE,
}

/// BusStatus 열거형에 확장 기능 추가
extension BusStatusExtension on BusStatus {
  /// 사용자에게 표시할 한글 상태명 반환
  String get name {
    switch (this) {
      case BusStatus.ACTIVE:
        return '운행 중';
      case BusStatus.IDLE:
        return '대기 중';
      case BusStatus.MAINTENANCE:
        return '정비 중';
      case BusStatus.OUT_OF_SERVICE:
        return '운행 중단';
    }
  }

  /// JSON 직렬화를 위한 문자열 반환
  String toJson() => toString().split('.').last;

  /// 문자열에서 BusStatus 열거형으로 변환
  static BusStatus fromJson(String json) {
    return BusStatus.values.firstWhere(
      (status) => status.toString().split('.').last == json,
      orElse: () => BusStatus.IDLE, // 기본값으로 IDLE 반환
    );
  }
}