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
  Map<MarkerId, Marker> markers = {};
  Timer? locationTimer;
  String currentPace = "0:00";
  String totalDistance = "0.0 km";
  String elapsedTime = "0:00";
  bool isRunning = false; // 달리기 시작 여부

  @override
  void initState() {
    super.initState();
    _drawInitialRoute();
  }

  void _drawInitialRoute() {
    // 코스의 좌표를 지도에 그림
    final List<LatLng> polylinePoints = widget.routeCoordinates
        .map((coord) => LatLng(coord['latitude']!, coord['longitude']!))
        .toList();

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
  }

  Future<void> _startFollowingRunning() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) throw Exception('Token not found');

      final response = await apiService.startFollowing(
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
          route.add(LatLng(position.latitude, position.longitude));
          markers[MarkerId("current_location")] = Marker(
            markerId: MarkerId("current_location"),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: InfoWindow(title: "Current Location"),
          );
          currentPace = response['current_pace']?.toString() ?? "0:00";
          totalDistance = response['total_distance'] ?? "0.0 km";
          elapsedTime = response['elapsed_time']?.toString() ?? "0:00";
        });
      } catch (e) {
        print("Error sending location data: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send location data. Retrying...')),
        );
      }
    });
  }

  void _endFollowingRunning() {
    locationTimer?.cancel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("따라 달리기"),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
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
                  color: Colors.red, // 따라 달리기 코스 색상
                ),
              },
              markers: markers.values.toSet(),
            ),
          ),
          if (!isRunning)
            ElevatedButton(
              onPressed: _startFollowingRunning,
              child: Text("달리기 시작"),
            ),
          if (isRunning)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text("Current Pace: $currentPace min/km"),
                  Text("Total Distance: $totalDistance"),
                  Text("Elapsed Time: $elapsedTime"),
                  ElevatedButton(
                    onPressed: _endFollowingRunning,
                    child: Text("Finish Running"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    super.dispose();
  }
}
