import 'package:flutter/material.dart';
import 'package:kids_activity_control/Screen/parent.dart'; // Import for parent screen
import 'package:shared_preferences/shared_preferences.dart'; // For storing local user type
import 'Child.dart'; // Import for child screen

/// The main function initializes the app and routes the user
/// to the appropriate screen based on stored user type.
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized

  // Retrieve stored user type (parent/child) from shared preferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userType = prefs.getString('userType');

  // Decide which screen to launch as default
  Widget defaultHome;
  if (userType == 'Parent') {
    defaultHome = const Parents(); // Navigate to Parent screen
  } else if (userType == 'Child') {
    defaultHome = const Child(); // Navigate to Child screen
  } else {
    defaultHome = const Info(); // Show Info screen to choose
  }

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: defaultHome,
  ));
}

/// Info screen asks the user to choose between Parent or Child mode
class Info extends StatefulWidget {
  const Info({super.key});

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 23),

            // Title Text
            const Text(
              "Who is Going to use this device?",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFF5EE),
                fontFamily: "FascinateInline",
              ),
            ),

            const SizedBox(height: 23),

            /// Parent Card
            GestureDetector(
              onTap: () async {
                // Save user type as 'parent' locally
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('userType', 'parent');

                // Navigate to Parents screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Parents()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff2DFfF5),
                      Color(0xffFFF878),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Card(
                  color: Colors.transparent,
                  elevation: 5,
                  margin: EdgeInsets.all(20),
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: ListTile(
                      leading: Image(image: AssetImage('asset/parent.gif')),
                      title: Column(
                        children: [
                          Text(
                            "Parents",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              fontFamily: "ProtestGuerrilla",
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Tap here To enter Is a Parents.",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// Child Card
            GestureDetector(
              onTap: () async {
                // Save user type as 'child' locally
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('userType', 'child');

                // Navigate to Child screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Child()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff2DFfF5),
                      Color(0xffFFF878),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Card(
                  color: Colors.transparent,
                  elevation: 5,
                  margin: EdgeInsets.all(20),
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: ListTile(
                      leading: Image(image: AssetImage('asset/child.gif')),
                      title: Column(
                        children: [
                          Text(
                            "Child",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              fontFamily: "ProtestGuerrilla",
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Tap here To enter Is a Child",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
