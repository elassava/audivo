import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emotionmobileversion/screens/patient_settings.dart';
import 'package:emotionmobileversion/screens/patients_test_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

class PatientDashboard extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<DocumentSnapshot> _getPatientInfo() async {
    final userId = _auth.currentUser!.uid;
    return await FirebaseFirestore.instance
        .collection('patients')
        .doc(userId)
        .get();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      Navigator.popUntil(context, (route) => false);
      Navigator.pushNamed(context, '/');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Are you sure?',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 60, 145, 230),
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'No',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _signOut(context);
            },
            child: Text(
              'Yes',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 60, 145, 230),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dashboard',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            FutureBuilder<DocumentSnapshot>(
                              future: _getPatientInfo(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text(
                                    'Welcome, ...',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  );
                                }
                                if (snapshot.hasError ||
                                    !snapshot.hasData ||
                                    !snapshot.data!.exists) {
                                  return Text(
                                    'Welcome, Patient!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  );
                                }
                                var patientData = snapshot.data!.data()
                                    as Map<String, dynamic>;
                                String patientName =
                                    patientData['name'] ?? 'Patient';
                                return Text(
                                  'Welcome, $patientName!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      FutureBuilder<DocumentSnapshot>(
                        future: _getPatientInfo(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              child: CircularProgressIndicator(
                                  color: Color.fromARGB(255, 60, 145, 230)),
                            );
                          }
                          if (snapshot.hasError ||
                              !snapshot.hasData ||
                              !snapshot.data!.exists) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => PSettingsScreen()),
                                );
                              },
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.person,
                                    size: 30,
                                    color: Color.fromARGB(255, 60, 145, 230)),
                              ),
                            );
                          }
                          var patientData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          String? profileImg = patientData['profileImg'];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => PSettingsScreen()),
                              );
                            },
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              backgroundImage: profileImg != null
                                  ? NetworkImage(profileImg)
                                  : null,
                              child: profileImg == null
                                  ? Icon(Icons.person,
                                      size: 30,
                                      color: Color.fromARGB(255, 60, 145, 230))
                                  : null,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // GridView on top of the dashboard
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: EdgeInsets.only(
                    top: 150), // Adjust this margin for correct positioning
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/background.png'),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  children: [
                    _buildGlassEffectCard(
                      context,
                      icon: Icons.medical_services,
                      label: 'My Tests',
                      onTap: () async {
                        String patientId = await _getPatientId();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PPatientTestsScreen(patientId: patientId),
                          ),
                        );
                      },
                    ),
                    _buildGlassEffectCard(
                      context,
                      icon: Icons.settings,
                      label: 'Settings',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PSettingsScreen()),
                        );
                      },
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

  Widget _buildGlassEffectCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = const Color.fromARGB(255, 60, 145, 230),
    Color textColor = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7), // Glass effect opacity
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.09),
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 50),
            SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getPatientId() async {
    return _auth.currentUser!.uid;
  }
}
