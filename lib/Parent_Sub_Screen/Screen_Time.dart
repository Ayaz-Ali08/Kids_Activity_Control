import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// A screen that calculates and displays the total screen time
/// of a user over the last 24 hours by reading usage stats from Firestore.
class ScreenTimeScreen extends StatelessWidget {
  const ScreenTimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Time'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getUsageStatsStream(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          // Show loading indicator while waiting for data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error message if something goes wrong
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white, fontSize: 23),
              ),
            );
          }

          // Show message if no data is available
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No usage data available.',
                style: TextStyle(color: Colors.white, fontSize: 23),
              ),
            );
          }

          // Total screen time accumulator
          double totalScreenTime = 0;

          // Current time and 24-hour threshold
          DateTime now = DateTime.now();
          DateTime last24Hours = now.subtract(const Duration(hours: 24));

          // Loop through documents to calculate screen time within the last 24 hours
          for (var document in snapshot.data!.docs) {
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;

            // Safely extract and convert the timestamp
            Timestamp timestamp = data['timestamp'] as Timestamp;
            DateTime usageTimeDate = timestamp.toDate();

            // Only include entries from the last 24 hours
            if (usageTimeDate.isAfter(last24Hours)) {
              double usageTime = double.tryParse(data['totalTimeInForeground']?.toString() ?? '0') ?? 0;
              totalScreenTime += usageTime;
            }
          }

          // Convert milliseconds to hours
          double totalScreenTimeInHours = totalScreenTime / 3600000;

          // Display screen time result
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Total Screen Time',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFF5EE),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${totalScreenTimeInHours.toStringAsFixed(2)} hours',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFFFFF5EE),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Fetches a real-time Firestore stream of app usage records for the current user.
  Stream<QuerySnapshot> _getUsageStatsStream() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('usageStats')
        .doc(user.uid)
        .collection('records')
        .snapshots();
  }
}
