/**
 * 비동기 컨트롤러 핸들러 유틸리티
 * 
 * Express 라우트 핸들러에서 발생하는 비동기 오류를 자동으로 캐치하여
 * Express의 오류 처리 미들웨어로 전달하는 래퍼 함수.
 * 
 * 이 유틸리티를 사용하면:
 * 1. 각 컨트롤러에서 try-catch 블록을 반복 작성할 필요가 없어짐.
 * 2. 처리되지 않은 Promise 거부가 적절히 처리.
 * 3. 컨트롤러의 타입 안전성이 유지.
 */
import { Request, Response, NextFunction } from 'express';

/**
 * 비동기 Express 요청 핸들러 타입 정의
 * Promise<void> 반환 타입은 Express 라우터와의 타입 호환성을 보장.
 */
type AsyncFunction = (req: Request, res: Response, next: NextFunction) => Promise<void>;

/**
 * 비동기 컨트롤러 함수를 위한 오류 처리 래퍼
 * 
 * @param {AsyncFunction} fn - 래핑할 비동기 컨트롤러 함수
 * @returns {Function} Express 미들웨어 함수
 * 
 * @example
 * // 라우터에서 사용 방법
 * ex) router.get('/users', asyncHandler(getUsers));
 */
export const asyncHandler = (fn: AsyncFunction) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    // Promise를 실행하고 발생한 오류를 next()로 전달
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};