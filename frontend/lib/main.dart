import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api/api_service.dart';
import 'providers/auth_provider.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/profile_page.dart';
import 'screens/signup_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider()), // AuthProvider 추가
      ],
      child: MaterialApp(
        title: 'My App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => LoginPage(),
          '/home': (context) => HomePage(),
          '/profile': (context) =>
              ProfilePage(userId: 'user_id', token: 'token'), // 예시를 위해 임시 값 사용
          '/signup': (context) => SignupPage(),
        },
      ),
    );
  }
}
