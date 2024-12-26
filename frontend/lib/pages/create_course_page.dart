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
  bool showEndOverlay = false; // 반투명 화면과 종료 메시지 표시 여부
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
    print("현재 속도: $currentPace, 총 거리: $totalDistance, 경과 시간: $elapsedTime");
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: (controller) {
                mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(37.7749, -122.4194),
                zoom: 14.0,
              ),
              markers: markers.values.toSet(),
              polylines: {
                Polyline(
                  polylineId: PolylineId("route"),
                  points: route,
                  color: Colors.blue,
                ),
              },
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 40,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("현재 속도: $currentPace 분/킬로미터"),
                  Text("총 거리: $totalDistance"),
                  Text("경과 시간: $elapsedTime"),
                ],
              ),
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width * 0.5 - 50,
            bottom: isCreatingCourse ? 40 : 240,
            child: GestureDetector(
              onTap:
                  isCreatingCourse ? _endCourseCreation : _startCourseCreation,
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
                    isCreatingCourse ? "종료" : "시작",
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
          if (!isCreatingCourse)
            Positioned(
              left: 16,
              right: 16,
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: courseNameController,
                      decoration: InputDecoration(
                        labelText: "코스 이름",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text("공개 코스"),
                      value: isPublic,
                      activeColor: const Color(0xFFEC6E4F),
                      activeTrackColor: const Color(0xFFF6CCC0),
                      onChanged: (value) {
                        setState(() {
                          isPublic = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          if (showEndOverlay)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Color(0xFFEC6E4F),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '종료!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w800,
                          height: 1.30,
                        ),
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

  Future<void> _startCourseCreation() async {
    try {
      String courseName = courseNameController.text.trim();
      if (courseName.isEmpty) {
        courseName = "Untitled Course";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('코스 이름이 비어있습니다. "Untitled Course"로 설정합니다.')),
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

  Future<void> _endCourseCreation() async {
    locationTimer?.cancel();
    if (courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course creation not started yet.')),
      );
      return;
    }

    String courseName = courseNameController.text.trim();
    if (courseName.isEmpty) {
      courseName = "Untitled Course";
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('User token or ID not found');
      }

      await apiService.endCourse(
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
        showEndOverlay = true; // 반투명 화면 표시
      });

      // 2초 후 종료 화면 숨기기
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          showEndOverlay = false;
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course creation ended successfully!')),
      );
    } catch (e) {
      print("Error ending course creation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to end course creation.')),
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

        if (token == null || courseId == null) {
          print("Missing token or courseId. Stopping location updates.");
          timer.cancel(); // 타이머 중단
          return;
        }
        final response = await apiService.sendSoloData(
          token: token,
          courseId: courseId!,
          latitude: position.latitude,
          longitude: position.longitude,
        );

        setState(() {
          route.add(LatLng(position.latitude, position.longitude));
          currentPace = response['current_pace']?.toString() ?? "0:00";
          totalDistance = response['total_distance']?.toString() ?? "0.0 km";
          elapsedTime = response['elapsed_time']?.toString() ?? "0:00";

          print("갱신된 현재 속도: $currentPace");
          print("갱신된 총 거리: $totalDistance");
          print("갱신된 경과 시간: $elapsedTime");
        });
      } catch (e) {
        print("Error sending solo data: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send location data. Retrying...')),
        );
      }
    });
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    super.dispose();
  }
}
