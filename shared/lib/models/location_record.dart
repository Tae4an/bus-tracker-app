import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'location.dart';

part 'location_record.g.dart';

/// 버스 위치 기록을 나타내는 클래스
/// 과거 위치 데이터를 저장하고 분석하는 데 사용됨
@JsonSerializable()
class LocationRecord extends Equatable {
  /// 위치 기록 고유 식별자
  @JsonKey(name: '_id')
  final String id;
  
  /// 해당 버스 ID
  final String busId;
  
  /// 위치 정보
  final Location location;
  
  /// 이동 속도 (m/s)
  final double? speed;
  
  /// 이동 방향 (0-359도)
  final double? heading;
  
  /// GPS 정확도 (미터)
  final double? accuracy;
  
  /// 위치 기록 시간
  final DateTime timestamp;
  
  /// 추가 메타데이터 (날씨, 교통 상황 등)
  final Map<String, dynamic>? metadata;
  
  const LocationRecord({
    required this.id,
    required this.busId,
    required this.location,
    this.speed,
    this.heading,
    this.accuracy,
    required this.timestamp,
    this.metadata,
  });
  
  /// JSON에서 LocationRecord 객체 생성
  factory LocationRecord.fromJson(Map<String, dynamic> json) => _$LocationRecordFromJson(json);
  
  /// LocationRecord 객체를 JSON으로 변환
  Map<String, dynamic> toJson() => _$LocationRecordToJson(this);
  
  @override
  List<Object?> get props => [
    id, 
    busId, 
    location, 
    speed, 
    heading,
    accuracy, 
    timestamp, 
    metadata
  ];
  
/// 새로운 속성으로 복사본 생성
  LocationRecord copyWith({
    String? id,
    String? busId,
    Location? location,
    double? speed,
    double? heading,
    double? accuracy,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return LocationRecord(
      id: id ?? this.id,
      busId: busId ?? this.busId,
      location: location ?? this.location,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }
}