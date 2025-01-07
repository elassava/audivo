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
      // Ensure we're signed out before attempting to sign in
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();

      // Attempt to sign in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If user cancels the sign-in process
      if (googleUser == null) {
        // Silent return - user canceled
        return;
      }

      try {
        // Get authentication details
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Create credentials
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase
        UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

        // Check user role
        await _checkUserRole(userCredential.user!.uid, googleUser: googleUser);
      } catch (authError) {
        // Clean up on authentication error
        await _googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
        setState(() {
          _errorMessage = 'Authentication failed: ${authError.toString()}';
        });
      }
    } catch (e) {
      // Handle Google Sign In API exceptions
      if (e.toString().contains('com.google.android.gms.common.api.ApiException')) {
        setState(() {
          _errorMessage = 'Google Sign In was canceled or failed. Please try again.';
        });
      } else {
        setState(() {
          _errorMessage = 'Sign in error: ${e.toString()}';
        });
      }
      
      // Ensure cleanup
      try {
        await _googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
      } catch (_) {
        // Ignore cleanup errors
      }
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
        String phoneNumber = '';
        String countryCode = '+90';
        DateTime? birthDate;
        String birthDateText = 'Select Birth Date';  // Add this for dynamic button text

        final additionalInfo = await showDialog<Map<String, dynamic>>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  title: Center(
                    child: Text(
                      'Additional Information',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
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
                              width: 100,
                              child: DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                                  filled: true,
                                  fillColor: Color.fromARGB(255, 230, 243, 255),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                ),
                                value: countryCode,
                                items: [
                                  DropdownMenuItem(value: '+90', child: Text('🇹🇷 +90')),
                                  DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1')),
                                  DropdownMenuItem(value: '+44', child: Text('🇬🇧 +44')),
                                  DropdownMenuItem(value: '+49', child: Text('🇩🇪 +49')),
                                ],
                                onChanged: (value) {
                                  countryCode = value!;
                                },
                                style: GoogleFonts.poppins(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: Color(0xFF1A237E),
                                ),
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
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                  counterText: "",
                                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 10,
                                onChanged: (value) {
                                  phoneNumber = value;
                                },
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
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
                                color: Color(0xFF1A237E),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        SizedBox(height: 20),
                        // Birth Date Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime(2000),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Color(0xFF1A237E),
                                        onPrimary: Colors.white,
                                      ),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Color(0xFF1A237E),
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  birthDate = picked;
                                  birthDateText = "${picked.day}/${picked.month}/${picked.year}";
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF1A237E),
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  birthDateText,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
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
                        backgroundColor: Color(0xFF1A237E),
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
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Sign In Text
                          Text(
                            'Patient Sign In',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF283593),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 40),

                          // Email TextField
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                hintText: 'Enter your Email',
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                                prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400]),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          SizedBox(height: 20),

                          // Password TextField
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                hintText: 'Enter your Password',
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                              obscureText: true,
                            ),
                          ),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.poppins(
                                  color: Color(0xFF283593),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          // Error Message
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.poppins(
                                  color: Colors.red[400],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          // Login Button
                          Container(
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.white],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'LOGIN',
                                style: GoogleFonts.poppins(
                                  color: Color(0xFF1A237E),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),

                          // OR Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Color(0xFF1A237E), thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'OR',
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFF283593),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Color(0xFF283593), thickness: 1)),
                            ],
                          ),
                          SizedBox(height: 20),

                          // Sign in with text
                          Text(
                            'Sign in with',
                            style: GoogleFonts.poppins(
                              color: Color(0xFF283593),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),

                          // Social Login Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google Login Button
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Image.asset(
                                    'assets/images/google_icon.png',
                                    height: 24,
                                  ),
                                  onPressed: _googleLogin,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 30),

                          // Don't have an account
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an Account? ",
                                style: GoogleFonts.poppins(
                                  color: Color(0xFF283593),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/patientRegister');
                                },
                                child: Text(
                                  'Sign Up',
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFF283593),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
