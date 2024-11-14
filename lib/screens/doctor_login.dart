import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class DoctorLoginScreen extends StatefulWidget {
  @override
  _DoctorLoginScreenState createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
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

        // Check if the role is "doctor"
        if (role == 'doctor') {
          Navigator.pushReplacementNamed(context, '/doctorDashboard');
        } else {
          // Role is not "doctor"
          setState(() {
            _errorMessage = 'Giriş başarısız: Sadece doktorlar giriş yapabilir.';
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
        title: Text("Doktor Giriş", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 60, 145, 230),
        centerTitle: true,  // Centered title
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'), // PNG görseli buraya ekliyoruz
            fit: BoxFit.cover, // Görselin ekranı kaplamasını sağlıyoruz
          ),
        ),
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
                    labelStyle: GoogleFonts.poppins(),
                    filled: true,
                    fillColor: Colors.blue[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20),
                // Password TextField
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    labelStyle: GoogleFonts.poppins(),
                    filled: true,
                    fillColor: Colors.blue[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  obscureText: true,
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
                    backgroundColor: Color.fromARGB(255, 60, 145, 230),
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
                    Navigator.pushNamed(context, '/doctorRegister');
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
    );
  }
}
