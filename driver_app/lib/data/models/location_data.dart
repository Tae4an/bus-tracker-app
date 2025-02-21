// 위치 데이터 모델
// 위치 추적 서비스에서 사용하는 위치 정보 모델

import 'package:shared/models/location.dart';

class LocationData {
 final String busId;
 final double latitude;
 final double longitude;
 final double? speed;
 final double? heading;
 final double? accuracy;
 final DateTime timestamp;
 
 LocationData({
   required this.busId,
   required this.latitude,
   required this.longitude,
   this.speed,
   this.heading,
   this.accuracy,
   required this.timestamp,
 });
 
 // JSON으로 변환
 Map<String, dynamic> toJson() {
   return {
     'busId': busId,
     'latitude': latitude,
     'longitude': longitude,
     'speed': speed,
     'heading': heading,
     'accuracy': accuracy,
     'timestamp': timestamp.toIso8601String(),
   };
 }
 
 // JSON에서 변환
 factory LocationData.fromJson(Map<String, dynamic> json) {
   return LocationData(
     busId: json['busId'],
     latitude: json['latitude'],
     longitude: json['longitude'],
     speed: json['speed'],
     heading: json['heading'],
     accuracy: json['accuracy'],
     timestamp: DateTime.parse(json['timestamp']),
   );
 }
 
 // 데이터베이스 저장용 맵으로 변환
 Map<String, dynamic> toMap() {
   return {
     'busId': busId,
     'latitude': latitude,
     'longitude': longitude,
     'speed': speed ?? 0.0,
     'heading': heading ?? 0.0,
     'accuracy': accuracy ?? 0.0,
     'timestamp': timestamp.millisecondsSinceEpoch,
   };
 }
 
 // 데이터베이스 맵에서 변환
 factory LocationData.fromMap(Map<String, dynamic> map) {
   return LocationData(
     busId: map['busId'],
     latitude: map['latitude'],
     longitude: map['longitude'],
     speed: map['speed'],
     heading: map['heading'],
     accuracy: map['accuracy'],
     timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
   );
 }
 
 // shared 패키지의 Location 객체로 변환
 Location toSharedLocation() {
   return Location(
     latitude: latitude,
     longitude: longitude,
     accuracy: accuracy,
     heading: heading,
     speed: speed,
     timestamp: timestamp,
   );
 }
}