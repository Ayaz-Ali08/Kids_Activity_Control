import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Constant.dart';
import 'info.dart';      // Redirect screen after successful login
import 'sign_up.dart';  // Sign up screen

/// Authentication screen allows users to sign in using email & password.
/// Uses FirebaseAuth to handle authentication.
class Authentication extends StatefulWidget {
  const Authentication({super.key});

  @override
  State<Authentication> createState() => _AuthenticationState();
}

class _AuthenticationState extends State<Authentication> {
  // State variables
  bool _flag = false;              // Used to toggle password visibility icon
  bool _obscureText = true;        // Controls whether password is hidden
  late String _email;              // Stores email input
  late String _password;           // Stores password input
  final FirebaseAuth _auth = FirebaseAuth.instance; // FirebaseAuth instance

  // Text controllers for email and password
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Welcome",
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffFCF5E5),
                  fontFamily: "FascinateInline",
                ),
              ),
              const SizedBox(height: 12),

              /// Email input field
              customTextField(
                controller: _emailController,
                label: "Email",
                obscureText: false,
              ),

              const SizedBox(height: 10),

              /// Password input field with visibility toggle
              customTextField(
                controller: _passwordController,
                label: "Password",
                obscureText: _obscureText,
                suffixIcon: InkWell(
                  child: _flag
                      ? const Icon(Icons.visibility)
                      : const Icon(Icons.visibility_off),
                  onTap: () {
                    setState(() {
                      _flag = !_flag;
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),

              const SizedBox(height: 20),

              /// Sign In Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: GestureDetector(
                  onTap: _signIn,
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xff0172AF),  // Gradient start
                          Color(0xff74FEBD),  // Gradient end
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "Sign In",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 27,
                          fontFamily: "Lobster",
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Not a Member? ",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Sign_UP(),
                        ),
                      );
                    },
                    child: const Text(
                      "Register Now",
                      style: TextStyle(
                        color: Colors.lightBlueAccent,
                        fontSize: 17,
                        fontFamily: "Lobster",
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Method to sign in the user using FirebaseAuth
  Future<void> _signIn() async {
    _email = _emailController.text.trim();
    _password = _passwordController.text.trim();

    try {
      await _auth.signInWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      // Navigate to Info screen after successful sign-in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Info()),
      );
    } catch (e) {
      // Display error message using a snackbar
      print('Error signing in: email or password is incorrect $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign in: $e'),
        ),
      );
    }
  }
}
