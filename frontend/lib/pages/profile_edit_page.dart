import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/pages/running_session_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEditPage extends StatefulWidget {
  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final TextEditingController profileImageController = TextEditingController();
  final TextEditingController weeklyGoalController = TextEditingController();
  String errorMessage = '';
  ApiService apiService = ApiService();
  String? token;

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
    });
  }

  Future<void> updateProfile() async {
    if (token == null) {
      setState(() {
        errorMessage = 'User data not found.';
      });
      return;
    }

    final response = await apiService.updateUserProfile(
      token!,
      profileImageController.text.isNotEmpty
          ? profileImageController.text
          : "default_image.png",
      weeklyGoalController.text.isNotEmpty ? weeklyGoalController.text : "0",
    );

    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('first_login', false); // 첫 로그인 플래그 제거
      await prefs.setString('username', 'YOUR_USERNAME'); // username 저장
      await prefs.setString('token', token!); // token 저장

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RunningSessionPage(),
        ),
      );
    } else {
      setState(() {
        errorMessage = 'Profile update failed. Please try again.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: profileImageController,
              decoration: InputDecoration(labelText: 'Profile Image URL'),
            ),
            TextField(
              controller: weeklyGoalController,
              decoration: InputDecoration(labelText: 'Weekly Goal'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateProfile,
              child: Text('Update Profile'),
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
