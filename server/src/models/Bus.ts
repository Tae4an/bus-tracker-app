import mongoose, { Document, Schema } from 'mongoose';
import { BusStatus, ObjectId, GeoPoint } from './types';

// 버스 인터페이스
export interface IBus extends Document {
  routeId: ObjectId;
  driverId?: ObjectId;
  status: BusStatus;
  capacity: number;
  plateNumber: string;
  lastLocation: GeoPoint;
  lastUpdated: Date;
  displayName?: string;
  description?: string;
  imageUrl?: string;
  metadata?: Map<string, any>;
  createdAt: Date;
  updatedAt: Date;
}

// 버스 스키마 정의
const busSchema = new Schema<IBus>(
  {
    routeId: {
      type: Schema.Types.ObjectId,
      ref: 'Route',
      required: [true, '노선 ID는 필수입니다'],
    },
    driverId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    status: {
      type: String,
      enum: Object.values(BusStatus),
      default: BusStatus.IDLE,
    },
    capacity: {
      type: Number,
      required: [true, '버스 수용 인원은 필수입니다'],
      min: [1, '수용 인원은 최소 1명 이상이어야 합니다'],
    },
    plateNumber: {
      type: String,
      required: [true, '차량 번호는 필수입니다'],
      unique: true,
      trim: true,
    },
    lastLocation: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        default: [0, 0],
      },
    },
    lastUpdated: {
      type: Date,
      default: Date.now,
    },
    displayName: {
      type: String,
      trim: true,
    },
    description: {
      type: String,
      trim: true,
    },
    imageUrl: {
      type: String,
      trim: true,
    },
    metadata: {
      type: Map,
      of: Schema.Types.Mixed,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// 지리적 인덱스 추가
busSchema.index({ lastLocation: '2dsphere' });
busSchema.index({ plateNumber: 1 });

// 버스 정보에 현재 위치 정보 추가 가상 필드
busSchema.virtual('location').get(function (this: IBus) {
  if (this.lastLocation?.coordinates) {
    return {
      longitude: this.lastLocation.coordinates[0],
      latitude: this.lastLocation.coordinates[1]
    };
  }
  return null;
});

export default mongoose.model<IBus>('Bus', busSchema);