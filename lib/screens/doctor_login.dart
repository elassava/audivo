import 'package:emotionmobileversion/screens/forgot_pwd_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';

class DoctorLoginScreen extends StatefulWidget {
  @override
  _DoctorLoginScreenState createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _login() async {
    try {
      
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      
      if (!userCredential.user!.emailVerified) {
        setState(() {
          _errorMessage = "Email not verified. Please verify your email.";
        });
        await FirebaseAuth.instance.signOut();
        return;
      }

      
      String uid = userCredential.user!.uid;
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        String role = userDoc['role'] ?? '';

        
        if (role == 'doctor') {
          Navigator.pushReplacementNamed(context, '/doctorDashboard');
        } else {
          setState(() {
            _errorMessage = 'Login failed: Only doctors can log in.';
          });
          await FirebaseAuth.instance.signOut();
        }
      } else {
        setState(() {
          _errorMessage = 'No user role found.';
        });
      }
    } on FirebaseAuthException catch (e) {
      
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = 'No account found with this email.';
            break;
          case 'invalid-credential':
            _errorMessage = 'No account found with this email.';
            break;
          case 'wrong-password':
            _errorMessage = 'Incorrect password. Please try again.';
            break;
          case 'invalid-email':
            _errorMessage = 'The email address is not valid.';
            break;
          case 'user-disabled':
            _errorMessage = 'This account has been disabled. Contact support.';
            break;
          default:
            _errorMessage = e.code;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed: $e';
      });
    }
  }

  Future<void> _googleLogin(BuildContext context) async {
    try {
      
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();

      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      
      if (googleUser == null) {
        
        return;
      }

      try {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

       
        UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

       
        String uid = userCredential.user!.uid;

   
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (!userDoc.exists) {
          
          String fullName = userCredential.user!.displayName ?? '';
          List<String> nameParts = fullName.split(' ');
          String firstName = nameParts.isNotEmpty ? nameParts[0] : '';
          String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

          
          String phoneNumber = '';
          String countryCode = '+90';
          DateTime? birthDate;
          String birthDateText = 'Select Birth Date';

          final additionalInfo = await showDialog<Map<String, dynamic>>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              String phoneNumber = '';
              String countryCode = '+90';
              DateTime? birthDate;

              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    title: Text(
                      'Additional Information',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              
                              Container(
                                width: 100,
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 15),
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
                                    DropdownMenuItem(
                                        value: '+90', child: Text('🇹🇷 +90')),
                                    DropdownMenuItem(
                                        value: '+1', child: Text('🇺🇸 +1')),
                                    DropdownMenuItem(
                                        value: '+44', child: Text('🇬🇧 +44')),
                                    DropdownMenuItem(
                                        value: '+49', child: Text('🇩🇪 +49')),
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
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 15),
                                  ),
                                  keyboardType: TextInputType.number,
                                  maxLength: 10,
                                  onChanged: (value) {
                                    setState(() {
                                      phoneNumber = value;
                                    });
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
                                  birthDate = picked;
                                  birthDateText = "${picked.day}/${picked.month}/${picked.year}";
                                  (context as Element).markNeedsBuild();  // Force rebuild to update text
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1A237E),
                                padding:
                                    EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                              'birthDate':
                                  "${birthDate!.year}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}",
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
           
            await FirebaseFirestore.instance.collection('users').doc(uid).set({
              'name': firstName,
              'surname': lastName,
              'email': googleUser.email,
              'role': 'doctor',
              'phoneNumber': additionalInfo['phoneNumber'],
              'birthDate': additionalInfo['birthDate'],
              'createdAt': FieldValue.serverTimestamp(),
            });

            
            await FirebaseFirestore.instance.collection('doctors').doc(uid).set({
              'name': firstName,
              'surname': lastName,
              'email': googleUser.email,
              'role': 'doctor',
              'phoneNumber': additionalInfo['phoneNumber'],
              'birthDate': additionalInfo['birthDate'],
              'createdAt': FieldValue.serverTimestamp(),
            });
          } else {
            
            await FirebaseAuth.instance.signOut();
            return;
          }
        }

        
        String role = userDoc.exists ? userDoc['role'] ?? '' : 'doctor';

        if (role == 'doctor') {
          Navigator.pushReplacementNamed(context, '/doctorDashboard');
        } else {
          await FirebaseAuth.instance.signOut();
          setState(() {
            _errorMessage = 'Login failed: Only doctors can log in.';
          });
        }
      } catch (authError) {
        
        await _googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
        setState(() {
          _errorMessage = 'Authentication failed: ${authError.toString()}';
        });
      }
    } catch (e) {
      
      if (e.toString().contains('com.google.android.gms.common.api.ApiException')) {
        setState(() {
          _errorMessage = 'Google Sign In was canceled or failed. Please try again.';
        });
      } else {
        setState(() {
          _errorMessage = 'Sign in error: ${e.toString()}';
        });
      }
      
      
      try {
        await _googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
      } catch (_) {
        
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
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      
                      Text(
                        'Doctor Sign In',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF283593)
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 40),

                     
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
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey[400],
                            ),
                            prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400]),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      SizedBox(height: 20),

                     
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
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey[400],
                            ),
                            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          obscureText: true,
                        ),
                      ),

                      
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

                      
                      Row(
                        children: [
                          Expanded(child: Divider(color: Color.fromARGB(255, 38, 38, 38), thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: GoogleFonts.poppins(
                                color:Color(0xFF283593),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Color(0xFF283593), thickness: 1)),
                        ],
                      ),
                      SizedBox(height: 20),

                      
                      Text(
                        'Sign in with',
                        style: GoogleFonts.poppins(
                          color:Color(0xFF283593),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),

                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          
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
                              onPressed: () => _googleLogin(context),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),

                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an Account? ",
                            style: GoogleFonts.poppins(
                              color:Color(0xFF283593),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/doctorRegister');
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
    );
  }
}
