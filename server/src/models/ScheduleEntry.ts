import { Schema } from 'mongoose';

// 시간 구조 (분 단위로 저장)
export interface IScheduleTime {
  minutes: number;
}

const scheduleTimeSchema = new Schema<IScheduleTime>(
  {
    minutes: {
      type: Number,
      required: true,
      min: 0,
      max: 1439, // 0-1439분 (24시간)
    },
  },
  { _id: false }
);

// 시간표 항목 인터페이스
export interface IScheduleEntry {
  stopId: Schema.Types.ObjectId;
  arrivalTime: IScheduleTime;
  departureTime?: IScheduleTime;
  isTimingPoint: boolean;
}

// 시간표 항목 스키마
export const scheduleEntrySchema = new Schema<IScheduleEntry>(
  {
    stopId: {
      type: Schema.Types.ObjectId,
      ref: 'Stop',
      required: true,
    },
    arrivalTime: {
      type: scheduleTimeSchema,
      required: true,
    },
    departureTime: {
      type: scheduleTimeSchema,
    },
    isTimingPoint: {
      type: Boolean,
      default: false,
    },
  },
  { _id: false }
);