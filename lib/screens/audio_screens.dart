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
  int? _correctOption;
  List<String> _options = ['Happy', 'Sad', 'Angry', 'Terrified', 'Surprised', 'Disgusted'];
  bool _isLoading = true;
  bool _isAnswered = false;
  int _questionNumber = 0; 
  String _questionId = '';
  List<DocumentSnapshot> _allQuestions = []; 
  List<DocumentSnapshot> _remainingQuestions = []; 

  Duration _audioDuration = Duration.zero; // Total audio duration
  Duration _audioPosition = Duration.zero; // Current position of the audio

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
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
    if (_correctOption != null) {
      bool isCorrect = selectedEmotionIndex + 1 == _correctOption;

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
      } catch (e) {
        print('Error saving answer: $e');
      }
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
        title: Text('Test Bitti'),
        content: Text('Tebrikler, testi tamamladınız!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
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
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: Text('Audio Test', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    // Question Number at the top
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Question: $_questionNumber', // Show current question number
                        style: GoogleFonts.poppins(fontSize: 20, color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Progress Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: LinearProgressIndicator(
                      value: _audioDuration.inSeconds > 0
                          ? _audioPosition.inSeconds / _audioDuration.inSeconds
                          : 0, // Eğer sesin süresi geçerli değilse, 0 olarak ayarlayın
                      backgroundColor: Colors.grey[300],
                      color: Color.fromARGB(255, 60, 145, 230),
                    ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'How do you feel after listening?',
                      style: GoogleFonts.poppins(fontSize: 18, color: Colors.black),
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
                ),
        ),
      ),
    );
  }
}
