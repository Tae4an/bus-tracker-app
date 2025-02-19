/**
 * API 라우트 통합 설정
 * 
 * 모든 API 엔드포인트를 /api 경로 아래에 그룹화하고
 * 각 리소스별 라우터를 연결
 */
import { Router } from 'express';
import authRoutes from './auth.routes';
import busRoutes from './bus.routes';
import routeRoutes from './route.routes';
import stopRoutes from './stop.routes';
import userRoutes from './user.routes';
import { logger } from '../utils/logger';

const router = Router();

// API 버전 헤더 및 요청 로깅 미들웨어
router.use((req, res, next) => {
  const apiVersion = req.headers['x-api-version'] || '1.0';
  logger.debug(`API 요청: ${req.method} ${req.path} [API 버전: ${apiVersion}]`);
  next();
});

// 각 리소스별 라우트 등록
router.use('/auth', authRoutes);
router.use('/buses', busRoutes);
router.use('/routes', routeRoutes);
router.use('/stops', stopRoutes);
router.use('/users', userRoutes);

// API 상태 체크 엔드포인트
router.get('/status', (req, res) => {
  res.status(200).json({
    status: 'online',
    timestamp: new Date(),
    version: process.env.npm_package_version || '1.0.0',
    environment: process.env.NODE_ENV
  });
});

export default router;