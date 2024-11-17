import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _successMessage;
  String? _errorMessage;

  Future<void> _resetPassword() async {
    try {
      String email = _emailController.text.trim();

      // Firestore'da e-posta adresini kontrol et
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _successMessage = null;
          _errorMessage = 'No matching mail address found.';
        });
        return;
      }

      // Eğer e-posta mevcutsa şifre sıfırlama e-postası gönder
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _successMessage = 'Mail sent successfully! Please check your mail.';
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _successMessage = null;
        _errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          "Reset Password",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color.fromARGB(255, 60, 145, 230),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    labelStyle: GoogleFonts.poppins(),
                    filled: true,
                    fillColor: Colors.blue[50]?.withOpacity(0.8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _resetPassword,
                  child: Text(
                    'Reset Password',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 60, 145, 230),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                if (_successMessage != null)
                  Text(
                    _successMessage!,
                    style: TextStyle(color: Colors.green, fontSize: 14),
                  ),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
