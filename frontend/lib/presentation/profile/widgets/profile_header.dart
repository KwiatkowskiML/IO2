import 'package:flutter/material.dart';
import 'package:resellio/core/models/models.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile userProfile;
  const ProfileHeader({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Text('Welcome, ${userProfile.firstName}!',
        style: Theme.of(context).textTheme.headlineMedium);
  }
}
