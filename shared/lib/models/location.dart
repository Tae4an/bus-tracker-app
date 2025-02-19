import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'location.g.dart';

/// 위치 정보를 나타내는 클래스
/// 버스 및 정류장의 위치 데이터를 표현하는데 사용됨
@JsonSerializable()
class Location extends Equatable {
  /// 위도 (북위/남위)
  final double latitude;
  
  /// 경도 (동경/서경)
  final double longitude;
  
  /// GPS 정확도 (미터 단위)
  final double? accuracy;
  
  /// 고도 (미터 단위)
  final double? altitude;
  
  /// 이동 방향 (0-359도, 북쪽이 0도)
  final double? heading;
  
  /// 이동 속도 (m/s)
  final double? speed;
  
  /// 데이터 수집 시간
  final DateTime? timestamp;

  const Location({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.heading,
    this.speed,
    this.timestamp,
  });

  /// JSON에서 Location 객체 생성
  /// MongoDB의 GeoJSON 형식도 처리 가능
  factory Location.fromJson(Map<String, dynamic> json) {
    // MongoDB GeoJSON 포맷 처리 (Point 타입)
    if (json['type'] == 'Point' && json['coordinates'] is List) {
      return Location(
        // MongoDB에서는 [longitude, latitude] 순서로 저장
        longitude: json['coordinates'][0],
        latitude: json['coordinates'][1],
      );
    }
    
    return _$LocationFromJson(json);
  }

  /// Location 객체를 JSON으로 변환
  Map<String, dynamic> toJson() => _$LocationToJson(this);

  /// MongoDB GeoJSON 포맷으로 변환
  /// 지리적 인덱싱 및 쿼리에 사용됨
  Map<String, dynamic> toGeoJson() {
    return {
      'type': 'Point',
      'coordinates': [longitude, latitude], // 주의: MongoDB는 [lng, lat] 순서
    };
  }

  @override
  List<Object?> get props => [
    latitude, 
    longitude, 
    accuracy, 
    altitude, 
    heading, 
    speed, 
    timestamp
  ];

  /// 새로운 속성으로 복사본 생성
  Location copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? heading,
    double? speed,
    DateTime? timestamp,
  }) {
    return Location(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}