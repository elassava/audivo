import 'package:emotionmobileversion/screens/forgot_pwd_screen.dart';
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

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      setState(() {
        _errorMessage = "Email not verified! Please check your inbox.";
      });

      // Doğrulama e-postası gönder
      await user.sendEmailVerification();
      return;
    }

    await _checkUserRole(userCredential.user!.uid);
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      setState(() {
        _errorMessage = 'No user found for this email.';
      });
      } else if (e.code == 'invalid-credential') {
      setState(() {
        _errorMessage = 'Incorrect password. Please try again.';
      });
    } else if (e.code == 'wrong-password') {
      setState(() {
        _errorMessage = 'Incorrect password. Please try again.';
      });
    } else if (e.code == 'invalid-email') {
      setState(() {
        _errorMessage = 'Invalid email address format.';
      });
    } 
  } catch (e) {
    setState(() {
      _errorMessage = 'Login failed: $e';
    });
  }
}
  // Function for Google sign-in
// Function for Google sign-in with account selection each time
Future<void> _googleLogin() async {
  try {
    // Google'dan çıkış yaparak hesap seçici ekranını göster
    await _googleSignIn.signOut();

    // Google ile giriş yapmayı dene
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return; // Kullanıcı girişini iptal etti

    // Google'dan kimlik bilgilerini al
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Kimlik bilgilerini kullanarak yeni bir OAuthCredential oluştur
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Firebase ile giriş yap
    UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

    // Kullanıcı rolünü kontrol et
    await _checkUserRole(userCredential.user!.uid, googleUser: googleUser);

  } catch (e) {
    setState(() {
      _errorMessage = 'Google Authentication failed: $e';
    });
  }
}

// Kullanıcı rolünü kontrol et, eğer yoksa yeni kullanıcı oluştur
Future<void> _checkUserRole(String uid, {GoogleSignInAccount? googleUser}) async {
  DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

  if (userDoc.exists) {
    String role = userDoc['role'] ?? '';
    if (role == 'patient') {
      Navigator.pushReplacementNamed(context, '/patientDashboard');
    } else {
      setState(() {
        _errorMessage = 'Login failed: Only patients can log in.';
      });
      await FirebaseAuth.instance.signOut();
    }
  } else {
    // Eğer kullanıcı mevcut değilse, yeni kullanıcıyı oluştur
    if (googleUser != null) {
      String fullName = googleUser.displayName ?? '';
      List<String> nameParts = fullName.split(' '); // Ad ve soyadı ayırmak için boşlukla bölelim
      String firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : ''; // Soyadını al

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': firstName,  // Ad
        'surname': lastName,    // Soyad
        'email': googleUser.email,
        'role': 'patient',       // Varsayılan olarak 'patient' rolü atanıyor
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Aynı veriyi 'patients' koleksiyonuna da kaydedelim
      await FirebaseFirestore.instance.collection('patients').doc(uid).set({
        'name': firstName,
        'surname': lastName,
        'email': googleUser.email,
        'role': 'patient', // Varsayılan hasta rolü
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Yeni kullanıcı kaydedildikten sonra, hastanın dashboard'una yönlendir
      Navigator.pushReplacementNamed(context, '/patientDashboard');
    } else {
      await FirebaseFirestore.instance.collection('patients').doc(uid).set({
        'email': _emailController.text.trim(),
        'role': 'patient',
      });
      Navigator.pushReplacementNamed(context, '/patientDashboard');
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: Text("Patient Login", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        labelText: 'E-mail',
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
                        labelText: 'Password',
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
                        style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    SizedBox(height: 20),
                    // Login Button
                    ElevatedButton(
                      onPressed: _login,
                      child: Text('Login', style: GoogleFonts.poppins(color: Colors.white)),
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
                    label: Text('Login with Google',style: GoogleFonts.poppins(color: const Color.fromARGB(255, 8, 8, 8), fontSize: 12),
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
                    TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                      );
                    },
                    child: Text(
                      "Forgot my Password",
                      style: GoogleFonts.poppins(color: Color.fromARGB(255, 60, 145, 230)),
                    ),
                  ),
                    // Register Button
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/patientRegister');
                      },
                      child: Text(
                        "Register",
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
