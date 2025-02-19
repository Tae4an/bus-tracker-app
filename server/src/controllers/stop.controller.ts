/**
 * 정류장 컨트롤러
 * 
 * 버스 정류장 관련 CRUD 작업을 처리
 * 정류장 생성, 조회, 수정, 삭제 및 위치 기반 검색 기능 제공
 */
import { Request, Response, NextFunction } from 'express';
import { Stop, Route } from '../models';
import { logger } from '../utils/logger';

/**
 * 모든 정류장 조회
 * @route   GET /api/stops
 * @access  Public - 누구나 접근 가능
 * @returns {object} 정류장 목록
 */
export const getStops = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    // 쿼리 파라미터 처리
    const { withFacilities, search } = req.query;
    const query: any = {};

    // 시설 유무로 필터링
    if (withFacilities === 'true') {
      query.$or = [
        { 'facilities.hasShelter': true },
        { 'facilities.hasBench': true },
        { 'facilities.hasLighting': true },
        { 'facilities.hasElectronicDisplay': true },
        { 'facilities.isAccessible': true }
      ];
    }

    // 이름 검색
    if (search) {
      query.name = { $regex: search, $options: 'i' };
    }

    const stops = await Stop.find(query)
      .populate('routes', 'name color active');

    res.status(200).json({
      success: true,
      count: stops.length,
      data: stops
    });
  } catch (error) {
    logger.error(`정류장 목록 조회 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 특정 정류장 조회
 * @route   GET /api/stops/:id
 * @access  Public - 누구나 접근 가능
 * @param   {string} id - 정류장 ID
 * @returns {object} 정류장 상세 정보
 */
export const getStop = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const stop = await Stop.findById(req.params.id)
      .populate('routes', 'name color active');

    if (!stop) {
      res.status(404).json({
        success: false,
        error: '해당 ID의 정류장을 찾을 수 없습니다'
      });
      return;
    }

    res.status(200).json({
      success: true,
      data: stop
    });
  } catch (error) {
    logger.error(`정류장 조회 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 특정 위치 근처의 정류장 검색
 * @route   GET /api/stops/nearby
 * @access  Public - 누구나 접근 가능
 * @param   {number} lat - 위도
 * @param   {number} lng - 경도
 * @param   {number} [distance=1000] - 검색 반경(미터)
 * @returns {object} 주변 정류장 목록
 */
export const getNearbyStops = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { lat, lng, distance = 1000 } = req.query;

    // 파라미터 유효성 검사
    if (!lat || !lng) {
      res.status(400).json({
        success: false,
        error: '위도(lat)와 경도(lng)가 필요합니다'
      });
      return;
    }

    const latitude = parseFloat(lat as string);
    const longitude = parseFloat(lng as string);
    const radius = parseFloat(distance as string);

    // 좌표 유효성 검사
    if (isNaN(latitude) || isNaN(longitude) || isNaN(radius)) {
      res.status(400).json({
        success: false,
        error: '유효한 숫자 형식이 아닙니다'
      });
      return;
    }

    // MongoDB 지리 공간 쿼리를 사용한 주변 정류장 검색
    // $near 연산자는 가까운 순서대로 결과 반환
    const stops = await Stop.find({
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [longitude, latitude]  // MongoDB는 [lng, lat] 순서 사용
          },
          $maxDistance: radius  // 미터 단위
        }
      }
    }).populate('routes', 'name color active');

    res.status(200).json({
      success: true,
      count: stops.length,
      data: stops
    });
  } catch (error) {
    logger.error(`주변 정류장 검색 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 정류장 생성
 * @route   POST /api/stops
 * @access  Private (Admin) - 관리자만 접근 가능
 * @param   {string} name - 정류장 이름
 * @param   {object} location - 위치 정보 (위도, 경도)
 * @param   {object} [facilities] - 시설 정보
 * @returns {object} 생성된 정류장 정보
 */
export const createStop = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    // 위치 정보 형식 변환 (클라이언트에서 lat, lng로 보낼 경우)
    if (req.body.location && typeof req.body.location === 'object') {
      const { lat, lng, latitude, longitude } = req.body.location;
      
      // lat/lng 또는 latitude/longitude 형식 모두 지원
      const lat_value = lat || latitude;
      const lng_value = lng || longitude;
      
      if (lat_value !== undefined && lng_value !== undefined) {
        req.body.location = {
          type: 'Point',
          coordinates: [lng_value, lat_value]  // MongoDB GeoJSON 형식
        };
      }
    }

    const stop = await Stop.create(req.body);

    res.status(201).json({
      success: true,
      data: stop
    });
  } catch (error) {
    logger.error(`정류장 생성 오류: ${error}`);
    
    // 중복 키 오류 처리
    if ((error as any).code === 11000) {
      res.status(400).json({
        success: false,
        error: '이미 등록된 정류장 이름 또는 위치입니다'
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
 * 정류장 정보 수정
 * @route   PUT /api/stops/:id
 * @access  Private (Admin) - 관리자만 접근 가능
 * @param   {string} id - 정류장 ID
 * @param   {object} updateData - 업데이트할 데이터
 * @returns {object} 업데이트된 정류장 정보
 */
export const updateStop = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    // 위치 정보 형식 변환 (클라이언트에서 lat, lng로 보낼 경우)
    if (req.body.location && typeof req.body.location === 'object') {
      const { lat, lng, latitude, longitude } = req.body.location;
      
      const lat_value = lat || latitude;
      const lng_value = lng || longitude;
      
      if (lat_value !== undefined && lng_value !== undefined) {
        req.body.location = {
          type: 'Point',
          coordinates: [lng_value, lat_value]
        };
      }
    }

    const stop = await Stop.findById(req.params.id);

    if (!stop) {
      res.status(404).json({
        success: false,
        error: '해당 ID의 정류장을 찾을 수 없습니다'
      });
      return;
    }

    // 정류장 정보 업데이트
    const updatedStop = await Stop.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true
    });

    res.status(200).json({
      success: true,
      data: updatedStop
    });
  } catch (error) {
    logger.error(`정류장 수정 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 정류장 삭제
 * @route   DELETE /api/stops/:id
 * @access  Private (Admin) - 관리자만 접근 가능
 * @param   {string} id - 정류장 ID
 * @returns {object} 성공 메시지
 */
export const deleteStop = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const stop = await Stop.findById(req.params.id);

    if (!stop) {
      res.status(404).json({
        success: false,
        error: '해당 ID의 정류장을 찾을 수 없습니다'
      });
      return;
    }

    // 이 정류장을 참조하는 노선 확인
    const routesUsingStop = await Route.find({ stops: stop._id });
    
    if (routesUsingStop.length > 0) {
      const routeNames = routesUsingStop.map(r => r.name).join(', ');
      res.status(400).json({
        success: false,
        error: `이 정류장은 다음 노선에서 사용 중입니다: ${routeNames}`
      });
      return;
    }

    // 정류장 삭제
    await stop.deleteOne();

    res.status(200).json({
      success: true,
      data: {}
    });
  } catch (error) {
    logger.error(`정류장 삭제 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 정류장 시설 정보 업데이트
 * @route   PATCH /api/stops/:id/facilities
 * @access  Private (Admin) - 관리자만 접근 가능
 * @param   {string} id - 정류장 ID
 * @param   {object} facilities - 시설 정보
 * @returns {object} 업데이트된 정류장 정보
 */
export const updateStopFacilities = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { facilities } = req.body;
    
    if (!facilities || typeof facilities !== 'object') {
      res.status(400).json({
        success: false,
        error: '유효한 시설 정보가 필요합니다'
      });
      return;
    }

    const stop = await Stop.findById(req.params.id);

    if (!stop) {
      res.status(404).json({
        success: false,
        error: '해당 ID의 정류장을 찾을 수 없습니다'
      });
      return;
    }

    // 시설 정보만 업데이트
    const updatedStop = await Stop.findByIdAndUpdate(
      req.params.id,
      { facilities },
      { new: true }
    );

    res.status(200).json({
      success: true,
      data: updatedStop
    });
  } catch (error) {
    logger.error(`정류장 시설 정보 업데이트 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};