/**
 * 인증 미들웨어
 * JWT 토큰 검증과 권한 관리를 처리
 */
/**
 * @swagger
 * components:
 *   securitySchemes:
 *     bearerAuth:
 *       type: http
 *       scheme: bearer
 *       bearerFormat: JWT
 *   responses:
 *     UnauthorizedError:
 *       description: 인증 오류
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               success:
 *                 type: boolean
 *                 example: false
 *               error:
 *                 type: string
 *                 example: 이 리소스에 접근할 권한이 없습니다
 *     ForbiddenError:
 *       description: 권한 없음
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               success:
 *                 type: boolean
 *                 example: false
 *               error:
 *                 type: string
 *                 example: 이 리소스에 접근할 권한이 없습니다
 */
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { User, UserRole } from '../models';
import { logger } from '../utils/logger';

// Request 타입 확장 - user 속성 추가
declare global {
  namespace Express {
    interface Request {
      user?: any;
    }
  }
}

/**
 * JWT 토큰 검증 및 사용자 설정 미들웨어
 * 요청 헤더나 쿠키에서 토큰을 추출하고 검증한 후, 
 * 해당 사용자 정보를 req.user에 저장
 */
/**
 * @swagger
 * security:
 *   - bearerAuth: []
 */
export const protect = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  let token;

  // 1. Authorization 헤더에서 Bearer 토큰 추출
  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer')
  ) {
    token = req.headers.authorization.split(' ')[1];
  }
  // 2. 쿠키에서 토큰 추출 (대체 방법)
  else if (req.cookies?.token) {
    token = req.cookies.token;
  }

  // 토큰이 없는 경우
  if (!token) {
    res.status(401).json({
      success: false,
      error: '이 리소스에 접근할 권한이 없습니다'
    });
    return;
  }

  try {
    // 토큰 검증
    const decoded = jwt.verify(token, process.env.JWT_SECRET as string) as any;

    // 토큰에서 추출한 사용자 ID로 사용자 정보 조회
    const user = await User.findById(decoded.id);

    // 사용자가 존재하지 않는 경우
    if (!user) {
      res.status(401).json({
        success: false,
        error: '토큰에 해당하는 사용자가 존재하지 않습니다'
      });
      return;
    }

    // 비활성화된 계정인 경우
    if (!user.isActive) {
      res.status(401).json({
        success: false,
        error: '비활성화된 계정입니다'
      });
      return;
    }

    // 요청 객체에 사용자 정보 추가
    req.user = user;
    next();
  } catch (error) {
    logger.error(`인증 오류: ${error}`);
    res.status(401).json({
      success: false,
      error: '인증에 실패했습니다'
    });
  }
};

/**
 * 역할 기반 권한 부여 미들웨어
 * 특정 역할을 가진 사용자만 접근을 허용
 * @param {...UserRole} roles - 허용할 사용자 역할 목록
 * @returns {Function} Express 미들웨어 함수
 */
/**
 * @swagger
 * components:
 *   schemas:
 *     UserRole:
 *       type: string
 *       enum: [PASSENGER, DRIVER, ADMIN]
 */
export const authorize = (...roles: UserRole[]) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    // 사용자 정보가 없는 경우 (protect 미들웨어를 먼저 거치지 않은 경우)
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: '인증이 필요합니다'
      });
      return;
    }

    // 요청한 사용자의 역할이 허용된 역할 목록에 포함되지 않는 경우
    if (!roles.includes(req.user.role)) {
      res.status(403).json({
        success: false,
        error: '이 리소스에 접근할 권한이 없습니다'
      });
      return;
    }

    // 권한이 확인되면 다음 미들웨어로 진행
    next();
  };
};