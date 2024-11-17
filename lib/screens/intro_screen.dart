import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        centerTitle: true,
        title: Text(
          "Audivo",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color.fromARGB(255, 60, 145, 230),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'), // Arka plan görseli
            fit: BoxFit.cover, // Görselin ekran boyutuna uyacak şekilde sığdırılması
          ),
        ),
        padding: EdgeInsets.all(20.0),
        child: Center( // Metinleri ve butonları ortalamak için Center widget'ı eklendi
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Uygulama tanıtımı başlığı
                Text(
                  'Welcome to Audivo!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 60, 145, 230),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                // Uygulama tanıtımı açıklaması
                Text(
                  "Whether you're a doctor or a patient, we're here to help you understand emotions through hearing and take meaningful steps toward better health.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.black),
                ),
                SizedBox(height: 40),
                // Doktor girişine yönlendiren buton
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/doctorLogin');
                  },
                  child: Text(
                    'Doctor Login',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 60, 145, 230),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Hasta girişine yönlendiren buton
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/patientLogin');
                  },
                  child: Text(
                    'Patient Login',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 60, 145, 230),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
