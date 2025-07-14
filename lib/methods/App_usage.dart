import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:usage_stats/usage_stats.dart';

class UsageStatsHelper {
  // Method to check if the app has permission to access usage stats
  static Future<bool?> hasUsageStatsPermission() async {
    if (Platform.isAndroid) {
      try {
        return await UsageStats.checkUsagePermission();
      } catch (e) {
        print('Error checking usage stats permission: $e');
        return false;
      }
    }
    return false;
  }

  // Method to request permission to access usage stats
  static Future<void> requestUsageStatsPermission(BuildContext context) async {
    if (Platform.isAndroid) {
      try {
        const AndroidIntent intent = AndroidIntent(
          action: 'android.settings.USAGE_ACCESS_SETTINGS',
        );
        await intent.launch();

        // Show an instructional message to guide the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please grant usage access permission. After that, return to the app.'),
            duration: Duration(seconds: 5),
          ),
        );

        // Instead of waiting for a fixed delay, let's loop until the user grants permission
        bool hasPermission = await hasUsageStatsPermission() ?? false;
        while (!hasPermission) {
          await Future.delayed(Duration(seconds: 1)); // Wait for a second before checking again
          hasPermission = await hasUsageStatsPermission() ?? false;
        }

        // After permission is granted, notify the user and fetch data
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission granted! Fetching usage data...')),
        );
        await getAndUploadUsageStats();

      } catch (e) {
        print('Error requesting usage stats permission: $e');
      }
    }
  }

  // Method to get usage stats for a specific time range and upload to Firestore
  static Future<void> getAndUploadUsageStats() async {
    if (Platform.isAndroid) {
      try {
        DateTime endDate = DateTime.now();
        DateTime startDate = endDate.subtract(Duration(days: 1)); // Last 24 hours
        List<UsageInfo> stats = await UsageStats.queryUsageStats(startDate, endDate);

        // Upload usage stats to Firestore
        await uploadUsageStatsToFirestore(stats);
      } catch (e) {
        print('Error getting usage stats: $e');
      }
    }
  }

  // Method to upload usage stats to Firestore
  static Future<void> uploadUsageStatsToFirestore(List<UsageInfo> stats) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final CollectionReference usageStatsRef = FirebaseFirestore.instance
            .collection('usageStats')
            .doc(user.uid)
            .collection('records');

        for (UsageInfo info in stats) {
          await usageStatsRef.doc(info.packageName).set({
            'packageName': info.packageName,
            'totalTimeInForeground': info.totalTimeInForeground,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)); // Use packageName as document ID to prevent duplicates
        }
      }
    } catch (e) {
      print('Failed to upload usage stats: $e');
    }
  }
}
