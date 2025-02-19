import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'location.dart';

part 'stop.g.dart';

/// 버스 정류장 정보를 나타내는 클래스
@JsonSerializable()
class Stop extends Equatable {
  /// 정류장 고유 식별자
  @JsonKey(name: '_id')
  final String id;
  
  /// 정류장 이름
  final String name;
  
  /// 정류장 위치 정보
  final Location location;
  
  /// 이 정류장을 경유하는 노선 ID 목록
  final List<String> routes;
  
  /// 정류장 시설 정보 (대기실, 벤치 등)
  /// 예: {'hasShelter': true, 'hasBench': true}
  final Map<String, bool>? facilities;
  
  /// 정류장 설명
  final String? description;
  
  /// 정류장 주소
  final String? address;
  
  /// 정류장 이미지 URL
  final String? imageUrl;
  
  /// 추가 메타데이터
  final Map<String, dynamic>? metadata;

  const Stop({
    required this.id,
    required this.name,
    required this.location,
    required this.routes,
    this.facilities,
    this.description,
    this.address,
    this.imageUrl,
    this.metadata,
  });

  /// JSON에서 Stop 객체 생성
  factory Stop.fromJson(Map<String, dynamic> json) => _$StopFromJson(json);
  
  /// Stop 객체를 JSON으로 변환
  Map<String, dynamic> toJson() => _$StopToJson(this);

  @override
  List<Object?> get props => [
    id, 
    name, 
    location, 
    routes, 
    facilities,
    description, 
    address, 
    imageUrl, 
    metadata
  ];

  /// 새로운 속성으로 복사본 생성
  Stop copyWith({
    String? id,
    String? name,
    Location? location,
    List<String>? routes,
    Map<String, bool>? facilities,
    String? description,
    String? address,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return Stop(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      routes: routes ?? this.routes,
      facilities: facilities ?? this.facilities,
      description: description ?? this.description,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}