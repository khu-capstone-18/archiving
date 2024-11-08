import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/pages/running_session_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  /*
  Future<Map<String, dynamic>> fetchUserProfile() async {
    try {
      final response = await apiService.fetchUserProfile();
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Best Record 데이터가 있는 경우만 가져오기
        if (responseData['best_record'] != null) {
          responseData['best_record'] = responseData['best_record'];
        } else {
          // Best Record가 없을 경우 기본값 설정
          responseData['best_record'] = {'distance': 0, 'time': 0};
        }

        return responseData;
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      print('Error fetching profile: $e');
      throw Exception('Error fetching profile');
    }
  }
*/
  // 프로필 정보 가져오기 (임시 코드 - 서버 오류 시 기본값 설정)
  Future<Map<String, dynamic>> fetchUserProfile() async {
    try {
      final response = await apiService.fetchUserProfile();
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // 서버가 total_distance, total_time, best_record를 반환하지 못할 때 기본값을 설정 (임시 코드)
        responseData['total_distance'] ??= 0; // total_distance 기본값
        responseData['total_time'] ??= 0; // total_time 기본값
        responseData['best_record'] ??= {
          'distance': 0,
          'time': 0
        }; // best_record 기본값

        return responseData;
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      // 임시 코드: 서버 오류 시 무한 재시도 방지 및 기본값 반환
      print('Error fetching profile (임시 코드): $e');
      return {
        'username': 'Unknown',
        'profile_image': '',
        'total_distance': 0,
        'total_time': 0,
        'best_record': {'distance': 0, 'time': 0},
        'weekly_goal': 0
      };
    }
  }

  @override
  void initState() {
    super.initState();
    userProfile = fetchUserProfile();
  }

  // 로그아웃 처리 함수
  Future<void> logout() async {
    try {
      // 서버에 로그아웃 요청
      final response = await apiService.logout();

      if (response.statusCode == 200) {
        // 로그아웃 성공 시 SharedPreferences에서 토큰과 user_id 삭제
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('user_id');

        // 로그인 페이지로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        // 로그아웃 실패 시 사용자에게 알림
        print('Logout failed with status: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed. Please try again.')),
        );
      }
    } catch (e) {
      // 네트워크 오류 등 예외 발생 시 처리
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again later.')),
      );
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
            onPressed: logout,
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
                  Text('Total Distance: ${profileData['total_distance']} km'),
                  Text('Total Time: ${profileData['total_time']}'),
                  Text(
                      'Best Record - Distance: ${profileData['best_record']['distance']} km'),
                  Text(
                      'Best Record - Time: ${profileData['best_record']['time']}'),
                  Text('Weekly Goal: ${profileData['weekly_goal']} km'),
                  SizedBox(height: 20),
                  // 프로필 페이지에서 러닝 세션으로 이동하는 버튼
                  ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('first_login', false);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RunningSessionPage(),
                        ),
                      );
                    },
                    child: Text('Go to Running Session'),
                  ),
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
