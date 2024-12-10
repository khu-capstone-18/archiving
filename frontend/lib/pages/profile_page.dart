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
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 프로필 이미지
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(userProfile!['profile_image']),
                onBackgroundImageError: (_, __) {
                  Icon(Icons.account_circle, size: 60);
                },
              ),
              SizedBox(height: 16),

              // 사용자 이름
              Text(
                userProfile!['username'],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),

              // 총 거리 및 시간
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoCard(
                    title: 'Total Distance',
                    value: '${userProfile!['total_distance']} km',
                  ),
                  _buildInfoCard(
                    title: 'Total Time',
                    value: '${userProfile!['total_time']} mins',
                  ),
                ],
              ),
              SizedBox(height: 16),

              // 최고 기록
              if (userProfile!['best_record'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Best Record',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Distance: ${userProfile!['best_record']['distance']} km',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Time: ${userProfile!['best_record']['time']} mins',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              SizedBox(height: 16),

              // 주간 목표
              _buildInfoCard(
                title: 'Weekly Goal',
                value: '${userProfile!['weekly_goal']} km',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String value}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFFEC6E4F)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
