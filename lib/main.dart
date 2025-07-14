import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Screen/authentication.dart'; // Auth screen for login/signup
import 'Screen/parent.dart';         // Screen shown to parents
import 'Screen/child.dart';          // Screen shown to children
import 'firebase_options.dart';      // Firebase setup options

// Entry point of the app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures binding before Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Firebase config
  );
  runApp(MyApp());
}

// Main widget of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove debug banner
      theme: ThemeData(
        primaryColor: const Color(0xff27262c),
        scaffoldBackgroundColor: const Color(0xff37383a),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff27262c),
          titleTextStyle: TextStyle(
            color: Color(0xfff0f8ff),
            fontSize: 28,
            fontFamily: 'pacifico',
          ),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xffe3dcaf),
        ),
      ),
      home: const SplashScreen(), // Launch splash screen first
    );
  }
}

// Splash screen shown on app startup
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    // Hide system UI for splash screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Wait for 4 seconds, then check login state
    Timer(const Duration(seconds: 4), () {
      _checkUserLoginStatus();
    });
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersive,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  /// Check login and user type (parent/child), and navigate accordingly
  Future<void> _checkUserLoginStatus() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userType = prefs.getString('userType');

      if (userType == 'parent') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Parents()),
        );
      } else if (userType == 'child') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Child()),
        );
      } else {
        // Invalid or no userType found, fallback to Authentication
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Authentication()),
        );
      }
    } else {
      // No user logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Authentication()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xff76f2ec),
                Color(0xff5d6066),
                Color(0xfff4ee90),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Parental Control App",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 35,
                  color: Colors.white,
                  fontFamily: 'FascinateInline',
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Prototype Application", // <- You can reword this!
                style: TextStyle(
                  fontSize: 30,
                  fontFamily: "pacifico",
                  color: Color(0xffe3dcaf),
                ),
              ),
              Image(
                width: double.infinity,
                image: AssetImage("asset/abc.png"),
              ),
              Image(
                width: 80,
                height: 80,
                image: AssetImage("asset/loading.gif"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
