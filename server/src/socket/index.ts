/**
 * Socket.IO 실시간 통신 모듈
 * 
 * 버스 위치 실시간 업데이트, 구독 관리 등 실시간 통신 기능을 처리
 * 모든 소켓 연결은 인증을 거쳐야 하며, 권한에 따라 기능이 제한됨
 */
/**
 * @swagger
 * tags:
 *   name: Realtime
 *   description: 실시간 통신 API (Socket.IO)
 */

/**
 * @swagger
 * components:
 *   securitySchemes:
 *     socketAuth:
 *       type: apiKey
 *       in: header
 *       name: Authorization
 *       description: Socket.IO 연결 시 인증 토큰
 */

/**
 * @swagger
 * /socket.io:
 *   get:
 *     summary: Socket.IO 연결
 *     tags: [Realtime]
 *     security:
 *       - socketAuth: []
 *     description: |
 *       Socket.IO 서버에 연결합니다. 연결 시 인증 토큰이 필요합니다.
 *       
 *       # 이벤트
 *       
 *       ## 서버로 전송하는 이벤트
 *       
 *       ### updateBusLocation
 *       버스 위치 업데이트
 *       ```
 *       {
 *         busId: string,
 *         latitude: number,
 *         longitude: number,
 *         speed?: number,
 *         heading?: number,
 *         accuracy?: number
 *       }
 *       ```
 *       
 *       ### subscribeToBus
 *       특정 버스 구독
 *       ```
 *       busId: string
 *       ```
 *       
 *       ### unsubscribeFromBus
 *       특정 버스 구독 취소
 *       ```
 *       busId: string
 *       ```
 *       
 *       ## 서버에서 수신하는 이벤트
 *       
 *       ### busLocationUpdated
 *       버스 위치 업데이트 수신
 *       ```
 *       {
 *         busId: string,
 *         latitude: number,
 *         longitude: number,
 *         speed?: number,
 *         heading?: number,
 *         accuracy?: number,
 *         timestamp: Date
 *       }
 *       ```
 *       
 *       ### locationUpdateSuccess
 *       위치 업데이트 성공 확인
 *       ```
 *       {
 *         busId: string,
 *         timestamp: Date
 *       }
 *       ```
 *       
 *       ### error
 *       오류 메시지 수신
 *       ```
 *       {
 *         message: string
 *       }
 *       ```
 *     responses:
 *       101:
 *         description: Switching Protocols to WebSocket
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
import { Server as SocketServer, Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { Bus, LocationRecord, UserRole } from '../models';
import { logger } from '../utils/logger';

/**
 * 인증된 소켓 인터페이스
 * 기본 Socket에 인증된 사용자 정보를 추가
 */
interface AuthenticatedSocket extends Socket {
  user?: {
    id: string;
    role: UserRole;
  };
}

/**
 * Socket.IO 서버 초기화 및 이벤트 핸들러 등록
 * @param {SocketServer} io - Socket.IO 서버 인스턴스
 */
export const initializeSocket = (io: SocketServer) => {
  // 모든 소켓 연결에 적용되는 인증 미들웨어
  io.use(async (socket: AuthenticatedSocket, next) => {
    try {
      const token = socket.handshake.auth.token;
      
      // 토큰이 없는 경우
      if (!token) {
        return next(new Error('인증 토큰이 필요합니다'));
      }
      
      // 토큰 검증
      const decoded = jwt.verify(token, process.env.JWT_SECRET as string) as any;
      
      // 소켓 객체에 사용자 정보 저장
      socket.user = {
        id: decoded.id,
        role: decoded.role
      };
      
      // 다음 미들웨어 또는 연결 핸들러로 진행
      next();
    } catch (error) {
      logger.error(`소켓 인증 오류: ${error}`);
      next(new Error('인증에 실패했습니다'));
    }
  });

  /**
   * 클라이언트 연결 이벤트 핸들러
   * 연결된 클라이언트의 이벤트 구독 및 처리
   */
  io.on('connection', (socket: AuthenticatedSocket) => {
    logger.info(`새로운 클라이언트 연결: ${socket.id}, 사용자: ${socket.user?.id}`);
    
    /**
     * 버스 위치 업데이트 이벤트 핸들러
     * 기사 앱에서 보내는 실시간 위치 데이터를 처리하고 구독자에게 브로드캐스트
     * @param {object} data - 위치 업데이트 데이터
     * @param {string} data.busId - 버스 ID
     * @param {number} data.latitude - 위도
     * @param {number} data.longitude - 경도
     * @param {number} [data.speed] - 속도 (m/s)
     * @param {number} [data.heading] - 방향 (0-359도)
     * @param {number} [data.accuracy] - GPS 정확도 (미터)
     */
    socket.on('updateBusLocation', async (data: {
      busId: string;
      latitude: number;
      longitude: number;
      speed?: number;
      heading?: number;
      accuracy?: number;
    }) => {
      try {
        const { busId, latitude, longitude, speed, heading, accuracy } = data;
        
        // 데이터 유효성 검사
        if (!busId || !latitude || !longitude) {
          return socket.emit('error', { message: '유효하지 않은 위치 데이터입니다' });
        }
        
        // 버스 존재 여부 확인
        const bus = await Bus.findById(busId);
        if (!bus) {
          return socket.emit('error', { message: '해당 ID의 버스가 존재하지 않습니다' });
        }
        
        // 권한 확인: 기사 또는 관리자만 위치 업데이트 가능
        if (socket.user?.role !== UserRole.DRIVER && socket.user?.role !== UserRole.ADMIN) {
          return socket.emit('error', { message: '위치 업데이트 권한이 없습니다' });
        }
        
        // 기사인 경우, 해당 버스의 담당자인지 확인
        if (
          socket.user.role === UserRole.DRIVER &&
          bus.driverId &&
          bus.driverId.toString() !== socket.user.id
        ) {
          return socket.emit('error', { message: '이 버스의 위치를 업데이트할 권한이 없습니다' });
        }
        
        // MongoDB GeoJSON 형식의 위치 데이터 생성
        const locationData = {
          busId,
          location: {
            type: 'Point' as const,
            coordinates: [longitude, latitude] // MongoDB: [lng, lat] 순서
          },
          speed: speed || 0,
          heading: heading || 0,
          accuracy: accuracy || 0,
          timestamp: new Date()
        };
        
        // 위치 기록 데이터베이스에 저장
        await LocationRecord.create(locationData);
        
        // 버스 문서의 마지막 위치 정보 업데이트
        await Bus.findByIdAndUpdate(busId, {
          lastLocation: locationData.location,
          lastUpdated: locationData.timestamp
        });
        
        // 해당 버스를 구독 중인 모든 클라이언트에게 위치 브로드캐스트
        io.to(`bus:${busId}`).emit('busLocationUpdated', {
          busId,
          latitude,
          longitude,
          speed,
          heading,
          accuracy,
          timestamp: locationData.timestamp
        });
        
        // 위치 업데이트 성공 응답
        socket.emit('locationUpdateSuccess', {
          busId,
          timestamp: locationData.timestamp
        });
        
      } catch (error) {
        logger.error(`위치 업데이트 오류: ${error}`);
        socket.emit('error', { message: '위치 업데이트 중 오류가 발생했습니다' });
      }
    });
    
    /**
     * 버스 구독 이벤트 핸들러
     * 클라이언트가 특정 버스의 위치 업데이트를 실시간으로 받기 위해 구독
     * @param {string} busId - 구독할 버스 ID
     */
    socket.on('subscribeToBus', (busId: string) => {
      if (!busId) return;
      
      // 소켓 룸에 클라이언트 추가
      socket.join(`bus:${busId}`);
      logger.info(`클라이언트 ${socket.id}가 버스 ${busId} 구독`);
    });
    
    /**
     * 버스 구독 취소 이벤트 핸들러
     * 클라이언트가 특정 버스 구독을 중단
     * @param {string} busId - 구독 취소할 버스 ID
     */
    socket.on('unsubscribeFromBus', (busId: string) => {
      if (!busId) return;
      
      // 소켓 룸에서 클라이언트 제거
      socket.leave(`bus:${busId}`);
      logger.info(`클라이언트 ${socket.id}가 버스 ${busId} 구독 취소`);
    });
    
    /**
     * 연결 해제 이벤트 핸들러
     * 클라이언트 연결이 종료될 때 정리 작업 수행
     */
    socket.on('disconnect', () => {
      logger.info(`클라이언트 연결 해제: ${socket.id}`);
      // 여기서 필요한 정리 작업 수행 (메모리 정리, 상태 업데이트 등)
    });
  });
};