import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emotionmobileversion/screens/audio_screens.dart';
import 'package:emotionmobileversion/screens/video_test_screen.dart';
import 'package:emotionmobileversion/screens/masked_video_test_screen.dart';

class PPatientTestsScreen extends StatelessWidget {
  final String patientId;

  PPatientTestsScreen({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 60, 145, 230),
              Color.fromARGB(255, 60, 145, 230).withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Tests',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildTestsList(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'My Tests',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTestsList(BuildContext context) {
    final tests = [
      {
        'title': 'Video Test',
        'icon': Icons.video_camera_front,
        'color': Colors.blue,
        'screen': VideoScreen(patientId: patientId),
      },
      {
        'title': 'Masked Video Test',
        'icon': Icons.videocam_off,
        'color': Colors.purple,
        'screen': MaskedVideoScreen(patientId: patientId),
      },
      {
        'title': 'Audio Test',
        'icon': Icons.headset,
        'color': Colors.green,
        'screen': AudioScreen(patientId: patientId),
      },
    ];

    return Column(
      children: tests.map((test) => _buildTestCard(context, test)).toList(),
    );
  }

  Widget _buildTestCard(BuildContext context, Map<String, dynamic> test) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => test['screen'] as Widget),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (test['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    test['icon'] as IconData,
                    color: test['color'] as Color,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    test['title'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
