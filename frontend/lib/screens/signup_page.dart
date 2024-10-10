import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SignupPage extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  void _signup(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final username = _usernameController.text;
    final password = _passwordController.text;
    final email = _emailController.text;
    final nickname = _nicknameController.text;

    try {
      await authProvider.signup(username, password, email, nickname);
      // 회원가입이 성공하면 로그인 페이지로 이동
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      print('Signup failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Signup')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(labelText: 'Nickname'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _signup(context),
              child: Text('Signup'),
            ),
          ],
        ),
      ),
    );
  }
}
