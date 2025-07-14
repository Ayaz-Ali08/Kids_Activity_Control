import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Screen to display app usage statistics in a pie chart and list format.
/// Fetches data from Firebase Firestore and filters out system apps or apps used < 10 minutes.
class AppUsageScreen extends StatelessWidget {
  AppUsageScreen({super.key});

  // List of system apps to exclude from the report.
  final List<String> systemPackageNames = [
    'com.android.systemui',
    'com.android.settings',
    // Add more system package names here if necessary
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Usage'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getUsageStatsStream(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          // Show loading indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error if fetching fails
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white, fontSize: 23),
              ),
            );
          }

          // Handle no data
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No usage data available.',
                style: TextStyle(color: Colors.white, fontSize: 23),
              ),
            );
          }

          // Filter out system apps and usage < 10 min (600000 ms)
          final filteredDocs = snapshot.data!.docs.where((document) {
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;
            double usageTime = double.tryParse(data['totalTimeInForeground'].toString()) ?? 0;
            return !systemPackageNames.contains(data['packageName']) && usageTime > 600000;
          }).toList();

          // If no filtered data, inform user
          if (filteredDocs.isEmpty) {
            return const Center(
              child: Text(
                'No app usage data available for more than 10 minutes.',
                style: TextStyle(color: Color(0xFFFFF5EE), fontSize: 23),
              ),
            );
          }

          // Pie chart colors
          List<Color> colors = [
            Colors.blue,
            Colors.red,
            Colors.green,
            Colors.orange,
            Colors.purple,
            Colors.yellow,
            Colors.grey,
          ];

          // Map each document to a pie chart section
          List<PieChartSectionData> pieSections = filteredDocs.asMap().entries.map((entry) {
            int index = entry.key;
            DocumentSnapshot document = entry.value;
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;
            double usageTime = (double.tryParse(data['totalTimeInForeground'].toString()) ?? 0) / 60000;

            return PieChartSectionData(
              color: colors[index % colors.length],
              value: usageTime,
              title: '${usageTime.toStringAsFixed(1)} min',
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Pie chart view
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: pieSections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      borderData: FlBorderData(show: false),
                      pieTouchData: PieTouchData(
                        touchCallback: (event, pieTouchResponse) {
                          // Optional: handle pie slice tap here
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // List view of apps with icon and usage
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> appData = filteredDocs[index].data() as Map<String, dynamic>;
                      final appIconBase64 = appData['appIcon'];
                      String appName = appData['appName'] ?? appData['packageName'];
                      double usageTime = (double.tryParse(appData['totalTimeInForeground'].toString()) ?? 0) / 60000;

                      return Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xffFF8473),
                              Color(0xffFFF9D2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          style: ListTileStyle.list,
                          leading: appIconBase64 != null
                              ? Image.memory(
                            const Base64Decoder().convert(appIconBase64),
                            width: 40,
                            height: 40,
                          )
                              : const Icon(Icons.apps),
                          title: Text(appName),
                          subtitle: Text('${usageTime.toStringAsFixed(1)} min'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Stream that listens to usage data from Firebase based on current user.
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
