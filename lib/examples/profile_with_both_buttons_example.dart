import 'package:flutter/material.dart';
import '../features/profile/presentation/pages/profile_page.dart';
class ProfileWithBothButtonsExample extends StatelessWidget {
  const ProfileWithBothButtonsExample({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile with Friend & Follow Buttons'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: const Text(
              'Dual-mode profile control:\n\n'
              '🤝 Friend button:\n'
              '• Add Friend - for new connections\n'
              '• Request Sent - after sending a friend request\n'
              '• Accept Request - when a pending request arrives\n'
              '• Friends - once the friendship is confirmed\n\n'
              '👥 Follow button:\n'
              '• Follow - to start following the user\n'
              '• Following - when actively following\n\n'
              'Both buttons operate independently!',
              style: TextStyle(fontSize: 14, height: 1.6),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: ProfilePage(
              userId: 456, // Dummy user for testing
            ),
          ),
        ],
      ),
    );
  }
}
