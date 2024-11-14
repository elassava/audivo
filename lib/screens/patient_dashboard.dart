import 'package:emotionmobileversion/screens/patients_test_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class PatientDashboard extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Hasta bilgisini Firebase'den alacak fonksiyon
  Future<DocumentSnapshot> _getPatientInfo() async {
    final userId = _auth.currentUser!.uid;
    return await FirebaseFirestore.instance.collection('users').doc(userId).get();
  }

Future<void> _signOut(BuildContext context) async {
  try {
    // Google Sign-In'dan çıkış yap
    await _googleSignIn.signOut();
    
    // Firebase Authentication'dan çıkış yap
    await _auth.signOut();
    
    // Kullanıcı çıkış yaptıktan sonra, geçmişi temizlemek için:
    Navigator.popUntil(context, (route) => false);
    Navigator.pushNamed(context, '/');
  } catch (e) {
    print('Error signing out: $e');
  }
}

  // Show logout confirmation dialog
  Future<void> _showLogoutConfirmation(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Emin misiniz?', // "Are you sure?" in Turkish
          style: GoogleFonts.poppins(
            fontSize: 20, // Custom font size
            fontWeight: FontWeight.bold, // Bold text
            color: Color.fromARGB(255, 60, 145, 230), // Custom color (you can adjust)
          ),
        ),
        content: Text(
          'Çıkış yapmak istediğinizden emin misiniz?', // "Are you sure you want to log out?" in Turkish
          style: GoogleFonts.poppins(
            fontSize: 16, // Custom font size
            fontWeight: FontWeight.normal, // Regular text
            color: Colors.black, // Color for the content
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Close the dialog
            child: Text(
              'Hayır',
              style: GoogleFonts.poppins(
                fontSize: 16, // Custom font size
                fontWeight: FontWeight.bold, // Bold text
                color: Colors.blue, // Custom color for "No"
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              _signOut(context); // Proceed with sign out
            },
            child: Text(
              'Evet',
              style: GoogleFonts.poppins(
                fontSize: 16, // Custom font size
                fontWeight: FontWeight.bold, // Bold text
                color: Colors.blue, // Custom color for "Yes"
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Get patient ID from Firebase and navigate to PatientTestsScreen
  Future<String> _getPatientId() async {
    final userId = _auth.currentUser!.uid;
    final patientDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final patientData = patientDoc.data() as Map<String, dynamic>;

    // Firebase'deki doğru anahtarları kullanıyoruz. Bu örnekte 'patientId' kullanılıyor.
    return patientData['patientId'] ?? ''; // patientId'nin doğru alan olduğuna emin olun
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        automaticallyImplyLeading: false,
        title: Text(
          'Patient Dashboard',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Color.fromARGB(255, 60, 145, 230),
      ),
      body: Container(
        color: Color.fromARGB(255, 230, 243, 255),
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<DocumentSnapshot>(
          future: _getPatientInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text("No patient data found."));
            }

            var patientData = snapshot.data!.data() as Map<String, dynamic>;
            String patientName = patientData['name'] ?? 'N/A';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome message with patient name
                Text(
                  'Welcome, $patientName!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  color: Colors.white,
                  elevation: 4,
                  child: ListTile(
                    leading: Icon(Icons.medical_services, color: Color.fromARGB(255, 60, 145, 230)),
                    title: Text('My Tests', style: GoogleFonts.poppins()),
                    subtitle: Text('View your test results and history', style: GoogleFonts.poppins()),
                    onTap: () async {
                      String patientId = await _getPatientId();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PPatientTestsScreen(patientId: patientId),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                // Other cards and functionality can go here...
                Card(
                  color: Colors.white,
                  elevation: 4,
                  child: ListTile(
                    leading: Icon(Icons.settings, color: Color.fromARGB(255, 60, 145, 230)),
                    title: Text('Settings', style: GoogleFonts.poppins()),
                    subtitle: Text('Manage your settings', style: GoogleFonts.poppins()),
                    onTap: () {
                      Navigator.pushNamed(context, '/patientSettings');
                    },
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  color: Colors.white,
                  elevation: 4,
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('Log Out', style: GoogleFonts.poppins(color: Colors.red)),
                    onTap: () => _showLogoutConfirmation(context), // Show confirmation on logout
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
