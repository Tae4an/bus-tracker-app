/**
 * 정류장 관련 라우트
 * 
 * 정류장 CRUD 및 위치 기반 검색 엔드포인트 정의
 * 일부 라우트는 관리자 권한 필요
 */
import { Router } from 'express';
import {
  getStops,
  getStop,
  getNearbyStops,
  createStop,
  updateStop,
  deleteStop,
  updateStopFacilities
} from '../controllers/stop.controller';
import { protect, authorize } from '../middleware/auth.middleware';
import { UserRole } from '../models';
import { asyncHandler } from '../utils/asyncHandler';

const router = Router();

// 공개 접근 라우트 - 조회 작업
router.get('/', asyncHandler(getStops));
router.get('/nearby', asyncHandler(getNearbyStops));
router.get('/:id', asyncHandler(getStop));

// 관리자 전용 라우트 - 생성, 수정, 삭제
router.post(
  '/',
  protect,
  authorize(UserRole.ADMIN),
  asyncHandler(createStop)
);

router.put(
  '/:id',
  protect,
  authorize(UserRole.ADMIN),
  asyncHandler(updateStop)
);

router.delete(
  '/:id',
  protect,
  authorize(UserRole.ADMIN),
  asyncHandler(deleteStop)
);

router.patch(
  '/:id/facilities',
  protect,
  authorize(UserRole.ADMIN),
  asyncHandler(updateStopFacilities)
);

export default router;