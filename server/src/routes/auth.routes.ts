/**
 * 인증 관련 라우트
 * 회원가입, 로그인, 로그아웃, 사용자 정보 조회 엔드포인트 정의
 */
import { Router } from 'express';
import { register, login, getMe, logout } from '../controllers/auth.controller';
import { protect } from '../middleware/auth.middleware';
import { asyncHandler } from '../utils/asyncHandler';

const router = Router();

// 공개 접근 라우트
router.post('/register', asyncHandler(register));
router.post('/login', asyncHandler(login));

// 인증 필요 라우트
router.get('/me', protect, asyncHandler(getMe));
router.get('/logout', protect, logout); // logout은 비동기가 아니므로 asyncHandler 불필요

export default router;