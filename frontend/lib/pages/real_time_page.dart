import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/gyroscope_service.dart';
import 'package:geolocator/geolocator.dart';

class RealTimePage extends StatefulWidget {
  @override
  _RealTimePageState createState() => _RealTimePageState();
}

class _RealTimePageState extends State<RealTimePage> {
  ApiService apiService = ApiService();
  GyroscopeService gyroscopeService = GyroscopeService();
  String? token;
  String? userId;
  double currentSpeed = 0.0;
  String currentPace = "00:00";
  int cadence = 0;
  String elapsedTime = "00:00:00";
  Map<String, double> gyroscopeData = {'x': 0.0, 'y': 0.0, 'z': 0.0};

  // 실시간 데이터 전송
  Future<void> sendRealTimeData() async {
    await apiService.sendRealTimeRunningData(
      token: token!,
      userId: userId!,
      gyroscopeData: gyroscopeData,
      currentSpeed: currentSpeed,
      currentPace: currentPace,
      cadence: cadence,
      elapsedTime: elapsedTime,
    );
  }

  @override
  void initState() {
    super.initState();
    startTracking();
  }

  // 자이로스코프 데이터 및 위치 추적 시작
  void startTracking() {
    gyroscopeService.startListening((gyroscopeData) {
      setState(() {
        this.gyroscopeData = gyroscopeData;
      });
    });
    // 위치 추적 시작
    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        currentSpeed = position.speed;
      });
      sendRealTimeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Real-time Tracking')),
      body: Column(
        children: [
          Text('Speed: $currentSpeed'),
          Text('Pace: $currentPace'),
          Text('Cadence: $cadence'),
          Text('Elapsed Time: $elapsedTime'),
          Text(
              'Gyroscope - X: ${gyroscopeData['x']}, Y: ${gyroscopeData['y']}, Z: ${gyroscopeData['z']}'),
        ],
      ),
    );
  }
}
