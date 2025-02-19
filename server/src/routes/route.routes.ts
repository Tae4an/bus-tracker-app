/**
 * 노선 관련 라우트
 * 
 * 노선 CRUD 및 관련 기능의 엔드포인트 정의
 * 일부 라우트는 관리자 권한 필요
 */
import { Router } from 'express';
import {
  getRoutes,
  getRoute,
  getRoutesByStop,
  createRoute,
  updateRoute,
  deleteRoute,
  toggleRouteActive
} from '../controllers/route.controller';
import { protect, authorize } from '../middleware/auth.middleware';
import { UserRole } from '../models';
import { asyncHandler } from '../utils/asyncHandler';

const router = Router();

// 공개 접근 라우트 - 조회 작업
router.get('/', asyncHandler(getRoutes));
router.get('/:id', asyncHandler(getRoute));
router.get('/stop/:stopId', asyncHandler(getRoutesByStop));

// 관리자 전용 라우트 - 생성, 수정, 삭제
router.post(
  '/',
  protect,
  authorize(UserRole.ADMIN),
  asyncHandler(createRoute)
);

router.put(
  '/:id',
  protect,
  authorize(UserRole.ADMIN),
  asyncHandler(updateRoute)
);

router.delete(
  '/:id',
  protect,
  authorize(UserRole.ADMIN),
  asyncHandler(deleteRoute)
);

router.patch(
  '/:id/toggle-active',
  protect,
  authorize(UserRole.ADMIN),
  asyncHandler(toggleRouteActive)
);

export default router;