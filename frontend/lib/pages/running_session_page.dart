import 'package:flutter/material.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/pages/profile_page.dart';
import 'package:frontend/pages/profile_edit_page.dart';
import 'package:frontend/pages/create_course_page.dart';
import 'package:frontend/pages/running_page.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RunningSessionPage extends StatefulWidget {
  @override
  _RunningSessionPageState createState() => _RunningSessionPageState();
}

class _RunningSessionPageState extends State<RunningSessionPage> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> courseList = [];
  Map<String, dynamic>? selectedCourse;
  String selectedMode = ""; // "solo" 또는 "following"

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  // 전체 코스 데이터 로드
  Future<void> _loadCourses() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token != null) {
        final courses = await apiService.fetchCourses(token);
        setState(() {
          courseList = courses;
        });
      } else {
        throw Exception('User token not found');
      }
    } catch (e) {
      print('Error fetching courses: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load courses. Please try again.')),
      );
    }
  }

  void _navigateToRunningPage() {
    if (selectedCourse == null || selectedMode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a course and mode.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RunningPage(
          course: selectedCourse!,
          mode: selectedMode, // 선택된 모드 전달
        ),
      ),
    );
  }

  void _navigateToCreateCourse() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateCoursePage()),
    );
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
      return;
    }

    final response = await apiService.logout(token);
    if (response.statusCode == 200) {
      await prefs.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
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
          DropdownButton<String>(
            value: selectedMode.isEmpty ? null : selectedMode,
            hint: Text("달리기 모드 선택"),
            onChanged: (mode) {
              setState(() {
                selectedMode = mode!;
              });
            },
            items: [
              DropdownMenuItem(value: "solo", child: Text("혼자 달리기")),
              DropdownMenuItem(value: "following", child: Text("따라 달리기")),
            ],
          ),
          ElevatedButton(
            onPressed: _navigateToRunningPage,
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
        ],
      ),
    );
  }
}
