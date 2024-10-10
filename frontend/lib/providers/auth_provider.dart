import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _token;

  UserModel? get user => _user;
  String? get token => _token;

  Future<void> login(String username, String password) async {
    final response = await ApiService().login({
      'username': username,
      'password': password,
    });

    if (response.statusCode == 200) {
      // 응답 데이터에서 토큰을 문자열로 가져오기
      final token =
          response.data['token'].toString(); // 이 부분을 수정하여 항상 String으로 캐스팅
      _token = token;

      // 최소한의 유저 정보를 설정
      _user = UserModel(
        userId: response.data['user_id'].toString(), // userId도 String으로 변환
        username: username,
        email: '', // 필요에 따라 변경
        nickname: '', // 필요에 따라 변경
      );

      notifyListeners();
    } else {
      throw Exception('Login failed');
    }
  }

  Future<void> signup(
      String username, String password, String email, String nickname) async {
    final response = await ApiService().signup({
      'username': username,
      'password': password,
      'email': email,
      'nickname': nickname,
    });

    if (response.statusCode == 200) {
      notifyListeners();
    } else {
      throw Exception('Signup failed');
    }
  }

  Future<void> logout() async {
    if (_token == null) return;

    final response = await ApiService().logout(_token!, {
      'user_id': _user?.userId,
    });

    if (response.statusCode == 200) {
      _user = null;
      _token = null;
      notifyListeners();
    } else {
      throw Exception('Logout failed');
    }
  }

  void setToken(String token) {
    _token = token;
    notifyListeners();
  }

  void clearToken() {
    _token = null;
    _user = null;
    notifyListeners();
  }
}
