import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

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
  int _correctAnswers = 0;
  int _totalQuestions = 0;

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
            .collection('maskedQuestions') // Default test type
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

  // Add this method to calculate statistics
  void _calculateStats() {
    _totalQuestions = _results.length;
    _correctAnswers = _results.where((result) => result['isCorrect']).length;
  }

  Widget _buildPieChart() {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              color: Colors.green,
              value: _correctAnswers.toDouble(),
              title: '${((_correctAnswers / _totalQuestions) * 100).toStringAsFixed(1)}%',
              radius: 60,
              titleStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              color: Colors.red,
              value: (_totalQuestions - _correctAnswers).toDouble(),
              title: '${(((_totalQuestions - _correctAnswers) / _totalQuestions) * 100).toStringAsFixed(1)}%',
              radius: 60,
              titleStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Test Summary',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Questions',
                  _totalQuestions.toString(),
                  Icons.quiz,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Correct',
                  _correctAnswers.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  'Incorrect',
                  (_totalQuestions - _correctAnswers).toString(),
                  Icons.cancel,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPieChart(),
            const SizedBox(height: 20),
            Text(
              'Success Rate: ${((_correctAnswers / _totalQuestions) * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        var result = _results[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: Icon(
              result['isCorrect'] ? Icons.check_circle : Icons.cancel,
              color: result['isCorrect'] ? Colors.green : Colors.red,
            ),
            title: Text(
              'Question ${result['questionNumber']}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnswerRow(
                      'Your Answer:',
                      result['selectedOption'],
                      result['isCorrect'],
                    ),
                    SizedBox(height: 8),
                    _buildAnswerRow(
                      'Correct Answer:',
                      widget.options[result['correctOption'] - 1],
                      true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnswerRow(String label, String answer, bool isCorrect) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(width: 8),
        Text(
          answer,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: isCorrect ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_results.isNotEmpty) {
      _calculateStats();
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Test Results',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 60, 145, 230),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? Center(child: Text('No results found for this patient'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildStatsCard(),
                      ),
                      Divider(thickness: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        child: Text(
                          'Detailed Results',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildQuestionList(),
                    ],
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
