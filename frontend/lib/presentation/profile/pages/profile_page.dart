import 'package:flutter/material.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageLayout(
      title: 'Profile',
      body: Center(child: Text('Profile Page - Coming Soon!')),
    );
  }
}
