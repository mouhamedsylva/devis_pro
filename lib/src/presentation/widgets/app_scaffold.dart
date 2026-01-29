import 'package:flutter/material.dart';
import 'custom_connectivity_banner.dart';

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar; // Added this line

  const AppScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.backgroundColor,
    this.bottomNavigationBar, // Added this line to the constructor
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: CustomConnectivityBanner(
        child: body ?? const SizedBox.shrink(),
      ),
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor,
      bottomNavigationBar: bottomNavigationBar, // Passed to the internal Scaffold
    );
  }
}
