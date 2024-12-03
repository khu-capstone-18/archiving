import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/api_service.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService apiService = ApiService();
  Map<String, dynamic>? userProfile;
  String? token;
  String? username;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchUserProfile();
    });
  }

  Future<void> fetchUserProfile() async {
    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final username = prefs.getString('username');

    print("SharedPreferences 상태 확인:");
    print(" - token: $token");
    print(" - username: $username");

    if (token == null || username == null) {
      setState(() {
        errorMessage = 'User authentication failed.';
        isLoading = false;
      });
      return;
    }

    try {
      final userProfileData = await apiService.fetchUserProfile(
        token: token,
        username: username,
      );

      setState(() {
        userProfile = {
          "user_id": userProfileData['user_id'] ?? "N/A",
          "username": userProfileData['username'] ?? "N/A",
          "profile_image":
              userProfileData['profile_image'] ?? "default_image.png",
          "total_distance": userProfileData['total_distance'] ?? 0.0,
          "total_time": userProfileData['total_time'] ?? 0.0,
          "best_record":
              userProfileData['best_record'] ?? {"distance": 0.0, "time": 0.0},
          "weekly_goal": userProfileData['weekly_goal'] ?? 0,
        };
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load user profile. Please try again later.';
        isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user profile.')),
        );
      });

      print("Error fetching user profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(
            child: Text(errorMessage, style: TextStyle(color: Colors.red))),
      );
    }

    if (userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: Text('Failed to load user profile.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userProfile!['profile_image'] != null)
              Image.network(
                userProfile!['profile_image'],
                height: 100,
                width: 100,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.account_circle, size: 100); // 기본 아이콘
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                    ),
                  );
                },
              ),
            Text('Username: ${userProfile!['username']}'),
            Text('Total Distance: ${userProfile!['total_distance']} km'),
            Text('Total Time: ${userProfile!['total_time']} mins'),
            if (userProfile!['best_record'] != null) ...[
              Text(
                  'Best Record - Distance: ${userProfile!['best_record']['distance']} km'),
              Text(
                  'Best Record - Time: ${userProfile!['best_record']['time']} mins'),
            ],
            Text('Weekly Goal: ${userProfile!['weekly_goal']} km'),
          ],
        ),
      ),
    );
  }
}
