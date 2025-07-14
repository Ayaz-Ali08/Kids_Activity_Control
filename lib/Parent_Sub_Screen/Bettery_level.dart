import 'package:flutter/material.dart';

/// A simple screen to display the current battery level visually and textually.
/// The battery level is represented by a colored container and percentage text.
class BatteryLevelScreen extends StatelessWidget {
  final int? batteryLevel;

  // Constructor takes batteryLevel (can be null)
  const BatteryLevelScreen({super.key, required this.batteryLevel});

  @override
  Widget build(BuildContext context) {
    // Determine the container's color based on the battery percentage
    Color containerColor;

    if (batteryLevel != null) {
      if (batteryLevel! > 35) {
        containerColor = Colors.green; // Safe level
      } else if (batteryLevel! > 20) {
        containerColor = Colors.yellow; // Warning level
      } else {
        containerColor = Colors.red; // Critical level
      }
    } else {
      containerColor = Colors.grey; // Battery level unknown
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Level'),
        centerTitle: true,
      ),
      body: Center(
        child: batteryLevel != null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Battery level visual representation
            Container(
              width: 100,
              height: 200,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF5EE), // Light container background
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Fill the container proportionally from bottom
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: batteryLevel! / 100, // From 0.0 to 1.0
                      child: Container(
                        color: containerColor,
                      ),
                    ),
                  ),
                  // Show battery % in the center
                  Center(
                    child: Text(
                      '$batteryLevel%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Battery text below container
            Text(
              'Battery Level: $batteryLevel%',
              style: const TextStyle(
                fontSize: 24,
                color: Color(0xFFFFF5EE),
              ),
            ),
          ],
        )
            : const Text(
          'No battery level data available',
          style: TextStyle(fontSize: 24, color: Color(0xFFFFF5EE)),
        ),
      ),
    );
  }
}
