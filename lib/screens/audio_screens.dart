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
        .get();
  String testType = 'audioQuestions'; 
    if (testStatusSnapshot.exists &&
        testStatusSnapshot['AudioIsCompleted'] == true) {
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
            .set({'AudioIsCompleted': true}, SetOptions(merge: true));
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
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Audio Test',
          style: GoogleFonts.poppins(
            color: Colors.white, 
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 60, 145, 230),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.9),
              BlendMode.lighten,
            ),
          ),
        ),
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator(
                  color: Color.fromARGB(255, 60, 145, 230),
                )
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Question $_questionNumber',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 60, 145, 230),
                              ),
                            ),
                            SizedBox(height: 20),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 60, 145, 230).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.music_note_rounded,
                                    size: 40,
                                    color: Color.fromARGB(255, 60, 145, 230),
                                  ),
                                  SizedBox(height: 10),
                                  LinearProgressIndicator(
                                    value: _audioDuration.inSeconds > 0
                                        ? (_audioPosition.inSeconds / _audioDuration.inSeconds).clamp(0.0, 1.0)
                                        : 0,
                                    backgroundColor: Colors.grey[200],
                                    color: Color.fromARGB(255, 60, 145, 230),
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'How do you feel after listening?',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12.0,
                        runSpacing: 12.0,
                        children: List.generate(_options.length, (index) {
                          return SizedBox(
                            width: MediaQuery.of(context).size.width * 0.4,
                            child: ElevatedButton(
                              onPressed: _isAnswered ? null : () {
                                setState(() {
                                  _isAnswered = true;
                                });
                                _submitEmotion(index);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromARGB(255, 60, 145, 230),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: Text(
                                _options[index],
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
