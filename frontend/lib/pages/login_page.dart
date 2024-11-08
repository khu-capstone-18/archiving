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

  Future<void> login() async {
    final response = await apiService.login(
      usernameController.text,
      passwordController.text,
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', responseData['token']);
      await prefs.setString('user_id', responseData['user_id']);

      bool firstLogin = prefs.getBool('first_login') ?? true;
      print("Is first login: $firstLogin");

      if (firstLogin) {
        await prefs.setBool('first_login', false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileEditPage()),
        );
        print("Navigating to Profile Edit Page."); // 프로필 업데이트 페이지 이동 로그
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RunningSessionPage()),
        );
        print("Navigating to Running Session Page."); // 러닝 세션 페이지 이동 로그
      }
    } else {
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
              onPressed: login,
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
