// 인증 상태 관리 프로바이더
// 로그인, 로그아웃, 토큰 관리 등 인증 관련 상태 관리

import 'package:driver_app/config/app_config.dart';
import 'package:driver_app/core/api/auth_api.dart';
import 'package:driver_app/data/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared/models/auth_response.dart';

enum AuthStatus {
  initial,     // 초기 상태
  authenticated, // 인증됨
  unauthenticated, // 인증되지 않음
  loading,     // 로딩 중
  error        // 오류 발생
}

class AuthProvider with ChangeNotifier {
  // 인증 API 서비스
  final AuthApi _authApi = AuthApi();
  
  // 보안 저장소
  final _secureStorage = const FlutterSecureStorage();
  
  // 상태 관리 변수
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _token;
  String? _errorMessage;
  
  // 게터
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  
  // 생성자
  AuthProvider() {
    // 앱 시작 시 저장된 토큰과 사용자 정보 로드
    _loadUserData();
  }
  
  // 저장된 토큰 및 사용자 정보 로드
  Future<void> _loadUserData() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();
      
      final token = await _secureStorage.read(key: AppConfig.tokenKey);
      
      if (token != null) {
        // 토큰이 있으면 사용자 정보 요청
        _token = token;
        await _fetchUserProfile();
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = '세션이 만료되었습니다. 다시 로그인하세요.';
    }
    
    notifyListeners();
  }
  
  // 사용자 프로필 정보 가져오기
  Future<void> _fetchUserProfile() async {
    try {
      final user = await _authApi.getUserProfile(_token!);
      
      // 기사 계정이 아닌 경우 오류 처리
      if (user.role != 'DRIVER') {
        throw Exception('기사 계정으로만 로그인할 수 있습니다.');
      }
      
      _user = UserModel.fromUser(user);
      _status = AuthStatus.authenticated;
    } catch (e) {
      // 오류 발생 시 로그아웃 처리
      await logout();
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    }
  }
    // 사용자 프로필 업데이트
  void updateUserProfile(UserModel updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }
  // 로그인 기능
  Future<bool> login(String email, String password) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      final AuthResponse response = await _authApi.login(email, password);
      
      // 기사 계정인지 확인
      if (response.user.role != 'DRIVER') {
        _errorMessage = '기사 계정으로만 로그인할 수 있습니다.';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
      
      // 토큰 저장
      _token = response.token;
      await _secureStorage.write(key: AppConfig.tokenKey, value: _token);
      
      // 사용자 정보 변환 및 상태 업데이트
      _user = UserModel.fromUser(response.user);
      _status = AuthStatus.authenticated;
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '로그인에 실패했습니다. 다시 시도해주세요.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }
  
  // 로그아웃 기능
  Future<void> logout() async {
    try {
      // API 로그아웃 호출 (선택적)
      if (_token != null) {
        await _authApi.logout(_token!);
      }
    } catch (e) {
      // API 오류는 무시하고 로컬에서 정리
      if (kDebugMode) {
        print('로그아웃 API 오류: $e');
      }
    } finally {
      // 로컬 데이터 정리
      await _secureStorage.delete(key: AppConfig.tokenKey);
      _token = null;
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }
  
  // 토큰 갱신 기능
  Future<bool> refreshToken() async {
    try {
      // 리프레시 토큰이 있는 경우에만 처리
      final refreshToken = await _secureStorage.read(key: AppConfig.refreshTokenKey);
      if (refreshToken == null) {
        return false;
      }
      
      final response = await _authApi.refreshToken(refreshToken);
      
      // 새 토큰 저장
      _token = response.token;
      await _secureStorage.write(key: AppConfig.tokenKey, value: _token);
      
      return true;
    } catch (e) {
      // 토큰 갱신 실패 시 로그아웃
      await logout();
      return false;
    }
  }
}