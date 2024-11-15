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
  late Timer _timer;
  double _currentSpeed = 0.0;
  double _totalDistance = 0.0;
  int _cadence = 0;
  int _secondsElapsed = 0;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    startRealTimeSession();
  }

  void _getCurrentLocation() {
    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
      sendRealTimeData();
    });
  }

  void startRealTimeSession() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        _secondsElapsed++;
        //실제 자이로스코프 데이터를 이용
        _totalDistance += _currentSpeed;
      });
    });
  }

  // 실시간 데이터 전송 함수
  void sendRealTimeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('user_id');

    if (_currentPosition != null && token != null && userId != null) {
      await apiService.sendRealTimeRunningData(
        token: token,
        userId: userId,
        currentSpeed: _currentSpeed,
        currentPace: "${_currentSpeed.toStringAsFixed(2)} km/h",
        cadence: _cadence,
        elapsedTime: "$_secondsElapsed",
        currentLocation: {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
        },
      );
    }
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
