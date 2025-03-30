import 'package:flutter/material.dart';
import 'package:resellio/presentation/main_page/page_layout.dart';

class MyTicketsPage extends StatelessWidget {
  const MyTicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageLayout(
      title: 'My Tickets',
      body: Center(
        child: Text('My Tickets Page Content'),
      ),
    );
  }
}