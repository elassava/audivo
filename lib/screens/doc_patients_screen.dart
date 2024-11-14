import 'package:emotionmobileversion/screens/doc_patients_test_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class PatientsScreen extends StatefulWidget {
  @override
  _PatientsScreenState createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String doctorId;
  late Future<List<Map<String, dynamic>>> patients;

  @override
  void initState() {
    super.initState();
    doctorId = _auth.currentUser!.uid;
    patients = _getPatients();
  }

  Future<List<Map<String, dynamic>>> _getPatients() async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('patients')
        .where('doctorId', isEqualTo: doctorId)
        .get();

    List<Map<String, dynamic>> patientsList = querySnapshot.docs.map((doc) {
      Map<String, dynamic> patientData = doc.data() as Map<String, dynamic>;

      // Null kontrolleri ekleyelim
      String name = patientData['name'] ?? 'Unknown Name';  // Eğer null ise default bir değer ver
      String surname = patientData['surname'] ?? 'Unknown Surname';
      String email = patientData['email'] ?? 'Unknown Email';

      return {
        'name': name,
        'surname': surname,
        'email': email,
        'id': doc.id,  // id'yi de alıyoruz
      };
    }).toList();

    return patientsList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: Text('Patients', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 60, 145, 230), // Mavi
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'), // PNG görseli buraya ekliyoruz
            fit: BoxFit.cover, // Görselin ekranı kaplamasını sağlıyoruz
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Map<String, dynamic>>>( 
          future: patients,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(fontFamily: 'Poppins')));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No patients found.', style: TextStyle(fontFamily: 'Poppins')));
            }

            List<Map<String, dynamic>> patientsList = snapshot.data!;

            return ListView.builder(
              itemCount: patientsList.length,
              itemBuilder: (context, index) {
                var patient = patientsList[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text('${patient['name']} ${patient['surname']}', style: GoogleFonts.poppins()),
                    subtitle: Text('Email: ${patient['email']}', style: GoogleFonts.poppins()),
                    onTap: () {
                      // Hastaya tıklanınca yeni sayfaya yönlendirme
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PatientTestsScreen(patientId: patient['id']),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
