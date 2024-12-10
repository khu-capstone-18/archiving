import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_edit_page.dart';
import 'running_session_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  Future<void> navigateToNextPage(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstLogin = prefs.getBool('first_login') ?? true;

    if (isFirstLogin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfileEditPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RunningSessionPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // 반투명 오버레이
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          // 텍스트와 버튼
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '모션업에 오신 걸 환영해요!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.08, // 화면 너비의 8% 크기
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.03), // 화면 높이의 3% 여백
                Text(
                  '함께 멋진 배움의 여정을 시작해봐요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.05, // 화면 너비의 5% 크기
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.07), // 화면 높이의 7% 여백
                ElevatedButton(
                  onPressed: () => navigateToNextPage(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF121212),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.02, // 버튼 높이의 2%
                      horizontal: screenWidth * 0.2, // 버튼 너비의 20%
                    ),
                  ),
                  child: Text(
                    '시작하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.05, // 화면 너비의 5% 크기
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
