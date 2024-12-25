import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateCoursePage extends StatefulWidget {
  @override
  _CreateCoursePageState createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final ApiService apiService = ApiService();
  GoogleMapController? mapController;
  List<LatLng> route = [];
  Map<MarkerId, Marker> markers = {};
  bool isCreatingCourse = false;
  String? courseId;
  TextEditingController courseNameController = TextEditingController();
  bool isPublic = false;

  Timer? locationTimer; // 위치 전송 타이머
  String currentPace = "0:00";
  String totalDistance = "0.0 km";
  String elapsedTime = "0:00";

  @override
  void initState() {
    super.initState();
    _setInitialLocation(); // 초기 위치 설정
  }

  Future<void> _setInitialLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 지도 카메라 위치를 초기화
      if (mapController != null) {
        mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }

      // 마커 추가
      final markerId = MarkerId("initial_location");
      final marker = Marker(
        markerId: markerId,
        position: LatLng(position.latitude, position.longitude),
        infoWindow: InfoWindow(title: "Initial Location"),
      );

      setState(() {
        markers[markerId] = marker;
      });
    } catch (e) {
      print("Error setting initial location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set initial location.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Course"),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                _setInitialLocation();
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(37.7749, -122.4194), // 샘플 초기 위치
                zoom: 14.0,
              ),
              polylines: {
                Polyline(
                  polylineId: PolylineId("route"),
                  points: route,
                  color: Colors.blue,
                ),
              },
              markers: markers.values.toSet(), // 마커 추가
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: courseNameController,
                  decoration: InputDecoration(
                    labelText: "Course Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                SwitchListTile(
                  title: Text("Public Course"),
                  value: isPublic,
                  onChanged: (value) {
                    setState(() {
                      isPublic = value;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: isCreatingCourse ? null : _startCourseCreation,
                      child: Text("Create & Start Course"),
                    ),
                    ElevatedButton(
                      onPressed: isCreatingCourse ? _endCourseCreation : null,
                      child: Text("End Course"),
                    ),
                  ],
                ),
                if (isCreatingCourse) ...[
                  Text("Current Pace: $currentPace min/km"),
                  Text("Total Distance: $totalDistance"),
                  Text("Elapsed Time: $elapsedTime sec"),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startCourseCreation() async {
    try {
      // 코스 이름 검증 및 기본값 설정
      String courseName = courseNameController.text.trim();
      if (courseName.isEmpty) {
        courseName = "Untitled Course"; // 기본값 설정
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Course name is empty. Using "Untitled Course".')),
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) throw Exception('User token not found');

      final response = await apiService.startCourse(
        location: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        token: token,
      );

      setState(() {
        isCreatingCourse = true;
        courseId = response['course_id'];
        route.add(LatLng(position.latitude, position.longitude));
      });

      // 실시간 위치 전송 시작
      _startLocationUpdates();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course creation started!')),
      );
    } catch (e) {
      print("Error starting course creation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start course creation.')),
      );
    }
  }

  void _addMarker(Position position) {
    final markerId = MarkerId("current_location");
    final marker = Marker(
      markerId: markerId,
      position: LatLng(position.latitude, position.longitude),
      infoWindow: InfoWindow(title: "Current Location"),
    );

    setState(() {
      markers[markerId] = marker;
    });
  }

  void _updateMapLocation(Position position) {
    mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(position.latitude, position.longitude),
      ),
    );
  }

  void _navigateBack() {
    print("Navigating back to RunningSessionPage with success.");
    Navigator.pop(context, true);
  }

  void _startLocationUpdates() {
    locationTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('token');

        if (token == null || courseId == null)
          throw Exception('Token or Course ID not found');

        final response = await apiService.sendSoloData(
          token: token,
          courseId: courseId!,
          latitude: position.latitude,
          longitude: position.longitude,
        );

        setState(() {
          route.add(LatLng(position.latitude, position.longitude));
          _addMarker(position); // 위치마다 마커 갱신
          _updateMapLocation(position);
          currentPace =
              response['current_pace']?.toString() ?? "0"; // int -> String
          totalDistance =
              response['total_distance'] ?? "0.0 km"; // string 그대로 사용
          elapsedTime =
              (response['elapsed_time'] ?? 0).toString(); // int -> String
        });
      } catch (e) {
        print("Error sending solo data: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send location data. Retrying...')),
        );
      }
    });
  }

  Future<void> _endCourseCreation() async {
    locationTimer?.cancel(); // 실시간 위치 전송 중단
    if (courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course creation not started yet.')),
      );
      return;
    }

    // 코스 이름 검증 및 기본값 설정
    String courseName = courseNameController.text.trim();
    if (courseName.isEmpty) {
      courseName = "Untitled Course"; // 기본값 설정
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('User token or ID not found');
      }

      final response = await apiService.endCourse(
        courseId: courseId!,
        courseName: courseName,
        public: isPublic,
        userId: userId,
        location: route.map((point) {
          return {
            'latitude': point.latitude,
            'longitude': point.longitude,
          };
        }).toList(),
        token: token,
      );

      setState(() {
        isCreatingCourse = false;
        route.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Course created! Total Distance: ${response['total_distance']} km'),
        ),
      );
    } catch (e) {
      print("Error ending course creation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to end course creation.')),
      );
    }
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    super.dispose();
  }
}
