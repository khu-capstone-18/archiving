import 'package:flutter/material.dart';
import 'package:frontend/pages/reset_password_page.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/pages/signup_page.dart';
import 'package:frontend/pages/welcome_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  ApiService apiService = ApiService();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = '';

  /// 로그인 로직
  Future<void> _login(String username, String password) async {
    print("Login method called");
    print("Attempting login with:");
    print(" - username: $username");

    try {
      final response = await apiService.login(username, password);

      print("Login API response:");
      print(" - Status code: ${response.statusCode}");
      print(" - Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 서버 응답에서 필드가 존재하는지 확인
        if (data['token'] == null || data['user_id'] == null) {
          throw Exception('Invalid server response: Missing token or user_id.');
        }

        // SharedPreferences에 token과 user_id 저장
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user_id', data['user_id']);
        await prefs.setString('username', username); // 입력한 username 저장

        // 로그인 성공 후 WelcomePage로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WelcomePage()),
        );
      } else {
        throw Exception(
            'Login failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: 428,
              height: 926,
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              child: Stack(
                children: [
                  // 이메일 입력 필드
                  Positioned(
                    left: 42,
                    top: 324,
                    child: SizedBox(
                      width: 329,
                      height: 53,
                      child: TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          hintText: '아이디',
                          hintStyle: TextStyle(
                            color: Colors.black.withOpacity(0.7),
                            fontSize: 18,
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w700,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 20.0),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Color(0xFFEC6E4F),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Color(0xFFEC6E4F),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 비밀번호 입력 필드
                  Positioned(
                    left: 42,
                    top: 402,
                    child: SizedBox(
                      width: 329,
                      height: 53,
                      child: TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: '비밀번호',
                          hintStyle: TextStyle(
                            color: Colors.black.withOpacity(0.7),
                            fontSize: 18,
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w700,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 20.0),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Color(0xFFEC6E4F),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Color(0xFFEC6E4F),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 로그인 버튼
                  Positioned(
                    left: 48,
                    top: 509,
                    child: SizedBox(
                      width: 317,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _login(
                          usernameController.text,
                          passwordController.text,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEC6E4F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        child: const Text(
                          '로그인',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
