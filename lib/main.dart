
import 'package:emotionmobileversion/screens/doctor_notes_screen.dart';
import 'package:emotionmobileversion/screens/intro_screen.dart';
import 'package:emotionmobileversion/screens/patient_settings.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/doctor_register.dart';
import 'screens/patient_register.dart';
import 'screens/doctor_login.dart';
import 'screens/patient_login.dart';
import 'screens/doctor_dashboard.dart';
import 'screens/patient_dashboard.dart';
import 'screens/doc_patients_screen.dart';
import 'screens/audio_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sağlık Uygulaması',
      initialRoute: '/',
      routes: {
        '/': (context) => IntroScreen(),
        '/doctorRegister': (context) => DoctorRegisterScreen(),
        '/patientRegister': (context) => PatientRegisterScreen(),
        '/doctorLogin': (context) => DoctorLoginScreen(),
        '/patientLogin': (context) => PatientLoginScreen(),
        '/doctorDashboard': (context) => DoctorDashboard(),
        '/patientDashboard': (context) => PatientDashboard(),
        '/patientsScreen': (context) => PatientsScreen(), // PatientsScreen'e rota ekledik
        '/patientSettings': (context) => PSettingsScreen(),
        '/audioScreen': (context) => AudioScreen(patientId: '',),
        '/notesScreen': (context) => NotesScreen(),
      },
    );
  }
}
