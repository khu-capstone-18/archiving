import 'package:flutter/material.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/pages/profile_edit_page.dart';
import 'package:frontend/pages/running_session_page.dart';
import 'package:frontend/pages/signup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // 초기화 로직
  if (!prefs.containsKey('first_login')) {
    print("first_login 값이 없으므로 기본값(true) 설정");
    await prefs.setBool('first_login', true);
  }

  // SharedPreferences 상태 디버깅
  debugSharedPreferences(prefs);

  runApp(MyApp());
}

/// SharedPreferences 디버깅 함수
void debugSharedPreferences(SharedPreferences prefs) {
  print("SharedPreferences 상태:");
  print(" - token: ${prefs.getString('token')}");
  print(" - user_id: ${prefs.getString('user_id')}");
  print(" - first_login: ${prefs.getBool('first_login')}");
}

class MyApp extends StatelessWidget {
  Future<void> _checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      print("위치 권한이 영구적으로 거부되었습니다.");
    }
  }

  Future<Widget> _determineStartPage() async {
    final prefs = await SharedPreferences.getInstance();

    // SharedPreferences 값 가져오기
    final token = prefs.getString('token'); // null: 로그인 안됨
    final userId = prefs.getString('user_id'); // null: 사용자 정보 없음
    final firstLogin = prefs.getBool('first_login') ?? true; // 기본값: true

    // 상태 확인 로그
    print("초기 페이지 결정:");
    print(" - token: $token");
    print(" - user_id: $userId");
    print(" - first_login: $firstLogin");

    // 토큰이 유효하고 사용자 정보가 있는 경우
    if (token != null && userId != null) {
      if (firstLogin) {
        print("Navigating to Profile Edit Page (First Login)");
        return ProfileEditPage();
      } else {
        print("Navigating to Running Session Page");
        return RunningSessionPage();
      }
    } else {
      // 로그인 상태가 아닌 경우 로그인 페이지로 이동
      print("Navigating to Login Page");
      return LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<Widget>(
        future: _checkPermissions().then((_) => _determineStartPage()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // 에러 처리
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            // 올바른 데이터를 반환받았을 때
            return snapshot.data as Widget; // 타입 캐스팅
          } else {
            return LoginPage();
          }
        },
      ),
      routes: {
        '/signup': (context) => SignupPage(),
        '/profileEdit': (context) => ProfileEditPage(),
        '/runningSession': (context) => RunningSessionPage(),
      },
    );
  }
}
