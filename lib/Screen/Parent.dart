import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Parent_Sub_Screen/AppUsageScreen.dart';
import '../Parent_Sub_Screen/Bettery_level.dart';
import '../Parent_Sub_Screen/MapScreen.dart';
import '../Parent_Sub_Screen/Screen_Time.dart';
import '../Parent_Sub_Screen/Web_Activity.dart';
import 'authentication.dart';
import 'package:flutter_background/flutter_background.dart';

class Parents extends StatefulWidget {
  const Parents({super.key});

  @override
  _ParentsState createState() => _ParentsState();
}

class _ParentsState extends State<Parents> {
  List<String> _webActivity = [];
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _usageStats = [];
  int? _batteryLevel;
  int _totalScreenTime = 0; // Initialize screen time with default value
  StreamSubscription<DocumentSnapshot>? _batterySubscription;
  StreamSubscription<QuerySnapshot>? _webActivitySubscription;
  StreamSubscription<QuerySnapshot>? _locationSubscription;
  StreamSubscription<DocumentSnapshot>? _screenTimeSubscription;
  Timer? _batteryLevelTimer;

  @override
  void initState() {
    super.initState();
    _initializeBackgroundExecution();
    _listenToWebActivity();
    _listenToLocationData();
    _listenToBatteryLevel();
    _fetchUsageStats(); // Fetch usage stats from Firestore
  }

  @override
  void dispose() {
    _batterySubscription?.cancel();
    _webActivitySubscription?.cancel();
    _locationSubscription?.cancel();
    _batteryLevelTimer?.cancel();
    FlutterBackground.disableBackgroundExecution();
    super.dispose();
  }

  Future<void> _initializeBackgroundExecution() async {
    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "Parent App",
      notificationText: "Monitoring child's activity.",
      notificationImportance: AndroidNotificationImportance.high,
    );

    await FlutterBackground.initialize(androidConfig: androidConfig);
    await FlutterBackground.enableBackgroundExecution();
  }

  void _listenToLocationData() {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _locationSubscription = FirebaseFirestore.instance
            .collection('locations')
            .doc(user.uid)
            .collection('positions')
            .orderBy('timestamp',
            descending: true) // Get the most recent location first
            .snapshots()
            .listen((QuerySnapshot querySnapshot) async {
          List<Map<String, dynamic>> locations = [];
          for (var doc in querySnapshot.docs) {
            double latitude = doc['latitude'];
            double longitude = doc['longitude'];
            DateTime timestamp = doc['timestamp'].toDate();

            // Reverse geocoding to get address
            try {
              List<Placemark> placemarks =
              await placemarkFromCoordinates(latitude, longitude);
              if (placemarks.isNotEmpty) {
                Placemark place = placemarks.first;

                // Construct a readable address without plus codes
                String address =
                    " ${place.locality}, ${place.administrativeArea}, ${place
                    .country}";

                // Exclude any plus codes or empty segments
                address =
                    address.replaceAll(RegExp(r'[^a-zA-Z0-9, ]'), '').trim();

                locations.add({
                  'latitude': latitude,
                  'longitude': longitude,
                  'timestamp': timestamp,
                  'address': address, // Use the readable address
                });
              } else {
                locations.add({
                  'latitude': latitude,
                  'longitude': longitude,
                  'timestamp': timestamp,
                  'address': 'Unknown place', // Fallback if no placemarks found
                });
              }
            } catch (e) {
              print('Failed to get address: $e');
              locations.add({
                'latitude': latitude,
                'longitude': longitude,
                'timestamp': timestamp,
                'address': 'Unknown address',
                // Fallback if address retrieval fails
              });
            }
          }

          setState(() {
            _locations = locations;
          });
        });
      }
    } catch (e) {
      print('Failed to retrieve location data: $e');
    }
  }

  void _listenToBatteryLevel() {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _batterySubscription = FirebaseFirestore.instance
            .collection('batteryLevels')
            .doc(user.uid)
            .snapshots()
            .listen((DocumentSnapshot documentSnapshot) {
          if (documentSnapshot.exists) {
            setState(() {
              _batteryLevel = documentSnapshot['batteryLevel'];
            });
          }
        });
      }
    } catch (e) {
      print('Failed to retrieve battery level: $e');
    }
  }

  void _listenToWebActivity() {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final threeDaysAgo = DateTime.now().subtract(Duration(days: 3));
        _webActivitySubscription = FirebaseFirestore.instance
            .collection('webActivity')
            .doc(user.uid)
            .collection('urls')
            .where('timestamp', isGreaterThan: threeDaysAgo)
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen((QuerySnapshot querySnapshot) {
          setState(() {
            _webActivity =
                querySnapshot.docs.map((doc) => doc['url'] as String).toList();
          });
        });
      }
    } catch (e) {
      print('Failed to retrieve web activity: $e');
    }
  }


  void _fetchUsageStats() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final usageStatsSnapshot = await FirebaseFirestore.instance
          .collection('usageStats')
          .doc(user.uid)
          .get();

      if (usageStatsSnapshot.exists) {
        setState(() {
          _usageStats = List<Map<String, dynamic>>.from(
              usageStatsSnapshot.data()?['apps'] ?? []);
          _totalScreenTime = usageStatsSnapshot.data()?['totalTime'] ?? 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Color(0xfffff5ee),
      appBar: AppBar(
        title: Text('Parent'),
        // backgroundColor: Color(0xffe2dfd2),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => Parents()));
          },
          child: const Icon(Icons.refresh,color: Color(0xFFFFF5EE)),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout,color: Color(0xFFFFF5EE),),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => Authentication()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            buildInfoCard(
              context,
              'Battery Level',
              'Tap here To view Battery Level of Your Child Device',
                  () =>
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            BatteryLevelScreen(batteryLevel: _batteryLevel)),
                  ),
            ),
            buildInfoCard(
              context,
              'Location',
              _locations.isNotEmpty
                  ? _locations
                  .last['address'] // Display the descriptive address without plus codes
                  : 'N/A',
                  () =>
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MapScreen(
                            locationHistory: _locations, // Directly navigate to MapScreen with location history
                          ),
                    ),
                  ),
            ),

            buildInfoCard(
              context,
              'Screen Time',
              'Tap here To view Screen Time  of Your Child Device',
                  () =>
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScreenTimeScreen(),
                    ),
                  ),
            ),
            buildInfoCard(
              context,
              'App Usage',
              'Tap here To view App Usage of Your Child Device',
                  () =>
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AppUsageScreen(), // Navigate to the AppUsageScreen
                    ),
                  ),
            ),

            buildInfoCard(
              context,
              'Web Activity',
              'Tap here To view Web History of Your Child Device',
                  () =>
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            WebActivityScreen(webActivity: _webActivity)),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoCard(BuildContext context,
      String title,
      String data,
      VoidCallback onTap,) {
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
              12), // Rounded corners for the card
        ),
        margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xffFF8473), // Starting color
                Color(0xffFFF9D2), // Ending color
              ],
              begin: Alignment.topLeft, // Start the gradient from top left
              end: Alignment.bottomRight, // End the gradient at bottom right
            ),
            borderRadius: BorderRadius.circular(
                8.0), // Same borderRadius as Card
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            // Add vertical padding to center content
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              // Center items vertically in the column
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  // Remove default padding
                  onTap: onTap,
                  leading: CircleAvatar(
                    backgroundColor: Color(0xfffaf9f6),
                    child: Text(
                      title.isNotEmpty ? title[0] : '',
                      style: const TextStyle(color: Colors.black , fontFamily: 'Lobster',fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style:const  TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'protestGuerrilla',
                          fontSize: 28,
                        ),
                      ),
                     const  SizedBox(height: 8), // Space between title and subtitle
                      Text(
                        data,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold ), // Subtitle text
                      ),
                    ],
                  ),
                  trailing: const  Icon(
                      Icons.keyboard_arrow_right), // Use the custom icon here
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}