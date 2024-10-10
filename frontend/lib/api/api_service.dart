import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio();

  // 로그인 요청
  Future<Response> login(Map<String, dynamic> credentials) async {
    return await _dio.post(
      'http://localhost:8080/auth/login',
      data: credentials,
      options: Options(
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  // 회원가입 요청
  Future<Response> signup(Map<String, dynamic> userInfo) async {
    return await _dio.post(
      'http://localhost:8080/auth/signup',
      data: userInfo,
      options: Options(
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  // 로그아웃 요청
  Future<Response> logout(String token, Map<String, dynamic> userData) async {
    return await _dio.post(
      'http://localhost:8080/auth/logout',
      data: userData,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<Response> getUserProfile(String userId, String token) async {
    try {
      final response = await _dio.get(
        'http://localhost:8080/user/profile/$userId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } catch (e) {
      throw Exception('Failed to load profile');
    }
  }
}
