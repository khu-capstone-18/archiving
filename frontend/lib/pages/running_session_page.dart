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
    _logSharedPreferencesState();
    _loadCourses();
  }

  Future<void> _logSharedPreferencesState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("러닝 세션 페이지 초기화 상태:");
    print(" - token: ${prefs.getString('token')}");
    print(" - user_id: ${prefs.getString('user_id')}");
    print(" - first_login: ${prefs.getBool('first_login')}");
  }

  // 전체 코스 데이터 로드
  Future<void> _loadCourses() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token != null) {
        final courses = await apiService.fetchCourses(token);

        // 데이터 검증 및 디버깅
        if (courses == null || courses.isEmpty) {
          print("Fetched courses are empty or null.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No courses available.')),
          );
          return;
        }

        // 각 코스 데이터의 필수 필드 확인
        for (var course in courses) {
          print("Course data: $course");
          if (course['course_name'] == null || course['course_name'].isEmpty) {
            print("Course with missing name: $course");
          }
        }

        setState(() {
          courseList = courses.map((course) {
            return {
              ...course,
              'course_name': course['course_name']?.isEmpty ?? true
                  ? 'Unnamed Course'
                  : course['course_name'],
            };
          }).toList();
        });
        print("Successfully loaded courses: $courseList");
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
          course: {
            'name': 'Test Course',
            'route': [], // 빈 리스트나 실제 경로 데이터를 전달
          },
          mode: 'solo', // 'solo' 또는 'following'
        ),
      ),
    );
  }

  void _navigateToCreateCourse() async {
    print("Navigating to CreateCoursePage...");
    final courseCreated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateCoursePage()),
    );

    print("Returned from CreateCoursePage. courseCreated: $courseCreated");
    if (courseCreated == true) {
      print("Course creation detected. Reloading courses...");
      await _loadCourses(); // 코스 갱신
      print("Courses reloaded. Current course list: $courseList");
    }
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
      // 필요한 데이터만 삭제
      await prefs.remove('token'); // 토큰 삭제
      await prefs.remove('user_id'); // 사용자 ID 삭제
      print("Logout completed. first_login 상태 유지.");

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
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/second.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // 검정색 투명 오버레이
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          // 메인 콘텐츠
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '러닝 세션 시작',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 30),
                DropdownButton<Map<String, dynamic>>(
                  dropdownColor: Colors.white,
                  value: selectedCourse,
                  hint: Text(
                    "코스 선택",
                    style: TextStyle(color: Colors.white),
                  ),
                  onChanged: (course) {
                    setState(() {
                      selectedCourse = course;
                    });
                  },
                  items: courseList.map((course) {
                    final courseName =
                        course['course_name'] ?? "Unnamed Course";
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: course,
                      child: Text(courseName),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
                DropdownButton<String>(
                  dropdownColor: Colors.white,
                  value: selectedMode.isEmpty ? null : selectedMode,
                  hint: Text(
                    "달리기 모드 선택",
                    style: TextStyle(color: Colors.white),
                  ),
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
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _navigateToCreateCourse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEC6E4F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 40,
                    ),
                  ),
                  child: Text(
                    '코스 생성하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _navigateToProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEC6E4F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 40,
                    ),
                  ),
                  child: Text(
                    '프로필 보기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _navigateToProfileEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEC6E4F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 40,
                    ),
                  ),
                  child: Text(
                    '프로필 수정하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
