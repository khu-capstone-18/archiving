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
    positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) async {
      Map<String, double> currentLocation = {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };

      if (widget.mode == "solo") {
        _updateSoloRunning(currentLocation);
      } else if (widget.mode == "following") {
        _updateFollowingRunning(currentLocation);
      }

      setState(() {
        markers.add(Marker(
          markerId: MarkerId("current"),
          position: LatLng(position.latitude, position.longitude),
        ));
        route.add(LatLng(position.latitude, position.longitude));
      });
    });
  }

  Future<void> _updateSoloRunning(Map<String, double> currentLocation) async {
    try {
      final response = await apiService.sendSoloData(
        token: await apiService.getToken(),
        courseId: widget.course['course_id'],
        latitude: currentLocation['latitude']!,
        longitude: currentLocation['longitude']!,
      );
      setState(() {
        currentPace = response['current_pace'].toString();
        totalDistance = double.parse(response['total_distance']);
        elapsedTime = int.parse(response['elapsed_time']);
      });
    } catch (e) {
      print("Error updating solo running: $e");
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
      setState(() {
        currentPace = response['current_pace'];
        totalDistance = double.parse(response['total_distance']);
        elapsedTime = int.parse(response['elapsed_time']);
        locationGap = {
          'latitude': response['location_gap']['latitude'],
          'longitude': response['location_gap']['longitude'],
        };
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
          target: LatLng(
            widget.course['start_point']['latitude'],
            widget.course['start_point']['longitude'],
          ),
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
    super.dispose();
  }
}
