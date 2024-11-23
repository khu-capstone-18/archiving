import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class CreateCoursePage extends StatefulWidget {
  @override
  _CreateCoursePageState createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  ApiService apiService = ApiService();
  String? course_Id;
  Timer? locationTimer;
  int secondsElapsed = 0;
  double totalDistance = 0.0;
  String currentPace = "0:00";
  bool isCourseStarted = false;
  StreamSubscription<Position>? positionStream;

  // 현재 위치 가져오기
  Future<Map<String, double>> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
  }

  // 코스 시작
  Future<void> _startCourse() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? user_Id = prefs.getString('user_id');

      if (token == null || user_Id == null) {
        throw Exception('User ID or token not found.');
      }

      Map<String, double> startLocation = await _getCurrentLocation();
      print("Starting location: $startLocation");

      final response = await apiService.startCourse(
        user_Id: user_Id,
        location: startLocation,
        token: token,
      );

      if (response.containsKey('course_id')) {
        setState(() {
          course_Id = response['course_id'];
          isCourseStarted = true;
        });

        print("Course started successfully with ID: $course_Id");

        _startLocationUpdates(token, user_Id);
      } else {
        print("Failed to start course: Response does not contain course_id");
      }
    } catch (e) {
      print("Error starting course: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start course. Please try again.")),
      );
    }
  }

  // 위치 업데이트 시작
  void _startLocationUpdates(String token, String user_Id) {
    positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) async {
      try {
        Map<String, double> currentLocation = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
        await apiService.updateCourseLocation(
          course_Id: course_Id!,
          user_Id: user_Id,
          location: currentLocation,
          token: token,
        );
        print("Location updated: $currentLocation");
        setState(() {
          secondsElapsed += 5;
        });
      } catch (e) {
        print("Error updating location: $e");
      }
    });
  }

  // 실시간 페이스 계산
  void _calculatePace() {
    if (totalDistance > 0) {
      double pace = secondsElapsed / totalDistance;
      int minutes = pace ~/ 60;
      int seconds = (pace % 60).toInt();
      currentPace = "$minutes:${seconds.toString().padLeft(2, '0')}";
    }
  }

  // 코스 종료
  Future<void> _endCourse() async {
    if (locationTimer != null) {
      locationTimer!.cancel(); // 타이머 중단
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? user_Id = prefs.getString('user_id');

    if (course_Id == null || user_Id == null || token == null) {
      print("코스 종료에 필요한 데이터가 없습니다.");
      return;
    }

    try {
      final endLocation = await _getCurrentLocation();
      print("코스 종료 위치: $endLocation");

      final response = await apiService.endCourse(
        course_Id: course_Id!,
        user_Id: user_Id,
        location: endLocation,
        token: token,
      );

      if (response != null && response.containsKey('total_distance')) {
        print('코스 종료 성공: ${response['total_distance']} km');
        setState(() {
          course_Id = null;
          isCourseStarted = false;
          secondsElapsed = 0;
          totalDistance = 0.0;
          currentPace = "0:00";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Course ended successfully.")),
        );
      } else {
        print('서버에서 잘못된 응답을 받았습니다.');
      }
    } catch (e) {
      print('코스 종료 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to end course. Please try again.")),
      );
    }
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Course')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _startCourse,
              child: Text('Start Course'),
            ),
            ElevatedButton(
              onPressed: _endCourse,
              child: Text('End Course'),
            ),
            if (isCourseStarted) ...[
              SizedBox(height: 20),
              Text("경과 시간: $secondsElapsed 초"),
              Text("실시간 페이스: $currentPace"),
            ],
          ],
        ),
      ),
    );
  }
}
