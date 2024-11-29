import 'package:flutter/material.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/pages/profile_edit_page.dart';
import 'package:frontend/pages/running_session_page.dart';
import 'package:frontend/pages/signup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // 앱이 처음 실행될 때 `first_login` 플래그를 명확히 초기화
  if (!prefs.containsKey('first_login')) {
    await prefs.setBool('first_login', false);
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Future<Widget> _determineStartPage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('user_id');
    final firstLogin = prefs.getBool('first_login') ?? true;

    if (token != null && userId != null) {
      if (firstLogin) {
        // 첫 로그인 시 ProfileEditPage로 이동
        return ProfileEditPage();
      } else {
        // 이후의 로그인은 RunningSessionPage로 이동
        return RunningSessionPage();
      }
    } else {
      // 로그인 상태가 아닌 경우 LoginPage로 이동
      return LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<Widget>(
        future: _determineStartPage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasData) {
            return snapshot.data!;
          } else {
            return LoginPage();
          }
        },
      ),
      routes: {
        '/signup': (context) => SignupPage(), // 회원가입 경로 정의
      },
    );
  }
}
