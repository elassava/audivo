import 'package:emotionmobileversion/screens/audio_screens.dart';
import 'package:emotionmobileversion/screens/video_test_screen.dart';
import 'package:emotionmobileversion/screens/masked_video_test_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientTestsScreen extends StatelessWidget {
  final String patientId;

  PatientTestsScreen({required this.patientId});

  Future<Map<String, dynamic>> _fetchPatientInfo() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('patients')
        .doc(patientId)
        .get();

    if (snapshot.exists) {
      return snapshot.data() as Map<String, dynamic>;
    } else {
      throw Exception('Patient not found');
    }
  }

  int _calculateAge(String birthDate) {
    final birthDateTime = DateTime.parse(birthDate);
    final today = DateTime.now();
    int age = today.year - birthDateTime.year;

    if (today.month < birthDateTime.month ||
        (today.month == birthDateTime.month && today.day < birthDateTime.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: Text('Tests',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color.fromARGB(255, 60, 145, 230), // Blue
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png', // Update this with the path to your background image
              fit: BoxFit.cover,
            ),
          ),
          // Content on top of the background
          Container(
            color: Color.fromARGB(50, 230, 243, 255), // Semi-transparent overlay
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _fetchPatientInfo(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading patient info'));
                } else {
                  final patientInfo = snapshot.data!;
                  final birthDate = patientInfo['birthDate'] ?? '';
                  final age = birthDate.isNotEmpty ? _calculateAge(birthDate) : 'N/A';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        color: Colors.white.withOpacity(0.8),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Patient Information',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 60, 145, 230),
                                ),
                              ),
                              SizedBox(height: 8.0),
                              _buildInfoRow('Name', patientInfo['name']),
                              _buildInfoRow('Surname', patientInfo['surname']),
                              _buildInfoRow('Age', age.toString()),
                              _buildInfoRow('DOB', birthDate),
                              _buildInfoRow('Gender', patientInfo['gender']),
                              _buildInfoRow('Email', patientInfo['email']),
                              _buildInfoRow('Phone', patientInfo['phone']),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      // Video Test Card
                      _buildTestCard(
                        context,
                        title: "Video Test",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoScreen(patientId: patientId),
                            ),
                          );
                        },
                        icon: Icons.video_camera_front, // Blue Video Icon
                      ),
                      SizedBox(height: 16.0),
                      // Masked Video Test Card
                      _buildTestCard(
                        context,
                        title: "Masked Video Test",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MaskedVideoScreen(patientId: patientId),
                            ),
                          );
                        },
                        icon: Icons.videocam_off, // Blue Masked Video Icon
                      ),
                      SizedBox(height: 16.0),
                      // Audio Test Card
                      _buildTestCard(
                        context,
                        title: "Audio Test",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AudioScreen(patientId: patientId),
                            ),
                          );
                        },
                        icon: Icons.headset, // Blue Audio Icon
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build info rows
  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        ),
      ],
    );
  }

  // Test Card builder with icon on the right side
  Widget _buildTestCard(BuildContext context,
      {required String title, required VoidCallback onTap, required IconData icon}) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.15,
      child: Card(
        color: Colors.white.withOpacity(0.8),
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0), // Shift text slightly to the right
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.normal, // No bold here
                  ),
                ),
              ),
              Spacer(), // Push icon to the right
              Padding(
                padding: const EdgeInsets.only(right: 16.0), // Shift icon slightly to the left
                child: Icon(
                  icon,
                  color: Color.fromARGB(255, 60, 145, 230), // Blue Icon
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
