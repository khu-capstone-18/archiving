import 'package:flutter/material.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/pages/profile_page.dart';
import 'package:frontend/pages/profile_edit_page.dart';
import 'package:frontend/pages/create_course_page.dart';
import 'package:frontend/pages/solorunning_page.dart';
import 'package:frontend/pages/followingrunning_page.dart';
import 'package:frontend/pages/solorunning_page.dart';
import 'package:frontend/pages/followingrunning_page.dart';
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
    _resetState();
    _logSharedPreferencesState();
    _loadCourses();
  }

  void _resetState() {
    // 상태 초기화 메서드
    setState(() {
      courseList.clear();
      selectedCourse = null;
      selectedMode = "";
    });
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

        if (courses == null || courses.isEmpty) {
          print("Fetched courses are empty or null.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No courses available.')),
          );
          return;
        }

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

  void _navigateToCreateCourse() async {
    print("Navigating to CreateCoursePage...");
    final courseCreated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateCoursePage()),
    );

    print("Returned from CreateCoursePage. courseCreated: $courseCreated");
    if (courseCreated == true) {
      print("Course creation detected. Reloading courses...");
      _resetState();
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

  void _startRunningSession() async {
    if (selectedMode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a running mode.')),
      );
      return;
    }

    if (selectedMode == "solo" || selectedCourse == null) {
      // 혼자 달리기
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SoloRunningPage(),
        ),
      );
    } else if (selectedMode == "following" && selectedCourse != null) {
      // 따라 달리기
      final locations = selectedCourse!['locations'];

      if (selectedCourse!['locations'] == null ||
          selectedCourse!['locations'] is! List) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid course data.')),
        );
        return;
      }

      final List<Map<String, double>> routeCoordinates =
          selectedCourse!['locations'].map<Map<String, double>>((location) {
        final lat = location['location']['latitude'] as double;
        final lng = location['location']['longitude'] as double;
        return {'latitude': lat, 'longitude': lng};
      }).toList();

      final String courseId = selectedCourse!['course_id'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FollowingRunningPage(
            routeCoordinates: routeCoordinates,
            courseId: courseId,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid selection.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: "로그아웃",
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 배경 이미지
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/second.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // 검정색 투명 오버레이
          // 검정색 투명 오버레이
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          // 메인 콘텐츠
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
                  dropdownColor: Colors.white, // 드롭다운 메뉴 배경색
                  value: selectedCourse,
                  hint: Text(
                    "코스 선택",
                    style: TextStyle(color: Colors.white), // 힌트 텍스트 흰색
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
                      child: Text(
                        courseName,
                        style: TextStyle(color: Colors.black), // 스크롤 시 텍스트 검은색
                      ),
                    );
                  }).toList(),
                  selectedItemBuilder: (BuildContext context) {
                    return courseList.map((course) {
                      final courseName =
                          course['course_name'] ?? "Unnamed Course";
                      return Text(
                        courseName,
                        style: TextStyle(color: Colors.white), // 선택된 텍스트 흰색
                      );
                    }).toList();
                  },
                ),
                SizedBox(height: 20),
                DropdownButton<String>(
                  dropdownColor: Colors.white, // 드롭다운 메뉴 배경색
                  value: selectedMode.isEmpty ? null : selectedMode,
                  hint: Text(
                    "달리기 모드 선택",
                    style: TextStyle(color: Colors.white), // 힌트 텍스트 흰색
                  ),
                  onChanged: (mode) {
                    setState(() {
                      selectedMode = mode!;
                    });
                  },
                  items: [
                    DropdownMenuItem(
                      value: "solo",
                      child: Text(
                        "혼자 달리기",
                        style: TextStyle(color: Colors.black), // 스크롤 시 텍스트 검은색
                      ),
                    ),
                    DropdownMenuItem(
                      value: "following",
                      child: Text(
                        "따라 달리기",
                        style: TextStyle(color: Colors.black), // 스크롤 시 텍스트 검은색
                      ),
                    ),
                  ],
                  selectedItemBuilder: (BuildContext context) {
                    return ["solo", "following"].map((mode) {
                      return Text(
                        mode == "solo" ? "혼자 달리기" : "따라 달리기",
                        style: TextStyle(color: Colors.white), // 선택된 텍스트 흰색
                      );
                    }).toList();
                  },
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
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _startRunningSession,
                  onPressed: _startRunningSession,
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
                    '달리기 시작하기',
                    '달리기 시작하기',
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
