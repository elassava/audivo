import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

class PatientLoginScreen extends StatefulWidget {
  @override
  _PatientLoginScreenState createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  // Google sign-in instance
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _login() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await _checkUserRole(userCredential.user!.uid);
    } catch (e) {
      setState(() {
        _errorMessage = 'Giriş başarısız: $e';
      });
    }
  }

  // Function for Google sign-in
// Function for Google sign-in with account selection each time
Future<void> _googleLogin() async {
  try {
    // Sign out from Google to ensure account picker appears
    await _googleSignIn.signOut();

    // Attempt Google sign-in
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return; // User canceled sign-in

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credentials
    UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

    // Check if the user already exists, or add them if they don't
    await _checkUserRole(userCredential.user!.uid, googleUser: googleUser);

  } catch (e) {
    setState(() {
      _errorMessage = 'Google ile giriş başarısız: $e';
    });
  }
}


  // Check user role in Firestore, create user if not exists
  Future<void> _checkUserRole(String uid, {GoogleSignInAccount? googleUser}) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userDoc.exists) {
      String role = userDoc['role'] ?? '';
      if (role == 'patient') {
        Navigator.pushReplacementNamed(context, '/patientDashboard');
      } else {
        setState(() {
          _errorMessage = 'Giriş başarısız: Sadece hastalar giriş yapabilir.';
        });
        await FirebaseAuth.instance.signOut();
      }
    } else {
      // If user doesn't exist, create a new record with 'patient' role
      if (googleUser != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': googleUser.email,
          'name': googleUser.displayName,
          'role': 'patient',
        });
      } else {
        await FirebaseFirestore.instance.collection('patients').doc(uid).set({
          'email': _emailController.text.trim(),
          'role': 'patient',
        });
      }
      Navigator.pushReplacementNamed(context, '/patientDashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: Text("Hasta Giriş", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 60, 145, 230),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Email TextField
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'E-posta',
                        labelStyle: GoogleFonts.poppins(color: Colors.black),
                        filled: true,
                        fillColor: Color.fromARGB(255, 230, 243, 255),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.poppins(),
                    ),
                    SizedBox(height: 20),
                    // Password TextField
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        labelStyle: GoogleFonts.poppins(color: Colors.black),
                        filled: true,
                        fillColor: Color.fromARGB(255, 230, 243, 255),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      obscureText: true,
                      style: GoogleFonts.poppins(),
                    ),
                    SizedBox(height: 20),
                    if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    SizedBox(height: 20),
                    // Login Button
                    ElevatedButton(
                      onPressed: _login,
                      child: Text('Giriş Yap', style: GoogleFonts.poppins(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 60, 145, 230),
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
           
                      ),
                    ),
                    SizedBox(height: 20),
                    // Google Sign-In Button
                    ElevatedButton.icon(
                      icon: Padding(
                      padding: const EdgeInsets.only(right: 0.0), // Reduces space between icon and text
                      child: Image.asset('assets/images/google_icon.png', height: 24, width: 25),
                     ),
                    label: Text('Google ile Giriş Yap',style: GoogleFonts.poppins(color: const Color.fromARGB(255, 8, 8, 8), fontSize: 12),
  ),
  onPressed: _googleLogin,
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color.fromARGB(255, 255, 255, 255),  // White background
    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 14),  // Adjust padding for button
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
),

                    SizedBox(height: 10),
                    // Register Button
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/patientRegister');
                      },
                      child: Text(
                        "Kayıt Ol",
                        style: GoogleFonts.poppins(color: Color.fromARGB(255, 60, 145, 230)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
