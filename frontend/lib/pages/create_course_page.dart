import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';

class CreateCoursePage extends StatefulWidget {
  @override
  _CreateCoursePageState createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  ApiService apiService = ApiService();
  List<Map<String, double>> locationList = [];
  String? courseId;
  Timer? _timer;
  int _secondsElapsed = 0;
  double _totalDistance = 0.0;
  int _cadence = 0;
  String _currentPace = "0:00";
  bool isCourseStarted = false;

  // 위치 데이터를 locationList에 추가
  Future<void> _addCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        locationList.add({
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      });
      print("Current location added to locationList: ${locationList.last}");
    } catch (e) {
      print("Error fetching location: $e");
    }
  }

  String getCurrentTimeInISO8601() {
    final now = DateTime.now().toUtc();
    return now.toIso8601String().split('.').first;
  }

  // 코스 시작
  Future<void> _startCourse() async {
    print("Attempting to start course...");

    if (locationList.isEmpty) {
      await _addCurrentLocation();
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    print("User ID from SharedPreferences: $userId");

    if (userId == null || locationList.isEmpty) {
      print("User ID or location list is null/empty.");
      if (userId == null) {
        print("Error: user_id not found. Ensure user_id is saved after login.");
      }
      if (locationList.isEmpty) {
        print(
            "Error: location list is empty. Ensure locations are added before starting course.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please add a location to start the course.")),
        );
      }
      return;
    }

    final startLocation = locationList.first;
    final currentTime = getCurrentTimeInISO8601();

    print("Request Body: ${jsonEncode({
          'user_id': userId,
          'location': [startLocation],
          'current_time': currentTime,
        })}");

    try {
      final response = await apiService.startCourse(userId, startLocation);
      if (response != null && response.containsKey('course_id')) {
        setState(() {
          courseId = response['course_id'];
          isCourseStarted = true;
        });

        print("Course started successfully with ID: $courseId");

        // 5초마다 위치 추가 및 데이터 갱신
        _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) async {
          await _addCurrentLocation();
          setState(() {
            _secondsElapsed += 5;
            _calculatePace();
            _calculateCadence();
          });
        });
      } else {
        print("No course_id in response: $response");
      }
    } catch (error) {
      print("Error in startCourse API call: $error");
    }
  }

  // 실시간 페이스 계산
  void _calculatePace() {
    if (_totalDistance > 0) {
      double pace = _secondsElapsed / _totalDistance;
      int minutes = pace ~/ 60;
      int seconds = (pace % 60).toInt();
      _currentPace = "$minutes:${seconds.toString().padLeft(2, '0')}";
    }
  }

  // 실시간 케이던스 계산
  void _calculateCadence() {
    _cadence = (_totalDistance / _secondsElapsed * 100).toInt();
  }

  // 코스 종료
  void _endCourse() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    if (courseId == null || userId == null) return;

    final response =
        await apiService.endCourse(courseId!, userId, locationList);
    print('Course ended: ${response['total_distance']} km');
    setState(() {
      locationList.clear();
      courseId = null;
      isCourseStarted = false;
      _secondsElapsed = 0;
      _currentPace = "0:00";
      _cadence = 0;
      _totalDistance = 0.0;
    });

    // 타이머 종료
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Course')),
      body: Column(
        children: [
          ElevatedButton(onPressed: _startCourse, child: Text('Start Course')),
          ElevatedButton(onPressed: _endCourse, child: Text('End Course')),
          if (isCourseStarted) ...[
            Text("경과 시간: $_secondsElapsed 초"),
            Text("실시간 페이스: $_currentPace"),
            Text("실시간 케이던스: $_cadence"),
          ],
        ],
      ),
    );
  }
}
