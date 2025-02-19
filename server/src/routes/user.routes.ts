/**
 * 사용자 관련 라우트
 * 
 * 사용자 계정 관리 및 프로필 관련 엔드포인트 정의
 * 일부 라우트는 관리자 권한 필요, 일부는 사용자 본인만 접근 가능
 */
import { Router } from 'express';
import {
  getUsers,
  getUser,
  createUser,
  updateUser,
  deleteUser,
  resetUserPassword,
  toggleUserActive,
  updateProfile,
  changePassword,
  updateFavorites
} from '../controllers/user.controller';
import { protect, authorize } from '../middleware/auth.middleware';
import { UserRole } from '../models';
import { asyncHandler } from '../utils/asyncHandler';

const router = Router();

// 관리자 전용 라우트 - 사용자 관리
router.get(
  '/',
  protect,
  authorize(UserRole.ADMIN),
  asyncHandler(getUsers)
);

router.get(
  '/:id',
  protect,
  authorize(UserRole.ADMIN),
  asyncHandler(getUser)
);

router.post(
  '/',
  protect,
  authorize(UserRole.ADMIN),
  asyncHandler(createUser)
);

router.put(
  '/:id',
  protect,
  authorize(UserRole.ADMIN),
  asyncHandler(updateUser)
);

router.delete(
  '/:id',
  protect,
  authorize(UserRole.ADMIN),
  asyncHandler(deleteUser)
);

router.put(
  '/:id/password',
  protect,
  authorize(UserRole.ADMIN),
  asyncHandler(resetUserPassword)
);

router.patch(
  '/:id/toggle-active',
  protect,
  authorize(UserRole.ADMIN),
  asyncHandler(toggleUserActive)
);

// 사용자 본인용 라우트 - 프로필 관리
router.put(
  '/profile',
  protect,
  asyncHandler(updateProfile)
);

router.put(
  '/change-password',
  protect,
  asyncHandler(changePassword)
);

router.put(
  '/favorites',
  protect,
  asyncHandler(updateFavorites)
);

export default router;