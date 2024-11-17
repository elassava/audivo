import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PPatientTestsScreen extends StatelessWidget {
  final String patientId;

  PPatientTestsScreen({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: Text('My Tests', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color.fromARGB(255, 60, 145, 230), // Mavi
      ),
      body: Stack(
        children: [
          // Background image (optional)
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png', // Gerekirse arka plan resmini buraya ekleyebilirsiniz
              fit: BoxFit.cover,
            ),
          ),
          // İçeriği arka planın üstüne ekleyeceğiz
          Container(
            color: Color.fromARGB(100, 230, 243, 255), // Okunaklılık için yarı saydam overlay
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Testler Alanı - Kartlar
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.15,
                  child: Card(
                    color: Colors.white,
                    child: InkWell(
                      onTap: () {
                        // Video Test işlemi
                        _showTestDetails(context, "Video Test");
                      },
                      child: Center(
                        child: Text("Video Test", style: GoogleFonts.poppins(fontSize: 20)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.0), // Kartlar arasında boşluk
                // Görüntülü Test Kartı
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.15,
                  child: Card(
                    color: Colors.white,
                    child: InkWell(
                      onTap: () {
                        // Görüntülü Test işlemi
                        _showTestDetails(context, "Masked Video Test");
                      },
                      child: Center(
                        child: Text("Masked Video Test", style: GoogleFonts.poppins(fontSize: 20)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.0), // Kartlar arasında boşluk
                // Maskeli Görüntü Testi Kartı
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.15,
                  child: Card(
                    color: Colors.white,
                    child: InkWell(
                      onTap: () {
                        // Maskeli Görüntü Testi işlemi
                        _showTestDetails(context, "Audio Test");
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

  // Test detaylarını gösterme fonksiyonu
  void _showTestDetails(BuildContext context, String testType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(testType, style: GoogleFonts.poppins()),
        content: Text('Test type: $testType', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Test detayını kapatma
            },
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}
