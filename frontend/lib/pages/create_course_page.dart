import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class CreateCoursePage extends StatefulWidget {
  @override
  _CreateCoursePageState createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  ApiService apiService = ApiService();
  String? courseId;
  Timer? locationTimer;
  int secondsElapsed = 0;
  double totalDistance = 0.0;
  String currentPace = "0:00";
  bool isCourseStarted = false;
  StreamSubscription<Position>? positionStream;

  // 현재 위치 가져오기
  Future<Map<String, double>> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
  }

  // 코스 생성 및 시작
  Future<void> _createAndStartCourse() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('User ID or token not found.');
      }

      // 코스 생성 데이터 입력 받기
      final courseNameController = TextEditingController();
      final descriptionController = TextEditingController();

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("코스 정보 입력"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: courseNameController,
                  decoration: InputDecoration(labelText: "코스 이름"),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: "설명"),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text("확인"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );

      if (courseNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("코스 이름을 입력해주세요.")),
        );
        return;
      }

      // 현재 위치 가져오기
      Map<String, double> startLocation = await _getCurrentLocation();
      print("Starting location: $startLocation");

      // 코스 생성
      final createResponse = await apiService.createCourse(
        userId: userId,
        courseName: courseNameController.text,
        description: descriptionController.text,
        startPoint: startLocation,
        endPoint: startLocation,
        route: [startLocation],
        length: 0.0, // 초기값
        estimatedTime: 0, // 초기값
        token: token,
      );

      print(
          "Course created successfully with ID: ${createResponse['course_id']}");

      // 생성된 course_id 저장
      setState(() {
        courseId = createResponse['course_id'];
      });

      // 위치 업데이트 시작
      _startSoloRunning(token, courseId!);
    } catch (e) {
      print("Error creating or starting course: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Failed to create or start course. Please try again.")),
      );
    }
  }

  // 혼자 달리기 위치 업데이트
  void _startSoloRunning(String token, String courseId) {
    positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) async {
      try {
        Map<String, double> currentLocation = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
        final response = await apiService.updateCourseLocation(
          courseId: courseId,
          location: currentLocation,
          token: token,
        );
        print("Solo running location updated: $response");
        setState(() {
          secondsElapsed += 5;
          totalDistance = double.parse(response['total_distance']);
          currentPace = response['current_pace'].toString();
        });
      } catch (e) {
        print("Error updating solo running location: $e");
      }
    });
  }

  // 코스 종료
  Future<void> _endCourse() async {
    if (locationTimer != null) {
      locationTimer!.cancel(); // 타이머 중단
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('user_id');

    if (courseId == null || userId == null || token == null) {
      print("코스 종료에 필요한 데이터가 없습니다.");
      return;
    }

    try {
      final endLocation = await _getCurrentLocation();
      print("코스 종료 위치: $endLocation");

      final response = await apiService.endCourse(
        course_Id: courseId!,
        course_name: "My Course", // 코스 이름 지정
        public: true, // 공개 여부 설정
        user_Id: userId,
        location: endLocation,
        token: token,
      );

      if (response != null && response.containsKey('total_distance')) {
        print('코스 종료 성공: ${response['total_distance']} km');
        setState(() {
          courseId = null;
          isCourseStarted = false;
          secondsElapsed = 0;
          totalDistance = 0.0;
          currentPace = "0:00";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Course ended successfully.")),
        );
      } else {
        print('서버에서 잘못된 응답을 받았습니다.');
      }
    } catch (e) {
      print('코스 종료 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to end course. Please try again.")),
      );
    }
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Course')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _createAndStartCourse,
              child: Text('Create & Start Course'),
            ),
            ElevatedButton(
              onPressed: _endCourse,
              child: Text('End Course'),
            ),
            if (isCourseStarted) ...[
              SizedBox(height: 20),
              Text("경과 시간: $secondsElapsed 초"),
              Text("실시간 페이스: $currentPace"),
            ],
          ],
        ),
      ),
    );
  }
}
