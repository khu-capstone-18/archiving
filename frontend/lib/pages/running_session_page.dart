import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/gyroscope_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class RunningSessionPage extends StatefulWidget {
  @override
  _RunningSessionPageState createState() => _RunningSessionPageState();
}

class _RunningSessionPageState extends State<RunningSessionPage> {
  GyroscopeService gyroscopeService = GyroscopeService();
  ApiService apiService = ApiService();
  late Timer _timer;
  int _secondsElapsed = 0;
  double _totalDistance = 0.0;
  double _currentSpeed = 0.0;

  @override
  void initState() {
    super.initState();
    startSession();
    gyroscopeService.startListening(updateGyroscopeData);
  }

  // 자이로스코프 데이터를 처리하는 함수
  void updateGyroscopeData(Map<String, double> gyroscopeData) {
    setState(() {
      // 예시: x축을 속도에 반영
      _currentSpeed = gyroscopeData['x'] ?? 0.0;
    });
  }

  void startSession() {
    gyroscopeService.startTracking();
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        _secondsElapsed++;
        // 자이로스코프 데이터를 활용하여 거리를 계산
        _totalDistance += _currentSpeed; // 이동 거리 업데이트
      });
    });
  }

  void endSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('user_id');

    if (token != null && userId != null) {
      int totalTime = _secondsElapsed;
      double caloriesBurned = _totalDistance * 0.05;
      String averagePace =
          totalTime > 0 ? "${_totalDistance / totalTime} km/h" : "0";

      await apiService.saveRunningSession(
        token: token,
        userId: userId,
        startTime: DateTime.now()
            .subtract(Duration(seconds: _secondsElapsed))
            .toIso8601String(),
        endTime: DateTime.now().toIso8601String(),
        totalDistance: _totalDistance,
        totalTime: totalTime,
        averagePace: averagePace,
        caloriesBurned: caloriesBurned,
      );

      Navigator.pop(context); // 세션 완료 후 페이지 종료
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Running Session'),
        actions: [
          IconButton(
            icon: Icon(Icons.stop),
            onPressed: endSession,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Time Elapsed: $_secondsElapsed seconds'),
            Text('Total Distance: ${_totalDistance.toStringAsFixed(2)} km'),
            Text('Current Speed: ${_currentSpeed.toStringAsFixed(2)} km/h'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
