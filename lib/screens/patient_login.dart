import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class PatientLoginScreen extends StatefulWidget {
  @override
  _PatientLoginScreenState createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  Future<void> _login() async {
    try {
      // Sign in with email and password
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Fetch user role from Firestore
      String uid = userCredential.user!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        String role = userDoc['role'] ?? '';

        // Check if the role is "patient"
        if (role == 'patient') {
          Navigator.pushReplacementNamed(context, '/patientDashboard');
        } else {
          // Role is not "patient"
          setState(() {
            _errorMessage = 'Giriş başarısız: Sadece hastalar giriş yapabilir.';
          });
          await FirebaseAuth.instance.signOut();  // Sign out the user
        }
      } else {
        setState(() {
          _errorMessage = 'Kullanıcı rolü bulunamadı.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Giriş başarısız: $e';
      });
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
        centerTitle: true,  // Centered title
      ),
      body: Stack( // Added Stack widget to set the background image
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',  // Add the background image path here
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(  // Center the login form content
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
                        fillColor: Color.fromARGB(255, 230, 243, 255),  // Baby Blue background
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
                        fillColor: Color.fromARGB(255, 230, 243, 255),  // Baby Blue background
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      obscureText: true,
                      style: GoogleFonts.poppins(),
                    ),
                    SizedBox(height: 20),
                    // Error message
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
                        backgroundColor: Color.fromARGB(255, 60, 145, 230), // Blue background
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Register Button
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/patientRegister');
                      },
                      child: Text(
                        "Kayıt Ol",
                        style: GoogleFonts.poppins(color: Color.fromARGB(255, 60, 145, 230)), // Blue text
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
