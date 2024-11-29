import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class RealTimePage extends StatefulWidget {
  @override
  _RealTimePageState createState() => _RealTimePageState();
}

class _RealTimePageState extends State<RealTimePage> {
  ApiService apiService = ApiService();
  StreamSubscription<Position>? positionStream; // 위치 스트림
  int _secondsElapsed = 0;
  Position? _currentPosition;
  double _currentSpeed = 0.0;
  String _currentPace = "0:00";
  String _elapsedTime = "00:00:00";
  int _cadence = 0; // 샘플로 임의 값을 사용. 실제 값은 계산 로직 추가 가능.

  @override
  void initState() {
    super.initState();
    _startRealTimeTracking(); // 실시간 추적 시작
  }

  // 위치 스트림을 시작하여 데이터를 실시간 전송
  void _startRealTimeTracking() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? user_Id = prefs.getString('user_id');

    if (token == null || user_Id == null) {
      print("User token or ID not found. Unable to start tracking.");
      return;
    }

    positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) async {
      setState(() {
        _currentPosition = position; // UI에 위치 업데이트
        _currentSpeed = position.speed; // 속도 업데이트
        _secondsElapsed++;
        _elapsedTime = _formatElapsedTime(_secondsElapsed); // 경과 시간 계산
        _currentPace = _calculatePace(_currentSpeed); // 현재 페이스 계산
        _cadence = _calculateCadence(_currentSpeed); // 샘플 케이던스 계산
      });

      // 서버로 실시간 데이터 전송
      try {
        await apiService.sendRealTimeRunningData(
          token: token,
          user_Id: user_Id,
          currentLocation: {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
          currentSpeed: _currentSpeed,
          currentPace: _currentPace,
          elapsedTime: _elapsedTime,
          cadence: _cadence,
        );
        print(
            "Real-time data sent: ${position.latitude}, ${position.longitude}, Speed: $_currentSpeed");
      } catch (e) {
        print("Error sending real-time data: $e");
      }
    });
  }

  // 경과 시간을 형식화 (초를 HH:MM:SS 형식으로 변환)
  String _formatElapsedTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // 현재 페이스 계산 (예시: 속도에 따라 임의 계산)
  String _calculatePace(double speed) {
    if (speed == 0) return "0:00";
    final pace = 1000 / speed; // 1km를 이동하는 데 걸리는 시간(초)
    final minutes = pace ~/ 60;
    final seconds = (pace % 60).toInt();
    return '${minutes.toInt()}:${seconds.toString().padLeft(2, '0')}';
  }

  // 샘플 케이던스 계산 (실제 로직은 수정 가능)
  int _calculateCadence(double speed) {
    return (speed * 160).toInt(); // 속도에 따라 임의 케이던스 계산
  }

  @override
  void dispose() {
    positionStream?.cancel(); // 스트림 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-time Running Data'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Time Elapsed: $_elapsedTime'),
            Text('Current Pace: $_currentPace'),
            Text('Current Speed: ${_currentSpeed.toStringAsFixed(2)} m/s'),
            Text('Cadence: $_cadence steps/min'),
            if (_currentPosition != null) ...[
              Text(
                  'Current Location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}'),
            ] else
              Text('Waiting for location...'),
          ],
        ),
      ),
    );
  }
}
