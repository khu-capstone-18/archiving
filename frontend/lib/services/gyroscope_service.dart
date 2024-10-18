import 'package:sensors_plus/sensors_plus.dart';

class GyroscopeService {
  double _x = 0.0;
  double _y = 0.0;
  double _z = 0.0;

  // 기존 자이로스코프 데이터를 추적하는 기능 유지
  void startTracking() {
    gyroscopeEvents.listen((GyroscopeEvent event) {
      _x = event.x;
      _y = event.y;
      _z = event.z;
      // 각도 변화나 이동 방향 기반 계산 (기존 로직 유지)
    });
  }

  // 자이로스코프 데이터를 가져오는 메서드 (기존 기능)
  Map<String, double> getGyroscopeData() {
    return {
      'x': _x,
      'y': _y,
      'z': _z,
    };
  }

  // 추가: 자이로스코프 데이터를 실시간 전송하는 새로운 기능
  void startListening(Function(Map<String, double>) onData) {
    gyroscopeEvents.listen((GyroscopeEvent event) {
      Map<String, double> gyroscopeData = {
        'x': event.x,
        'y': event.y,
        'z': event.z,
      };
      onData(gyroscopeData); // 실시간 데이터 전송을 위한 콜백 호출
    });
  }
}
