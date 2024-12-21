import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:emotionmobileversion/screens/result_screen.dart';

class AudioScreen extends StatefulWidget {
  final String patientId;
 // Type of test (audio, visual, etc.)

  AudioScreen({required this.patientId});

  @override
  _AudioScreenState createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  late AudioPlayer _audioPlayer;
  String? _audioUrl;
  int? _correctOption;
  List<String> _options = [
    'Happy',
    'Sad',
    'Angry',
    'Terrified',
    'Surprised',
    'Disgusted'
  ];
  bool _isLoading = true;
  bool _isAnswered = false;
  int _questionNumber = 0;
  String _questionId = '';
  List<DocumentSnapshot> _allQuestions = [];
  List<DocumentSnapshot> _remainingQuestions = [];

  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _checkIfTestCompleted();
    _fetchAllQuestions();
    _audioPlayer.onPositionChanged.listen((Duration duration) {
      setState(() {
        _audioPosition = duration;
      });
    });
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        _audioDuration = duration;
      });
    });
  }

  Future<void> _checkIfTestCompleted() async {
    DocumentSnapshot testStatusSnapshot = await FirebaseFirestore.instance
        .collection('patients')
        .doc(widget.patientId)
        .collection('audioQuestions')
        .doc('testStatus')
        .get();
  String testType = 'audioQuestions'; 
    if (testStatusSnapshot.exists &&
        testStatusSnapshot['isCompleted'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            patientId: widget.patientId, // patientId parametresini gönderiyoruz
            options: _options,
            testType:testType, // _options listesini de parametre olarak gönderiyoruz
          ),
        ),
      );
    }
  }

  Future<void> _fetchAllQuestions() async {
    setState(() {
      _isLoading = true;
      _isAnswered = false;
      _questionNumber = 0;
    });

    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('audioQuestions').get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _allQuestions = querySnapshot.docs;
          _remainingQuestions = List.from(_allQuestions);
          _isLoading = false;
        });

        _fetchAudioQuestion();
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

  Future<void> _fetchAudioQuestion() async {
    if (_remainingQuestions.isEmpty) {
      _showTestFinishedDialog();
      return;
    }

    setState(() {
      _isLoading = true;
      _isAnswered = false;
      _questionNumber++;
    });

    DocumentSnapshot audioQuestionSnapshot = _remainingQuestions.removeAt(0);

    try {
      setState(() {
        _audioUrl = audioQuestionSnapshot['audioUrl'];
        _correctOption = audioQuestionSnapshot['correctOption'] as int;
        _questionId = audioQuestionSnapshot.id;
        _isLoading = false;
      });

      _playAudio();
    } catch (e) {
      print('Error fetching audio question: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _playAudio() {
    if (_audioUrl != null) {
      _audioPlayer.play(UrlSource(_audioUrl!));
    } else {
      print('Audio URL is null');
    }
  }

  Future<void> _saveAnswer(int selectedEmotionIndex) async {
    bool isCorrect =
        _correctOption != null && selectedEmotionIndex + 1 == _correctOption;

    Map<String, dynamic> answerData = {
      'audioUrl': _audioUrl,
      'correctOption': _correctOption,
      'isCorrect': isCorrect,
      'questionNumber': _questionNumber,
      'selectedOption': _options[selectedEmotionIndex],
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .collection('audioQuestions')
          .doc(_questionId)
          .set({
        _questionNumber.toString(): answerData,
      }, SetOptions(merge: true));

      print('Answer saved successfully');

      if (_remainingQuestions.isEmpty) {
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(widget.patientId)
            .collection('audioQuestions')
            .doc('testStatus')
            .set({'isCompleted': true}, SetOptions(merge: true));
        print('Test completed and marked as isCompleted: true');
      }
    } catch (e) {
      print('Error saving answer: $e');
    }
  }

  void _submitEmotion(int selectedEmotionIndex) {
    if (_correctOption != null) {
      _saveAnswer(selectedEmotionIndex);
      _goToNextQuestion();
    }
  }

  void _goToNextQuestion() {
    setState(() {
      _audioPlayer.stop();
      _fetchAudioQuestion();
    });
  }

  void _showTestFinishedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        backgroundColor: Colors.white,
        title: Text(
          'Test Completed',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Congratulations! You have successfully completed the test.',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ResultScreen(
                            patientId: widget.patientId,
                            options: [
                              'Happy',
                              'Sad',
                              'Angry',
                              'Terrified',
                              'Surprised',
                              'Disgusted'
                            ],
                            testType: 'audioQuestions',
                          )),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 60, 145, 230),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Okay',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: Text('Audio Test',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color.fromARGB(255, 60, 145, 230),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Question: $_questionNumber',
                        style: GoogleFonts.poppins(
                            fontSize: 20, color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: LinearProgressIndicator(
                        value: _audioDuration.inSeconds > 0
                            ? (_audioPosition.inSeconds /
                                    _audioDuration.inSeconds)
                                .clamp(0.0, 1.0)
                            : 0, // Avoid division by zero and null values
                        backgroundColor: Colors.grey[300],
                        color: Color.fromARGB(255, 60, 145, 230),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'How do you feel after listening?',
                      style: GoogleFonts.poppins(
                          fontSize: 18, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10.0,
                      runSpacing: 10.0,
                      children: List.generate(_options.length, (index) {
                        return SizedBox(
                          width: MediaQuery.of(context).size.width * 0.4,
                          child: ElevatedButton(
                            onPressed: _isAnswered
                                ? null
                                : () {
                                    setState(() {
                                      _isAnswered = true;
                                    });
                                    _submitEmotion(index);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 60, 145, 230),
                            ),
                            child: Text(
                              _options[index],
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
