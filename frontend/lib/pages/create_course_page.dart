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
  bool isCreatingCourse = false;
  String? courseId;
  TextEditingController courseNameController = TextEditingController();
  bool isPublic = false;

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
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: courseNameController,
              decoration: InputDecoration(
                labelText: "Course Name",
                border: OutlineInputBorder(),
              ),
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
        ],
      ),
    );
  }

  Future<void> _startCourseCreation() async {
    try {
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

      print('Route after starting course: $route');

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
    if (courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course creation not started yet.')),
      );
      return;
    }

    if (courseNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a course name.')),
      );
      return;
    }

    print('Route before ending course: $route');

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        throw Exception('User token or ID not found');
      }

      final response = await apiService.endCourse(
        courseId: courseId!,
        courseName: courseNameController.text,
        public: isPublic,
        userId: userId,
        location: route.map((point) {
          return {
            'latitude': point.latitude,
            'longitude': point.longitude,
          };
        }).toList(),
        currentTime: DateTime.now().toIso8601String(),
        token: token,
      );

      setState(() {
        isCreatingCourse = false;
        print('Route before clearing: $route'); // 초기화 전 로그
        route.clear();
      });

      print('Course ended successfully with response: $response');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Course created! Total Distance: ${response['total_distance']} km',
          ),
        ),
      );
    } catch (e) {
      print("Error ending course creation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to end course creation.')),
      );
    }
  }
}
