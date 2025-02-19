/**
 * 버스 관련 라우트
 * 
 * 버스 CRUD 및 상태 관리 엔드포인트 정의
 */
import { Router } from 'express';
import {
  getBuses,
  getBus,
  getBusesByRoute,
  createBus,
  updateBus,
  deleteBus,
  updateBusStatus
} from '../controllers/bus.controller';
import { protect, authorize } from '../middleware/auth.middleware';
import { UserRole } from '../models';
import { asyncHandler } from '../utils/asyncHandler';

const router = Router();

// 공개 접근 라우트 - 조회 작업
router.get('/', asyncHandler(getBuses));
router.get('/:id', asyncHandler(getBus));
router.get('/route/:routeId', asyncHandler(getBusesByRoute));

// 관리자 전용 라우트 - 생성, 수정, 삭제
router.post('/', protect, authorize(UserRole.ADMIN), asyncHandler(createBus));
router.put('/:id', protect, authorize(UserRole.ADMIN), asyncHandler(updateBus));
router.delete('/:id', protect, authorize(UserRole.ADMIN), asyncHandler(deleteBus));

// 기사 접근 가능 라우트 - 상태 업데이트
router.patch(
  '/:id/status',
  protect,
  authorize(UserRole.DRIVER, UserRole.ADMIN), // 기사와 관리자 모두 접근 가능
  asyncHandler(updateBusStatus)
);

export default router;