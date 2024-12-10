import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/pages/running_session_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEditPage extends StatefulWidget {
  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final TextEditingController profileImageController = TextEditingController();
  final TextEditingController weeklyGoalController = TextEditingController();
  String errorMessage = '';
  ApiService apiService = ApiService();
  String? token;

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
    });
  }

  Future<void> updateProfile() async {
    if (token == null) {
      setState(() {
        errorMessage = 'User data not found.';
      });
      return;
    }

    final response = await apiService.updateUserProfile(
      token!,
      profileImageController.text.isNotEmpty
          ? profileImageController.text
          : "default_image.png",
      weeklyGoalController.text.isNotEmpty ? weeklyGoalController.text : "0",
    );

    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // first_login 값을 false로 설정
      await prefs.setBool('first_login', false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RunningSessionPage(),
        ),
      );
    } else {
      setState(() {
        errorMessage = 'Profile update failed. Please try again.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: screenWidth,
          height: screenHeight,
          decoration: const BoxDecoration(color: Colors.white),
          child: Stack(
            children: [
              // "프로필 입력" 제목
              Positioned(
                left: screenWidth * 0.1,
                top: screenHeight * 0.1,
                child: Text(
                  '프로필 입력',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: screenWidth * 0.07, // 화면 너비의 7%
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              // 설명 텍스트
              Positioned(
                left: screenWidth * 0.1,
                top: screenHeight * 0.15,
                child: Text(
                  '프로필 이미지와 주간 목표를 입력해주세요',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                    fontSize: screenWidth * 0.045, // 화면 너비의 4.5%
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              // 프로필 이미지 입력 필드
              Positioned(
                left: screenWidth * 0.1,
                top: screenHeight * 0.35,
                child: SizedBox(
                  width: screenWidth * 0.8, // 화면 너비의 80%
                  height: screenHeight * 0.06, // 화면 높이의 6%
                  child: TextField(
                    controller: profileImageController,
                    decoration: InputDecoration(
                      hintText: '프로필 이미지 URL',
                      hintStyle: TextStyle(
                        color: Colors.black.withOpacity(0.7),
                        fontSize: screenWidth * 0.045,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w700,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.015,
                        horizontal: screenWidth * 0.05,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFEC6E4F),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFEC6E4F),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 주간 목표 입력 필드
              Positioned(
                left: screenWidth * 0.1,
                top: screenHeight * 0.45,
                child: SizedBox(
                  width: screenWidth * 0.8,
                  height: screenHeight * 0.06,
                  child: TextField(
                    controller: weeklyGoalController,
                    decoration: InputDecoration(
                      hintText: '주간 목표 (km)',
                      hintStyle: TextStyle(
                        color: Colors.black.withOpacity(0.7),
                        fontSize: screenWidth * 0.045,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w700,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.015,
                        horizontal: screenWidth * 0.05,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFEC6E4F),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFEC6E4F),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 업데이트 버튼
              Positioned(
                left: screenWidth * 0.1,
                top: screenHeight * 0.55,
                child: SizedBox(
                  width: screenWidth * 0.8,
                  height: screenHeight * 0.06,
                  child: ElevatedButton(
                    onPressed: updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC6E4F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: Text(
                      '프로필 업데이트',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.05,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              // 에러 메시지 표시
              if (errorMessage.isNotEmpty)
                Positioned(
                  left: screenWidth * 0.1,
                  top: screenHeight * 0.65,
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
