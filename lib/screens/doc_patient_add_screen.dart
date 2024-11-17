import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class PatientAddScreen extends StatefulWidget {
  @override
  _PatientAddScreenState createState() => _PatientAddScreenState();
}

class _PatientAddScreenState extends State<PatientAddScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String surname = '';
  String birthDate = '';
  String gender = 'Kadın'; // Default "Kadın"
  String email = '';
  String phone = '';
  final _auth = FirebaseAuth.instance;

  // Function to save data to Firebase
  void _addPatient() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Authenticated doctor ID
        final doctorId = _auth.currentUser!.uid;

        // Add to users collection
        await FirebaseFirestore.instance.collection('users').add({
          'name': name,
          'surname': surname,
          'birthDate': birthDate,
          'gender': gender,
          'email': email,
          'phone': phone,
          'role': "patient"
        });

        // Add to patients collection
        await FirebaseFirestore.instance.collection('patients').add({
          'doctorId': doctorId,
          'name': name,
          'surname': surname,
          'birthDate': birthDate,
          'gender': gender,
          'email': email,
          'phone': phone,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Patient added successfully'))
        );
        Navigator.pop(context); // Close screen
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add patient: $e'))
        );
      }
    }
  }

  // Calendar for selecting birth date
  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null && selectedDate != DateTime.now()) {
      setState(() {
        birthDate = '${selectedDate.toLocal()}'.split(' ')[0]; // Format as Year-Month-Day
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: Text('Add Patient', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color.fromARGB(255, 60, 145, 230), // Blue color
      ),
      body: Container(
        height: MediaQuery.of(context).size.height, // Full screen height
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'), // Background image
            fit: BoxFit.cover, // Ensures the image covers the entire screen
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Name Field
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Color.fromARGB(255, 60, 145, 230)),
                      ),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16.0),
                        ),
                        onChanged: (value) => setState(() => name = value),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter the name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  // Surname Field
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Color.fromARGB(255, 60, 145, 230)),
                      ),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Surname',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16.0),
                        ),
                        onChanged: (value) => setState(() => surname = value),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter the surname';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  // Birth Date Field
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: GestureDetector(
                      onTap: () => _selectBirthDate(context),
                      child: AbsorbPointer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Color.fromARGB(255, 60, 145, 230)),
                          ),
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Birth Date',
                              hintText: birthDate.isEmpty ? 'Select Birth Date' : birthDate,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16.0),
                            ),
                            validator: (value) {
                              if (birthDate.isEmpty) {
                                return 'Please select the birth date';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Gender Field
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Color.fromARGB(255, 60, 145, 230)),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: gender,
                        onChanged: (value) {
                          setState(() {
                            gender = value!;
                          });
                        },
                        items: ['Kadın', 'Erkek']
                            .map((label) => DropdownMenuItem(
                                  value: label,
                                  child: Text(label),
                                ))
                            .toList(),
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16.0),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select the gender';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  // Email Field
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Color.fromARGB(255, 60, 145, 230)),
                      ),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16.0),
                        ),
                        onChanged: (value) => setState(() => email = value),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter the email';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  // Phone Field
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Color.fromARGB(255, 60, 145, 230)),
                      ),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Phone',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16.0),
                        ),
                        onChanged: (value) => setState(() => phone = value),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter the phone';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addPatient,
                    child: Text('Add Patient', style: GoogleFonts.poppins(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 60, 145, 230), // Blue
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
