import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/pages/profile_edit_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = '';
  ApiService apiService = ApiService();

  // 로그인 후 프로필 입력 페이지로 이동
  Future<void> login() async {
    final response = await apiService.login(
        usernameController.text, passwordController.text);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      String token = responseData['token'];
      String userId = responseData['user_id'];

      // user_id와 token을 SharedPreferences에 저장
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
      await prefs.setString('token', token);

      // 프로필 입력 페이지로 이동 (token과 userId 전달 불필요)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileEditPage(),
        ),
      );
    } else {
      setState(() {
        errorMessage = 'Invalid username or password';
      });
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
              onPressed: login,
              child: Text('Login'),
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
