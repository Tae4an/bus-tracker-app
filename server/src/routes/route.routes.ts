/**
 * 노선 관련 라우트
 * 
 * 노선 CRUD 및 관련 기능의 엔드포인트 정의
 * 일부 라우트는 관리자 권한 필요
 */
/**
 * @swagger
 * tags:
 *   name: Routes
 *   description: 노선 관리 API
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
/**
 * @swagger
 * /api/routes:
 *   get:
 *     summary: 모든 노선 조회
 *     tags: [Routes]
 *     parameters:
 *       - in: query
 *         name: active
 *         schema:
 *           type: boolean
 *         description: 활성 상태 필터링 (optional)
 *     responses:
 *       200:
 *         description: 노선 목록 조회 성공
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 count:
 *                   type: integer
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Route'
 */
router.get('/', asyncHandler(getRoutes));

/**
 * @swagger
 * /api/routes/{id}:
 *   get:
 *     summary: 특정 노선 조회
 *     tags: [Routes]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: 노선 조회 성공
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Route'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.get('/:id', asyncHandler(getRoute));

/**
 * @swagger
 * /api/routes/stop/{stopId}:
 *   get:
 *     summary: 특정 정류장을 경유하는 노선 목록 조회
 *     tags: [Routes]
 *     parameters:
 *       - in: path
 *         name: stopId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: 정류장별 노선 목록 조회 성공
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 count:
 *                   type: integer
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Route'
 */
router.get('/stop/:stopId', asyncHandler(getRoutesByStop));

// 관리자 전용 라우트 - 생성, 수정, 삭제
/**
 * @swagger
 * /api/routes:
 *   post:
 *     summary: 노선 생성
 *     tags: [Routes]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/RouteRequest'
 *     responses:
 *       201:
 *         description: 노선 생성 성공
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Route'
 *       400:
 *         $ref: '#/components/responses/BadRequestError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */
router.post(
  '/',
  protect,
  authorize(UserRole.ADMIN),
  asyncHandler(createRoute)
);

/**
 * @swagger
 * /api/routes/{id}:
 *   put:
 *     summary: 노선 정보 수정
 *     tags: [Routes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/RouteRequest'
 *     responses:
 *       200:
 *         description: 노선 정보 수정 성공
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Route'
 *       400:
 *         $ref: '#/components/responses/BadRequestError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.put(
  '/:id',
  protect,
  authorize(UserRole.ADMIN),
  asyncHandler(updateRoute)
);

/**
 * @swagger
 * /api/routes/{id}:
 *   delete:
 *     summary: 노선 삭제
 *     tags: [Routes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: 노선 삭제 성공
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.delete(
  '/:id',
  protect,
  authorize(UserRole.ADMIN),
  asyncHandler(deleteRoute)
);

/**
 * @swagger
 * /api/routes/{id}/toggle-active:
 *   patch:
 *     summary: 노선 활성화/비활성화 토글
 *     tags: [Routes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: 노선 활성화 상태 변경 성공
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Route'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.patch(
  '/:id/toggle-active',
  protect,
  authorize(UserRole.ADMIN),
  asyncHandler(toggleRouteActive)
);

export default router;