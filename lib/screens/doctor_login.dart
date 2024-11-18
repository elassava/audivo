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

Future<void> _login() async {
  try {
    // Email ve şifre ile giriş yap
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // Kullanıcı doğrulama durumunu kontrol et
    if (!userCredential.user!.emailVerified) {
      setState(() {
        _errorMessage = "Email not verified. Please verify your email.";
      });
      await FirebaseAuth.instance.signOut();
      return;
    }

    // Kullanıcı rolünü Firestore'dan al
    String uid = userCredential.user!.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userDoc.exists) {
      String role = userDoc['role'] ?? '';

      // Kullanıcı rolünü kontrol et
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
    // Firebase hata kodlarını kontrol et
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
    // Google ile giriş yap
    final GoogleSignIn googleSignIn = GoogleSignIn();

    // Silently login'ı devre dışı bırak
    await googleSignIn.signOut(); // Eğer daha önce giriş yapılmışsa oturumu kapat

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      // Kullanıcı oturumu iptal etti
      return;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Firebase ile giriş yap
    UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

    // Kullanıcı UID'sini al
    String uid = userCredential.user!.uid;

    // Kullanıcı Firestore'da kayıtlı mı kontrol et
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      // Firebase'de kayıtlı değilse, yeni kullanıcıyı kaydet
      String fullName = userCredential.user!.displayName ?? '';
      List<String> nameParts = fullName.split(' '); // Ad ve soyadı ayırmak için boşlukla bölelim
      String firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : ''; // Soyadını al

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': firstName,  // Ad
        'surname': lastName,    // Soyad
        'email': userCredential.user!.email,
        'role': 'doctor', // Varsayılan olarak 'doctor' rolü atanıyor
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Aynı veriyi doctor koleksiyonuna da kaydedelim
      await FirebaseFirestore.instance.collection('doctors').doc(uid).set({
        'name': firstName,
        'surname': lastName,
        'email': userCredential.user!.email,
        'role': 'doctor', // Varsayılan uzmanlık atanabilir
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Yeni kullanıcı kaydedildikten sonra, rolünü al
      userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    }

    // Kullanıcı bilgilerini güncelledikten sonra rol kontrolünü yap
    String role = userDoc['role'] ?? '';

    if (role == 'doctor') {
      // Rol 'doctor' ise doktor dashboard'una yönlendir
      Navigator.pushReplacementNamed(context, '/doctorDashboard');
    } else {
      // Eğer rol uyumsuzsa, kullanıcıyı çıkış yapıp hata mesajı göster
      await FirebaseAuth.instance.signOut();
      setState(() {
        _errorMessage = 'Login failed: Only doctors can log in.';
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Login failed: $e';
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
        title: Text("Doctor Login", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
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
                // Email TextField
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
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
                    labelText: 'Password',
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
                    style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                SizedBox(height: 20),
                // Email Login Button
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
                // Google Login Button
             ElevatedButton.icon(
              onPressed: () => _googleLogin(context),
              icon: Padding(
                padding: const EdgeInsets.only(right: 0.0),
                child: Image.asset(
                  'assets/images/google_icon.png', // This loads the image from assets
                  height: 24, width: 25  // Adjust the size of the icon
                ),
              ),
              label: Text('Login with Google',style: GoogleFonts.poppins(color: const Color.fromARGB(255, 8, 8, 8), fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 14),
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
                    Navigator.pushNamed(context, '/doctorRegister');
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
    );
  }
}
