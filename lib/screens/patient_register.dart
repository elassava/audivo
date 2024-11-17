import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class PatientRegisterScreen extends StatefulWidget {
  @override
  _PatientRegisterScreenState createState() => _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends State<PatientRegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  String _gender = 'Male';
  String _dob = '';
  String? _errorMessage;

  // Doğum tarihi seçimi için takvim fonksiyonu
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selectedDate != null && selectedDate != DateTime.now()) {
      setState(() {
        _dob = '${selectedDate.toLocal()}'.split(' ')[0]; // GG/AA/YYYY formatında
      });
    }
  }

  // Kayıt fonksiyonu
  Future<void> _register() async {
    setState(() {
      _errorMessage = null; // Hata mesajını sıfırlama
    });

    // Alanların boş olup olmadığını kontrol et
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _dob.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all areas!';
      });
      return;
    }

    try {
      // Firebase Authentication ile kullanıcı kaydı
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Ad ve soyad bilgilerini ilk harfleri büyük olacak şekilde düzenleyelim
      String firstName = _firstNameController.text.trim();
      String lastName = _lastNameController.text.trim();

      // İlk harfleri büyük yapma
      firstName = _capitalizeWords(firstName);
      lastName = _capitalizeWords(lastName);

      // Kullanıcı verisini users koleksiyonuna kaydet
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': firstName,
        'surname': lastName,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'birthDate': _dob,
        'gender': _gender,
        'role': 'patient',  // Kullanıcı rolü hasta
      });

      // Kullanıcı verisini patients koleksiyonuna kaydet
      await FirebaseFirestore.instance.collection('patients').doc(userCredential.user!.uid).set({
        'name': firstName,
        'surname': lastName,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'birthDate': _dob,
        'gender': _gender,
      });

      // Başarılı kayıt sonrası giriş ekranına yönlendirme
      Navigator.pushReplacementNamed(context, '/patientLogin');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  // İsimlerdeki her kelimenin ilk harfini büyük yapacak fonksiyon
  String _capitalizeWords(String input) {
    if (input.isEmpty) return input;

    return input.split(' ').map((word) {
      // Her kelimenin ilk harfini büyük yapalım
      return word.isNotEmpty
          ? word[0].toUpperCase() + word.substring(1).toLowerCase()
          : '';
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          "Patient Register",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color.fromARGB(255, 60, 145, 230),
      ),
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height, // Full screen height
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - kToolbarHeight - 20,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ad alanı
                    TextField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                      textCapitalization: TextCapitalization.words, // Her kelimenin ilk harfini büyük yapar
                    ),
                    SizedBox(height: 20),
                    // Soyad alanı
                    TextField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Surname',
                        labelStyle: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                      textCapitalization: TextCapitalization.words, // Her kelimenin ilk harfini büyük yapar
                    ),
                    SizedBox(height: 20),
                    // E-posta alanı
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'E-mail',
                        labelStyle: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.poppins(),
                    ),
                    SizedBox(height: 20),
                    // Şifre alanı
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      obscureText: true,
                      style: GoogleFonts.poppins(),
                    ),
                    SizedBox(height: 20),
                    // Telefon numarası alanı
                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.poppins(),
                    ),
                    SizedBox(height: 20),
                    // Doğum tarihi seçimi
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: TextEditingController(text: _dob),
                          decoration: InputDecoration(
                            labelText: 'Date of Birth (YYYY/MM/DD)',
                            labelStyle: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            hintText: _dob.isEmpty ? 'Choose Date' : _dob,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Cinsiyet seçim alanı
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<String>(
                        value: _gender,
                        onChanged: (String? newValue) {
                          setState(() {
                            _gender = newValue!;
                          });
                        },
                        items: <String>['Male', 'Female', 'Other']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text(value, style: GoogleFonts.poppins()),
                            ),
                          );
                        }).toList(),
                        isExpanded: true,
                        underline: SizedBox(),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Hata mesajı
                    if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    SizedBox(height: 20),
                    // Kayıt butonu
                    ElevatedButton(
                      onPressed: _register,
                      child: Text('Register', style: GoogleFonts.poppins(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 60, 145, 230),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
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
