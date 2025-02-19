/**
 * 노선 컨트롤러
 * 
 * 버스 노선 관련 CRUD 작업을 처리
 * 노선 생성, 조회, 수정, 삭제 및 특정 정류장을 경유하는 노선 조회 기능 제공
 */
import { Request, Response, NextFunction } from 'express';
import { Route, Stop, Bus } from '../models';
import { logger } from '../utils/logger';

/**
 * 모든 노선 조회
 * @route   GET /api/routes
 * @access  Public - 누구나 접근 가능
 * @returns {object} 노선 목록
 */
export const getRoutes = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    // 쿼리 파라미터로 필터링 옵션 제공
    const filter: any = {};
    
    // 활성 상태 필터링 (active=true 또는 active=false)
    if (req.query.active !== undefined) {
      filter.active = req.query.active === 'true';
    }
    
    const routes = await Route.find(filter)
      .populate('stops', 'name location');  // 정류장 정보 포함

    res.status(200).json({
      success: true,
      count: routes.length,
      data: routes
    });
  } catch (error) {
    logger.error(`노선 목록 조회 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 특정 노선 조회
 * @route   GET /api/routes/:id
 * @access  Public - 누구나 접근 가능
 * @param   {string} id - 노선 ID
 * @returns {object} 노선 상세 정보
 */
export const getRoute = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const route = await Route.findById(req.params.id)
      .populate('stops', 'name location facilities');  // 정류장 상세 정보 포함

    if (!route) {
      res.status(404).json({
        success: false,
        error: '해당 ID의 노선을 찾을 수 없습니다'
      });
      return;
    }

    res.status(200).json({
      success: true,
      data: route
    });
  } catch (error) {
    logger.error(`노선 조회 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 특정 정류장을 경유하는 노선 목록 조회
 * @route   GET /api/routes/stop/:stopId
 * @access  Public - 누구나 접근 가능
 * @param   {string} stopId - 정류장 ID
 * @returns {object} 해당 정류장을 경유하는 노선 목록
 */
export const getRoutesByStop = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    // 정류장 존재 여부 확인
    const stop = await Stop.findById(req.params.stopId);
    if (!stop) {
      res.status(404).json({
        success: false,
        error: '해당 ID의 정류장을 찾을 수 없습니다'
      });
      return;
    }

    // 해당 정류장을 경유하는 노선 조회
    const routes = await Route.find({ 
      stops: req.params.stopId,
      active: true  // 활성화된 노선만 포함
    });

    res.status(200).json({
      success: true,
      count: routes.length,
      data: routes
    });
  } catch (error) {
    logger.error(`정류장별 노선 조회 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 노선 생성
 * @route   POST /api/routes
 * @access  Private (Admin) - 관리자만 접근 가능
 * @param   {string} name - 노선 이름
 * @param   {string[]} stops - 정류장 ID 배열 (순서대로)
 * @param   {boolean} [active=true] - 노선 활성화 상태
 * @param   {string} [color] - UI 표시용 색상 (HEX)
 * @param   {object[]} [schedules] - 요일별 시간표
 * @returns {object} 생성된 노선 정보
 */
export const createRoute = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { stops } = req.body;

    // 정류장 ID 배열 유효성 검사
    if (stops && stops.length > 0) {
      for (const stopId of stops) {
        const stopExists = await Stop.exists({ _id: stopId });
        if (!stopExists) {
          res.status(400).json({
            success: false,
            error: `ID가 ${stopId}인 정류장이 존재하지 않습니다`
          });
          return;
        }
      }
    }

    // 노선 생성
    const route = await Route.create(req.body);

    // 생성된 노선 ID를 각 정류장의 routes 배열에 추가
    if (stops && stops.length > 0) {
      await Stop.updateMany(
        { _id: { $in: stops } },
        { $addToSet: { routes: route._id } }
      );
    }

    res.status(201).json({
      success: true,
      data: route
    });
  } catch (error) {
    logger.error(`노선 생성 오류: ${error}`);
    
    // 중복 키 오류 처리 (이름 등)
    if ((error as any).code === 11000) {
      res.status(400).json({
        success: false,
        error: '이미 등록된 노선 이름입니다'
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
 * 노선 정보 수정
 * @route   PUT /api/routes/:id
 * @access  Private (Admin) - 관리자만 접근 가능
 * @param   {string} id - 노선 ID
 * @param   {object} updateData - 업데이트할 데이터
 * @returns {object} 업데이트된 노선 정보
 */
export const updateRoute = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { stops } = req.body;
    const oldRoute = await Route.findById(req.params.id);

    if (!oldRoute) {
      res.status(404).json({
        success: false,
        error: '해당 ID의 노선을 찾을 수 없습니다'
      });
      return;
    }

    // 정류장 ID 배열 유효성 검사
    if (stops && stops.length > 0) {
      for (const stopId of stops) {
        const stopExists = await Stop.exists({ _id: stopId });
        if (!stopExists) {
          res.status(400).json({
            success: false,
            error: `ID가 ${stopId}인 정류장이 존재하지 않습니다`
          });
          return;
        }
      }
    }

    // 노선 정보 업데이트
    const route = await Route.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true
    });

    // 정류장 업데이트 로직 - 노선이 변경된 경우
    if (stops && JSON.stringify(oldRoute.stops) !== JSON.stringify(stops)) {
      // 기존 정류장에서 이 노선 ID 제거
      await Stop.updateMany(
        { _id: { $in: oldRoute.stops } },
        { $pull: { routes: oldRoute._id } }
      );
      
      // 새 정류장에 이 노선 ID 추가
      await Stop.updateMany(
        { _id: { $in: stops } },
        { $addToSet: { routes: oldRoute._id } }
      );
    }

    res.status(200).json({
      success: true,
      data: route
    });
  } catch (error) {
    logger.error(`노선 수정 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 노선 삭제
 * @route   DELETE /api/routes/:id
 * @access  Private (Admin) - 관리자만 접근 가능
 * @param   {string} id - 노선 ID
 * @returns {object} 성공 메시지
 */
export const deleteRoute = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const route = await Route.findById(req.params.id);

    if (!route) {
      res.status(404).json({
        success: false,
        error: '해당 ID의 노선을 찾을 수 없습니다'
      });
      return;
    }

    // 트랜잭션 처리가 이상적이지만, 간단하게 구현
    // 1. 이 노선을 참조하는 버스 확인
    const busCount = await Bus.countDocuments({ routeId: route._id });
    if (busCount > 0) {
      res.status(400).json({
        success: false,
        error: '이 노선에 할당된 버스가 있어 삭제할 수 없습니다'
      });
      return;
    }

    // 2. 관련 정류장에서 이 노선 ID 제거
    await Stop.updateMany(
      { routes: route._id },
      { $pull: { routes: route._id } }
    );

    // 3. 노선 삭제
    await route.deleteOne();

    res.status(200).json({
      success: true,
      data: {}
    });
  } catch (error) {
    logger.error(`노선 삭제 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 노선 활성화/비활성화 토글
 * @route   PATCH /api/routes/:id/toggle-active
 * @access  Private (Admin) - 관리자만 접근 가능
 * @param   {string} id - 노선 ID
 * @returns {object} 업데이트된 노선 정보
 */
export const toggleRouteActive = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const route = await Route.findById(req.params.id);

    if (!route) {
      res.status(404).json({
        success: false,
        error: '해당 ID의 노선을 찾을 수 없습니다'
      });
      return;
    }

    // 활성 상태 토글
    route.active = !route.active;
    await route.save();

    res.status(200).json({
      success: true,
      data: route
    });
  } catch (error) {
    logger.error(`노선 활성화 상태 변경 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};