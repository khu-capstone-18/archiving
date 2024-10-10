import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'dart:convert';

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
  String successMessage = '';
  ApiService apiService = ApiService();

  Future<void> signup() async {
    final response = await apiService.signup(
      usernameController.text,
      passwordController.text,
      emailController.text,
      nicknameController.text,
    );

    if (response.statusCode == 200) {
      setState(() {
        successMessage = 'Signup successful! Please log in.';
        errorMessage = '';
      });
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    } else {
      setState(() {
        errorMessage = 'Signup failed';
        successMessage = '';
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
            if (successMessage.isNotEmpty)
              Text(
                successMessage,
                style: TextStyle(color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}
