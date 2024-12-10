import 'package:flutter/material.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/pages/signup_page.dart';
import 'package:geolocator/geolocator.dart';

class SecondPage extends StatefulWidget {
  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission(); // 위치 권한 확인
  }

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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: screenWidth, // 화면 너비로 조정
              height: screenHeight, // 화면 높이로 조정
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              child: Stack(
                children: [
                  // 배경 이미지
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/images/second.jpg"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  // 검정색 투명 오버레이
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.37),
                      ),
                    ),
                  ),
                  // 상단 텍스트
                  Positioned(
                    left: screenWidth * 0.08, // 화면 너비의 8%만큼 왼쪽 여백
                    top: screenHeight * 0.07, // 화면 높이의 7%만큼 위쪽 여백
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'MOTIONUP ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.08, // 화면 너비 기준 글자 크기
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: '과 함께하는\n',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.05, // 화면 너비 기준 글자 크기
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: screenWidth * 0.08,
                    top: screenHeight * 0.13,
                    child: Text(
                      '러닝 챌린지',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.05, // 화면 너비 기준 글자 크기
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  // 로그인 버튼
                  Positioned(
                    left: screenWidth * 0.09, // 화면 너비 기준 왼쪽 여백
                    top: screenHeight * 0.8, // 화면 높이 기준 위치
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF121212),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                        minimumSize: Size(
                            screenWidth * 0.82, screenHeight * 0.06), // 버튼 크기
                      ),
                      child: Text(
                        '로그인',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.05,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  // 회원가입 버튼
                  Positioned(
                    left: screenWidth * 0.09,
                    top: screenHeight * 0.88,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignupPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF121212),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                        minimumSize:
                            Size(screenWidth * 0.82, screenHeight * 0.06),
                      ),
                      child: Text(
                        '회원가입',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.05,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
