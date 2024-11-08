import 'package:flutter/material.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/pages/profile_page.dart';
import 'package:frontend/pages/profile_edit_page.dart';
import 'package:frontend/pages/create_course_page.dart';
import 'package:frontend/services/api_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class RunningSessionPage extends StatefulWidget {
  @override
  _RunningSessionPageState createState() => _RunningSessionPageState();
}

class _RunningSessionPageState extends State<RunningSessionPage> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> courseList = [];
  Map<String, dynamic>? selectedCourse;
  Timer? _timer;
  int _secondsElapsed = 0;
  double _totalDistance = 0.0;
  int _cadence = 0;
  String _currentPace = "0:00";

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final courses = await apiService.fetchCourses();
    setState(() {
      courseList = courses;
    });
  }

  void _startRunningCourse() {
    if (selectedCourse != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RunningPageWithPacer(course: selectedCourse!),
        ),
      );
    } else {
      print("Please select a course first.");
    }
  }

  void _navigateToCreateCourse() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateCoursePage()),
    );
  }

  Future<void> _logout() async {
    await apiService.logout();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
    );
  }

  void _navigateToProfileEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileEditPage()),
    );
  }

  void _startSession() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        _secondsElapsed++;
        _calculatePace();
        _calculateCadence();
      });
    });
  }

  void _calculatePace() {
    if (_totalDistance > 0) {
      double pace = _secondsElapsed / _totalDistance;
      int minutes = pace ~/ 60;
      int seconds = (pace % 60).toInt();
      _currentPace = "$minutes:${seconds.toString().padLeft(2, '0')}";
    }
  }

  void _calculateCadence() {
    _cadence = (_totalDistance / _secondsElapsed * 100).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Running Session"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _navigateToCreateCourse,
            child: Text("코스 생성"),
          ),
          DropdownButton<Map<String, dynamic>>(
            value: selectedCourse,
            hint: Text("코스 선택"),
            onChanged: (course) {
              setState(() {
                selectedCourse = course;
              });
            },
            items: courseList.map((course) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: course,
                child: Text(course['course_name']),
              );
            }).toList(),
          ),
          ElevatedButton(
            onPressed: () {
              _startRunningCourse();
              _startSession();
            },
            child: Text("선택한 코스로 시작하기"),
          ),
          ElevatedButton(
            onPressed: _navigateToProfile,
            child: Text("프로필 페이지로 이동"),
          ),
          ElevatedButton(
            onPressed: _navigateToProfileEdit,
            child: Text("프로필 수정 페이지로 이동"),
          ),
          Text("실시간 페이스: $_currentPace"),
          Text("실시간 케이던스: $_cadence"),
          Text("달린 시간: $_secondsElapsed 초"),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class RunningPageWithPacer extends StatelessWidget {
  final Map<String, dynamic> course;

  RunningPageWithPacer({required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Running with Pacer"),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(course['start_point']['latitude'],
              course['start_point']['longitude']),
          zoom: 14.0,
        ),
        markers: {
          Marker(
            markerId: MarkerId("start"),
            position: LatLng(course['start_point']['latitude'],
                course['start_point']['longitude']),
          ),
          Marker(
            markerId: MarkerId("end"),
            position: LatLng(course['end_point']['latitude'],
                course['end_point']['longitude']),
          ),
          Marker(
            markerId: MarkerId("current"),
            position: LatLng(course['start_point']['latitude'],
                course['start_point']['longitude']),
          ),
        },
        polylines: {
          Polyline(
            polylineId: PolylineId("route"),
            points: course['route'].map<LatLng>((point) {
              return LatLng(point['latitude'], point['longitude']);
            }).toList(),
            color: Colors.blue,
          ),
        },
      ),
    );
  }
}
