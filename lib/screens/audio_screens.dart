import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioScreen extends StatefulWidget {
  final String patientId;

  AudioScreen({required this.patientId});

  @override
  _AudioScreenState createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  late AudioPlayer _audioPlayer;
  String? _audioUrl;
  int? _correctOption; // _correctOption as int (1-6 range)
  List<String> _options = ['Mutlu', 'Üzgün', 'Kızgın', 'Korkmuş', 'Şaşırmış', 'İğrenmiş'];
  bool _isLoading = true;
  bool _isAnswered = false;
  int _questionNumber = 0; // Track question number
  String _questionId = ''; // Track question ID
  List<DocumentSnapshot> _allQuestions = []; // List of all questions
  List<DocumentSnapshot> _remainingQuestions = []; // Remaining questions to show

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _fetchAllQuestions(); // Fetch all 20 questions at the start
  }

  // Fetch all audio questions from Firestore
  Future<void> _fetchAllQuestions() async {
    setState(() {
      _isLoading = true;
      _isAnswered = false;
      _questionNumber = 0;
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('audioQuestions').get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _allQuestions = querySnapshot.docs;
          _remainingQuestions = List.from(_allQuestions); // Copy all questions to remaining list
          _isLoading = false;
        });

        _fetchAudioQuestion(); // Load the first question
      } else {
        print('No audio questions available in the collection');
        throw Exception('No audio questions found in the collection');
      }
    } catch (e) {
      print('Error fetching audio questions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch a random audio question from the remaining list
Future<void> _fetchAudioQuestion() async {
  if (_remainingQuestions.isEmpty) {
    // If no remaining questions, show "Test Bitti"
    _showTestFinishedDialog();
    return;
  }

  setState(() {
    _isLoading = true;
    _isAnswered = false;
    _questionNumber++;
  });

  // Get a random question from remaining questions
  DocumentSnapshot audioQuestionSnapshot = _remainingQuestions.removeAt(0);

  print('Loading question ${_questionNumber}: Question ID - ${audioQuestionSnapshot.id}');

  // Check if the question has all necessary fields
  try {
    setState(() {
      _audioUrl = audioQuestionSnapshot['audioUrl'];
      _correctOption = audioQuestionSnapshot['correctOption'] as int;
      _questionId = audioQuestionSnapshot.id; // Get the question ID
      _isLoading = false;
    });

    // Ensure that the question URL is valid
    if (_audioUrl != null) {
      print('Audio URL for Question ${_questionNumber}: $_audioUrl');
    } else {
      print('Error: Audio URL is null for question ID ${audioQuestionSnapshot.id}');
    }

    // Play audio automatically on question load
    _playAudio();
  } catch (e) {
    print('Error fetching audio question: $e');
    setState(() {
      _isLoading = false;
    });
  }
}


  // Play audio
  void _playAudio() {
    if (_audioUrl != null) {
      _audioPlayer.play(UrlSource(_audioUrl!));
    } else {
      print('Audio URL is null');
    }
  }

  // Save answer to Firebase
  Future<void> _saveAnswer(int selectedEmotionIndex) async {
    if (_correctOption != null) {
      bool isCorrect = selectedEmotionIndex + 1 == _correctOption;
      // Create the answer data
      Map<String, dynamic> answerData = {
        'audioUrl': _audioUrl,
        'correctOption': _correctOption,
        'isCorrect': isCorrect,
        'questionNumber': _questionNumber,
        'selectedOption': _options[selectedEmotionIndex],
        'timestamp': FieldValue.serverTimestamp(), // Save current time
      };

      try {
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(widget.patientId)
            .collection('audioQuestions') // Or 'videoQuestions' / 'maskedQuestions'
            .doc(_questionId) // Question ID
            .set({
          _questionNumber.toString(): answerData, // Save based on question number
        }, SetOptions(merge: true)); // Merge to avoid overwriting other answers
        print('Answer saved successfully');
      } catch (e) {
        print('Error saving answer: $e');
      }
    }
  }

  // Submit the selected emotion
  void _submitEmotion(int selectedEmotionIndex) {
    if (_correctOption != null) {
      bool isCorrect = selectedEmotionIndex + 1 == _correctOption;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isCorrect ? 'Correct!' : 'Incorrect'),
          content: Text(
            isCorrect
                ? 'You selected the correct emotion: ${_options[selectedEmotionIndex]}'
                : 'The correct emotion was: ${_options[_correctOption! - 1]}', // Adjust for 1-6 range
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _saveAnswer(selectedEmotionIndex); // Save the answer
                _goToNextQuestion(); // Go to next question
              },
              child: Text('Next Question'),
            ),
          ],
        ),
      );
    }
  }

  // Function to load the next question
  void _goToNextQuestion() {
    setState(() {
      _audioPlayer.stop();
      _fetchAudioQuestion(); // Load the next question
    });
  }

  // Show the "Test Finished" dialog
  void _showTestFinishedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test Bitti'),
        content: Text('Tebrikler, testi tamamladınız!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to the previous screen
            },
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audio Test', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 60, 145, 230),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'How do you feel after listening?',
                    style: GoogleFonts.poppins(fontSize: 18),
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: List.generate(_options.length, (index) {
                      return ElevatedButton(
                        onPressed: _isAnswered
                            ? null
                            : () {
                                setState(() {
                                  _isAnswered = true; // Prevent multiple answers
                                });
                                _submitEmotion(index); // Submit the selected emotion
                              },
                        child: Text(_options[index], style: GoogleFonts.poppins(fontSize: 16)),
                      );
                    }),
                  ),
                ],
              ),
            ),
    );
  }
}
