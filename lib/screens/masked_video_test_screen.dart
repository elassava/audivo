import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:emotionmobileversion/screens/result_screen.dart';

class MaskedVideoScreen extends StatefulWidget {
  final String patientId;

  MaskedVideoScreen({required this.patientId});

  @override
  _MaskedVideoScreenState createState() => _MaskedVideoScreenState();
}

class _MaskedVideoScreenState extends State<MaskedVideoScreen> {
  VideoPlayerController? _videoPlayerController;
  List<DocumentSnapshot> _allQuestions = [];
  List<DocumentSnapshot> _remainingQuestions = [];
  String? _videoUrl;
  int? _correctOption;
  int _questionNumber = 0;
  String _questionId = '';
  bool _isLoading = true;
  bool _isAnswered = false;
  List<String> _options = [
    'Happy',
    'Sad',
    'Angry',
    'Terrified',
    'Surprised',
    'Disgusted'
  ];

  @override
  void initState() {
    super.initState();
    _checkIfTestCompleted();
    _fetchAllQuestions();
  }

  Future<void> _checkIfTestCompleted() async {
    DocumentSnapshot testStatusSnapshot = await FirebaseFirestore.instance
        .collection('patients')
        .doc(widget.patientId)
        .get();
    String testType = 'maskedQuestions';
    if (testStatusSnapshot.exists &&
        testStatusSnapshot['MaskedVideoIsCompleted'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            patientId: widget.patientId, // patientId parametresini gönderiyoruz
            options: _options,
            testType:
                testType, // _options listesini de parametre olarak gönderiyoruz
          ),
        ),
      );
    }
  }

  Future<void> _fetchAllQuestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('maskedQuestions').get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _allQuestions = querySnapshot.docs;
          _remainingQuestions = List.from(_allQuestions);
          _isLoading = false;
        });

        _fetchVideoQuestion();
      } else {
        print('No video questions available in the collection');
        throw Exception('No video questions found in the collection');
      }
    } catch (e) {
      print('Error fetching video questions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchVideoQuestion() async {
    setState(() {
      _isLoading = true;
      _isAnswered = false;
      _questionNumber++;
    });

    if (_remainingQuestions.isEmpty) {
      _showTestFinishedDialog();
      return;
    }

    DocumentSnapshot videoQuestionSnapshot = _remainingQuestions.removeAt(0);

    try {
      setState(() {
        _videoUrl = videoQuestionSnapshot['audioUrl'];
        _correctOption = videoQuestionSnapshot['correctOption'] as int?;
        _questionId = videoQuestionSnapshot.id;
      });

      _initializeVideoPlayer(_videoUrl!);
    } catch (e) {
      print('Error fetching video question: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeVideoPlayer(String url) async {
    _videoPlayerController
        ?.dispose(); // Dispose the previous controller if it exists
    _videoPlayerController = VideoPlayerController.network(url);

    try {
      await _videoPlayerController!.initialize();
      setState(() {
        _isLoading = false;
      });
      _videoPlayerController!.play();
    } catch (e) {
      print('Error initializing video player: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAnswer(int selectedEmotionIndex) async {
    bool isCorrect =
        _correctOption != null && selectedEmotionIndex + 1 == _correctOption;

    Map<String, dynamic> answerData = {
      'audioUrl': _videoUrl,
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
          .collection('maskedQuestions')
          .doc(_questionId)
          .set({
        _questionNumber.toString(): answerData,
      }, SetOptions(merge: true));

      print('Answer saved successfully');

      // If all questions are answered, mark the test as completed
      if (_remainingQuestions.isEmpty) {
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(widget.patientId)
            .set({'MaskedVideoIsCompleted': true}, SetOptions(merge: true));
        print('Test completed and marked as isCompleted: true');
      }
    } catch (e) {
      print('Error saving answer: $e');
    }
  }

  void _submitEmotion(int selectedEmotionIndex) {
    if (_correctOption != null) {
      _saveAnswer(selectedEmotionIndex);
      _goToNextQuestion(); // Go to the next question
    }
  }

  void _goToNextQuestion() {
    setState(() {
      _videoPlayerController?.pause();
      _fetchVideoQuestion();
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
                            testType: 'maskedQuestions',
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
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Masked Video Test',
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
              : _videoPlayerController != null && _videoPlayerController!.value.isInitialized
                  ? Padding(
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
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: AspectRatio(
                                      aspectRatio: _videoPlayerController!.value.aspectRatio,
                                      child: VideoPlayer(_videoPlayerController!),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 24),
                                Text(
                                  'How do you feel after watching?',
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
                    )
                  : Center(
                      child: Text(
                        'No video available or error loading video.',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}
