import 'package:flutter/material.dart';
import 'package:resellio/core/models/models.dart';

class AccountInfo extends StatelessWidget {
  final UserProfile userProfile;
  const AccountInfo({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(userProfile.email),
            ),
            ListTile(
              leading: const Icon(Icons.verified_user),
              title: const Text('Status'),
              subtitle: Text(userProfile.isActive ? 'Active' : 'Inactive'),
            ),
          ],
        ),
      ),
    );
  }
}
