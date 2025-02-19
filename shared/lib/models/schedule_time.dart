import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

part 'schedule_time.g.dart';

/// 시간표에 사용되는 시간 정보 클래스
/// 하루 중 특정 시간을 분 단위로 저장하여 효율적인 계산 지원
@JsonSerializable()
class ScheduleTime extends Equatable {
  /// 자정부터 경과한 시간(분) - 하루는 총 1440분
  /// 예: 8:30 AM = 8*60+30 = 510분
  final int minutes;
  
  const ScheduleTime({required this.minutes});
  
  /// 시간 문자열("HH:mm")에서 ScheduleTime 객체 생성
  factory ScheduleTime.fromTimeString(String timeString) {
    final format = DateFormat('HH:mm');
    final time = format.parse(timeString);
    return ScheduleTime(
      minutes: time.hour * 60 + time.minute,
    );
  }
  
  /// 시간과 분을 직접 지정하여 ScheduleTime 객체 생성
  factory ScheduleTime.fromHourMinute(int hour, int minute) {
    return ScheduleTime(minutes: hour * 60 + minute);
  }
  
  /// 시간을 "HH:mm" 형식 문자열로 변환
  String toTimeString() {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
  
  /// 기준 날짜에 현재 시간을 적용한 DateTime 객체 반환
  DateTime toDateTime([DateTime? referenceDate]) {
    final date = referenceDate ?? DateTime.now();
    return DateTime(
      date.year, 
      date.month, 
      date.day, 
      minutes ~/ 60, 
      minutes % 60
    );
  }
  
  /// JSON에서 ScheduleTime 객체 생성
  factory ScheduleTime.fromJson(Map<String, dynamic> json) => _$ScheduleTimeFromJson(json);
  
  /// ScheduleTime 객체를 JSON으로 변환
  Map<String, dynamic> toJson() => _$ScheduleTimeToJson(this);
  
  @override
  List<Object> get props => [minutes];
  
  /// 새로운 속성으로 복사본 생성
  ScheduleTime copyWith({int? minutes}) {
    return ScheduleTime(minutes: minutes ?? this.minutes);
  }
}