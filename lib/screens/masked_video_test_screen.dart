import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

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
  int _questionNumber = 0;
  String _questionId = '';
  bool _isLoading = true;
  bool _isAnswered = false;
  List<String> _options = ['Happy', 'Sad', 'Angry', 'Terrified', 'Surprised', 'Disgusted'];

  @override
  void initState() {
    super.initState();
    _fetchAllQuestions();
  }

  Future<void> _fetchAllQuestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('maskedQuestions').get();

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

  Future<void> _saveAnswer(int selectedEmotionIndex) async {
    Map<String, dynamic> answerData = {
      'videoUrl': _videoUrl,
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
    } catch (e) {
      print('Error saving answer: $e');
    }
  }

  void _submitEmotion(int selectedEmotionIndex) {
    setState(() {
      _isAnswered = true;
    });

    _saveAnswer(selectedEmotionIndex);
    _goToNextQuestion();
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
        title: Text('Test Finished'),
        content: Text('Congratulations, you have completed the test!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('OK'),
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
