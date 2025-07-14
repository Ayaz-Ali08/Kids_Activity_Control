import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background/flutter_background.dart';
import '../methods/App_usage.dart';

/// The Child screen displays a WebView and monitors:
/// - Web activity
/// - Battery level
/// - Location in background
/// - App usage (via usage_stats permissions)
class Child extends StatefulWidget {
  const Child({Key? key}) : super(key: key);

  @override
  _ChildState createState() => _ChildState();
}

class _ChildState extends State<Child> with WidgetsBindingObserver {
  late final WebViewController _controller;
  Position? _currentPosition;
  bool _isLocationTrackingEnabled = false;

  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batterySubscription;
  Timer? _batteryLevelTimer;

  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initializeWebView();
    _setupBackgroundLocationTracking();
    _monitorBatteryLevel();
    _checkAndRequestUsageStatsPermission();
  }

  /// Request usage stats permission and upload usage data
  void _checkAndRequestUsageStatsPermission() async {
    bool hasPermission = await UsageStatsHelper.hasUsageStatsPermission() ?? false;

    if (!hasPermission) {
      await UsageStatsHelper.requestUsageStatsPermission(context);
    } else {
      await UsageStatsHelper.getAndUploadUsageStats(); // Upload if permission is granted
    }
  }

  /// Initialize the WebView with navigation handlers and JS channel
  void _initializeWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView loading progress: $progress%');
          },
          onPageStarted: (String url) {
            debugPrint('Started loading: $url');
            _logWebActivity(url); // Log the URL in Firestore
          },
          onPageFinished: (String url) {
            debugPrint('Finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Error loading page: ${error.description}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load: ${error.description}')),
            );
          },
          onNavigationRequest: (NavigationRequest request) {
            // Example: block YouTube
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      )
      ..loadRequest(Uri.parse('https://www.google.com')); // Default page

    // Enable WebView debugging on Android
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    setState(() {
      _controller = controller;
    });
  }

  /// Save visited web URLs into Firestore under `webActivity` collection
  Future<void> _logWebActivity(String url) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final historyRef = FirebaseFirestore.instance
            .collection('webActivity')
            .doc(user.uid)
            .collection('urls');

        await historyRef.add({
          'url': url,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Failed to log web activity: $e');
    }
  }

  /// Monitor battery level by polling and listening to state changes
  void _monitorBatteryLevel() {
    _batterySubscription = _battery.onBatteryStateChanged.listen((_) {
      _uploadBatteryLevel();
    });

    _batteryLevelTimer = Timer.periodic(Duration(minutes: 1), (_) {
      _uploadBatteryLevel();
    });
  }

  /// Upload battery level to Firestore
  Future<void> _uploadBatteryLevel() async {
    try {
      int batteryLevel = await _battery.batteryLevel;
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('batteryLevels')
            .doc(user.uid)
            .set({
          'batteryLevel': batteryLevel,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Failed to upload battery level: $e');
    }
  }

  /// Upload current GPS location to Firestore
  Future<void> _logLocationToFirestore(Position position) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final locationRef = FirebaseFirestore.instance
            .collection('locations')
            .doc(user.uid)
            .collection('positions');

        await locationRef.add({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Failed to log location: $e');
    }
  }

  /// Set up GPS stream and allow location updates in background
  Future<void> _setupBackgroundLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return;
    }

    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "Child Location Tracking",
      notificationText: "Location is being tracked in the background.",
      notificationImportance: AndroidNotificationImportance.normal,
    );

    await FlutterBackground.initialize(androidConfig: androidConfig);
    await FlutterBackground.enableBackgroundExecution();

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
      _logLocationToFirestore(position);
    });

    setState(() {
      _isLocationTrackingEnabled = true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _batterySubscription?.cancel();
    _batteryLevelTimer?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Child'),
        centerTitle: true,
      ),
      body: WebViewWidget(controller: _controller), // Main WebView
    );
  }
}
