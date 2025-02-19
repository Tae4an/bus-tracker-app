import mongoose, { Document, Schema } from 'mongoose';
import { ObjectId, DayType } from './types';
import { IScheduleEntry, scheduleEntrySchema } from './ScheduleEntry';

// 노선 시간표 인터페이스
export interface IRouteSchedule {
  dayType: DayType;
  entries: IScheduleEntry[];
}

// 노선 시간표 스키마
const routeScheduleSchema = new Schema<IRouteSchedule>(
  {
    dayType: {
      type: String,
      enum: Object.values(DayType),
      required: true,
    },
    entries: [scheduleEntrySchema],
  },
  { _id: false }
);

// 노선 인터페이스
export interface IRoute extends Document {
  name: string;
  description?: string;
  stops: ObjectId[]; // 정류장 ID 목록 (순서대로)
  schedules?: IRouteSchedule[]; // 요일별 시간표
  active: boolean;
  color?: string; // UI 표시용 색상 (HEX)
  fareAmount?: number; // 요금
  fareType?: string; // 요금 유형 (기본, 거리비례 등)
  metadata?: Map<string, any>;
  createdAt: Date;
  updatedAt: Date;
}

// 노선 스키마 정의
const routeSchema = new Schema<IRoute>(
  {
    name: {
      type: String,
      required: [true, '노선 이름은 필수입니다'],
      trim: true,
    },
    description: {
      type: String,
      trim: true,
    },
    stops: [
      {
        type: Schema.Types.ObjectId,
        ref: 'Stop',
        required: [true, '노선에는 최소 하나 이상의 정류장이 필요합니다'],
      },
    ],
    schedules: [routeScheduleSchema],
    active: {
      type: Boolean,
      default: true,
    },
    color: {
      type: String,
      match: [/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/, '유효한 HEX 색상 코드를 입력하세요'],
    },
    fareAmount: {
      type: Number,
      min: 0,
    },
    fareType: {
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

// 인덱스 추가
routeSchema.index({ name: 1 });
routeSchema.index({ active: 1 });

// 정류장 수 가상 필드
routeSchema.virtual('stopCount').get(function (this: IRoute) {
  return this.stops.length;
});

export default mongoose.model<IRoute>('Route', routeSchema);