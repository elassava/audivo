import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emotionmobileversion/models/patient.dart';
import 'package:firebase_auth/firebase_auth.dart';


class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Yeni hasta ekleme
  Future<void> addPatient(Patient patient) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Users koleksiyonuna hastayı ekle
        await _firestore.collection('users').doc(user.uid).collection('patients').add(patient.toMap());

        // Patients koleksiyonuna hastayı ekle
        await _firestore.collection('patients').add(patient.toMap());
      }
    } catch (e) {
      print('Error adding patient: $e');
    }
  }
}
