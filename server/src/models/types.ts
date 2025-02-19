import { Document, Types } from 'mongoose';

// MongoDB Document ID 타입
export type ObjectId = Types.ObjectId;

// 버스 상태 열거형
export enum BusStatus {
  ACTIVE = 'ACTIVE',
  IDLE = 'IDLE',
  MAINTENANCE = 'MAINTENANCE',
  OUT_OF_SERVICE = 'OUT_OF_SERVICE'
}

// 사용자 역할 열거형
export enum UserRole {
  PASSENGER = 'PASSENGER',
  DRIVER = 'DRIVER',
  ADMIN = 'ADMIN'
}

// 요일 타입 열거형
export enum DayType {
  WEEKDAY = 'WEEKDAY',
  SATURDAY = 'SATURDAY',
  SUNDAY = 'SUNDAY',
  HOLIDAY = 'HOLIDAY'
}

// 지리적 좌표 인터페이스
export interface GeoPoint {
  type: 'Point';
  coordinates: [number, number]; // [longitude, latitude]
}

// 시설 정보 인터페이스
export interface Facilities {
  hasShelter?: boolean;
  hasBench?: boolean;
  hasLighting?: boolean;
  hasElectronicDisplay?: boolean;
  isAccessible?: boolean;
}