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
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

    List<Map<String, dynamic>> patientsList = await Future.wait(
      querySnapshot.docs.map((doc) async {
        Map<String, dynamic> patientData = doc.data() as Map<String, dynamic>;
        
        // Tamamlanmış test sayısını hesapla
        int completedTests = 0;
        String? lastTest; // null olarak başlat
        
        // Test durumlarını ve tarihlerini kontrol et
        Map<String, DateTime?> testDates = {
          'Video Test': patientData['VideoCompletedAt']?.toDate(),
          'Masked Video Test': patientData['MaskedVideoCompletedAt']?.toDate(),
          'Audio Test': patientData['AudioCompletedAt']?.toDate(),
        };

        // Tamamlanmış testleri say
        if (patientData['VideoIsCompleted'] == true) completedTests++;
        if (patientData['MaskedVideoIsCompleted'] == true) completedTests++;
        if (patientData['AudioIsCompleted'] == true) completedTests++;

        // En son yapılan testi bul
        DateTime? latestDate;
        testDates.forEach((testName, date) {
          if (date != null && (latestDate == null || date.isAfter(latestDate!))) {
            latestDate = date;
            lastTest = testName;
          }
        });

        // Firestore'da testCount ve lastTest'i güncelle
        await _firestore.collection('patients').doc(doc.id).update({
          'testCount': completedTests,
          'lastTest': lastTest, // null olabilir
        });

        return {
          'name': patientData['name'] ?? 'Unknown Name',
          'surname': patientData['surname'] ?? 'Unknown Surname',
          'email': patientData['email'] ?? 'Unknown Email',
          'id': doc.id,
          'lastTest': lastTest, // null olabilir
          'testCount': completedTests,
        };
      }),
    );

    return patientsList;
  }

  Future<void> _deletePatient(String patientId) async {
    try {

      await _firestore.collection('users').doc(patientId).delete();
      // Delete from patients collection
      await _firestore.collection('patients').doc(patientId).delete();

      // Delete from users collection
      

      // Refresh patients list
      setState(() {
        patients = _getPatients();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Patient deleted successfully',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error deleting patient: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search patients...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Color.fromARGB(255, 60, 145, 230)),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return Dismissible(
      key: Key(patient['id']),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Delete Patient',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Are you sure you want to delete ${patient['name']} ${patient['surname']}?',
                style: GoogleFonts.poppins(),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Delete',
                    style: GoogleFonts.poppins(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        _deletePatient(patient['id']);
      },
      background: Container(
        color: Colors.red,
        padding: EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PatientTestsScreen(patientId: patient['id']),
              ),
            );
          },
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 60, 145, 230).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${patient['name'][0]}${patient['surname'][0]}',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 60, 145, 230),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${patient['name']} ${patient['surname']}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        patient['email'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.assessment,
                            '${patient['testCount']} tests',
                            Colors.green,
                          ),
                          SizedBox(width: 8),
                          _buildInfoChip(
                            Icons.access_time,
                            'Last: ${patient['lastTest']}',
                            Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    // lastTest null ise chip'i gösterme
    if (label.startsWith('Last: ') && label == 'Last: null') {
      return Container(); // Boş container döndür
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'My Patients',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 60, 145, 230),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: patients,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: GoogleFonts.poppins(),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No patients found',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  var filteredPatients = snapshot.data!.where((patient) {
                    final searchStr =
                        '${patient['name']} ${patient['surname']} ${patient['email']}'
                            .toLowerCase();
                    return searchStr.contains(_searchQuery);
                  }).toList();

                  if (filteredPatients.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No matching patients found',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      return _buildPatientCard(filteredPatients[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
