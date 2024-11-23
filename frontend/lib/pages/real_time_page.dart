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
        _secondsElapsed++; // 경과 시간 증가
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
        );
        print(
            "Real-time data sent: ${position.latitude}, ${position.longitude}");
      } catch (e) {
        print("Error sending real-time data: $e");
      }
    });
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
            Text('Time Elapsed: $_secondsElapsed seconds'),
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
