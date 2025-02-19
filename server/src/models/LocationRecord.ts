import mongoose, { Document, Schema } from 'mongoose';
import { ObjectId, GeoPoint } from './types';

// 위치 기록 인터페이스
export interface ILocationRecord extends Document {
  busId: ObjectId;
  location: GeoPoint;
  speed?: number;
  heading?: number;
  accuracy?: number;
  timestamp: Date;
  metadata?: Map<string, any>;
  createdAt: Date;
}

// 위치 기록 스키마 정의
const locationRecordSchema = new Schema<ILocationRecord>(
  {
    busId: {
      type: Schema.Types.ObjectId,
      ref: 'Bus',
      required: [true, '버스 ID는 필수입니다'],
    },
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: [true, '위치 좌표는 필수입니다'],
      },
    },
    speed: {
      type: Number,
      min: 0,
    },
    heading: {
      type: Number,
      min: 0,
      max: 359.99,
    },
    accuracy: {
      type: Number,
      min: 0,
    },
    timestamp: {
      type: Date,
      default: Date.now,
      required: [true, '타임스탬프는 필수입니다'],
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

// 인덱스 추가
locationRecordSchema.index({ location: '2dsphere' });
locationRecordSchema.index({ busId: 1, timestamp: -1 });
locationRecordSchema.index({ timestamp: 1 });

// TTL 인덱스: 30일 후 자동 삭제
locationRecordSchema.index({ createdAt: 1 }, { expireAfterSeconds: 60 * 60 * 24 * 30 });

// 가상 필드: 위도/경도
locationRecordSchema.virtual('latitude').get(function (this: ILocationRecord) {
  return this.location.coordinates[1];
});

locationRecordSchema.virtual('longitude').get(function (this: ILocationRecord) {
  return this.location.coordinates[0];
});

export default mongoose.model<ILocationRecord>('LocationRecord', locationRecordSchema);