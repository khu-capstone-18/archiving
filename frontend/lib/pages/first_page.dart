import 'package:flutter/material.dart';

class FirstPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 화면의 크기 정보 가져오기
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/second');
    });

    return Scaffold(
      backgroundColor: Color(0xFFEB6E4F), // 배경색 설정
      body: Center(
        child: Container(
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
              // 배경색 박스
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: screenWidth, // 화면 너비에 맞게 설정
                  height: screenHeight, // 화면 높이에 맞게 설정
                  decoration: BoxDecoration(color: Color(0xFFEB6E4F)),
                ),
              ),
              // 로고 이미지 삽입
              Positioned(
                left: screenWidth * 0.32, // 화면 너비 기준으로 중앙 정렬
                top: screenHeight * 0.4, // 화면 높이를 기준으로 위치 조정
                child: Container(
                  width: screenWidth * 0.36, // 화면 너비의 36% 사용
                  height: screenWidth * 0.36, // 정사각형으로 설정
                  child: Image.asset(
                    'assets/images/logo.jpg', // 로고 이미지 경로
                    fit: BoxFit.cover, // 이미지 크기 맞추기
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
