import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultScreen extends StatefulWidget {
  final String patientId;
  final List<String> options;
  final String
      testType; // Add a test type parameter to handle different test types

  ResultScreen({
    required this.patientId,
    required this.options,
    required this.testType, // Initialize the test type
  });

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    try {
      // Firestore query to fetch results based on patientId and testType
      QuerySnapshot querySnapshot;
      if (widget.testType == 'audioQuestions') {
        querySnapshot = await FirebaseFirestore.instance
            .collection('patients')
            .doc(widget.patientId)
            .collection(
                'audioQuestions') // Fetching data specific to audio test
            .get();
      } else if (widget.testType == 'videoQuestions') {
        print(widget.testType);
        querySnapshot = await FirebaseFirestore.instance
            .collection('patients')
            .doc(widget.patientId)
            .collection('videoQuestions')
            .get();
        print(querySnapshot);
      } else {
        querySnapshot = await FirebaseFirestore.instance
            .collection('patients')
            .doc(widget.patientId)
            .collection('generalQuestions') // Default test type
            .get();
      }

      if (querySnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> results = [];

        // Loop through the documents and extract relevant data
        for (var doc in querySnapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          data.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              print("AAAAAAAA");
              var questionData = value;
              results.add({
                'questionNumber': questionData['questionNumber'],
                'selectedOption': questionData['selectedOption'],
                'isCorrect': questionData['isCorrect'],
                'correctOption': questionData['correctOption'],
              });
            }
          });
        }
        
        setState(() {
          _results = results;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching results: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Test Results - ${widget.testType.capitalize()}',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color.fromARGB(255, 60, 145, 230),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? Center(child: Text('No results found for this patient'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      var result = _results[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 10),
                        child: ListTile(
                          title: Text(
                            'Question ${result['questionNumber']}',
                            style: GoogleFonts.poppins(fontSize: 18),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Answer: ${result['selectedOption']}',
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                              Text(
                                'Correct Answer: ${widget.options[result['correctOption'] - 1]}',
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                              Text(
                                'Result: ${result['isCorrect'] ? 'Correct' : 'Incorrect'}',
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() {
    return this.isEmpty ? this : this[0].toUpperCase() + this.substring(1);
  }
}
