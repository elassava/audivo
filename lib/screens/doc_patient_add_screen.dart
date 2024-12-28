import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

class PatientAddScreen extends StatefulWidget {
  @override
  _PatientAddScreenState createState() => _PatientAddScreenState();
}

class _PatientAddScreenState extends State<PatientAddScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String surname = '';
  String birthDate = '';
  String email = '';
  String phone = '';
  String? gender;
  String countryCode = '+90'; // Default country code
  final _auth = FirebaseAuth.instance;

  void _addPatient() async {
    if (_formKey.currentState!.validate()) {
      try {
        final doctorId = _auth.currentUser!.uid;
        String fullPhoneNumber = countryCode + phone;

        await FirebaseFirestore.instance.collection('patients').add({
          'doctorId': doctorId,
          'name': name,
          'surname': surname,
          'birthDate': birthDate,
          'gender': gender,
          'email': email,
          'phone': fullPhoneNumber,
        });

        // Show success dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Column(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'Patient Added',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Patient details have been successfully added:',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Name', '$name $surname'),
                      SizedBox(height: 8),
                      _buildInfoRow('Gender', gender ?? ''),
                      SizedBox(height: 8),
                      _buildInfoRow('Birth Date', birthDate),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 5,
            actionsPadding: EdgeInsets.all(16),
            actions: [
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pop(context); // Return to previous screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } catch (e) {
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[400],
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'Error',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[400],
                  ),
                ),
              ],
            ),
            content: Text(
              'Failed to add patient: ${e.toString()}',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 5,
            actionsPadding: EdgeInsets.all(16),
            actions: [
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Okay',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
            primaryColor: Color(0xFF1A237E), // App bar color
            hintColor: Color(0xFF1A237E), // Selected day color
            buttonTheme: ButtonThemeData(
                textTheme: ButtonTextTheme.primary), // Button style
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                  foregroundColor:
                      Color(0xFF1A237E)), // Button text color
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

  BoxDecoration _containerDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w500,
        color: Colors.black54,
      ),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: Color(0xFF1A237E), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300, width: 2),
      ),
    );
  }

  // Helper method to build info rows
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // List of country codes for dropdown, sorted in ascending order
    List<String> countryCodes = [
      '+1', // USA/Canada
      '+20', // Egypt
      '+27', // South Africa
      '+31', // Netherlands
      '+33', // France
      '+34', // Spain
      '+39', // Italy

      '+90', // Turkey
    ]..sort(); // Sorting the list in ascending order.

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Add Patient',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFF1A237E),
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
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: _containerDecoration(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Patient Information',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 24),
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
                          textInputAction: TextInputAction
                              .none, // Disable text action on the keyboard
                          decoration: _inputDecoration(birthDate.isEmpty
                              ? 'Select Birth Date'
                              : birthDate),
                          validator: (value) => birthDate.isEmpty
                              ? 'Please select the birth date (YYYY/DD/MM)'
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField<String>(
  value: gender,
  hint: Text('Select Gender'), // Add this line for default text
  items: ['Female', 'Male']
      .map((label) => DropdownMenuItem(
            value: label,
            child: Text(label),
          ))
      .toList(),
  onChanged: (value) => setState(() => gender = value),
  decoration: _inputDecoration('Gender'),
  validator: (value) =>
      value == null || value.isEmpty ? 'Please select the gender' : null,
  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color.fromARGB(255, 177, 177, 177)),
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
                            items: [
                              DropdownMenuItem(
                                  value: '+90', child: Text('🇹🇷 +90')),
                              DropdownMenuItem(
                                  value: '+1', child: Text('🇺🇸 +1')),
                              DropdownMenuItem(
                                  value: '+44', child: Text('🇬🇧 +44')),
                              DropdownMenuItem(
                                  value: '+49', child: Text('🇩🇪 +49')),
                            ],
                            onChanged: (value) {
                              countryCode = value!;
                            },
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
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
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(
                                  10), // Allow only digits
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _addPatient,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Add Patient',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1A237E),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
