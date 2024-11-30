import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences 추가

class ApiService {
  final String baseUrl = "http://172.30.1.32:8080"; // PC의 IPv4 주소

  // 회원가입
  Future<http.Response> signup(
      String username, String password, String email, String weight) async {
    final url = Uri.parse('$baseUrl/auth/signup');
    final body = jsonEncode({
      'username': username,
      'password': password,
      'email': email,
      'weight': weight,
    });
    return await http.post(url,
        headers: {'Content-Type': 'application/json'}, body: body);
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
  Future<Map<String, dynamic>> fetchUserProfile({
    required String token,
    required String username,
  }) async {
    final url = Uri.parse('$baseUrl/users/$username/profile');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch user profile: ${response.statusCode}');
    }
  }

  // 유저 프로필 업데이트 API
  Future<http.Response> updateUserProfile(
      String token, String profileImage, String weeklyGoal) async {
    final url = Uri.parse('$baseUrl/profile');
    return await http.put(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        'profile_image': profileImage,
        'weekly_goal': weeklyGoal,
      }),
    );
  }

  // 로그아웃 API
  Future<http.Response> logout(String token) async {
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
    required String user_Id,
    required String startTime,
    required String endTime,
    required double totalDistance,
    required List<Map<String, double>> route,
    required int totalTime,
    required String averagePace,
    required double caloriesBurned,
  }) async {
    final url = Uri.parse('$baseUrl/running/session/$user_Id');
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

  // 러닝 코스 생성 시작 API
  Future<Map<String, dynamic>> startCourse({
    required Map<String, double> location,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/course/start');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'location': location}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          "Failed to start course: ${response.statusCode}, ${response.body}");
    }
  }

  Future<Map<String, dynamic>> createCourse({
    required String userId,
    required String courseName,
    required String description,
    required Map<String, double> startPoint,
    required Map<String, double> endPoint,
    required List<Map<String, double>> route,
    required double length,
    required int estimatedTime,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/course');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
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

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          "Failed to create course: ${response.statusCode}, ${response.body}");
    }
  }

// 전체 유저 러닝 코스 조회
  Future<List<Map<String, dynamic>>> fetchCourses(String token) async {
    final url = Uri.parse('$baseUrl/courses');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      // 응답 데이터를 파싱하여 반환
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((course) => {
                'course_id': course['course_id'],
                'course_name': course['course_name'],
                'creator_id': course['creator_id'],
              })
          .toList();
    } else {
      throw Exception(
          'Failed to fetch courses. Status Code: ${response.statusCode}');
    }
  }

  // 코스 종료
  Future<Map<String, dynamic>> endCourse({
    required String course_Id,
    required String course_name,
    required bool public,
    required String user_Id,
    required Map<String, double> location,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/courses/$course_Id/end');

    final requestBody = {
      'course_id': course_Id,
      'course_name': course_name,
      'user_id': user_Id,
      'location': [
        {'latitude': location['latitude'], 'longitude': location['longitude']}
      ],
      'current_time': DateTime.now().toIso8601String(),
      'public': public,
    };

    print("코스 종료 요청 URL: $url");
    print("코스 종료 요청 데이터: ${jsonEncode(requestBody)}");

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print("응답 상태 코드: ${response.statusCode}");
      print("응답 본문: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            "코스 종료 요청 실패: 상태 코드 ${response.statusCode}, 응답 ${response.body}");
      }
    } catch (e) {
      print("코스 종료 요청 중 오류 발생: $e");
      throw e;
    }
  }

  Future<String> getToken() async {
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

  //따라 달리기 데이터 전송
  Future<Map<String, dynamic>> updateRunningSessionLocation({
    required String courseId,
    required String userId,
    required Map<String, double> location,
    required String currentTime,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/courses/$courseId/session/data');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'course_id': courseId,
        'user_id': userId,
        'location': location,
        'current_time': currentTime,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          "Failed to update running session location. Status code: ${response.statusCode}");
    }
  }

  // 혼자 달리기 데이터 전송
  Future<Map<String, dynamic>> updateCourseLocation({
    required String courseId,
    required Map<String, double> location,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/courses/$courseId/location');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'location': location,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          "Failed to update course location. Status code: ${response.statusCode}");
    }
  }

  // 실시간 러닝 데이터 전송 API
  Future<void> sendRealTimeRunningData({
    required String user_Id,
    required Map<String, double> currentLocation,
    required double currentSpeed,
    required String currentPace,
    required String elapsedTime,
    required int cadence,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/running/real-time/$user_Id');

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        'current_location': {
          'latitude': currentLocation['latitude'],
          'longitude': currentLocation['longitude'],
        },
        'current_speed': currentSpeed,
        'current_pace': currentPace,
        'elapsed_time': elapsedTime,
        'cadence': cadence,
      }),
    );

    if (response.statusCode == 200) {
      print('실시간 러닝 데이터 전송 성공: ${response.body}');
    } else {
      print('실시간 러닝 데이터 전송 실패: ${response.statusCode}, 응답: ${response.body}');
      throw Exception(
          "실시간 데이터 전송 실패: 상태 코드 ${response.statusCode}, 응답 ${response.body}");
    }
  }
}
