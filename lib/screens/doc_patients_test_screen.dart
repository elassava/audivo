import 'package:emotionmobileversion/screens/audio_screens.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PatientTestsScreen extends StatelessWidget {
  final String patientId;

  PatientTestsScreen({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: Text('Tests', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color.fromARGB(255, 60, 145, 230), // Mavi
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
            color: Color.fromARGB(0, 230, 243, 255), // Semi-transparent overlay for readability
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: 16.0),
                // Görüntülü Test Card
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.15,
                  child: Card(
                    color: Colors.white,
                    child: InkWell(
                      onTap: () {
                        // Görüntülü Test işlemi
                        _showTestDetails(context, "Video Test");
                      },
                      child: Center(
                        child: Text("Video Test", style: GoogleFonts.poppins(fontSize: 20)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                // Maskeli Görüntü Test Card
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.15,
                  child: Card(
                    color: Colors.white,
                    child: InkWell(
                      onTap: () {
                        // Maskeli Görüntü Test işlemi
                        _showTestDetails(context, "Masked Video Test");
                      },
                      child: Center(
                        child: Text("Masked Video Test", style: GoogleFonts.poppins(fontSize: 20)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                // Audio Test Card
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.15,
                  child: Card(
                    color: Colors.white,
                    child: InkWell(
                      onTap: () {
                        // Navigate to Audio Test page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AudioScreen(patientId: patientId),
                          ),
                        );
                      },
                      child: Center(
                        child: Text("Audio Test", style: GoogleFonts.poppins(fontSize: 20)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Test details display function
  void _showTestDetails(BuildContext context, String testType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(testType, style: GoogleFonts.poppins()),
        content: Text('Test type: $testType chosen.', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}
