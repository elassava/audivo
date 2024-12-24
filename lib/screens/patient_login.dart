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
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
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
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Kimlik bilgilerini kullanarak yeni bir OAuthCredential oluştur
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase ile giriş yap
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Kullanıcı rolünü kontrol et
      await _checkUserRole(userCredential.user!.uid, googleUser: googleUser);
    } catch (e) {
      setState(() {
        _errorMessage = 'Google Authentication failed: $e';
      });
    }
  }

// Kullanıcı rolünü kontrol et, eğer yoksa yeni kullanıcı oluştur
  Future<void> _checkUserRole(String uid,
      {GoogleSignInAccount? googleUser}) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

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
      // Google ile giriş yapan yeni kullanıcı için ek bilgi al
      if (googleUser != null) {
        // Telefon ve doğum tarihi için dialog göster
        final additionalInfo = await showDialog<Map<String, dynamic>>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            String phoneNumber = '';
            String countryCode = '+90'; // Default Türkiye
            DateTime? birthDate;

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                'Additional Information',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 60, 145, 230),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Ülke Kodu Dropdown
                        Container(
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 230, 243, 255),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          width: 100,
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            value: countryCode,
                            items: [
                              DropdownMenuItem(
                                  value: '+90', child: Text('🇹🇷 +90')),
                              DropdownMenuItem(
                                  value: '+1', child: Text('🇺🇸 +1')),
                              DropdownMenuItem(
                                  value: '+44', child: Text('🇬🇧 +44')),
                              DropdownMenuItem(
                                  value: '+49', child: Text('🇩🇪 +49')),
                              // Daha fazla ülke kodu eklenebilir
                            ],
                            onChanged: (value) {
                              countryCode = value!;
                            },
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                        SizedBox(width: 8),
                        // Telefon Numarası Input
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.black87,
                              ),
                              filled: true,
                              fillColor: Color.fromARGB(255, 230, 243, 255),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Color.fromARGB(255, 60, 145, 230),
                                ),
                              ),
                              errorStyle: GoogleFonts.poppins(
                                color: Colors.red,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 10,
                            onChanged: (value) {
                              phoneNumber = value;
                            },
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      ],
                    ),
                    if (phoneNumber.length > 0 && phoneNumber.length < 10)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Phone number must be 10 digits',
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    SizedBox(height: 20),
                    // Doğum tarihi seçici butonu...
                    ElevatedButton(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2000),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          birthDate = picked;
                        }
                      },
                      // ... mevcut buton stili ...
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Select Birth Date',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (phoneNumber.length == 10 && birthDate != null) {
                      Navigator.of(context).pop({
                        'phoneNumber': countryCode + phoneNumber,
                        'birthDate': birthDate,
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            phoneNumber.length != 10
                                ? 'Phone number must be 10 digits'
                                : 'Please fill all fields',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 60, 145, 230),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Submit',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );

        if (additionalInfo != null) {
          String fullName = googleUser.displayName ?? '';
          List<String> nameParts = fullName.split(' ');
          String firstName = nameParts.isNotEmpty ? nameParts[0] : '';
          String lastName =
              nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

          // DateTime'ı istenen formatta (yyyy-MM-dd) string'e çevir
          DateTime birthDate = additionalInfo['birthDate'];
          String formattedDate = "${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}";

          // Kullanıcı bilgilerini kaydet
          Map<String, dynamic> userData = {
            'name': firstName,
            'surname': lastName,
            'email': googleUser.email,
            'role': 'patient',
            'phoneNumber': additionalInfo['phoneNumber'],
            'birthDate': formattedDate,  // String olarak kaydediyoruz
            'createdAt': FieldValue.serverTimestamp(),
          };

          // Her iki koleksiyona da aynı veriyi kaydet
          await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);
          await FirebaseFirestore.instance.collection('patients').doc(uid).set(userData);

          Navigator.pushReplacementNamed(context, '/patientDashboard');
        }
      } else {
        // Normal email/password girişi için mevcut kod
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
        title: Text("Patient Login",
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
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
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    SizedBox(height: 20),
                    // Login Button
                    ElevatedButton(
                      onPressed: _login,
                      child: Text('Login',
                          style: GoogleFonts.poppins(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 60, 145, 230),
                        padding:
                            EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Google Sign-In Button
                    ElevatedButton.icon(
                      icon: Padding(
                        padding: const EdgeInsets.only(
                            right: 0.0), // Reduces space between icon and text
                        child: Image.asset('assets/images/google_icon.png',
                            height: 24, width: 25),
                      ),
                      label: Text(
                        'Login with Google',
                        style: GoogleFonts.poppins(
                            color: const Color.fromARGB(255, 8, 8, 8),
                            fontSize: 12),
                      ),
                      onPressed: _googleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                            255, 255, 255, 255), // White background
                        padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 14), // Adjust padding for button
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
                          MaterialPageRoute(
                              builder: (context) => ForgotPasswordScreen()),
                        );
                      },
                      child: Text(
                        "Forgot my Password",
                        style: GoogleFonts.poppins(
                            color: Color.fromARGB(255, 60, 145, 230)),
                      ),
                    ),
                    // Register Button
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/patientRegister');
                      },
                      child: Text(
                        "Register",
                        style: GoogleFonts.poppins(
                            color: Color.fromARGB(255, 60, 145, 230)),
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
