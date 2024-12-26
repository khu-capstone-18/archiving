import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FollowingRunningPage extends StatefulWidget {
  final List<Map<String, double>> routeCoordinates; // 지정된 코스의 x, y 좌표 리스트
  final String courseId;

  const FollowingRunningPage({
    required this.routeCoordinates,
    required this.courseId,
  });

  @override
  _FollowingRunningPageState createState() => _FollowingRunningPageState();
}

class _FollowingRunningPageState extends State<FollowingRunningPage> {
  final ApiService apiService = ApiService();
  GoogleMapController? mapController;
  List<LatLng> route = [];
  List<LatLng> userRoute = []; // 사용자 실시간 경로
  Map<MarkerId, Marker> markers = {};
  Timer? locationTimer;
  String currentPace = "0:00";
  String totalDistance = "0.0 km";
  String elapsedTime = "0:00";
  String gapDistance = "0.0 km"; // 거리 차이
  String gapPace = "0:00"; // 페이스 차이
  String gapTime = "0:00"; // 시간 차이
  bool isRunning = false; // 달리기 시작 여부

  @override
  void initState() {
    super.initState();
    _drawInitialRoute();
  }

  void _updateElapsedTime(String elapsedTimeInSeconds) {
    try {
      final int seconds = int.tryParse(elapsedTimeInSeconds) ?? 0;
      final int minutes = seconds ~/ 60;
      final int remainingSeconds = seconds % 60;

      setState(() {
        elapsedTime =
            "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}"; // "분:초" 포맷
      });
    } catch (e) {
      print("Error formatting elapsed time: $e");
      elapsedTime = "00:00";
    }
  }

  void _drawInitialRoute() {
    try {
      final List<LatLng> polylinePoints = widget.routeCoordinates.map((coord) {
        if (coord['latitude'] == null || coord['longitude'] == null) {
          throw Exception('Invalid coordinate data: $coord');
        }
        return LatLng(coord['latitude']!, coord['longitude']!);
      }).toList();

      final startMarkerId = MarkerId("start");
      final endMarkerId = MarkerId("end");

      setState(() {
        route = polylinePoints;

        if (polylinePoints.isNotEmpty) {
          markers[startMarkerId] = Marker(
            markerId: startMarkerId,
            position: polylinePoints.first,
            infoWindow: InfoWindow(title: "Start"),
          );

          markers[endMarkerId] = Marker(
            markerId: endMarkerId,
            position: polylinePoints.last,
            infoWindow: InfoWindow(title: "End"),
          );
        }
      });

      print("Following route drawn with ${route.length} points.");
    } catch (e) {
      print("Error drawing route: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to draw route.')),
      );
    }
  }

  Future<void> _startFollowingRunning() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) throw Exception('Token not found');

      await apiService.startFollowing(
        courseId: widget.courseId,
        location: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        token: token,
      );

      setState(() {
        isRunning = true; // 달리기 시작 상태 변경
      });

      print("따라 달리기 시작 성공");
      _startLocationUpdates();
    } catch (e) {
      print("Error starting following running: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start following running.')),
      );
    }
  }

  Future<void> _endFollowingRunning() async {
    try {
      locationTimer?.cancel();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('Token or userId is missing');
      }

      final response = await apiService.endRunning(
        courseId: widget.courseId,
        courseName: "Sample Course",
        isPublic: false,
        userId: userId,
        location: userRoute.map((point) {
          return {'latitude': point.latitude, 'longitude': point.longitude};
        }).toList(),
        token: token,
      );

      print("End Running API Response: $response");

      setState(() {
        isRunning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Following running ended successfully.')),
      );
    } catch (e) {
      print("Error ending following running: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to end following running.')),
      );
    }
  }

  void _startLocationUpdates() {
    locationTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('token');

        if (token == null) throw Exception('Token not found');

        final response = await apiService.sendFollowingData(
          courseId: widget.courseId,
          location: {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
          token: token,
        );

        setState(() {
          userRoute.add(LatLng(position.latitude, position.longitude));

          markers[MarkerId("current_location")] = Marker(
            markerId: MarkerId("current_location"),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: InfoWindow(title: "Current Location"),
          );

          currentPace = response['current_pace']?.toString() ?? "0:00";
          totalDistance = response['total_distance'] ?? "0.0 km";
          _updateElapsedTime(response['elapsed_time']?.toString() ?? "0");

          // 추가된 데이터 처리
          gapDistance = response['gap_distance'] ?? "0.0 km";
          gapPace = response['gap_pace']?.toString() ?? "0:00";
          gapTime = response['gap_time']?.toString() ?? "0:00";
        });
      } catch (e) {
        print("Error sending location data: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send location data. Retrying...')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;

              if (route.isNotEmpty) {
                controller.moveCamera(
                  CameraUpdate.newLatLng(route.first),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target:
                  route.isNotEmpty ? route.first : LatLng(37.7749, -122.4194),
              zoom: 14.0,
            ),
            polylines: {
              Polyline(
                polylineId: PolylineId("route"),
                points: route,
                color: Colors.red,
              ),
              Polyline(
                polylineId: PolylineId("user_route"),
                points: userRoute,
                color: Colors.blue,
                width: 4,
              ),
            },
            markers: markers.values.toSet(),
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              color: Colors.white.withOpacity(0.8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoTile("속도", currentPace),
                  _buildInfoTile("총 거리", totalDistance),
                  _buildInfoTile("경과 시간", elapsedTime),
                  _buildInfoTile("속도 차이", gapPace),
                  _buildInfoTile("거리 차이", gapDistance),
                  _buildInfoTile("시간 차이", gapTime),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: MediaQuery.of(context).size.width * 0.5 - 50,
            child: GestureDetector(
              onTap: isRunning ? _endFollowingRunning : _startFollowingRunning,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC6E4F),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isRunning ? "종료" : "시작",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 14.0, color: Colors.grey)),
        SizedBox(height: 4.0),
        Text(value,
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    mapController?.dispose();
    super.dispose();
  }
}
