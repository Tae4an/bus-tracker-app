import mongoose, { Document, Schema } from 'mongoose';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { UserRole } from './types';

// 사용자 인터페이스
export interface IUser extends Document {
  name: string;
  email: string;
  password: string;
  role: UserRole;
  favoriteRoutes?: string[];
  favoriteStops?: string[];
  licenseNumber?: string;
  phoneNumber?: string;
  profileImageUrl?: string;
  isActive: boolean;
  lastLoginAt?: Date;
  createdAt: Date;
  updatedAt: Date;
  
  // 인스턴스 메서드
  matchPassword(enteredPassword: string): Promise<boolean>;
  getSignedJwtToken(): string;
}

// 사용자 스키마 정의
const userSchema = new Schema<IUser>(
  {
    name: {
      type: String,
      required: [true, '이름은 필수입니다'],
      trim: true,
    },
    email: {
      type: String,
      required: [true, '이메일은 필수입니다'],
      unique: true,
      match: [
        /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/,
        '유효한 이메일 주소를 입력하세요',
      ],
      lowercase: true,
      trim: true,
    },
    password: {
      type: String,
      required: [true, '비밀번호는 필수입니다'],
      minlength: [6, '비밀번호는 최소 6자 이상이어야 합니다'],
      select: false, // 기본적으로 쿼리 결과에 포함하지 않음
    },
    role: {
      type: String,
      enum: Object.values(UserRole),
      default: UserRole.PASSENGER,
    },
    favoriteRoutes: [
      {
        type: Schema.Types.ObjectId,
        ref: 'Route',
      },
    ],
    favoriteStops: [
      {
        type: Schema.Types.ObjectId,
        ref: 'Stop',
      },
    ],
    licenseNumber: {
      type: String,
      trim: true,
    },
    phoneNumber: {
      type: String,
      trim: true,
    },
    profileImageUrl: {
      type: String,
      trim: true,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    lastLoginAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

// 인덱스 추가
userSchema.index({ email: 1 });
userSchema.index({ role: 1 });

// 저장 전 비밀번호 해싱
userSchema.pre('save', async function (next) {
  // 비밀번호가 변경되지 않았으면 다음 미들웨어로
  if (!this.isModified('password')) {
    return next();
  }

  // 비밀번호 해싱
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// 비밀번호 일치 확인 메서드
userSchema.methods.matchPassword = async function (enteredPassword: string): Promise<boolean> {
  return await bcrypt.compare(enteredPassword, this.password);
};

// JWT 토큰 생성 메서드
userSchema.methods.getSignedJwtToken = function (): string {
    return jwt.sign(
        { id: this._id, role: this.role },
        process.env.JWT_SECRET as string,
        {
        expiresIn: parseInt(process.env.JWT_EXPIRE as string, 10),
        }
    );
};

export default mongoose.model<IUser>('User', userSchema);