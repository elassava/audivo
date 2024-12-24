import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

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
  String countryCode = '+1'; // Default country code
  final _auth = FirebaseAuth.instance;

  void _addPatient() async {
    if (_formKey.currentState!.validate()) {
      try {
        final doctorId = _auth.currentUser!.uid;

        // Combine country code with the phone number
        String fullPhoneNumber = countryCode + phone;

        await FirebaseFirestore.instance.collection('users').add({
          'name': name,
          'surname': surname,
          'birthDate': birthDate,
          'gender': gender,
          'email': email,
          'phone': fullPhoneNumber, // Save combined phone number with country code
          'role': "patient"
        });

        await FirebaseFirestore.instance.collection('patients').add({
          'doctorId': doctorId,
          'name': name,
          'surname': surname,
          'birthDate': birthDate,
          'gender': gender,
          'email': email,
          'phone': fullPhoneNumber, // Save combined phone number with country code
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
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color.fromARGB(255, 60, 145, 230), // App bar color
            hintColor: Color.fromARGB(255, 60, 145, 230), // Selected day color
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary), // Button style
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Color.fromARGB(255, 60, 145, 230)), // Button text color
            ),
            textTheme: TextTheme(
              bodySmall: TextStyle(
                fontSize: 18, // Increased font size for Select Date
                fontWeight: FontWeight.bold,
                color: Colors.black, // Black text color
              ),
            ),
          ),
          child: child!,
        );
      },
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
    // List of country codes for dropdown, sorted in ascending order
    List<String> countryCodes = [
      '+1',  // USA/Canada
      '+20', // Egypt
      '+27', // South Africa
      '+31', // Netherlands
      '+33', // France
      '+34', // Spain
      '+39', // Italy
      '+41', // Switzerland
      '+43', // Austria
      '+44', // United Kingdom
      '+47', // Norway
      '+48', // Poland
      '+49', // Germany
      '+52', // Mexico
      '+55', // Brazil
      '+61', // Australia
      '+64', // New Zealand
      '+63', // Philippines
      '+64', // New Zealand
      '+71', // Russia
      '+82', // South Korea
      '+86', // China
      '+91', // India
      '+90', // Turkey
      '+971', // United Arab Emirates
      '+213', // Algeria
      '+254', // Kenya
      '+256', // Uganda
    ]..sort(); // Sorting the list in ascending order.

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
                        readOnly: true, // Prevent manual input
                        keyboardType: TextInputType.none, // Disable keyboard
                        textInputAction: TextInputAction.none, // Disable text action on the keyboard
                        decoration: _inputDecoration(
                          birthDate.isEmpty ? 'Select Birth Date' : birthDate),
                        validator: (value) =>
                            birthDate.isEmpty ? 'Please select the birth date (YYYY/DD/MM)' : null,
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
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black), // Bold text
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: _inputDecoration('Email'),
                    onChanged: (value) => setState(() => email = value),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter the email' : null,
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 3, // This gives 30% width
                        child: DropdownButtonFormField<String>(
                          value: countryCode,
                          items: countryCodes
                              .map((code) => DropdownMenuItem(
                                    value: code,
                                    child: Text(code),
                                  ))
                              .toList(),
                          onChanged: (value) => setState(() => countryCode = value!),
                          decoration: _inputDecoration('Country Code'),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Please select the country code' : null,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black), // Bold text
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        flex: 7, // This gives 70% width
                        child: TextFormField(
                          decoration: _inputDecoration('Phone'),
                          onChanged: (value) => setState(() => phone = value),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter the phone number';
                            } else if (value.length != 10) {
                              return 'Phone number must be exactly 10 digits';
                            }
                            return null;
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // Allow only digits
                          ],
                        ),
                      ),
                    ],
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
