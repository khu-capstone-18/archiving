import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/pages/login_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences 추가

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>> userProfile;
  ApiService apiService = ApiService();

  Future<Map<String, String>> getTokenAndUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('user_id');
    if (token == null || userId == null) {
      throw Exception("Token or User ID not found");
    }
    return {'token': token, 'user_id': userId};
  }

  // 프로필 정보 가져오기
  Future<Map<String, dynamic>> fetchProfile() async {
    final data = await getTokenAndUserId();
    final response = await apiService.fetchUserProfile();
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load profile');
    }
  }

  @override
  void initState() {
    super.initState();
    userProfile = fetchProfile();
  }

  // 로그아웃 처리 함수
  Future<void> logout() async {
    final response = await apiService.logout();
    if (response.statusCode == 200) {
      // 로그아웃 성공 후 로그인 페이지로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(),
        ),
      );
    } else {
      print('Logout failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: logout, // 로그아웃 버튼 클릭 시 실행
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: userProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final profileData = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Username: ${profileData['username']}'),
                  Text('Profile Image: ${profileData['profile_image']}'),
                  // 추가적으로 표시할 프로필 데이터들
                  Text('Total Distance: ${profileData['total_distance']} km'),
                  Text('Total Time: ${profileData['total_time']}'),
                  Text(
                      'Best Record - Distance: ${profileData['best_record']['distance']} km'),
                  Text(
                      'Best Record - Time: ${profileData['best_record']['time']}'),
                  Text('Weekly Goal: ${profileData['weekly_goal']} km'),
                ],
              ),
            );
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }
}
