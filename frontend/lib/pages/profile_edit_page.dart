import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/pages/profile_page.dart';
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
      profileImageController.text,
      weeklyGoalController.text,
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
