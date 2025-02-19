/**
 * 사용자 관리 컨트롤러
 * 
 * 사용자 계정 관련 CRUD 작업을 처리
 * 관리자를 위한 사용자 관리 기능과 사용자 자신의 프로필 관리 기능 제공
 */
import { Request, Response, NextFunction } from 'express';
import { User, UserRole, Bus, Route, Stop } from '../models';
import { logger } from '../utils/logger';

/**
 * 모든 사용자 조회 (관리자용)
 * @route   GET /api/users
 * @access  Private (Admin) - 관리자만 접근 가능
 * @returns {object} 사용자 목록
 */
export const getUsers = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    // 쿼리 파라미터 처리
    const { role, isActive, search } = req.query;
    const query: any = {};

    // 역할로 필터링
    if (role && Object.values(UserRole).includes(role as UserRole)) {
      query.role = role;
    }

    // 활성 상태로 필터링
    if (isActive !== undefined) {
      query.isActive = isActive === 'true';
    }

    // 이름 또는 이메일로 검색
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } }
      ];
    }

    // 페이지네이션 파라미터
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 10;
    
    // 페이지네이션 계산
    const skip = (page - 1) * limit;
    
    // 사용자 조회 (비밀번호 필드 제외)
    const users = await User.find(query)
      .select('-password')
      .skip(skip)
      .limit(limit)
      .sort({ createdAt: -1 });
    
    // 전체 사용자 수 계산 (페이지네이션 정보용)
    const totalUsers = await User.countDocuments(query);

    res.status(200).json({
      success: true,
      count: users.length,
      pagination: {
        page,
        limit,
        totalPages: Math.ceil(totalUsers / limit),
        totalCount: totalUsers
      },
      data: users
    });
  } catch (error) {
    logger.error(`사용자 목록 조회 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 특정 사용자 조회 (관리자용)
 * @route   GET /api/users/:id
 * @access  Private (Admin) - 관리자만 접근 가능
 * @param   {string} id - 사용자 ID
 * @returns {object} 사용자 상세 정보
 */
export const getUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const user = await User.findById(req.params.id).select('-password');

    if (!user) {
      res.status(404).json({
        success: false,
        error: '해당 ID의 사용자를 찾을 수 없습니다'
      });
      return;
    }

    res.status(200).json({
      success: true,
      data: user
    });
  } catch (error) {
    logger.error(`사용자 조회 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 사용자 생성 (관리자용)
 * @route   POST /api/users
 * @access  Private (Admin) - 관리자만 접근 가능
 * @param   {string} name - 사용자 이름
 * @param   {string} email - 이메일
 * @param   {string} password - 비밀번호
 * @param   {string} role - 역할 (PASSENGER, DRIVER, ADMIN)
 * @returns {object} 생성된 사용자 정보
 */
export const createUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    // 이메일 중복 확인
    const existingUser = await User.findOne({ email: req.body.email });
    if (existingUser) {
      res.status(400).json({
        success: false,
        error: '이미 등록된 이메일입니다'
      });
      return;
    }

    // 사용자 생성
    const user = await User.create(req.body);

    // 응답에서 비밀번호 제외
    const { password, ...responseData } = user.toObject();
    res.status(201).json({
      success: true,
      data: responseData
    });
    
  } catch (error) {
    logger.error(`사용자 생성 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 사용자 정보 수정 (관리자용)
 * @route   PUT /api/users/:id
 * @access  Private (Admin) - 관리자만 접근 가능
 * @param   {string} id - 사용자 ID
 * @param   {object} updateData - 업데이트할 데이터
 * @returns {object} 업데이트된 사용자 정보
 */
export const updateUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    // 관리자 자신의 역할 변경 방지
    if (
      req.params.id === req.user.id &&
      req.body.role &&
      req.body.role !== UserRole.ADMIN
    ) {
      res.status(400).json({
        success: false,
        error: '관리자는 자신의 역할을 변경할 수 없습니다'
      });
      return;
    }

    // 이메일 변경 시 중복 확인
    if (req.body.email) {
      const existingUser = await User.findOne({ 
        email: req.body.email,
        _id: { $ne: req.params.id } // 자기 자신 제외
      });
      
      if (existingUser) {
        res.status(400).json({
          success: false,
          error: '이미 등록된 이메일입니다'
        });
        return;
      }
    }

    // 사용자 정보 업데이트
    const user = await User.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true
    }).select('-password');

    if (!user) {
      res.status(404).json({
        success: false,
        error: '해당 ID의 사용자를 찾을 수 없습니다'
      });
      return;
    }

    res.status(200).json({
      success: true,
      data: user
    });
  } catch (error) {
    logger.error(`사용자 수정 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 사용자 삭제 (관리자용)
 * @route   DELETE /api/users/:id
 * @access  Private (Admin) - 관리자만 접근 가능
 * @param   {string} id - 사용자 ID
 * @returns {object} 성공 메시지
 */
export const deleteUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    // 관리자 자신의 삭제 방지
    if (req.params.id === req.user.id) {
      res.status(400).json({
        success: false,
        error: '관리자는 자신의 계정을 삭제할 수 없습니다'
      });
      return;
    }

    const user = await User.findById(req.params.id);

    if (!user) {
      res.status(404).json({
        success: false,
        error: '해당 ID의 사용자를 찾을 수 없습니다'
      });
      return;
    }

    // 사용자가 기사인 경우, 운행 중인 버스가 있는지 확인
    if (user.role === UserRole.DRIVER) {
      const activeDriver = await Bus.findOne({ driverId: user._id });
      if (activeDriver) {
        res.status(400).json({
          success: false,
          error: '이 기사는 현재 버스에 배정되어 있어 삭제할 수 없습니다'
        });
        return;
      }
    }

    // 사용자 삭제
    await user.deleteOne();

    res.status(200).json({
      success: true,
      data: {}
    });
  } catch (error) {
    logger.error(`사용자 삭제 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 사용자 비밀번호 변경 (관리자용)
 * @route   PUT /api/users/:id/password
 * @access  Private (Admin) - 관리자만 접근 가능
 * @param   {string} id - 사용자 ID
 * @param   {string} newPassword - 새 비밀번호
 * @returns {object} 성공 메시지
 */
export const resetUserPassword = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { newPassword } = req.body;

    if (!newPassword || newPassword.length < 6) {
      res.status(400).json({
        success: false,
        error: '비밀번호는 최소 6자 이상이어야 합니다'
      });
      return;
    }

    const user = await User.findById(req.params.id);

    if (!user) {
      res.status(404).json({
        success: false,
        error: '해당 ID의 사용자를 찾을 수 없습니다'
      });
      return;
    }

    // 비밀번호 업데이트
    user.password = newPassword;
    await user.save();

    res.status(200).json({
      success: true,
      message: '비밀번호가 성공적으로 변경되었습니다'
    });
  } catch (error) {
    logger.error(`비밀번호 변경 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 사용자 활성화/비활성화 토글 (관리자용)
 * @route   PATCH /api/users/:id/toggle-active
 * @access  Private (Admin) - 관리자만 접근 가능
 * @param   {string} id - 사용자 ID
 * @returns {object} 업데이트된 사용자 정보
 */
export const toggleUserActive = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    // 관리자 자신의 비활성화 방지
    if (req.params.id === req.user.id) {
      res.status(400).json({
        success: false,
        error: '관리자는 자신의 계정을 비활성화할 수 없습니다'
      });
      return;
    }

    const user = await User.findById(req.params.id);

    if (!user) {
      res.status(404).json({
        success: false,
        error: '해당 ID의 사용자를 찾을 수 없습니다'
      });
      return;
    }

    // 활성 상태 토글
    user.isActive = !user.isActive;
    await user.save();

    // 응답에서 비밀번호 제외
    const { password, ...responseData } = user.toObject();
    res.status(201).json({
      success: true,
      data: responseData
    });

  } catch (error) {
    logger.error(`사용자 활성화 상태 변경 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 내 프로필 정보 수정
 * @route   PUT /api/users/profile
 * @access  Private - 인증된 사용자만 접근 가능
 * @param   {string} [name] - 이름
 * @param   {string} [phoneNumber] - 전화번호
 * @param   {string} [profileImageUrl] - 프로필 이미지 URL
 * @returns {object} 업데이트된 사용자 정보
 */
export const updateProfile = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    // 수정 가능한 필드 제한
    const allowedFields = ['name', 'phoneNumber', 'profileImageUrl'];
    const updates: any = {};
    
    Object.keys(req.body).forEach(key => {
      if (allowedFields.includes(key)) {
        updates[key] = req.body[key];
      }
    });

    // 프로필 정보 업데이트
    const user = await User.findByIdAndUpdate(req.user.id, updates, {
      new: true,
      runValidators: true
    }).select('-password');

    res.status(200).json({
      success: true,
      data: user
    });
  } catch (error) {
    logger.error(`프로필 수정 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 내 비밀번호 변경
 * @route   PUT /api/users/change-password
 * @access  Private - 인증된 사용자만 접근 가능
 * @param   {string} currentPassword - 현재 비밀번호
 * @param   {string} newPassword - 새 비밀번호
 * @returns {object} 성공 메시지
 */
export const changePassword = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { currentPassword, newPassword } = req.body;

    // 필수 필드 검증
    if (!currentPassword || !newPassword) {
      res.status(400).json({
        success: false,
        error: '현재 비밀번호와 새 비밀번호를 모두 입력해주세요'
      });
      return;
    }

    // 새 비밀번호 길이 검증
    if (newPassword.length < 6) {
      res.status(400).json({
        success: false,
        error: '새 비밀번호는 최소 6자 이상이어야 합니다'
      });
      return;
    }

    // 비밀번호 필드를 포함하여 사용자 조회
    const user = await User.findById(req.user.id).select('+password');

    // null 체크
    if (!user) {
      res.status(404).json({
        success: false,
        error: '사용자를 찾을 수 없습니다'
      });
      return;
    }
    // 현재 비밀번호 확인
    const isMatch = await user.matchPassword(currentPassword);
    if (!isMatch) {
      res.status(401).json({
        success: false,
        error: '현재 비밀번호가 일치하지 않습니다'
      });
      return;
    }

    // 비밀번호 업데이트
    user.password = newPassword;
    await user.save();

    res.status(200).json({
      success: true,
      message: '비밀번호가 성공적으로 변경되었습니다'
    });
  } catch (error) {
    logger.error(`비밀번호 변경 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};

/**
 * 즐겨찾기 노선/정류장 관리
 * @route   PUT /api/users/favorites
 * @access  Private - 인증된 사용자만 접근 가능
 * @param   {string[]} [favoriteRoutes] - 즐겨찾기 노선 ID 배열
 * @param   {string[]} [favoriteStops] - 즐겨찾기 정류장 ID 배열
 * @returns {object} 업데이트된 즐겨찾기 정보
 */
export const updateFavorites = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { favoriteRoutes, favoriteStops } = req.body;
    const updates: any = {};

    // 노선 즐겨찾기 업데이트
    if (favoriteRoutes !== undefined) {
      // 유효한 노선 ID인지 확인
      if (favoriteRoutes.length > 0) {
        const validRoutes = await Route.find({ 
          _id: { $in: favoriteRoutes },
          active: true
        });
        updates.favoriteRoutes = validRoutes.map(route => route._id);
      } else {
        updates.favoriteRoutes = [];
      }
    }

    // 정류장 즐겨찾기 업데이트
    if (favoriteStops !== undefined) {
      // 유효한 정류장 ID인지 확인
      if (favoriteStops.length > 0) {
        const validStops = await Stop.find({ _id: {
          $in: favoriteStops 
        }});
        updates.favoriteStops = validStops.map(stop => stop._id);
      } else {
        updates.favoriteStops = [];
      }
    }

    // 필드가 업데이트되지 않는 경우
    if (Object.keys(updates).length === 0) {
      res.status(400).json({
        success: false,
        error: '업데이트할 즐겨찾기 정보가 없습니다'
      });
      return;
    }

    // 사용자 정보 업데이트
    const user = await User.findByIdAndUpdate(req.user.id, updates, {
      new: true
    })
      .select('-password')
      .populate('favoriteRoutes', 'name color')
      .populate('favoriteStops', 'name location');

      // null 체크
    if (!user) {
      res.status(404).json({
        success: false,
        error: '사용자를 찾을 수 없습니다'
      });
      return;
    }

    res.status(200).json({
      success: true,
      data: {
        favoriteRoutes: user.favoriteRoutes,
        favoriteStops: user.favoriteStops
      }
    });
  } catch (error) {
    logger.error(`즐겨찾기 업데이트 오류: ${error}`);
    res.status(500).json({
      success: false,
      error: '서버 오류가 발생했습니다'
    });
  }
};