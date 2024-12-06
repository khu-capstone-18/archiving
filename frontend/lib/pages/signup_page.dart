import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  ApiService apiService = ApiService();
  final TextEditingController usernameController =
      TextEditingController(); // 아이디
  final TextEditingController emailController = TextEditingController(); // 이메일
  final TextEditingController passwordController =
      TextEditingController(); // 비밀번호
  final TextEditingController weightController = TextEditingController(); // 체중

  String errorMessage = '';
  bool isLoading = false;

  // 회원가입 함수
  Future<void> signup() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();

    print("회원가입 완료 후 SharedPreferences 상태:");
    print(" - token: ${prefs.getString('token')}");
    print(" - user_id: ${prefs.getString('user_id')}");
    print(" - first_login: ${prefs.getBool('first_login')}");

    try {
      final response = await apiService.signup(
        usernameController.text,
        passwordController.text,
        emailController.text,
        weightController.text,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        try {
          await prefs.setBool('first_login', true);
          await prefs.setString('token', responseData['token']);
          await prefs.setString('user_id', responseData['user_id']);

          print("데이터 저장 후 SharedPreferences 상태:");
          print(" - first_login: ${prefs.getBool('first_login')}");
          print(" - token: ${prefs.getString('token')}");
          print(" - user_id: ${prefs.getString('user_id')}");
        } catch (e) {
          setState(() {
            errorMessage = 'Failed to save user data. Please try again.';
          });
          print("Error saving data to SharedPreferences: $e");
          return; // 에러 발생 시 추가 동작 중단
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else if (response.statusCode == 409) {
        setState(() {
          errorMessage = 'Username already exists. Please try another one.';
        });
        print("Signup failed: Username already exists.");
      } else {
        setState(() {
          errorMessage = 'Signup failed. Please try again.';
        });
        print(
            "Signup failed with unknown error. Status code: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred. Please try again.';
      });
      print('Error during signup: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 40.0, vertical: 30.0),
                child: Column(
                  children: [
                    Text(
                      '회원가입',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 30),
                    _buildTextField('아이디', usernameController),
                    SizedBox(height: 20),
                    _buildTextField('이메일', emailController),
                    SizedBox(height: 20),
                    _buildTextField('비밀번호', passwordController),
                    SizedBox(height: 20),
                    _buildTextField('체중', weightController),
                    SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFEC6E4F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        minimumSize: Size(317, 50),
                      ),
                      child: Text(
                        '회원가입',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '이미 계정이 있나요? ',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: '로그인',
                            style: TextStyle(
                              color: Color(0xFFEC6E4F),
                              fontSize: 16,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w400,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginPage(),
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Text(
                          errorMessage,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  // 텍스트 입력 필드 생성 함수
  Widget _buildTextField(String hintText, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFFEC6E4F), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFFEC6E4F), width: 2),
        ),
      ),
    );
  }
}
