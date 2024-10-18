import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences 추가

class ApiService {
  final String baseUrl = 'http://localhost:8080';

  // 회원가입 API
  Future<http.Response> signup(
      String username, String password, String email, String nickname) async {
    final url = Uri.parse('$baseUrl/auth/signup');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
        'nickname': nickname,
      }),
    );
    return response;
  }

  // 로그인 API
  Future<http.Response> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );
    return response;
  }

  // 유저 프로필 조회 API
  Future<http.Response> fetchUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('user_id');

    if (token == null || userId == null) {
      throw Exception('User ID or token not found in local storage');
    }

    final url = Uri.parse('$baseUrl/user/profile/$userId');
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
    return response;
  }

  // 유저 프로필 업데이트 API
  Future<http.Response> updateUserProfile(String userId, String profileImage,
      String nickname, String weeklyGoal, double weight) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null || userId == null) {
      throw Exception('User ID or token not found in local storage');
    }

    final url = Uri.parse('$baseUrl/user/profile/$userId');
    final response = await http.put(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        'user_id': userId,
        'profile_image': profileImage,
        'nickname': nickname,
        'weekly_goal': weeklyGoal,
        'weight': weight,
      }),
    );
    return response;
  }

  // 로그아웃 API
  Future<http.Response> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token not found in local storage');
    }

    final url = Uri.parse('$baseUrl/auth/logout');
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    // 로그아웃 시 로컬에 저장된 정보 삭제
    await prefs.remove('token');
    await prefs.remove('user_id');

    return response;
  }

  // 러닝 세션 저장 API
  Future<http.Response> saveRunningSession({
    required String token,
    required String userId,
    required String startTime,
    required String endTime,
    required double totalDistance,
    required int totalTime,
    required String averagePace,
    required double caloriesBurned,
  }) async {
    final url = Uri.parse('$baseUrl/running/session/$userId');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        'start_time': startTime,
        'end_time': endTime,
        'total_distance': totalDistance,
        'total_time': totalTime,
        'average_pace': averagePace,
        'calories_burned': caloriesBurned,
      }),
    );
    return response;
  }

  // 실시간 러닝 데이터 전송 API (Gyroscope 포함)
  Future<void> sendRealTimeRunningData({
    required String token,
    required String userId,
    required Map<String, double> gyroscopeData,
    required double currentSpeed,
    required String currentPace,
    required int cadence,
    required String elapsedTime,
  }) async {
    final url = Uri.parse('$baseUrl/running/real-time/$userId');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        'gyroscope_data': gyroscopeData,
        'current_speed': currentSpeed,
        'current_pace': currentPace,
        'cadence': cadence,
        'elapsed_time': elapsedTime,
      }),
    );

    if (response.statusCode == 200) {
      print('Real-time data sent successfully');
    } else {
      print('Failed to send real-time data');
    }
  }

  // 러닝 코스 생성 API 호출 추가
  Future<http.Response> createRunningCourse({
    required String token,
    required String userId,
    required String courseName,
    required String description,
    required List<Map<String, double>> route,
    required Map<String, double> startPoint,
    required Map<String, double> endPoint,
    required double length,
    required double estimatedTime,
  }) async {
    final url = Uri.parse('$baseUrl/course');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        'user_id': userId,
        'course_name': courseName,
        'description': description,
        'start_point': startPoint,
        'end_point': endPoint,
        'route': route,
        'length': length,
        'estimated_time': estimatedTime,
      }),
    );
    return response;
  }
}
