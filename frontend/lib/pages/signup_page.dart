import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/pages/profile_edit_page.dart'; // 프로필 입력 페이지로 이동
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences 추가

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  String errorMessage = '';
  ApiService apiService = ApiService();

  // 회원가입 후 자동 로그인 처리 함수
  Future<void> signup() async {
    final response = await apiService.signup(
      usernameController.text,
      passwordController.text,
      emailController.text,
      nicknameController.text,
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      String token = responseData['token'];
      String userId = responseData['user_id'];

      // user_id와 token을 SharedPreferences에 저장
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
      await prefs.setString('token', token);

      // 회원가입 성공 후 자동으로 프로필 입력 화면으로 이동 (token과 userId 전달 불필요)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileEditPage(),
        ),
      );
    } else {
      setState(() {
        errorMessage = 'Signup failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Signup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: nicknameController,
              decoration: InputDecoration(labelText: 'Nickname'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: signup,
              child: Text('Sign Up'),
            ),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
