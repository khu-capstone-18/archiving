import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences 추가

class ApiService {
  final String baseUrl = 'http://localhost:8080';

  // 회원가입 API
  Future<http.Response> signup(String username, String password, String email,
      String nickname, String weight) async {
    final url = Uri.parse('$baseUrl/auth/signup');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
        'nickname': nickname,
        'weight': weight,
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

  // 비밀번호 재설정 요청
  Future<http.Response> requestPasswordReset(String phoneNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phoneNumber}),
    );
    return response;
  }

  // 인증 코드 확인
  Future<http.Response> verifyResetCode(String phoneNumber, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone_number': phoneNumber,
        'verification_code': code,
      }),
    );
    return response;
  }

  // 비밀번호 재설정
  Future<http.Response> resetPassword(
      String phoneNumber, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password/reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone_number': phoneNumber,
        'new_password': newPassword,
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

    final url = Uri.parse('$baseUrl/users/$userId/profile');
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

    final url = Uri.parse('$baseUrl/users/$userId/profile');
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
      print('Token not found in local storage.');
      throw Exception('Token not found in local storage');
    }
    final url = Uri.parse('$baseUrl/auth/logout');
    print('Attempting to logout with token: $token'); // 디버그: 토큰 확인
    print('Sending logout request to URL: $url'); // 디버그: URL 확인

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    // 디버깅용 응답 출력
    print('Logout response status: ${response.statusCode}');
    print('Logout response body: ${response.body}');

    if (response.statusCode == 200) {
      // 성공 시 로컬에 저장된 정보 삭제
      await prefs.remove('token');
      await prefs.remove('user_id');
    } else {
      print('Logout failed with status code: ${response.statusCode}');
    }

    return response;
  }

  // 러닝 세션 저장 API
  Future<http.Response> saveRunningSession({
    required String token,
    required String userId,
    required String startTime,
    required String endTime,
    required double totalDistance,
    required List<Map<String, double>> route,
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
        'route': route,
        'total_distance': totalDistance,
        'total_time': totalTime,
        'average_pace': averagePace,
        'calories_burned': caloriesBurned,
      }),
    );
    return response;
  }

  // 실시간 러닝 데이터 전송 API
  Future<void> sendRealTimeRunningData({
    required String token,
    required String userId,
    required double currentSpeed,
    required String currentPace,
    required int cadence,
    required String elapsedTime,
    required Map<String, double> currentLocation,
  }) async {
    final url = Uri.parse('$baseUrl/running/real-time/$userId');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        'current_location': currentLocation,
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

  // 러닝 코스 생성 API
  Future<http.Response> createRunningCourse({
    required String courseId,
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
    final url = Uri.parse('$baseUrl/running/course/$userId');
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
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

  // 코스 생성 시작 API
  Future<Map<String, dynamic>> startCourse(
      String userId, Map<String, double> startLocation) async {
    final url = Uri.parse('$baseUrl/course/start');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'user_id': userId,
        'location': [startLocation],
        'current_time': DateTime.now().toIso8601String()
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          "Failed to start course with status code: ${response.statusCode}");
    }
  }

  // 코스 위치 업데이트 API
  Future<http.Response> updateCourseLocation(String courseId, String userId,
      List<Map<String, double>> locationList) async {
    final url = Uri.parse('$baseUrl/course/$courseId/location');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'course_id': courseId,
        'user_id': userId,
        'location': locationList,
        'current_time': DateTime.now().toIso8601String(),
      }),
    );
    return response;
  }

  // 코스 종료 API
  Future<Map<String, dynamic>> endCourse(String courseId, String userId,
      List<Map<String, double>> locationList) async {
    final url = Uri.parse('$baseUrl/course/$courseId/end');
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer ${await _getToken()}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        'course_id': courseId,
        'user_id': userId,
        'location': locationList,
        'current_time': DateTime.now().toIso8601String()
      }),
    );

    if (response.statusCode == 200) {
      // 빈 응답 처리
      if (response.body.isEmpty) {
        print("Received empty response from server.");
        return {};
      }
      return jsonDecode(response.body);
    } else {
      throw Exception(
          "Failed to end course with status code: ${response.statusCode}");
    }
  }

  Future<String> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

// 서버에서 받은 total_time을 Duration으로 변환하는 헬퍼 함수
  Duration _parseDuration(String duration) {
    final parts = duration.split(':');
    if (parts.length == 3) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final seconds = int.tryParse(parts[2]) ?? 0;
      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    } else if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      return Duration(minutes: minutes, seconds: seconds);
    } else {
      throw FormatException("Invalid duration format");
    }
  }

  // 러닝 코스 조회
  Future<List<Map<String, dynamic>>> fetchCourses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('user_id');

    if (token == null || userId == null) {
      throw Exception("Token or user ID not found");
    }

    final url = Uri.parse('$baseUrl/users/$userId/courses');
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic>? courses = jsonDecode(response.body);

      // 서버 응답이 null인 경우 빈 리스트 반환
      if (courses == null) {
        return [];
      }
      return courses.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
          "Failed to load courses with status code: ${response.statusCode}");
    }
  }
}
