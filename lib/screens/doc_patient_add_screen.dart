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
  String gender = 'Male';
  String email = '';
  String phone = '';
  final _auth = FirebaseAuth.instance;

  void _addPatient() async {
    if (_formKey.currentState!.validate()) {
      try {
        final doctorId = _auth.currentUser!.uid;

        await FirebaseFirestore.instance.collection('users').add({
          'name': name,
          'surname': surname,
          'birthDate': birthDate,
          'gender': gender,
          'email': email,
          'phone': phone,
          'role': "patient"
        });

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
          SnackBar(content: Text('Patient added successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add patient: $e')),
        );
      }
    }
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        birthDate = '${selectedDate.toLocal()}'.split(' ')[0];
      });
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black),
      filled: true,
      fillColor: Color.fromARGB(255, 230, 243, 255),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Add Patient',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 60, 145, 230),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: _inputDecoration('Name'),
                    onChanged: (value) => setState(() => name = value),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter the name' : null,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: _inputDecoration('Surname'),
                    onChanged: (value) => setState(() => surname = value),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter the surname' : null,
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _selectBirthDate(context),
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: _inputDecoration(
                            birthDate.isEmpty ? 'Select Birth Date' : birthDate),
                        validator: (value) =>
                            birthDate.isEmpty ? 'Please select the birth date(YYYY/DD/MM)' : null,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: gender,
                    items: ['Female', 'Male']
                        .map((label) => DropdownMenuItem(
                              value: label,
                              child: Text(label),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => gender = value!),
                    decoration: _inputDecoration('Gender'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Please select the gender' : null,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: _inputDecoration('Email'),
                    onChanged: (value) => setState(() => email = value),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter the email' : null,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: _inputDecoration('Phone'),
                    onChanged: (value) => setState(() => phone = value),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter the phone' : null,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addPatient,
                    child: Text('Add Patient', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
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
      ),
    );
  }
}
