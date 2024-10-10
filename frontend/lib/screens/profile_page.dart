import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../api/api_service.dart';

class ProfilePage extends StatelessWidget {
  final String userId;
  final String token;

  ProfilePage({required this.userId, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: FutureBuilder(
        future: ApiService().getUserProfile(userId, token),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final userData = snapshot.data!.data as Map<String, dynamic>;
            return Column(
              children: [
                Text('Username: ${userData['username']}'),
                Text('Email: ${userData['email']}'),
                // 다른 프로필 정보 표시
              ],
            );
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }
}
