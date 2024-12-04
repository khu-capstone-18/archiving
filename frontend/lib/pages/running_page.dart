import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:frontend/services/api_service.dart';
import 'dart:async';

class RunningPage extends StatefulWidget {
  final Map<String, dynamic> course;
  final String mode; // "solo" 또는 "following"

  RunningPage({required this.course, required this.mode});

  @override
  _RunningPageState createState() => _RunningPageState();
}

class _RunningPageState extends State<RunningPage> {
  final ApiService apiService = ApiService();
  StreamSubscription<Position>? positionStream;
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  List<LatLng> route = [];
  Map<String, double> locationGap = {};
  String currentPace = "0:00";
  double totalDistance = 0.0;
  int elapsedTime = 0;

  @override
  void initState() {
    super.initState();
    _startRunning();
  }

  void _startRunning() {
    if (positionStream != null) {
      print('Position stream is already active.');
      return;
    }

    positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (Position position) async {
        try {
          Map<String, double> currentLocation = {
            'latitude': position.latitude,
            'longitude': position.longitude,
          };

          print('Location update: $currentLocation'); // 위치 업데이트 로그

          if (widget.mode == "solo") {
            await _updateSoloRunning(currentLocation);
          } else if (widget.mode == "following") {
            await _updateFollowingRunning(currentLocation);
          }

          setState(() {
            markers.add(Marker(
              markerId: MarkerId("current"),
              position: LatLng(position.latitude, position.longitude),
            ));
            route.add(LatLng(position.latitude, position.longitude));
            print('Current route: $route'); // 경로 로그
          });
        } catch (e) {
          print('Error processing position data: $e');
        }
      },
      onError: (error) {
        print('Position stream error: $error');
      },
    );

    print('Position stream started successfully.');
  }

  LatLng _getInitialCameraPosition() {
    try {
      final startPoint = widget.course['start_point'];

      if (startPoint != null &&
          startPoint is Map &&
          startPoint.containsKey('latitude') &&
          startPoint.containsKey('longitude') &&
          startPoint['latitude'] != null &&
          startPoint['longitude'] != null &&
          startPoint['latitude'] is double &&
          startPoint['longitude'] is double) {
        return LatLng(
          startPoint['latitude'],
          startPoint['longitude'],
        );
      } else {
        print('Invalid or missing start_point data: $startPoint');
      }
    } catch (e) {
      print('Error parsing start_point: $e');
    }
    print('Using default initial camera position.');
    return LatLng(37.5665, 126.9780);
  }

  Future<void> _updateSoloRunning(Map<String, double> currentLocation) async {
    print('Route before sending to server: $route');

    int retryCount = 0;
    const int maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        print('Sending location: $currentLocation'); // API 호출 데이터 로그
        final response = await apiService.sendSoloData(
          token: await apiService.getToken(),
          courseId: widget.course['course_id'],
          latitude: currentLocation['latitude']!,
          longitude: currentLocation['longitude']!,
        );
        print('Response: $response'); // 서버 응답 로그

        // **TypeError 문제 해결**
        if (response == null) {
          throw Exception('Server response is null');
        }

        // **서버 응답 검증 추가**
        if (response == null ||
            response['current_pace'] == null ||
            response['total_distance'] == null ||
            response['elapsed_time'] == null) {
          print('Invalid server response: $response');
          throw Exception('Server response validation failed');
        }

        setState(() {
          currentPace = response['current_pace'].toString();
          totalDistance = double.parse(response['total_distance']);
          elapsedTime = int.parse(response['elapsed_time']);
          print(
              'Updated stats: pace=$currentPace, distance=$totalDistance, time=$elapsedTime');
        });
        return; // 성공적으로 전송된 경우 종료
      } catch (e) {
        retryCount++;
        print('Error sending location (Retry $retryCount): $e');
        if (retryCount == maxRetries) {
          print('Max retries reached. Failed to send location.');
        }
      }
    }
  }

  Future<void> _updateFollowingRunning(
      Map<String, double> currentLocation) async {
    try {
      final response = await apiService.sendFollowingData(
        token: await apiService.getToken(),
        courseId: widget.course['course_id'],
        userId: widget.course['creator_id'], // 서버에서 받는 userId 사용
        latitude: currentLocation['latitude']!,
        longitude: currentLocation['longitude']!,
        currentTime: DateTime.now().toIso8601String(),
      );
      print('Response: $response'); // 서버 응답 로그

      // **TypeError 문제 해결**
      if (response == null) {
        throw Exception('Server response is null');
      }

      setState(() {
        currentPace =
            response['current_pace']?.toString() ?? "0:00"; // String으로 변환
        totalDistance =
            double.tryParse(response['total_distance']?.toString() ?? "0.0") ??
                0.0; // 타입 변환 및 기본값 설정
        elapsedTime =
            int.tryParse(response['elapsed_time']?.toString() ?? "0") ??
                0; // 타입 변환 및 기본값 설정
        locationGap = {
          'latitude': double.tryParse(
                  response['location_gap']?['latitude']?.toString() ?? "0.0") ??
              0.0,
          'longitude': double.tryParse(
                  response['location_gap']?['longitude']?.toString() ??
                      "0.0") ??
              0.0,
        };

        print(
            'Updated stats: pace=$currentPace, distance=$totalDistance, time=$elapsedTime');
      });
    } catch (e) {
      print("Error updating following running: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == "solo" ? "혼자 달리기" : "따라 달리기"),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _getInitialCameraPosition(),
          zoom: 14.0,
        ),
        markers: markers,
        polylines: {
          Polyline(
            polylineId: PolylineId("route"),
            points: route,
            color: Colors.blue,
          ),
        },
      ),
    );
  }

  @override
  void dispose() {
    positionStream?.cancel();
    print('Position stream cancelled.');
    markers.clear();
    route.clear();
    print('Markers and route cleared.');
    super.dispose();
  }
}
