import 'package:flutter/material.dart';

class FirstPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/second');
    });

    return Scaffold(
      backgroundColor: Color(0xFFEB6E4F), // 배경색 설정
      body: Center(
        child: Container(
          width: 428,
          height: 926,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 428,
                  height: 926,
                  decoration: BoxDecoration(color: Color(0xFFEB6E4F)),
                ),
              ),
              // 로고 이미지 삽입
              Positioned(
                left: 137,
                top: 371,
                child: Container(
                  width: 155,
                  height: 155,
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
