import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PSettingsScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to fetch patient info from Firebase
  Future<DocumentSnapshot> _getPatientInfo() async {
    final userId = _auth.currentUser!.uid;
    return await FirebaseFirestore.instance.collection('users').doc(userId).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Color.fromARGB(255, 60, 145, 230), // Blue color
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
            String patientSurname = patientData['surname'] ?? 'N/A';
            String patientEmail = patientData['email'] ?? 'N/A';
            String patientBirthDate = patientData['birthDate'] ?? 'N/A';

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
                        'Patient Information',
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
                      _buildInfoRow('Name:', '$patientName $patientSurname'),
                      SizedBox(height: 10),
                      _buildInfoRow('Email:', patientEmail),
                      SizedBox(height: 10),
                      _buildInfoRow('Birth Date:', patientBirthDate),
                      SizedBox(height: 20),
                      // Add any other settings or options below as desired.
                    ],
                  ),
                ),
              ),
            );
          },
        ),
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
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
