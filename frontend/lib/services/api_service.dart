import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences 추가

class ApiService {
  final String baseUrl = "http://192.168.67.34:8080";
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

  // 로그인
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

// 로그아웃
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
      // 성공 시 필요한 데이터만 삭제
      await prefs.remove('token'); // 토큰 삭제
      await prefs.remove('user_id'); // 사용자 ID 삭제
      print("Logout completed. first_login 상태 유지.");
    } else {
      print('Logout failed with status code: ${response.statusCode}');
    }

    return response;
  }

// 유저 프로필 조회
  Future<Map<String, dynamic>> fetchUserProfile({
    required String token,
    required String username,
  }) async {
    final url = Uri.parse('$baseUrl/users/$username/profile');

    // 요청 시작 로그
    print('Fetching user profile from: $url');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    // 응답 로그
    print('User profile response status: ${response.statusCode}');
    print('User profile response body: ${response.body}');

    if (response.statusCode == 200) {
      // JSON 파싱
      final Map<String, dynamic> data = json.decode(response.body);

      if (!data.containsKey('user_id') || data['user_id'] == null) {
        throw Exception('Invalid user profile response: Missing user_id');
      }

      return data;
    } else {
      throw Exception(
          'Failed to fetch user profile. Status code: ${response.statusCode}');
    }
  }

// 유저 프로필 업데이트
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

// 달리기 시작 (페이스 메이커 기능 사용 시작)
  Future<Map<String, dynamic>> startRunning({
    required String courseId,
    required Map<String, double> location,
    required String name,
    required bool public,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/courses/$courseId/child/start');

    final requestBody = {
      'location': {
        'latitude': location['latitude'],
        'longitude': location['longitude'],
      },
      'name': name,
      'public': public,
    };

    print("달리기 시작 요청 URL: $url");
    print("달리기 시작 요청 데이터: ${jsonEncode(requestBody)}");

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
            "달리기 시작 요청 실패: 상태 코드 ${response.statusCode}, 응답 ${response.body}");
      }
    } catch (e) {
      print("달리기 시작 요청 중 오류 발생: $e");
      throw e;
    }
  }

// 실시간 따라 달리기 데이터 전송
  Future<Map<String, dynamic>> sendFollowingData({
    required String token,
    required String courseId,
    required String userId,
    required double latitude,
    required double longitude,
    required String currentTime,
  }) async {
    final url = Uri.parse('$baseUrl/courses/$courseId/session/data');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "course_id": courseId,
        "user_id": userId,
        "location": {"latitude": latitude, "longitude": longitude},
        "current_time": currentTime,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to send following data');
    }
  }

// 실시간 혼자 달리기 데이터 전송
  Future<Map<String, dynamic>> sendSoloData({
    required String token,
    required String courseId,
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse('$baseUrl/courses/$courseId/location');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "location": {"latitude": latitude, "longitude": longitude},
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to send solo data');
    }
  }

// 달리기 종료
  Future<void> stopRunning({
    required String token,
    required String courseId,
    required String userId,
    required double latitude,
    required double longitude,
    required String currentTime,
  }) async {
    final url = Uri.parse('$baseUrl/courses/$courseId/session/stop');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "course_id": courseId,
        "user_id": userId,
        "location": {"latitude": latitude, "longitude": longitude},
        "current_time": currentTime,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to stop running');
    }
  }

  // 러닝 코스 생성 시작
  Future<Map<String, dynamic>> startCourse({
    required Map<String, double> location,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/course/start');
    final requestBody = jsonEncode({'location': location});

    print("Start Course Request URL: $url");
    print("Request Body: $requestBody");

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: requestBody,
    );

    print("Response Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          "Failed to start course: ${response.statusCode}, ${response.body}");
    }
  }

  // 코스 생성 종료
  Future<Map<String, dynamic>> endCourse({
    required String courseId,
    required String courseName,
    required bool public,
    required String userId,
    required List<Map<String, double>> location,
    required String currentTime,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/courses/$courseId/end');

    final requestBody = {
      'course_id': courseId,
      'course_name': courseName,
      'public': public,
      'user_id': userId,
      'location': location,
      'current_time': currentTime,
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
}
