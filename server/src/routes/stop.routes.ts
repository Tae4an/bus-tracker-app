/**
 * 정류장 관련 라우트
 * 
 * 정류장 CRUD 및 위치 기반 검색 엔드포인트 정의
 * 일부 라우트는 관리자 권한 필요
 */
/**
 * @swagger
 * tags:
 *   name: Stops
 *   description: 정류장 관리 API
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
/**
 * @swagger
 * /api/stops:
 *   get:
 *     summary: 모든 정류장 조회
 *     tags: [Stops]
 *     parameters:
 *       - in: query
 *         name: withFacilities
 *         schema:
 *           type: boolean
 *         description: 시설이 있는 정류장만 필터링 (optional)
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: 정류장 이름 검색 (optional)
 *     responses:
 *       200:
 *         description: 정류장 목록 조회 성공
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
 *                     $ref: '#/components/schemas/Stop'
 */
router.get('/', asyncHandler(getStops));

/**
 * @swagger
 * /api/stops/nearby:
 *   get:
 *     summary: 특정 위치 근처의 정류장 검색
 *     tags: [Stops]
 *     parameters:
 *       - in: query
 *         name: lat
 *         required: true
 *         schema:
 *           type: number
 *         description: 위도
 *       - in: query
 *         name: lng
 *         required: true
 *         schema:
 *           type: number
 *         description: 경도
 *       - in: query
 *         name: distance
 *         schema:
 *           type: number
 *           default: 1000
 *         description: 검색 반경(미터)
 *     responses:
 *       200:
 *         description: 주변 정류장 검색 성공
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
 *                     $ref: '#/components/schemas/Stop'
 *       400:
 *         $ref: '#/components/responses/BadRequestError'
 */
router.get('/nearby', asyncHandler(getNearbyStops));

/**
 * @swagger
 * /api/stops/{id}:
 *   get:
 *     summary: 특정 정류장 조회
 *     tags: [Stops]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: 정류장 조회 성공
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Stop'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.get('/:id', asyncHandler(getStop));

// 관리자 전용 라우트 - 생성, 수정, 삭제
/**
 * @swagger
 * /api/stops:
 *   post:
 *     summary: 정류장 생성
 *     tags: [Stops]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/StopRequest'
 *     responses:
 *       201:
 *         description: 정류장 생성 성공
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Stop'
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
  asyncHandler(createStop)
);

/**
 * @swagger
 * /api/stops/{id}:
 *   put:
 *     summary: 정류장 정보 수정
 *     tags: [Stops]
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
 *             $ref: '#/components/schemas/StopRequest'
 *     responses:
 *       200:
 *         description: 정류장 정보 수정 성공
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Stop'
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
  asyncHandler(updateStop)
);


/**
 * @swagger
 * /api/stops/{id}:
 *   delete:
 *     summary: 정류장 삭제
 *     tags: [Stops]
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
 *         description: 정류장 삭제 성공
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
  asyncHandler(deleteStop)
);

/**
 * @swagger
 * /api/stops/{id}/facilities:
 *   patch:
 *     summary: 정류장 시설 정보 업데이트
 *     tags: [Stops]
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
 *             $ref: '#/components/schemas/Facilities'
 *     responses:
 *       200:
 *         description: 정류장 시설 정보 업데이트 성공
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Stop'
 *       400:
 *         $ref: '#/components/responses/BadRequestError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.patch(
  '/:id/facilities',
  protect,
  authorize(UserRole.ADMIN),
  asyncHandler(updateStopFacilities)
);

export default router;