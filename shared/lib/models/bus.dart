import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'location.dart';
import 'bus_status.dart';

part 'bus.g.dart';

/// 버스 정보를 나타내는 클래스
/// 각 셔틀버스의 기본 정보와 현재 상태를 포함
@JsonSerializable()
class Bus extends Equatable {
  /// 버스 고유 식별자
  @JsonKey(name: '_id')
  final String id;
  
  /// 버스가 운행 중인 노선 ID
  final String routeId;
  
  /// 현재 운전 중인 기사 ID (운행 중이 아닐 경우 null)
  final String? driverId;
  
  /// 버스 현재 운행 상태
  @JsonKey(
    fromJson: BusStatusExtension.fromJson,
    toJson: _busStatusToJson,
  )
  final BusStatus status;
  
  /// 최대 승객 수용 인원
  final int capacity;
  
  /// 차량 번호판
  final String plateNumber;
  
  /// 마지막으로 기록된 위치 정보
  @JsonKey(name: 'lastLocation')
  final Location? location;
  
  /// 마지막 위치 업데이트 시간
  final DateTime lastUpdated;
  
  /// 버스 표시 이름 (예: "1번 셔틀")
  final String? displayName;
  
  /// 버스 설명 (예: "메인 캠퍼스 순환")
  final String? description;
  
  /// 버스 이미지 URL
  final String? imageUrl;
  
  /// 추가 메타데이터 (확장성 제공)
  final Map<String, dynamic>? metadata;

  /// BusStatus를 JSON 문자열로 변환
  static String _busStatusToJson(BusStatus status) => status.toJson();

  const Bus({
    required this.id,
    required this.routeId,
    this.driverId,
    required this.status,
    required this.capacity,
    required this.plateNumber,
    this.location,
    required this.lastUpdated,
    this.displayName,
    this.description,
    this.imageUrl,
    this.metadata,
  });

  /// JSON에서 Bus 객체 생성
  factory Bus.fromJson(Map<String, dynamic> json) => _$BusFromJson(json);
  
  /// Bus 객체를 JSON으로 변환
  Map<String, dynamic> toJson() => _$BusToJson(this);

  @override
  List<Object?> get props => [
    id, 
    routeId, 
    driverId, 
    status, 
    capacity,
    plateNumber, 
    location, 
    lastUpdated, 
    displayName,
    description, 
    imageUrl, 
    metadata
  ];

  /// 새로운 속성으로 복사본 생성
  Bus copyWith({
    String? id,
    String? routeId,
    String? driverId,
    BusStatus? status,
    int? capacity,
    String? plateNumber,
    Location? location,
    DateTime? lastUpdated,
    String? displayName,
    String? description,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return Bus(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      capacity: capacity ?? this.capacity,
      plateNumber: plateNumber ?? this.plateNumber,
      location: location ?? this.location,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}