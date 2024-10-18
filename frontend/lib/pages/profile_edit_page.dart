import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/pages/profile_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEditPage extends StatefulWidget {
  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController profileImageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController weeklyGoalController = TextEditingController();
  String errorMessage = '';
  ApiService apiService = ApiService();
  String? token;
  String? userId;

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
      userId = prefs.getString('user_id');
    });
  }

  // 프로필 업데이트
  Future<void> updateProfile() async {
    if (token == null || userId == null) {
      setState(() {
        errorMessage = 'User data not found.';
      });
      return;
    }

    // updateUserProfile 호출 부분
    final response = await apiService.updateUserProfile(
      userId!, // userId 추가
      profileImageController.text,
      nicknameController.text,
      weeklyGoalController.text,
      double.parse(weightController.text), // weight 추가
    );

    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(),
        ),
      );
    } else {
      setState(() {
        errorMessage = 'Profile update failed';
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
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: profileImageController,
              decoration: InputDecoration(labelText: 'Profile Image URL'),
            ),
            TextField(
              controller: nicknameController,
              decoration: InputDecoration(labelText: 'Nickname'),
            ),
            TextField(
              controller: weeklyGoalController,
              decoration: InputDecoration(labelText: 'Weekly Goal'),
            ),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Weight (kg)'),
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
