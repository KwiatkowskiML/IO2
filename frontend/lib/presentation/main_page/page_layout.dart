import 'package:flutter/material.dart';
import 'package:resellio/core/utils/responsive_layout.dart';

class PageLayout extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingActionButton;
  final double maxContentWidth;

  const PageLayout({
    super.key,
    required this.title,
    this.actions,
    required this.body,
    this.floatingActionButton,
    this.maxContentWidth = 1200,
  });

  @override
  Widget build(BuildContext context) {
    final bool useAppBar = ResponsiveLayout.isMobile(context);

    return Scaffold(
      appBar: useAppBar
          ? AppBar(
        title: Text(title),
        actions: actions,
      )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          if (!useAppBar)
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (actions != null) Row(mainAxisSize: MainAxisSize.min, children: actions!),
                ],
              ),
            ),


          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(

                  padding: EdgeInsets.symmetric(horizontal: useAppBar ? 0 : 24.0),
                  child: body
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}