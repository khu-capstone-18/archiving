import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  ApiService apiService = ApiService();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  String errorMessage = '';

  Future<void> signup() async {
    print('Signup method called');

    // SharedPreferences 초기화
    SharedPreferences prefs = await SharedPreferences.getInstance();

    print("회원가입 완료 후 SharedPreferences 상태:");
    print(" - token: ${prefs.getString('token')}");
    print(" - user_id: ${prefs.getString('user_id')}");
    print(" - first_login: ${prefs.getBool('first_login')}");

    try {
      final response = await apiService.signup(
        usernameController.text,
        passwordController.text,
        emailController.text,
        weightController.text,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        try {
          await prefs.setBool('first_login', true);
          await prefs.setString('token', responseData['token']);
          await prefs.setString('user_id', responseData['user_id']);

          print("데이터 저장 후 SharedPreferences 상태:");
          print(" - first_login: ${prefs.getBool('first_login')}");
          print(" - token: ${prefs.getString('token')}");
          print(" - user_id: ${prefs.getString('user_id')}");
        } catch (e) {
          setState(() {
            errorMessage = 'Failed to save user data. Please try again.';
          });
          print("Error saving data to SharedPreferences: $e");
          return; // 에러 발생 시 추가 동작 중단
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else if (response.statusCode == 409) {
        setState(() {
          errorMessage = 'Username already exists. Please try another one.';
        });
        print("Signup failed: Username already exists.");
      } else {
        setState(() {
          errorMessage = 'Signup failed. Please try again.';
        });
        print(
            "Signup failed with unknown error. Status code: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred. Please try again.';
      });
      print('Error during signup: $e');
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
              controller: weightController,
              decoration: InputDecoration(labelText: 'Weight'),
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
