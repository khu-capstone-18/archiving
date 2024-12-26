import 'package:flutter/material.dart';
import 'package:frontend/pages/first_page.dart';
import 'package:frontend/pages/second_page.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/pages/profile_edit_page.dart';
import 'package:frontend/pages/running_session_page.dart';
import 'package:frontend/pages/signup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(FirstPageApp()); // 앱 실행 시 FirstPage부터 시작
}

/// FirstPage를 먼저 보여주는 앱
class FirstPageApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => FirstPage(), // 앱 시작 시 보여줄 첫 페이지
        '/second': (context) => SecondPage(), // 두 번째 페이지
        '/login': (context) => LoginPage(), // 로그인 페이지
        '/signup': (context) => SignupPage(), // 회원가입 페이지
        '/profileEdit': (context) => ProfileEditPage(), // 프로필 수정
        '/runningSession': (context) => RunningSessionPage(), // 러닝 세션
      },
    );
  }
}

/// Main 앱 로직을 실행하는 MyApp
class MyApp extends StatelessWidget {
  Future<void> _checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permission denied.');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      print('Location permission permanently denied.');
      return;
    }
    print('Location permission granted.');
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
    return FutureBuilder<Widget>(
      future: _checkAndRequestPermission().then((_) => _determineStartPage()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return MaterialApp(
            home: Center(child: Text("Error: ${snapshot.error}")),
          );
        } else if (snapshot.hasData) {
          return MaterialApp(
            home: snapshot.data as Widget,
            routes: {
              '/signup': (context) => SignupPage(),
              '/profileEdit': (context) => ProfileEditPage(),
              '/runningSession': (context) => RunningSessionPage(),
            },
          );
        } else {
          return MaterialApp(
            home: LoginPage(),
          );
        }
      },
    );
  }
}
