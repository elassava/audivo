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
  String? _correctOption;
  List<String> _options = [];
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isAnswered = false;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _fetchAudioQuestion();

    // Listen to playback completion and reset state
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        setState(() {
          _isPlaying = false;
        });
      }
    });

    // Listen to the current position of the audio
    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });

    // Listen to the total duration of the audio
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _totalDuration = duration;
      });
    });
  }

  // Fetch a random audio question from Firestore
  Future<void> _fetchAudioQuestion() async {
    setState(() {
      _isLoading = true;
      _isAnswered = false;
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('audioQuestions').get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot audioQuestionSnapshot = (querySnapshot.docs..shuffle()).first;

        setState(() {
          _audioUrl = audioQuestionSnapshot['audioUrl'];
          _correctOption = audioQuestionSnapshot['correctOption'];
          _options = List<String>.from(audioQuestionSnapshot['options']);
          _isLoading = false;
        });
        print('Random question loaded with audio URL: $_audioUrl');
      } else {
        print('No audio questions available in the collection');
        throw Exception('No audio questions found in the collection');
      }
    } catch (e) {
      print('Error fetching audio question: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Play or pause the audio
  void _playPauseAudio() {
    if (_audioUrl != null) {
      if (_isPlaying) {
        _audioPlayer.pause();
      } else {
        _audioPlayer.play(UrlSource(_audioUrl!));
      }

      setState(() {
        _isPlaying = !_isPlaying;
      });
    } else {
      print('Audio URL is null');
    }
  }

  // Submit the selected emotion
  void _submitEmotion(String selectedEmotion) {
    if (_correctOption != null) {
      bool isCorrect = selectedEmotion == _correctOption;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isCorrect ? 'Correct!' : 'Incorrect'),
          content: Text(
            isCorrect
                ? 'You selected the correct emotion: $selectedEmotion'
                : 'The correct emotion was: $_correctOption',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _goToNextQuestion();
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
      _isPlaying = false;
      _fetchAudioQuestion();
    });
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
                  ElevatedButton(
                    onPressed: _playPauseAudio,
                    child: Text(_isPlaying ? 'Pause' : 'Play'),
                  ),
                  SizedBox(height: 16),
                  // Display audio progress bar
                  if (_totalDuration > Duration.zero)
                    Column(
                      children: [
                        Slider(
                          min: 0,
                          max: _totalDuration.inSeconds.toDouble(),
                          value: _currentPosition.inSeconds.toDouble(),
                          onChanged: (value) async {
                            final position = Duration(seconds: value.toInt());
                            await _audioPlayer.seek(position);
                          },
                        ),
                        Text(
                          '${_currentPosition.inMinutes}:${(_currentPosition.inSeconds % 60).toString().padLeft(2, '0')} / ${_totalDuration.inMinutes}:${(_totalDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                      ],
                    ),
                  SizedBox(height: 32),
                  // Emotion selection options
                  Text(
                    'How do you feel after listening?',
                    style: GoogleFonts.poppins(fontSize: 18),
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: _options.map((emotion) {
                      return ElevatedButton(
                        onPressed: _isAnswered
                            ? null
                            : () {
                                setState(() {
                                  _isAnswered = true;
                                });
                                _submitEmotion(emotion);
                              },
                        child: Text(emotion, style: GoogleFonts.poppins(fontSize: 16)),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 32),
                  // Next audio button
                  ElevatedButton(
                    onPressed: _goToNextQuestion,
                    child: Text('Next Audio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
