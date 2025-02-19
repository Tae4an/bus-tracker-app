import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'schedule_entry.dart';

part 'route.g.dart';

/// 버스 노선 운행 요일 타입
enum DayType {
  /// 평일 (월~금)
  WEEKDAY,
  
  /// 토요일
  SATURDAY,
  
  /// 일요일
  SUNDAY,
  
  /// 공휴일
  HOLIDAY
}

/// DayType 열거형에 확장 기능 추가
extension DayTypeExtension on DayType {
  /// JSON 직렬화를 위한 문자열 반환
  String toJson() => toString().split('.').last;
  
  /// 문자열에서 DayType 열거형으로 변환
  static DayType fromJson(String json) {
    return DayType.values.firstWhere(
      (type) => type.toString().split('.').last == json,
      orElse: () => DayType.WEEKDAY, // 기본값으로 WEEKDAY 반환
    );
  }
}

/// 노선의 요일별 시간표를 나타내는 클래스
@JsonSerializable()
class RouteSchedule extends Equatable {
  /// 요일 유형 (평일, 토요일, 일요일, 공휴일)
  @JsonKey(
    fromJson: DayTypeExtension.fromJson,
    toJson: _dayTypeToJson,
  )
  final DayType dayType;
  
  /// 시간표 항목 목록 (정류장별 도착/출발 시간)
  final List<ScheduleEntry> entries;
  
  /// DayType을 JSON 문자열로 변환
  static String _dayTypeToJson(DayType dayType) => dayType.toJson();
  
  const RouteSchedule({
    required this.dayType,
    required this.entries,
  });
  
  /// JSON에서 RouteSchedule 객체 생성
  factory RouteSchedule.fromJson(Map<String, dynamic> json) => _$RouteScheduleFromJson(json);
  
  /// RouteSchedule 객체를 JSON으로 변환
  Map<String, dynamic> toJson() => _$RouteScheduleToJson(this);
  
  @override
  List<Object> get props => [dayType, entries];
}

/// 버스 노선 정보를 나타내는 클래스
@JsonSerializable()
class Route extends Equatable {
  /// 노선 고유 식별자
  @JsonKey(name: '_id')
  final String id;
  
  /// 노선 이름 (예: "A노선", "캠퍼스 순환")
  final String name;
  
  /// 노선 설명
  final String? description;
  
  /// 정류장 ID 목록 (순서대로)
  final List<String> stops;
  
  /// 요일별 시간표 목록
  final List<RouteSchedule>? schedules;
  
  /// 현재 운행 여부
  final bool active;
  
  /// UI 표시용 색상 (HEX 코드)
  final String? color;
  
  /// 기본 요금
  final double? fareAmount;
  
  /// 요금 유형 (기본, 거리비례 등)
  final String? fareType;
  
  /// 추가 메타데이터
  final Map<String, dynamic>? metadata;
  
  const Route({
    required this.id,
    required this.name,
    this.description,
    required this.stops,
    this.schedules,
    required this.active,
    this.color,
    this.fareAmount,
    this.fareType,
    this.metadata,
  });
  
  /// JSON에서 Route 객체 생성
  factory Route.fromJson(Map<String, dynamic> json) => _$RouteFromJson(json);
  
  /// Route 객체를 JSON으로 변환
  Map<String, dynamic> toJson() => _$RouteToJson(this);
  
  @override
  List<Object?> get props => [
    id, 
    name, 
    description, 
    stops, 
    schedules,
    active, 
    color, 
    fareAmount, 
    fareType, 
    metadata
  ];
  
  /// 새로운 속성으로 복사본 생성
  Route copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? stops,
    List<RouteSchedule>? schedules,
    bool? active,
    String? color,
    double? fareAmount,
    String? fareType,
    Map<String, dynamic>? metadata,
  }) {
    return Route(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      stops: stops ?? this.stops,
      schedules: schedules ?? this.schedules,
      active: active ?? this.active,
      color: color ?? this.color,
      fareAmount: fareAmount ?? this.fareAmount,
      fareType: fareType ?? this.fareType,
      metadata: metadata ?? this.metadata,
    );
  }
}