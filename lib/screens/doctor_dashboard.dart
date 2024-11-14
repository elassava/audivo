import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emotionmobileversion/screens/doc_settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'doc_patients_screen.dart';
import 'doc_patient_add_screen.dart';

class DoctorDashboard extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to fetch doctor's information from Firebase
  Future<DocumentSnapshot> _getDoctorInfo() async {
    final userId = _auth.currentUser!.uid;
    return await FirebaseFirestore.instance.collection('users').doc(userId).get();
  }

  // Çıkış yapma fonksiyonu
Future<void> _signOut(BuildContext context) async {
  try {
    await _auth.signOut();
    
    // Kullanıcı çıkış yaptıktan sonra, geçmişi temizlemek için:
    Navigator.popUntil(context, (route) => false);
    Navigator.pushNamed(context, '/');
  } catch (e) {
    print('Error signing out: $e');
  }
}


  // Show logout confirmation dialog with styled text
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false; // Prevent back button
      },
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
          automaticallyImplyLeading: false,
          title: Text(
            'Doctor Dashboard',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Color.fromARGB(255, 60, 145, 230),
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.png'), // PNG background
              fit: BoxFit.cover, // Cover the entire screen
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<DocumentSnapshot>(
            future: _getDoctorInfo(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: Text("No doctor data found."));
              }

              var doctorData = snapshot.data!.data() as Map<String, dynamic>;
              String doctorName = doctorData['name'] ?? 'Doctor'; // Retrieve doctor's name

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $doctorName!', // Display dynamic name
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
                      leading: Icon(Icons.person, color: Color.fromARGB(255, 60, 145, 230)),
                      title: Text('Patients', style: GoogleFonts.poppins(fontSize: 16)),
                      subtitle: Text('View and manage patients', style: GoogleFonts.poppins(fontSize: 14)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PatientsScreen()),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    color: Colors.white,
                    elevation: 4,
                    child: ListTile(
                      leading: Icon(Icons.add, color: Color.fromARGB(255, 60, 145, 230)),
                      title: Text('Add Patient', style: GoogleFonts.poppins(fontSize: 16)),
                      subtitle: Text('Add new patient', style: GoogleFonts.poppins(fontSize: 14)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PatientAddScreen()),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    color: Colors.white,
                    elevation: 4,
                    child: ListTile(
                      leading: Icon(Icons.settings, color: Color.fromARGB(255, 60, 145, 230)),
                      title: Text('Settings', style: GoogleFonts.poppins(fontSize: 16)),
                      subtitle: Text('Adjust your preferences', style: GoogleFonts.poppins(fontSize: 14)),
                      onTap: () {
                        // Navigate to settings screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SettingsScreen()),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    color: Colors.white,
                    elevation: 4,
                    child: ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text('Log Out', style: GoogleFonts.poppins(color: Colors.red, fontSize: 16)),
                      onTap: () => _showLogoutConfirmation(context), // Show confirmation on logout
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
