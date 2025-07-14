import 'package:flutter/material.dart';

/// A screen to display a list of web activity (e.g., visited websites).
/// This screen uses a ListView to display each entry with a styled container.
class WebActivityScreen extends StatelessWidget {
  // List of web activity entries (e.g., URLs or search queries)
  final List<String> webActivity;

  const WebActivityScreen({super.key, required this.webActivity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web Activity'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: webActivity.length,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xffFF8473), // Starting color
                  Color(0xffFFF9D2), // Ending color
                ],
                begin: Alignment.topLeft, // Gradient starts at the top-left corner
                end: Alignment.bottomRight, // Ends at the bottom-right corner
              ),
              borderRadius: BorderRadius.circular(8), // Rounded edges
            ),
            margin: const EdgeInsets.symmetric(vertical: 4), // Space between tiles
            child: ListTile(
              title: Text(webActivity[index]), // Display individual web activity item
            ),
          );
        },
      ),
    );
  }
}
