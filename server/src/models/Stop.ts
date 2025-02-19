import mongoose, { Document, Schema } from 'mongoose';
import { ObjectId, GeoPoint, Facilities } from './types';

// 정류장 인터페이스
export interface IStop extends Document {
  name: string;
  location: GeoPoint;
  routes: ObjectId[];
  facilities?: Facilities;
  description?: string;
  address?: string;
  imageUrl?: string;
  metadata?: Map<string, any>;
  createdAt: Date;
  updatedAt: Date;
}

// 정류장 스키마 정의
const stopSchema = new Schema<IStop>(
  {
    name: {
      type: String,
      required: [true, '정류장 이름은 필수입니다'],
      trim: true,
    },
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: [true, '정류장 위치는 필수입니다'],
      },
    },
    routes: [
      {
        type: Schema.Types.ObjectId,
        ref: 'Route',
      },
    ],
    facilities: {
      hasShelter: { type: Boolean, default: false },
      hasBench: { type: Boolean, default: false },
      hasLighting: { type: Boolean, default: false },
      hasElectronicDisplay: { type: Boolean, default: false },
      isAccessible: { type: Boolean, default: false },
    },
    description: {
      type: String,
      trim: true,
    },
    address: {
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
stopSchema.index({ location: '2dsphere' });
stopSchema.index({ name: 'text' }); // 텍스트 검색을 위한 인덱스

// 가상 필드: 위도/경도
stopSchema.virtual('latitude').get(function (this: IStop) {
  return this.location?.coordinates?.[1];
});

stopSchema.virtual('longitude').get(function (this: IStop) {
  return this.location?.coordinates?.[0];
});

export default mongoose.model<IStop>('Stop', stopSchema);