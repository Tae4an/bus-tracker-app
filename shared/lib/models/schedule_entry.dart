import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'schedule_time.dart';

part 'schedule_entry.g.dart';

/// 시간표의 각 항목을 나타내는 클래스
/// 특정 정류장의 도착/출발 시간 정보 포함
@JsonSerializable()
class ScheduleEntry extends Equatable {
  /// 정류장 ID
  final String stopId;
  
  /// 도착 예정 시간
  final ScheduleTime arrivalTime;
  
  /// 출발 예정 시간 (종점이 아닌 경우)
  final ScheduleTime? departureTime;
  
  /// 주요 정차지 여부 (시간 정확도가 중요한 정류장)
  /// 주요 정차지는 시간표 지연 계산의 기준점으로 사용됨
  final bool isTimingPoint;
  
  const ScheduleEntry({
    required this.stopId,
    required this.arrivalTime,
    this.departureTime,
    this.isTimingPoint = false,
  });
  
  /// JSON에서 ScheduleEntry 객체 생성
  factory ScheduleEntry.fromJson(Map<String, dynamic> json) => _$ScheduleEntryFromJson(json);
  
  /// ScheduleEntry 객체를 JSON으로 변환
  Map<String, dynamic> toJson() => _$ScheduleEntryToJson(this);
  
  @override
  List<Object?> get props => [stopId, arrivalTime, departureTime, isTimingPoint];
  
  /// 새로운 속성으로 복사본 생성
  ScheduleEntry copyWith({
    String? stopId,
    ScheduleTime? arrivalTime,
    ScheduleTime? departureTime,
    bool? isTimingPoint,
  }) {
    return ScheduleEntry(
      stopId: stopId ?? this.stopId,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureTime: departureTime ?? this.departureTime,
      isTimingPoint: isTimingPoint ?? this.isTimingPoint,
    );
  }
}