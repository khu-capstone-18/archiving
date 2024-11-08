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
  List<Map<String, double>> locationList = [];
  String? courseId;
  Timer? _timer;
  int _secondsElapsed = 0;
  double _totalDistance = 0.0;
  int _cadence = 0;
  String _currentPace = "0:00";
  bool isCourseStarted = false;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  // 위치 추적 시작
  void _startLocationTracking() async {
    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        locationList.add({
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      });
      if (isCourseStarted && courseId != null) {
        apiService.updateCourseLocation(courseId!, 'userId', locationList);
      }
    });
  }

  // 코스 시작
  void _startCourse() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    if (userId == null || locationList.isEmpty) return;

    final startLocation = locationList.first;
    final currentTime = DateTime.now().toIso8601String();
    final response = await apiService.startCourse(
        userId, startLocation, currentTime); // 세 인수를 전달
    setState(() {
      courseId = response['course_id'];
      isCourseStarted = true;
    });

    // 타이머 시작
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        _secondsElapsed++;
        _calculatePace();
        _calculateCadence();
      });
    });
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
