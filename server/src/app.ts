/**
 * Express 애플리케이션 설정
 * 
 * 서버 초기화, 미들웨어 설정, 라우트 등록 및 에러 핸들링을 담당
 * HTTP 서버와 Socket.IO 서버를 통합하여 관리
 */
import express, { Express, Request, Response, NextFunction } from 'express';
import http from 'http';
import { Server as SocketServer } from 'socket.io';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import cookieParser from 'cookie-parser';
import dotenv from 'dotenv';
import { connectDB } from './config/db';
import { logger } from './utils/logger';
import apiRoutes from './routes';
import { initializeSocket } from './socket';
import swaggerUi from 'swagger-ui-express';
import { specs } from './config/swagger';
// 환경 변수 로드
dotenv.config();

/**
 * Express 앱 초기화
 */
const app: Express = express();
const server = http.createServer(app);

// Swagger 문서 라우트 설정
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));

/**
 * Socket.IO 서버 설정
 * CORS 설정으로 모든 출처에서의 연결 허용 (개발 환경 기준)
 */
const io = new SocketServer(server, {
  cors: {
    origin: process.env.NODE_ENV === 'production' 
      ? process.env.CLIENT_URL 
      : '*',
    methods: ['GET', 'POST'],
    credentials: true
  },
});

/**
 * 데이터베이스 연결
 */
connectDB();

/**
 * 보안 및 기본 미들웨어 설정
 */
// CORS 설정
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? process.env.CLIENT_URL 
    : '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
}));

// 보안 헤더 설정
app.use(helmet());

// JSON 요청 본문 파싱
app.use(express.json({ limit: '10mb' }));

// URL 인코딩된 본문 파싱
app.use(express.urlencoded({ extended: false, limit: '10mb' }));

// 쿠키 파싱
app.use(cookieParser());

/**
 * API 요청 제한 (DDoS 방지)
 * 15분 동안 IP당 100회 요청으로 제한
 */
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15분
  max: 100, // IP당 최대 요청 수
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.' }
});
app.use('/api', limiter);

/**
 * 요청 로깅 미들웨어
 */
app.use((req: Request, _res: Response, next: NextFunction) => {
  logger.info(`${req.method} ${req.originalUrl} [${req.ip}]`);
  next();
});

/**
 * API 라우트 등록
 */
app.use('/api', apiRoutes);

/**
 * 기본 라우트 - API 서버 상태 확인용
 */
app.get('/', (_req: Request, res: Response) => {
  res.json({
    message: '셔틀버스 위치 추적 API 서버',
    version: '1.0.0',
    status: 'running',
    environment: process.env.NODE_ENV
  });
});

/**
 * 404 핸들러 - 존재하지 않는 라우트 처리
 */
app.use((_req: Request, res: Response) => {
  res.status(404).json({
    success: false,
    error: '요청한 리소스를 찾을 수 없습니다'
  });
});

/**
 * 전역 에러 핸들러
 */
app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  logger.error(`예기치 않은 오류: ${err.message}`);
  logger.error(err.stack);
  
  res.status(500).json({
    success: false,
    error: '서버 내부 오류가 발생했습니다'
  });
});

/**
 * Socket.IO 이벤트 처리 초기화
 */
initializeSocket(io);

export { app, server, io };