import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emotionmobileversion/screens/doctor_notes_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'doc_patients_screen.dart';
import 'doc_patient_add_screen.dart';
import 'doc_settings_screen.dart';

class DoctorDashboard extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<DocumentSnapshot> _getDoctorInfo() async {
    final userId = _auth.currentUser!.uid;
    return await FirebaseFirestore.instance.collection('doctors').doc(userId).get();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
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
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: FutureBuilder<DocumentSnapshot>(
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
            String doctorName = doctorData['name'] ?? 'Doctor';
            String? profileImg = doctorData['profileImg'];

            return Stack(
              children: [
                // Background image
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/background.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Dashboard content (longer top layer)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 60, 145, 230),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Audivo',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Welcome, $doctorName!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FutureBuilder<DocumentSnapshot>(
                            future: _getDoctorInfo(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.white,
                                  child: CircularProgressIndicator(
                                      color: Color.fromARGB(255, 60, 145, 230)),
                                );
                              }

                              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => SettingsScreen()),
                                    );
                                  },
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.white,
                                    child: Icon(Icons.person,
                                        size: 30, color: Color.fromARGB(255, 60, 145, 230)),
                                  ),
                                );
                              }

                              var doctorData = snapshot.data!.data() as Map<String, dynamic>;
                              String? profileImg = doctorData['profileImg'];

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SettingsScreen()),
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
                                          size: 30, color: Color.fromARGB(255, 60, 145, 230))
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
                // GridView on top of the dashboard
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: EdgeInsets.only(top: 150),
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
                          _buildDashboardTile(
                            context,
                            icon: Icons.person,
                            title: 'My Patients',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => PatientsScreen()),
                              );
                            },
                          ),
                          _buildDashboardTile(
                            context,
                            icon: Icons.add,
                            title: 'Add Patient',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => PatientAddScreen()),
                              );
                            },
                          ),
                          _buildDashboardTile(
                            context,
                            icon: Icons.notes,
                            title: 'Notes',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => NotesScreen()),
                              );
                            },
                          ),
                          _buildDashboardTile(
                            context,
                            icon: Icons.settings,
                            title: 'Settings',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SettingsScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },

        ),
      ),
    );
  }

  Widget _buildDashboardTile(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = const Color.fromARGB(255, 60, 145, 230),
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
            Icon(icon, size: 50, color: iconColor),
            SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
