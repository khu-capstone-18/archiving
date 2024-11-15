import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class ResetPasswordPage extends StatefulWidget {
  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  ApiService apiService = ApiService();
  String message = '';

  // 인증 코드 요청
  Future<void> requestCode() async {
    final response =
        await apiService.requestPasswordReset(phoneController.text);
    if (response.statusCode == 200) {
      setState(() {
        message = 'Code sent to your phone';
      });
    } else {
      setState(() {
        message = 'Failed to send code';
      });
    }
  }

  // 인증 코드 확인
  Future<void> verifyCode() async {
    final response = await apiService.verifyResetCode(
        phoneController.text, codeController.text);
    if (response.statusCode == 200) {
      setState(() {
        message = 'Verification successful. You can now reset your password';
      });
    } else {
      setState(() {
        message = 'Verification failed. Please check your code and try again.';
      });
    }
  }

  // 비밀번호 재설정
  Future<void> resetPassword() async {
    final response = await apiService.resetPassword(
        phoneController.text, newPasswordController.text);
    if (response.statusCode == 200) {
      setState(() {
        message = 'Password reset successful';
      });
    } else {
      setState(() {
        message = 'Failed to reset password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'Phone Number'),
            ),
            ElevatedButton(
              onPressed: requestCode,
              child: Text('Request Code'),
            ),
            TextField(
              controller: codeController,
              decoration: InputDecoration(labelText: 'Verification Code'),
            ),
            ElevatedButton(
              onPressed: verifyCode,
              child: Text('Verify Code'),
            ),
            TextField(
              controller: newPasswordController,
              decoration: InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: resetPassword,
              child: Text('Reset Password'),
            ),
            SizedBox(height: 20),
            Text(message, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
