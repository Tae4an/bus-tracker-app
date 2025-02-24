/**
 * 버스 관련 라우트
 * 
 * 버스 CRUD 및 상태 관리 엔드포인트 정의
 */
/**
 * @swagger
 * tags:
 *   name: Buses
 *   description: 버스 관리 API
 */
import { Router } from 'express';
import {
  getBuses,
  getBus,
  getBusesByRoute,
  createBus,
  updateBus,
  deleteBus,
  updateBusStatus,
  getAssignedBus,
  assignDriver
} from '../controllers/bus.controller';
import { protect, authorize } from '../middleware/auth.middleware';
import { UserRole } from '../models';
import { asyncHandler } from '../utils/asyncHandler';

const router = Router();

/**
 * @swagger
 * /api/buses/assigned/driver:
 *   get:
 *     summary: 현재 로그인한 기사가 담당하는 버스 조회
 *     tags: [Buses]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 담당 버스 조회 성공
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Bus'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.get('/assigned/driver', protect, getAssignedBus);

/**
 * @swagger
 * /api/buses/{id}/assign:
 *   put:
 *     summary: 버스에 기사 할당 (관리자용)
 *     tags: [Buses]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: 버스 ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - driverId
 *             properties:
 *               driverId:
 *                 type: string
 *                 example: '60d21b4667d0d8992e610c87'
 *                 description: 할당할 기사 사용자 ID
 *     responses:
 *       200:
 *         description: 기사 할당 성공
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Bus'
 *       400:
 *         description: 잘못된 요청
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             example:
 *               success: false
 *               error: '유효하지 않은 드라이버 ID 형식'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         description: 리소스 없음
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             examples:
 *               busNotFound:
 *                 value:
 *                   success: false
 *                   error: '해당 ID의 버스를 찾을 수 없습니다'
 *               userNotFound:
 *                 value:
 *                   success: false
 *                   error: '해당 ID의 사용자를 찾을 수 없습니다'
 *       500:
 *         $ref: '#/components/responses/ServerError'
 */
router.put('/:id/assign', protect, authorize(UserRole.ADMIN), assignDriver);

// 공개 접근 라우트 - 조회 작업
/**
 * @swagger
 * /api/buses:
 *   get:
 *     summary: 모든 버스 조회
 *     tags: [Buses]
 *     responses:
 *       200:
 *         description: 버스 목록 조회 성공
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
 *                     $ref: '#/components/schemas/Bus'
 */
router.get('/', asyncHandler(getBuses));

/**
 * @swagger
 * /api/buses/{id}:
 *   get:
 *     summary: 특정 버스 조회
 *     tags: [Buses]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: 버스 조회 성공
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Bus'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.get('/:id', asyncHandler(getBus));

/**
 * @swagger
 * /api/buses/route/{routeId}:
 *   get:
 *     summary: 특정 노선의 버스 목록 조회
 *     tags: [Buses]
 *     parameters:
 *       - in: path
 *         name: routeId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: 노선별 버스 목록 조회 성공
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
 *                     $ref: '#/components/schemas/Bus'
 */
router.get('/route/:routeId', asyncHandler(getBusesByRoute));

// 관리자 전용 라우트 - 생성, 수정, 삭제
/**
 * @swagger
 * /api/buses:
 *   post:
 *     summary: 버스 생성
 *     tags: [Buses]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/BusRequest'
 *     responses:
 *       201:
 *         description: 버스 생성 성공
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Bus'
 *       400:
 *         $ref: '#/components/responses/BadRequestError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 */
router.post('/', protect, authorize(UserRole.ADMIN), asyncHandler(createBus));

/**
 * @swagger
 * /api/buses/{id}:
 *   put:
 *     summary: 버스 정보 수정
 *     tags: [Buses]
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
 *             $ref: '#/components/schemas/BusRequest'
 *     responses:
 *       200:
 *         description: 버스 정보 수정 성공
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Bus'
 *       400:
 *         $ref: '#/components/responses/BadRequestError'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       403:
 *         $ref: '#/components/responses/ForbiddenError'
 *       404:
 *         $ref: '#/components/responses/NotFoundError'
 */
router.put('/:id', protect, authorize(UserRole.ADMIN), asyncHandler(updateBus));

/**
 * @swagger
 * /api/buses/{id}:
 *   delete:
 *     summary: 버스 삭제
 *     tags: [Buses]
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
 *         description: 버스 삭제 성공
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
router.delete('/:id', protect, authorize(UserRole.ADMIN), asyncHandler(deleteBus));

// 기사 접근 가능 라우트 - 상태 업데이트
/**
 * @swagger
 * /api/buses/{id}/status:
 *   patch:
 *     summary: 버스 상태 업데이트
 *     tags: [Buses]
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
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [ACTIVE, IDLE, MAINTENANCE, OUT_OF_SERVICE]
 *     responses:
 *       200:
 *         description: 버스 상태 업데이트 성공
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Bus'
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
  '/:id/status',
  protect,
  authorize(UserRole.DRIVER, UserRole.ADMIN), // 기사와 관리자 모두 접근 가능
  asyncHandler(updateBusStatus)
);

export default router;