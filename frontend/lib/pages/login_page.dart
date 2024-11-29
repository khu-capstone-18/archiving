import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/pages/signup_page.dart';
import 'package:frontend/pages/profile_edit_page.dart';
import 'package:frontend/pages/running_session_page.dart';
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

  Future<void> _login(String username, String password) async {
    try {
      final response = await apiService.login(username, password);

      print('Server response: ${response.body}'); // 서버 응답 디버깅

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 서버 응답에서 필드가 존재하는지 확인
        if (data['token'] == null || data['user_id'] == null) {
          throw Exception('Invalid server response: Missing token or user_id.');
        }

        // SharedPreferences에 token과 user_id 저장
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user_id', data['user_id']); // 수정된 부분

        // 첫 로그인 여부 확인 및 처리
        bool firstLogin = prefs.getBool('first_login') ?? true;

        print("Is first login: $firstLogin");

        if (firstLogin) {
          await prefs.setBool('first_login', false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfileEditPage()),
          );
          print("Navigating to Profile Edit Page.");
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => RunningSessionPage()),
          );
          print("Navigating to Running Session Page.");
        }
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
      appBar: AppBar(
        title: Text('Login'),
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _login(
                usernameController.text,
                passwordController.text,
              ),
              child: Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignupPage()),
                );
              },
              child: Text('Don\'t have an account? Sign up here.'),
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
