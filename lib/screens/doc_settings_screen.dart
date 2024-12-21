import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to fetch doctor's info from Firebase
  Future<DocumentSnapshot> _getDoctorInfo() async {
    final userId = _auth.currentUser!.uid;
    return await FirebaseFirestore.instance.collection('users').doc(userId).get();
  }

  // Function to sign out
  Future<void> _signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.popUntil(context, (route) => false);
      Navigator.pushNamed(context, '/'); // Navigate to the login screen
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Function to show logout confirmation dialog
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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50), // Reduce height of AppBar
        child: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
          title: Text(
            'Settings',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color.fromARGB(255, 60, 145, 230), // Blue color
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height, // Full screen height
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'), // Background image
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
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

            String doctorName = doctorData['name'] ?? 'N/A';
            String doctorSurname = doctorData['surname'] ?? 'N/A';
            String doctorEmail = doctorData['email'] ?? 'N/A';
            String doctorBirthDate = doctorData['birthDate'] ?? 'N/A';

            return SingleChildScrollView(
              child: Card(
                color: Colors.white.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Information',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 60, 145, 230),
                        ),
                      ),
                      Divider(
                        color: Colors.grey[400],
                        thickness: 1.0,
                        height: 20,
                      ),
                      SizedBox(height: 10),
                      _buildInfoRow('Name:', doctorName),
                      SizedBox(height: 10),
                      _buildInfoRow('Surname:', doctorSurname),
                      SizedBox(height: 10),
                      _buildInfoRow('Email:', doctorEmail),
                      SizedBox(height: 10),
                      _buildInfoRow('Birth Date:', doctorBirthDate),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: SizedBox(
        height: 80, // Increase button size
        width: 80, // Increase button size
        child: FloatingActionButton(
          onPressed: () => _showLogoutConfirmation(context),
          backgroundColor: Colors.red, // Change color to red
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40), // Make it circular
          ),
          child: Icon(Icons.exit_to_app, color: Colors.white, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Color.fromARGB(255, 60, 145, 230), // Blue color for the bottom bar
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0, // Notch margin for better visibility
        child: SizedBox(height:10), // Adjust height to match button spacing
      ),
    );
  }

  // Helper widget to style each information row
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}
