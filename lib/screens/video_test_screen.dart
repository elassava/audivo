import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:emotionmobileversion/screens/result_screen.dart';


class VideoScreen extends StatefulWidget {
  final String patientId;

  VideoScreen({required this.patientId});

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  VideoPlayerController? _videoPlayerController;
  List<DocumentSnapshot> _allQuestions = [];
  List<DocumentSnapshot> _remainingQuestions = [];
  List<Map<String, dynamic>> _answers = [];
  String? _videoUrl;
  int? _correctOption;
  int _questionNumber = 0;
  String _questionId = '';
  bool _isLoading = true;
  bool _isAnswered = false;
  List<String> _options = ['Happy', 'Sad', 'Angry', 'Terrified', 'Surprised', 'Disgusted'];

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

  String testType = 'videoQuestions'; 
    if (testStatusSnapshot.exists &&
        testStatusSnapshot['VideoIsCompleted'] == true) {
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
      _questionNumber = 0;
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('videoQuestions').get();

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
    if (_remainingQuestions.isEmpty) {
      await _saveAllAnswersToFirebase(); // Save all answers when the test is completed
      _showTestFinishedDialog();
      return;
    }

    setState(() {
      _isLoading = true;
      _isAnswered = false;
      _questionNumber++;
    });

    DocumentSnapshot videoQuestionSnapshot = _remainingQuestions.removeAt(0);

    try {
      setState(() {
        _videoUrl = videoQuestionSnapshot['audioUrl'];
        _correctOption = videoQuestionSnapshot['correctOption'] as int;
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
    _videoPlayerController?.dispose(); // Dispose the previous controller if it exists
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

  void _saveAnswerLocally(int selectedEmotionIndex) {
    // Check if the selected answer is correct
    bool isCorrect = _correctOption != null && selectedEmotionIndex+1 == _correctOption;

    // Add answer data to the local list
    _answers.add({ 
      'audioUrl': _videoUrl,
      'correctOption': _correctOption,
      'isCorrect': isCorrect,
      'questionNumber': _questionNumber,
      'selectedOption': _options[selectedEmotionIndex],
      'timestamp': DateTime.now().toIso8601String(), // Add local timestamp
    });

    print('Answer saved locally: $_answers');
  }

Future<void> _saveAllAnswersToFirebase() async {
  try {
    // Save each answer to Firebase
    for (var answer in _answers) {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .collection('videoQuestions')
          .doc(answer['questionId'])
          .set(answer);
    }

    // After all answers are saved, update isCompleted to true
    await FirebaseFirestore.instance
        .collection('patients')
        .doc(widget.patientId)
        .update({'VideoIsCompleted': true}); // Update the isCompleted field

    print('All answers saved to Firebase successfully');
  } catch (e) {
    print('Error saving all answers: $e');
  }
}


  void _submitEmotion(int selectedEmotionIndex) {
    if (_correctOption != null) {
      _saveAnswerLocally(selectedEmotionIndex); // Save answer locally
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
                            testType: 'videoQuestions',
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
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: Text('Video Test', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color.fromARGB(255, 60, 145, 230),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _videoPlayerController != null && _videoPlayerController!.value.isInitialized
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Question: $_questionNumber',
                        style: GoogleFonts.poppins(fontSize: 20, color: Colors.black),
                      ),
                    ),
                    AspectRatio(
                      aspectRatio: _videoPlayerController!.value.aspectRatio,
                      child: VideoPlayer(_videoPlayerController!),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'How do you feel after watching?',
                      style: GoogleFonts.poppins(fontSize: 18, color: Colors.black),
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
                                : () => _submitEmotion(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 60, 145, 230),
                            ),
                            child: Text(
                              _options[index],
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                )
              : Center(
                  child: Text(
                    'No video available or error loading video.',
                    style: GoogleFonts.poppins(),
                  ),
                ),
    );
  }
}
