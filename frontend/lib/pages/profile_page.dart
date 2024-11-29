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

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> _loadPreferencesAndFetchProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token');
      username = prefs.getString('username');

      if (token == null || username == null) {
        throw Exception('Username or token not found in local storage.');
      }

      await fetchUserProfile();
    } catch (e) {
      print('Error fetching user profile: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchUserProfile() async {
    try {
      final response = await apiService.fetchUserProfile(
        token: token!,
        username: username!,
      );

      setState(() {
        userProfile = response;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching user profile: $e');
      setState(() {
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
