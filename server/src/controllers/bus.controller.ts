/**
 * 버스 컨트롤러
 * 
 * 버스 관련 CRUD 작업 및 상태 관리 기능을 처리
 */
import { Request, Response, NextFunction } from 'express';
import { Bus, Route } from '../models';
import { logger } from '../utils/logger';

/**
 * 모든 버스 조회
 * @route   GET /api/buses
 * @access  Public - 누구나 접근 가능
 * @returns {object} 버스 목록
 */
export const getBuses = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    // 원본 쿼리 실행 (populate 포함)
    const buses = await Bus.find();
    
    // 안전하게 응답 데이터 준비
    const safeData = Array.isArray(buses) ? buses : [];
    const safeCount = safeData.length;
    
    res.status(200).json({
      success: true,
      count: safeCount,
      data: safeData
    });
  } catch (error) {
    logger.error(`버스 목록 조회 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 특정 버스 조회
 * @route   GET /api/buses/:id
 * @access  Public - 누구나 접근 가능
 * @param   {string} id - 버스 ID
 * @returns {object} 버스 상세 정보
 */
export const getBus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    // 특정 버스 정보 조회 시 더 많은 관련 정보 포함
    const bus = await Bus.findById(req.params.id)
      .populate('routeId', 'name stops schedule color') // 노선의 상세 정보 포함
      .populate('driverId', 'name');                   // 운전자 이름 포함

    if (!bus) {
      res.status(404).json({
        success: false,
        error: '해당 ID의 버스를 찾을 수 없습니다'
      });
      return;
    }

    res.status(200).json({
      success: true,
      data: bus
    });
  } catch (error) {
    logger.error(`버스 조회 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 특정 노선의 버스 목록 조회
 * @route   GET /api/buses/route/:routeId
 * @access  Public - 누구나 접근 가능
 * @param   {string} routeId - 노선 ID
 * @returns {object} 해당 노선의 버스 목록
 */
export const getBusesByRoute = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    // 노선 존재 여부 먼저 확인
    const route = await Route.findById(req.params.routeId);
    if (!route) {
      res.status(404).json({
        success: false,
        error: '해당 ID의 노선을 찾을 수 없습니다'
      });
      return;
    }

    // 해당 노선에 속한 버스 목록 조회
    const buses = await Bus.find({ routeId: req.params.routeId })
      .populate('driverId', 'name');

    res.status(200).json({
      success: true,
      count: buses.length,
      data: buses
    });
  } catch (error) {
    logger.error(`노선별 버스 조회 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 버스 생성
 * @route   POST /api/buses
 * @access  Private (Admin) - 관리자만 접근 가능
 * @param   {string} routeId - 노선 ID
 * @param   {string} plateNumber - 차량 번호
 * @param   {number} capacity - 수용 인원
 * @param   {string} [status] - 버스 상태 (기본값: IDLE)
 * @param   {string} [displayName] - 표시 이름
 * @returns {object} 생성된 버스 정보
 */
export const createBus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    // 연결하려는 노선 존재 여부 확인
    const route = await Route.findById(req.body.routeId);
    if (!route) {
      res.status(404).json({
        success: false,
        error: '해당 ID의 노선을 찾을 수 없습니다'
      });
      return;
    }

    // 새 버스 생성
    const bus = await Bus.create(req.body);

    res.status(201).json({
      success: true,
      data: bus
    });
  } catch (error) {
    logger.error(`버스 생성 오류: ${error}`);
    
    // 중복 키 오류 처리 (차량 번호 등)
    if ((error as any).code === 11000) {
      res.status(400).json({
        success: false,
        error: '이미 등록된 차량 번호입니다'
      });
      return;
    }
    
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 버스 정보 수정
 * @route   PUT /api/buses/:id
 * @access  Private (Admin) - 관리자만 접근 가능
 * @param   {string} id - 버스 ID
 * @param   {object} updateData - 업데이트할 데이터
 * @returns {object} 업데이트된 버스 정보
 */
export const updateBus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    let bus = await Bus.findById(req.params.id);

    if (!bus) {
      res.status(404).json({
        success: false,
        error: '해당 ID의 버스를 찾을 수 없습니다'
      });
      return;
    }

    // 노선 ID가 변경되는 경우 유효성 확인
    if (req.body.routeId && req.body.routeId !== bus.routeId.toString()) {
      const route = await Route.findById(req.body.routeId);
      if (!route) {
        res.status(404).json({
          success: false,
          error: '해당 ID의 노선을 찾을 수 없습니다'
        });
        return;
      }
    }

    // 버스 정보 업데이트 (new: true로 업데이트된 정보 반환)
    bus = await Bus.findByIdAndUpdate(req.params.id, req.body, {
      new: true,           // 업데이트된 데이터 반환
      runValidators: true  // 스키마 유효성 검사 실행
    });

    res.status(200).json({
      success: true,
      data: bus
    });
  } catch (error) {
    logger.error(`버스 수정 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 버스 삭제
 * @route   DELETE /api/buses/:id
 * @access  Private (Admin) - 관리자만 접근 가능
 * @param   {string} id - 버스 ID
 * @returns {object} 성공 메시지
 */
export const deleteBus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const bus = await Bus.findById(req.params.id);

    if (!bus) {
      res.status(404).json({
        success: false,
        error: '해당 ID의 버스를 찾을 수 없습니다'
      });
      return;
    }

    // 버스 데이터 삭제
    await bus.deleteOne();

    res.status(200).json({
      success: true,
      data: {}
    });
  } catch (error) {
    logger.error(`버스 삭제 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 버스 상태 업데이트 (기사용)
 * @route   PATCH /api/buses/:id/status
 * @access  Private (Driver) - 버스 기사와 관리자만 접근 가능
 * @param   {string} id - 버스 ID
 * @param   {string} status - 새로운 상태 (ACTIVE, IDLE, MAINTENANCE, OUT_OF_SERVICE)
 * @returns {object} 업데이트된 버스 정보
 */
export const updateBusStatus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { status } = req.body;
    const bus = await Bus.findById(req.params.id);

    if (!bus) {
      res.status(404).json({
        success: false,
        error: '해당 ID의 버스를 찾을 수 없습니다'
      });
      return;
    }

    // 현재 사용자가 해당 버스의 기사인지 확인 (인증 미들웨어에서 설정된 req.user 사용)
    if (bus.driverId && bus.driverId.toString() !== req.user.id) {
      res.status(403).json({
        success: false,
        error: '이 버스의 상태를 수정할 권한이 없습니다'
      });
      return;
    }

    // 상태 업데이트
    bus.status = status;
    await bus.save();

    res.status(200).json({
      success: true,
      data: bus
    });
  } catch (error) {
    logger.error(`버스 상태 업데이트 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};