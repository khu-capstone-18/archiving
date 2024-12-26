import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoloRunningPage extends StatefulWidget {
  @override
  _SoloRunningPageState createState() => _SoloRunningPageState();
}

class _SoloRunningPageState extends State<SoloRunningPage> {
  final ApiService apiService = ApiService();
  GoogleMapController? mapController;
  List<LatLng> route = [];
  Map<MarkerId, Marker> markers = {};
  Timer? locationTimer;
  String currentPace = "0:00";
  String totalDistance = "0.0 km";
  String elapsedTime = "0:00";
  String? courseId; // 서버에서 반환받은 course_id
  bool isRunning = false; // 달리기 시작 여부
  bool isCompleted = false; // 달리기 종료 여부
  String totalPace = "0:00"; // 종료 후 보여줄 데이터
  String totalDistanceResult = "0.0 km";
  String totalTimeResult = "0:00";

  @override
  void initState() {
    super.initState();
    _setInitialLocation();
  }

  Future<void> _setInitialLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mapController != null) {
        mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }

      final markerId = MarkerId("initial_location");
      final marker = Marker(
        markerId: markerId,
        position: LatLng(position.latitude, position.longitude),
        infoWindow: InfoWindow(title: "Starting Location"),
      );

      setState(() {
        markers[markerId] = marker;
        route.add(LatLng(position.latitude, position.longitude));
      });
    } catch (e) {
      print("Error setting initial location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set initial location.')),
      );
    }
  }

  Future<void> _startSoloRunning() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) throw Exception('Token not found');

      final response = await apiService.startSoloRunning(
        courseId: "new", // 새 코스를 생성하기 위해 요청
        location: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        token: token,
      );

      setState(() {
        courseId = response['course_id']; // 반환된 course_id 저장
        isRunning = true; // 달리기 상태 변경
        route.add(LatLng(position.latitude, position.longitude));
        markers[MarkerId("initial_location")] = Marker(
          markerId: MarkerId("initial_location"),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: InfoWindow(title: "Starting Location"),
        );
      });

      print("혼자 달리기 시작 성공, course_id: $courseId");
      _startLocationUpdates();
    } catch (e) {
      print("Error starting solo running: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start solo running.')),
      );
    }
  }

  void _startLocationUpdates() {
    locationTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        if (courseId == null) {
          throw Exception("Course ID is not available");
        }

        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('token');

        if (token == null) throw Exception('Token not found');

        final response = await apiService.sendSoloRunningData(
          courseId: courseId!,
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

  Future<void> _endRunning() async {
    if (courseId == null) {
      print("No course ID found to end the run.");
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) throw Exception('Token not found');

      final response = await apiService.endRunning(
        courseId: courseId!,
        courseName: "Solo Run",
        isPublic: false,
        userId: prefs.getString('user_id') ?? '',
        location: route
            .map((e) => {'latitude': e.latitude, 'longitude': e.longitude})
            .toList(),
        token: token,
      );

      setState(() {
        isRunning = false;
        isCompleted = true; // 종료 상태로 변경
        totalPace = response['total_pace']?.toString() ?? "0:00";
        totalDistanceResult = response['total_distance'] ?? "0.0 km";
        totalTimeResult = response['total_time']?.toString() ?? "0:00";
      });

      print("혼자 달리기 종료 성공");
    } catch (e) {
      print("Error ending solo running: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to end solo running.')),
      );
    } finally {
      locationTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      // 달리기 종료 후 결과 표시
      return Scaffold(
        appBar: AppBar(title: Text("Run Results")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Total Pace: $totalPace", style: TextStyle(fontSize: 18)),
              Text("Total Distance: $totalDistanceResult",
                  style: TextStyle(fontSize: 18)),
              Text("Total Time: $totalTimeResult",
                  style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Back to Running Session"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("혼자 달리기"),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(37.7749, -122.4194), // Default location
                zoom: 14.0,
              ),
              polylines: {
                Polyline(
                  polylineId: PolylineId("route"),
                  points: route,
                  color: Colors.blue,
                ),
              },
              markers: markers.values.toSet(),
            ),
          ),
          if (!isRunning && !isCompleted)
            ElevatedButton(
              onPressed: _startSoloRunning,
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
                    onPressed: _endRunning,
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
