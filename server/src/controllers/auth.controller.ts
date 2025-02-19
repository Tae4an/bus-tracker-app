/**
 * 인증 관련 컨트롤러
 * 
 * 회원가입, 로그인, 사용자 정보 조회 등의 인증 관련 기능을 처리
 */
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { User } from '../models';
import { logger } from '../utils/logger';

/**
 * 사용자 등록 (회원가입)
 * @route   POST /api/auth/register
 * @access  Public - 누구나 접근 가능
 * @param   {string} name - 사용자 이름
 * @param   {string} email - 사용자 이메일 (로그인 ID로 사용)
 * @param   {string} password - 비밀번호
 * @param   {string} role - 사용자 역할 (기본값: PASSENGER)
 * @returns {object} 성공 시 토큰과 사용자 정보, 실패 시 에러 메시지
 */
export const register = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { name, email, password, role } = req.body;

    // 이메일 중복 확인
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      res.status(400).json({
        success: false,
        error: '이미 등록된 이메일입니다'
      });
      return;
    }

    // 사용자 생성
    const user = await User.create({
      name,
      email,
      password,
      role
    });

    // 응답 전송 (토큰 생성)
    sendTokenResponse(user, 201, res);
  } catch (error) {
    logger.error(`회원가입 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 로그인
 * @route   POST /api/auth/login
 * @access  Public - 누구나 접근 가능
 * @param   {string} email - 사용자 이메일
 * @param   {string} password - 비밀번호
 * @returns {object} 성공 시 토큰과 사용자 정보, 실패 시 에러 메시지
 */
export const login = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { email, password } = req.body;

    // 이메일과 비밀번호 확인
    if (!email || !password) {
      res.status(400).json({
        success: false,
        error: '이메일과 비밀번호를 입력해주세요'
      });
      return;
    }

    // 이메일로 사용자 찾기 (비밀번호 필드 포함)
    // select('+password')는 기본적으로 제외된 password 필드를 포함하도록 함
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      res.status(401).json({
        success: false,
        error: '유효하지 않은 로그인 정보입니다'
      });
      return;
    }

    // 비밀번호 확인 (User 모델의 matchPassword 메서드 사용)
    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      res.status(401).json({
        success: false,
        error: '유효하지 않은 로그인 정보입니다'
      });
      return;
    }

    // 마지막 로그인 시간 업데이트
    user.lastLoginAt = new Date();
    await user.save();

    // 응답 전송
    sendTokenResponse(user, 200, res);
  } catch (error) {
    logger.error(`로그인 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 현재 로그인된 사용자 정보 조회
 * @route   GET /api/auth/me
 * @access  Private - 로그인한 사용자만 접근 가능
 * @returns {object} 현재 로그인한 사용자 정보
 */
export const getMe = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    // req.user는 auth 미들웨어에서 설정됨
    const user = await User.findById(req.user.id);

    res.status(200).json({
      success: true,
      data: user
    });
  } catch (error) {
    logger.error(`사용자 정보 조회 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 로그아웃
 * 클라이언트에서 토큰을 삭제하는 방식으로 구현
 * @route   GET /api/auth/logout
 * @access  Private - 로그인한 사용자만 접근 가능
 * @returns {object} 성공 메시지
 */
export const logout = (req: Request, res: Response, next: NextFunction): void => {
  res.status(200).json({
    success: true,
    data: {}
  });
};

/**
 * 토큰 생성 및 쿠키에 저장하여 응답 전송
 * @param {object} user - 사용자 객체
 * @param {number} statusCode - HTTP 상태 코드
 * @param {object} res - Express Response 객체
 */
const sendTokenResponse = (user: any, statusCode: number, res: Response): void => {
  // JWT 토큰 생성
  const token = user.getSignedJwtToken();

  // 쿠키 옵션 설정
  const options = {
    expires: new Date(
      Date.now() + parseInt(process.env.JWT_COOKIE_EXPIRE || '30', 10) * 24 * 60 * 60 * 1000
    ),
    httpOnly: true, // 클라이언트 JS에서 접근 불가
    secure: process.env.NODE_ENV === 'production' // HTTPS에서만 전송
  };

  // 응답 전송 (토큰을 쿠키와 JSON 응답 모두에 포함)
  res
    .status(statusCode)
    .cookie('token', token, options)
    .json({
      success: true,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    });
};