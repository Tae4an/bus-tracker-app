// 로그인 화면
// 기사 계정 인증 UI 구현

import 'package:driver_app/presentation/providers/auth_provider.dart';
import 'package:driver_app/presentation/widgets/app_logo.dart';
import 'package:driver_app/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = true;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // 로그인 처리
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // 키보드 닫기
    FocusScope.of(context).unfocus();
    
    // 로그인 요청
    final success = await Provider.of<AuthProvider>(context, listen: false)
        .login(_emailController.text, _passwordController.text);
    
    if (success && mounted) {
      // 로그인 성공 시 홈 화면으로 이동
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: size.width > 600 ? 500 : size.width * 0.9,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 로고
                  const AppLogo(size: 120),
                  const SizedBox(height: 32),
                  
                  // 앱 타이틀
                  Text(
                    '셔틀버스 기사용 앱',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // 서브타이틀
                  Text(
                    '버스 위치 전송 및 관리',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // 로그인 폼
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // 이메일 입력
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: '이메일',
                            hintText: 'driver@example.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '이메일을 입력해주세요';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return '유효한 이메일 주소를 입력해주세요';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // 비밀번호 입력
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: '비밀번호',
                            hintText: '비밀번호 입력',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '비밀번호를 입력해주세요';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 8),
                        
                        // 자동 로그인
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? true;
                                });
                              },
                            ),
                            const Text('자동 로그인'),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // 오류 메시지
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            if (auth.errorMessage != null) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  auth.errorMessage!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        
                        // 로그인 버튼
                        Consumer<AuthProvider>(
                          builder: (context, auth, child) {
                            return ElevatedButton(
                              onPressed: auth.status == AuthStatus.loading
                                  ? null
                                  : _login,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: auth.status == AuthStatus.loading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('로그인'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 앱 버전
                  Text(
                    '버전 1.0.0',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}