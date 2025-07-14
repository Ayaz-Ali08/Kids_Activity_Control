import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Constant.dart';
import 'authentication.dart';

class Sign_UP extends StatefulWidget {
  @override
  State<Sign_UP> createState() => _Sign_UPState();
}

class _Sign_UPState extends State<Sign_UP> {
  final _auth = FirebaseAuth.instance;

  bool _flag = false;
  bool _obscureText = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Register Here",
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Color(0xffFCF5E5),
                    fontFamily: "FascinateInline",
                  ),
                ),
                const SizedBox(height: 12),
                customTextField(
                  controller: _nameController,
                  label: "Name",
                  obscureText: false,
                ),
                const SizedBox(height: 8),
                customTextField(
                  controller: _emailController,
                  label: "Email",
                  obscureText: false,
                ),
                const SizedBox(height: 8),
                customTextField(
                  controller: _passwordController,
                  label: "New Password",
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
                const SizedBox(height: 12),
                customTextField(
                  controller: _confirmPasswordController,
                  label: "Confirm Password",
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(25),
                  margin: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff0172AF), Color(0xff74FEBD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: _signUp,
                    child: const Center(
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 27,
                          fontFamily: "Lobster",
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signUp() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set user display name
      await userCredential.user!.updateDisplayName(name);

      // Optionally store user profile in Firestore
      // await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
      //   'name': name,
      //   'email': email,
      //   'createdAt': FieldValue.serverTimestamp(),
      // });

      // Navigate to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Authentication()),
      );
    } catch (e) {
      print('Error signing up: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign up: $e')),
      );
    }
  }
}
