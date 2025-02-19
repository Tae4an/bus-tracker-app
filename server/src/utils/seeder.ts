/**
 * 데이터베이스 시드 스크립트
 * 
 * 개발 및 테스트 환경에서 초기 데이터를 생성하는 유틸리티
 * 사용자, 정류장, 노선 및 버스 데이터 자동 생성
 */
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { 
  Bus, 
  Route, 
  Stop, 
  User, 
  UserRole, 
  BusStatus, 
  DayType 
} from '../models';
import { logger } from './logger';

// 환경 변수 로드
dotenv.config();

// MongoDB 연결
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI as string);
    logger.info('MongoDB 연결 성공');
  } catch (error) {
    logger.error(`MongoDB 연결 오류: ${error}`);
    process.exit(1);
  }
};

// 더미 데이터 생성
const seedData = async () => {
  try {
    // 기존 데이터 삭제
    await Bus.deleteMany();
    await Route.deleteMany();
    await Stop.deleteMany();
    await User.deleteMany();

    logger.info('기존 데이터 삭제 완료');

    // 1. 사용자 생성
    logger.info('사용자 생성 중...');
    
    // 관리자
    const admin = await User.create({
      name: '관리자',
      email: 'admin@example.com',
      password: 'password123',
      role: UserRole.ADMIN,
      phoneNumber: '010-1234-5678',
      isActive: true,
      createdAt: new Date()
    });
    
    // 기사
    const drivers = await User.insertMany([
      {
        name: '홍길동 기사',
        email: 'driver1@example.com',
        password: 'password123',
        role: UserRole.DRIVER,
        licenseNumber: 'DL12345678',
        phoneNumber: '010-2222-1111',
        isActive: true,
        createdAt: new Date()
      },
      {
        name: '김운전 기사',
        email: 'driver2@example.com',
        password: 'password123',
        role: UserRole.DRIVER,
        licenseNumber: 'DL87654321',
        phoneNumber: '010-3333-1111',
        isActive: true,
        createdAt: new Date()
      },
      {
        name: '이기사',
        email: 'driver3@example.com',
        password: 'password123',
        role: UserRole.DRIVER,
        licenseNumber: 'DL55555555',
        phoneNumber: '010-4444-1111',
        isActive: true,
        createdAt: new Date()
      }
    ]);
    
    // 승객
    await User.insertMany([
      {
        name: '김승객',
        email: 'passenger1@example.com',
        password: 'password123',
        role: UserRole.PASSENGER,
        isActive: true,
        createdAt: new Date()
      },
      {
        name: '이용자',
        email: 'passenger2@example.com',
        password: 'password123',
        role: UserRole.PASSENGER,
        isActive: true,
        createdAt: new Date()
      }
    ]);
    
    logger.info(`${drivers.length + 1 + 2}명의 사용자 생성 완료`);

    // 2. 정류장 생성
    logger.info('정류장 생성 중...');
    
    const stops = await Stop.insertMany([
      {
        name: '대학 정문',
        location: {
          type: 'Point',
          coordinates: [127.0216, 37.4965]
        },
        facilities: {
          hasShelter: true,
          hasBench: true,
          hasLighting: true,
          hasElectronicDisplay: true,
          isAccessible: true
        },
        address: '서울특별시 강남구 대학로 123'
      },
      {
        name: '공학관',
        location: {
          type: 'Point',
          coordinates: [127.0235, 37.4980]
        },
        facilities: {
          hasShelter: true,
          hasBench: true,
          isAccessible: false
        },
        address: '서울특별시 강남구 대학로 136'
      },
      {
        name: '학생회관',
        location: {
          type: 'Point',
          coordinates: [127.0255, 37.4990]
        },
        facilities: {
          hasShelter: true,
          hasBench: true,
          hasElectronicDisplay: true,
          isAccessible: true
        },
        address: '서울특별시 강남구 대학로 142'
      },
      {
        name: '도서관',
        location: {
          type: 'Point',
          coordinates: [127.0275, 37.5000]
        },
        facilities: {
          hasShelter: true,
          hasBench: true,
          hasLighting: true,
          isAccessible: true
        },
        address: '서울특별시 강남구 대학로 156'
      },
      {
        name: '기숙사',
        location: {
          type: 'Point',
          coordinates: [127.0295, 37.5010]
        },
        facilities: {
          hasShelter: false,
          hasBench: true,
          isAccessible: false
        },
        address: '서울특별시 강남구 대학로 180'
      },
      {
        name: '연구동',
        location: {
          type: 'Point',
          coordinates: [127.0315, 37.5020]
        },
        facilities: {
          hasShelter: true,
          hasBench: true,
          hasLighting: true,
          isAccessible: true
        },
        address: '서울특별시 강남구 대학로 192'
      },
      {
        name: '체육관',
        location: {
          type: 'Point',
          coordinates: [127.0335, 37.5030]
        },
        facilities: {
          hasShelter: false,
          hasBench: false,
          isAccessible: true
        },
        address: '서울특별시 강남구 대학로 210'
      }
    ]);
    
    logger.info(`${stops.length}개의 정류장 생성 완료`);

    // 3. 노선 생성
    logger.info('노선 생성 중...');
    
    // A노선: 순환노선
    const routeA = await Route.create({
      name: 'A노선 (순환)',
      description: '캠퍼스 주요 시설을 순환하는 노선',
      stops: [
        stops[0]._id, // 대학 정문
        stops[1]._id, // 공학관
        stops[2]._id, // 학생회관
        stops[3]._id, // 도서관
        stops[4]._id, // 기숙사
        stops[0]._id  // 다시 정문으로 (순환)
      ],
      schedules: [
        {
          dayType: DayType.WEEKDAY,
          entries: [
            {
              stopId: stops[0]._id,
              arrivalTime: { minutes: 8 * 60 }, // 08:00
              departureTime: { minutes: 8 * 60 + 2 }, // 08:02
              isTimingPoint: true
            },
            {
              stopId: stops[1]._id,
              arrivalTime: { minutes: 8 * 60 + 5 }, // 08:05
              departureTime: { minutes: 8 * 60 + 6 }, // 08:06
              isTimingPoint: false
            },
            {
              stopId: stops[2]._id,
              arrivalTime: { minutes: 8 * 60 + 10 }, // 08:10
              departureTime: { minutes: 8 * 60 + 11 }, // 08:11
              isTimingPoint: true
            },
            {
              stopId: stops[3]._id,
              arrivalTime: { minutes: 8 * 60 + 15 }, // 08:15
              departureTime: { minutes: 8 * 60 + 16 }, // 08:16
              isTimingPoint: false
            },
            {
              stopId: stops[4]._id,
              arrivalTime: { minutes: 8 * 60 + 20 }, // 08:20
              departureTime: { minutes: 8 * 60 + 21 }, // 08:21
              isTimingPoint: true
            },
            {
              stopId: stops[0]._id,
              arrivalTime: { minutes: 8 * 60 + 30 }, // 08:30
              departureTime: { minutes: 8 * 60 + 32 }, // 08:32
              isTimingPoint: true
            }
          ]
        },
        {
          dayType: DayType.SATURDAY,
          entries: [
            {
              stopId: stops[0]._id,
              arrivalTime: { minutes: 9 * 60 }, // 09:00
              departureTime: { minutes: 9 * 60 + 2 }, // 09:02
              isTimingPoint: true
            },
            // 토요일 스케줄...
          ]
        }
      ],
      active: true,
      color: '#4285F4', // 파란색
    });
    
    // B노선: 직행노선
    const routeB = await Route.create({
      name: 'B노선 (직행)',
      description: '정문에서 기숙사까지 직행하는 노선',
      stops: [
        stops[0]._id, // 대학 정문
        stops[4]._id  // 기숙사
      ],
      schedules: [
        {
          dayType: DayType.WEEKDAY,
          entries: [
            {
              stopId: stops[0]._id,
              arrivalTime: { minutes: 8 * 60 + 15 }, // 08:15
              departureTime: { minutes: 8 * 60 + 17 }, // 08:17
              isTimingPoint: true
            },
            {
              stopId: stops[4]._id,
              arrivalTime: { minutes: 8 * 60 + 25 }, // 08:25
              departureTime: null, // 종점
              isTimingPoint: true
            }
          ]
        }
      ],
      active: true,
      color: '#EA4335', // 빨간색
    });
    
    // C노선: 연구동 노선
    const routeC = await Route.create({
      name: 'C노선 (연구동)',
      description: '연구동과 체육관을 경유하는 노선',
      stops: [
        stops[0]._id, // 대학 정문
        stops[5]._id, // 연구동
        stops[6]._id, // 체육관
        stops[0]._id  // 다시 정문으로
      ],
      active: true,
      color: '#FBBC05', // 노란색
    });
    
    logger.info(`${[routeA, routeB, routeC].length}개의 노선 생성 완료`);
    
    // 정류장 데이터에 노선 정보 추가
    logger.info('정류장에 노선 정보 업데이트 중...');

    for (const stop of stops) {
      // stop._id를 문자열로 변환
      const stopId = String(stop._id);
      
      const routesUsingThisStop = [routeA, routeB, routeC].filter(route => 
        route.stops.some(routeStopId => String(routeStopId) === stopId)
      );
      
      await Stop.findByIdAndUpdate(stop._id, {
        routes: routesUsingThisStop.map(route => route._id)
      });
    }
    
    logger.info('정류장 데이터 업데이트 완료');

    // 4. 버스 생성
    logger.info('버스 생성 중...');
    
    await Bus.insertMany([
      {
        routeId: routeA._id,
        driverId: drivers[0]._id,
        status: BusStatus.ACTIVE,
        capacity: 30,
        plateNumber: '서울 12가 3456',
        lastLocation: {
          type: 'Point',
          coordinates: [127.0235, 37.4980] // 공학관 근처
        },
        lastUpdated: new Date(),
        displayName: 'A-1호차'
      },
      {
        routeId: routeA._id,
        driverId: null, // 미배정
        status: BusStatus.IDLE,
        capacity: 30,
        plateNumber: '서울 45나 6789',
        lastLocation: {
          type: 'Point',
          coordinates: [127.0216, 37.4965] // 정문 근처
        },
        lastUpdated: new Date(),
        displayName: 'A-2호차'
      },
      {
        routeId: routeB._id,
        driverId: drivers[1]._id,
        status: BusStatus.ACTIVE,
        capacity: 20,
        plateNumber: '서울 78다 9012',
        lastLocation: {
          type: 'Point',
          coordinates: [127.0250, 37.4975] // 중간 지점
        },
        lastUpdated: new Date(),
        displayName: 'B-1호차'
      },
      {
        routeId: routeC._id,
        driverId: drivers[2]._id,
        status: BusStatus.MAINTENANCE,
        capacity: 25,
        plateNumber: '서울 34라 5678',
        lastLocation: {
          type: 'Point',
          coordinates: [127.0216, 37.4965] // 정문 근처
        },
        lastUpdated: new Date(),
        displayName: 'C-1호차'
      }
    ]);
    
    logger.info('4대의 버스 생성 완료');
    
    logger.info('데이터 시드 작업 완료!');
    
  } catch (error) {
    logger.error(`데이터 시드 오류: ${error}`);
    process.exit(1);
  }
};

// 실행
const runSeeder = async () => {
  await connectDB();
  await seedData();
  logger.info('모든 시드 작업이 완료되었습니다. 연결을 종료합니다.');
  await mongoose.disconnect();
  process.exit(0);
};

// 스크립트가 직접 실행될 때만 실행
if (require.main === module) {
  runSeeder();
}

export { runSeeder };