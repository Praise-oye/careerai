// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../services/ai_interview_service.dart';

// Custom painter for video call background effect
class VideoBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw subtle grid pattern
    for (int i = 0; i < size.width; i += 20) {
      paint.color = Colors.white.withOpacity(0.03);
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }
    for (int i = 0; i < size.height; i += 20) {
      paint.color = Colors.white.withOpacity(0.03);
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class InterviewPracticeScreen extends StatefulWidget {
  final String? field;
  final String? position;
  final String? company;

  const InterviewPracticeScreen({
    super.key,
    this.field,
    this.position,
    this.company,
  });

  @override
  State<InterviewPracticeScreen> createState() => _InterviewPracticeScreenState();
}

class _InterviewPracticeScreenState extends State<InterviewPracticeScreen> {
  final AIInterviewService _interviewService = AIInterviewService();
  final TextEditingController _answerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Speech recognition
  late stt.SpeechToText _speech;
  bool _speechEnabled = false;
  bool _isListening = false;
  String _spokenText = '';
  double _confidence = 0.0;
  
  // Text-to-speech
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;
  bool _ttsEnabled = false;
  
  // Voice mode toggle
  bool _useVoiceMode = false;
  
  // Simulation mode - realistic interview
  final bool _useSimulationMode = true;
  String _interviewStage = 'intro'; // intro, question, followup, closing, report
  final String _interviewerName = 'Thrive';
  final int _totalQuestions = 5;
  final List<QuestionAnswer> _questionsAndAnswers = [];
  final List<double> _allScores = [];
  InterviewReport? _finalReport;
  
  // Video call timer
  int _callDurationSeconds = 0;
  Timer? _callTimer;
  
  // Response timer
  int _responseTimeSeconds = 0;
  
  // Speech metrics
  DateTime? _speechStartTime;
  int _wordCount = 0;
  double _wordsPerMinute = 0;
  int _pauseCount = 0;
  List<double> _soundLevels = [];

  final List<InterviewMessage> _messages = [];
  String? _currentQuestion;
  bool _isLoading = false;
  bool _isWaitingForAnswer = false;
  InterviewFeedback? _lastFeedback;
  int _questionNumber = 1;
  bool _isFeedbackExpanded = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _startCallTimer();
    _startInterview();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _answerController.dispose();
    _scrollController.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _interviewStage != 'report') {
        setState(() => _callDurationSeconds++);
      }
    });
  }

  // Initialize speech recognition
  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechEnabled = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (_isListening) {
            setState(() {
              _isListening = false;
              _calculateSpeechMetrics();
            });
          }
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
        });
        _showError('Speech recognition error: ${error.errorMsg}');
      },
    );
    setState(() {});
  }

  // Initialize text-to-speech
  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(1); // Slightly faster for natural pace
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });
    
    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
    
    _flutterTts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
    });
    
    _ttsEnabled = true;
    setState(() {});
  }

  // Start listening to speech
  Future<void> _startListening() async {
    if (!_speechEnabled) {
      _showError('Speech recognition not available');
      return;
    }

    _spokenText = '';
    _soundLevels = [];
    _pauseCount = 0;
    _speechStartTime = DateTime.now();

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _spokenText = result.recognizedWords;
          _confidence = result.confidence;
          _answerController.text = _spokenText;
          _wordCount = _spokenText.split(' ').where((w) => w.isNotEmpty).length;
        });
      },
      onSoundLevelChange: (level) {
        _soundLevels.add(level);
        // Detect pauses (low sound level)
        if (level < -5 && _soundLevels.length > 10) {
          final recentLevels = _soundLevels.sublist(_soundLevels.length - 10);
          if (recentLevels.every((l) => l < -5)) {
            _pauseCount++;
          }
        }
      },
      listenFor: const Duration(minutes: 10),
      // No pauseFor - user controls when to stop
      cancelOnError: false,
      partialResults: true,
      localeId: 'en_US',
    );

    setState(() => _isListening = true);
  }

  // Stop listening
  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      _calculateSpeechMetrics();
    });
  }

  // Calculate speech metrics
  void _calculateSpeechMetrics() {
    if (_speechStartTime != null && _wordCount > 0) {
      final duration = DateTime.now().difference(_speechStartTime!);
      final minutes = duration.inSeconds / 60;
      if (minutes > 0) {
        _wordsPerMinute = _wordCount / minutes;
      }
    }
  }

  // Speak text using TTS
  Future<void> _speak(String text) async {
    if (!_ttsEnabled || !_useVoiceMode) return;
    
    await _flutterTts.speak(text);
  }

  // Stop speaking
  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() => _isSpeaking = false);
  }

  Future<void> _startInterview() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_useSimulationMode) {
        // Start with interviewer introduction
        final response = await _interviewService.simulateInterview(
          stage: 'intro',
          position: widget.position,
          company: widget.company,
          field: widget.field,
          totalQuestions: _totalQuestions,
          interviewerName: _interviewerName,
        );

        setState(() {
          _interviewStage = 'intro';
          _messages.add(InterviewMessage(
            role: 'assistant',
            content: response.response,
          ));
          _isLoading = false;
          _isWaitingForAnswer = true;
        });

        if (_useVoiceMode) {
          // Speak with intro
          await _speak('Hello and welcome. I am $_interviewerName, your interviewer. ${response.response}');
        }
      } else {
        // Original flow
    final question = await _interviewService.getInterviewQuestion(
      field: widget.field,
      position: widget.position,
      questionNumber: _questionNumber,
    );

    setState(() {
      _currentQuestion = question;
      _messages.add(InterviewMessage(
        role: 'assistant',
        content: question,
      ));
      _isLoading = false;
      _isWaitingForAnswer = true;
    });

        if (_useVoiceMode) {
          await _speak(question);
        }
      }

    _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError(e.toString());
    }
  }

  // Move to next stage in simulation
  Future<void> _continueSimulation() async {
    if (!_useSimulationMode) {
      await _nextQuestion();
      return;
    }

    setState(() {
      _isLoading = true;
      _responseTimeSeconds = 0;
    });

    try {
      if (_interviewStage == 'intro') {
        // After intro, ask first question
        final response = await _interviewService.simulateInterview(
          stage: 'question',
          position: widget.position,
          company: widget.company,
          field: widget.field,
          questionNumber: 1,
          totalQuestions: _totalQuestions,
          interviewerName: _interviewerName,
        );

        setState(() {
          _interviewStage = 'question';
          _questionNumber = 1;
          _currentQuestion = response.response;
          _messages.add(InterviewMessage(
            role: 'assistant',
            content: '🎙️ $_interviewerName\n\n${response.response}',
          ));
          _isLoading = false;
          _isWaitingForAnswer = true;
        });

        if (_useVoiceMode) await _speak(response.response);
      } else if (_interviewStage == 'question' || _interviewStage == 'followup') {
        if (_questionNumber >= _totalQuestions) {
          // End interview
          await _endSimulationInterview();
        } else {
          // Next question
          final response = await _interviewService.simulateInterview(
            stage: 'question',
            position: widget.position,
            company: widget.company,
            field: widget.field,
            questionNumber: _questionNumber + 1,
            totalQuestions: _totalQuestions,
            interviewerName: _interviewerName,
          );

          setState(() {
            _questionNumber++;
            _currentQuestion = response.response;
            _lastFeedback = null;
            _messages.add(InterviewMessage(
              role: 'assistant',
              content: '🎙️ $_interviewerName\n\n${response.response}',
            ));
            _isLoading = false;
            _isWaitingForAnswer = true;
          });

          if (_useVoiceMode) await _speak(response.response);
        }
      }

      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  Future<void> _endSimulationInterview() async {
    setState(() {
      _isLoading = true;
      _interviewStage = 'closing';
    });

    try {
      // Get closing remarks
      final closingResponse = await _interviewService.simulateInterview(
        stage: 'closing',
        position: widget.position,
        company: widget.company,
        interviewerName: _interviewerName,
      );

      _messages.add(InterviewMessage(
        role: 'assistant',
        content: '🎙️ $_interviewerName\n\n${closingResponse.response}',
      ));

      if (_useVoiceMode) await _speak(closingResponse.response);

      // Generate final report
      if (_questionsAndAnswers.isNotEmpty) {
        final report = await _interviewService.getInterviewReport(
          position: widget.position,
          company: widget.company,
          questionsAndAnswers: _questionsAndAnswers,
          overallScores: _allScores,
        );

        setState(() {
          _finalReport = report;
          _interviewStage = 'report';
          _messages.add(InterviewMessage(
            role: 'assistant',
            content: '📊 **INTERVIEW REPORT**\n\n**Verdict: ${report.verdict}**\n**Average Score: ${report.averageScore.toStringAsFixed(0)}/100**\n\n${report.report}',
          ));
          _isLoading = false;
          _isWaitingForAnswer = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isWaitingForAnswer = false;
        });
      }

      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }
  
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceAll('Exception: ', '')),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _submitAnswer() async {
    if (_answerController.text.trim().isEmpty) return;

    final userAnswer = _answerController.text.trim();
    
    // Build speech analysis context
    String speechContext = '';
    if (_useVoiceMode && _wordsPerMinute > 0) {
      speechContext = '''
Speech Analysis:
- Words per minute: ${_wordsPerMinute.toStringAsFixed(0)} (ideal: 120-150 WPM)
- Total words: $_wordCount
- Confidence level: ${(_confidence * 100).toStringAsFixed(0)}%
- Pauses detected: $_pauseCount
- Response time: $_responseTimeSeconds seconds
''';
    }
    
    // Add user message
    setState(() {
      _messages.add(InterviewMessage(
        role: 'user',
        content: '💬 You\n\n$userAnswer',
      ));
      _isWaitingForAnswer = false;
      _isLoading = true;
    });

    _answerController.clear();
    _spokenText = '';
    _scrollToBottom();

    try {
    // Get AI feedback
    final feedback = await _interviewService.getFeedback(
      question: _currentQuestion!,
        userAnswer: '$userAnswer\n\n$speechContext',
      field: widget.field,
      position: widget.position,
      company: widget.company,
    );

      // Store for final report in simulation mode
      if (_useSimulationMode && _currentQuestion != null) {
        _questionsAndAnswers.add(QuestionAnswer(
          question: _currentQuestion!,
          answer: userAnswer,
          score: feedback.score,
        ));
        _allScores.add(feedback.score);
      }

    setState(() {
      _lastFeedback = feedback;
      _messages.add(InterviewMessage(
        role: 'assistant',
        content: _formatFeedback(feedback),
      ));
      _isLoading = false;
    });

      // Speak summary feedback
      if (_useVoiceMode) {
        await _speak('Your score is ${feedback.score.toStringAsFixed(0)} out of 100. ${feedback.overallFeedback}');
      }

    _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isWaitingForAnswer = true;
      });
      _showError(e.toString());
    }
  }

  Future<void> _nextQuestion() async {
    if (_useSimulationMode) {
      await _continueSimulation();
      return;
    }

    setState(() {
      _questionNumber++;
      _lastFeedback = null;
      _isLoading = true;
      _wordsPerMinute = 0;
      _wordCount = 0;
      _confidence = 0;
      _pauseCount = 0;
      _responseTimeSeconds = 0;
    });

    try {
    final question = await _interviewService.getInterviewQuestion(
      field: widget.field,
      position: widget.position,
      questionNumber: _questionNumber,
    );

    setState(() {
      _currentQuestion = question;
      _messages.add(InterviewMessage(
        role: 'assistant',
        content: question,
      ));
      _isLoading = false;
      _isWaitingForAnswer = true;
    });

      // Speak the question
      if (_useVoiceMode) {
        await _speak(question);
      }

    _scrollToBottom();
    } catch (e) {
      setState(() {
        _questionNumber--;
        _isLoading = false;
      });
      _showError(e.toString());
    }
  }

  // Reset and restart the interview
  void _restartInterview() {
    setState(() {
      _messages.clear();
      _questionsAndAnswers.clear();
      _allScores.clear();
      _questionNumber = 1;
      _interviewStage = 'intro';
      _currentQuestion = null;
      _lastFeedback = null;
      _finalReport = null;
      _responseTimeSeconds = 0;
    });
    _startInterview();
  }

  String _formatFeedback(InterviewFeedback feedback) {
    final buffer = StringBuffer();
    buffer.writeln('📊 **Overall Score: ${feedback.score.toStringAsFixed(0)}/100**\n');
    buffer.writeln('✅ **Strengths:**');
    for (var strength in feedback.strengths) {
      buffer.writeln('• $strength');
    }
    buffer.writeln('\n💡 **Areas for Improvement:**');
    for (var improvement in feedback.improvements) {
      buffer.writeln('• $improvement');
    }
    buffer.writeln('\n📝 **Overall:** ${feedback.overallFeedback}');
    
    if (feedback.exampleResponses.isNotEmpty) {
      buffer.writeln('\n\n💡 **Example Responses:**');
      buffer.writeln('Here are different ways you could have answered this question:\n');
      for (var i = 0; i < feedback.exampleResponses.length; i++) {
        buffer.writeln('**Example ${i + 1}:**');
        buffer.writeln('${feedback.exampleResponses[i]}\n');
      }
    }
    
    return buffer.toString();
  }

  Widget _buildInterviewHeader() {
    if (!_useSimulationMode) {
      // Simple header for non-simulation mode
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _useVoiceMode ? const Color(0xFF6B46C1).withOpacity(0.1) : Colors.grey[100],
        ),
        child: Row(
          children: [
            Icon(
              _useVoiceMode ? Icons.mic : Icons.keyboard,
              color: _useVoiceMode ? const Color(0xFF6B46C1) : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _useVoiceMode ? 'Voice Mode' : 'Text Mode',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
            Switch(
              value: _useVoiceMode,
              onChanged: (value) => setState(() => _useVoiceMode = value),
              activeColor: const Color(0xFF6B46C1),
            ),
          ],
        ),
      );
    }

    // Video call style header
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
      ),
      child: Column(
        children: [
          // Video call top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Live indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                  children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                    Text(
                        'LIVE',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                        fontWeight: FontWeight.bold,
                          color: Colors.white,
                      ),
                    ),
                  ],
                ),
                ),
                const SizedBox(width: 12),
                // Call duration
                Text(
                  _formatDuration(_callDurationSeconds),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                // Question progress
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Q$_questionNumber/$_totalQuestions',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Interviewer video placeholder
                Container(
            height: 140,
            margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2d2d44), Color(0xFF1a1a2e)],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Stack(
              children: [
                // Animated background pattern
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomPaint(
                      painter: VideoBgPainter(),
                    ),
                  ),
                ),
                // Interviewer avatar
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B46C1).withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🤖', style: TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _interviewerName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                        Text(
                        _isSpeaking ? '🔊 Speaking...' : 'AI Coach',
                          style: GoogleFonts.inter(
                          fontSize: 10,
                          color: _isSpeaking ? const Color(0xFF10B981) : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                // Your video thumbnail
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    width: 50,
                    height: 65,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black87,
                      border: Border.all(
                        color: _isListening ? const Color(0xFF10B981) : Colors.white24,
                        width: _isListening ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person,
                          color: Colors.white54,
                          size: 22,
                        ),
                        if (_isListening)
                          const Text('🎤', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Call controls bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCallControl(
                  icon: _useVoiceMode ? Icons.mic : Icons.mic_off,
                  isActive: _useVoiceMode,
                  onTap: () => setState(() => _useVoiceMode = !_useVoiceMode),
                  label: 'Mic',
                ),
                _buildCallControl(
                  icon: Icons.videocam,
                  isActive: true,
                  onTap: () {},
                  label: 'Video',
                ),
                _buildCallControl(
                  icon: _isSpeaking ? Icons.volume_off : Icons.volume_up,
                  isActive: !_isSpeaking,
                  onTap: _isSpeaking ? _stopSpeaking : null,
                  label: 'Speaker',
                ),
                _buildCallControl(
                  icon: Icons.call_end,
                  isActive: false,
                  isEndCall: true,
                  onTap: () {
                    if (_interviewStage != 'intro' && _interviewStage != 'report') {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('End Interview?'),
                          content: const Text('Are you sure you want to end this interview?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Continue'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: const Text('End Call', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  label: 'End',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControl({
    required IconData icon,
    required bool isActive,
    required VoidCallback? onTap,
    required String label,
    bool isEndCall = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
                  Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEndCall 
                  ? Colors.red 
                  : (isActive ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1)),
            ),
            child: Icon(
              icon,
              color: isActive || isEndCall ? Colors.white : Colors.white54,
              size: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildSpeechMetrics() {
    if (!_useVoiceMode || (_wordsPerMinute == 0 && !_isListening)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
              Icon(Icons.analytics, size: 18, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                'Speech Analysis',
                              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
          Row(
            children: [
              _buildMetricChip(
                'WPM',
                _wordsPerMinute.toStringAsFixed(0),
                _wordsPerMinute >= 120 && _wordsPerMinute <= 150 
                    ? Colors.green 
                    : Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildMetricChip(
                'Words',
                '$_wordCount',
                _wordCount >= 50 ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
             
            ],
          ),
          if (_wordsPerMinute > 0) ...[
            const SizedBox(height: 8),
                        Text(
              _wordsPerMinute < 120 
                  ? '💡 Try speaking a bit faster for better engagement'
                  : _wordsPerMinute > 150 
                      ? '💡 Slow down slightly for better clarity'
                      : '✅ Great pace! Clear and engaging',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceInputArea() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: SingleChildScrollView(
                              child: Column(
          mainAxisSize: MainAxisSize.min,
                                children: [
            // Voice recording button
            GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isListening ? 70 : 60,
                height: _isListening ? 70 : 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? Colors.red : const Color(0xFF6B46C1),
                  boxShadow: _isListening
                      ? [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isListening 
                  ? 'Listening... Tap to stop'
                  : 'Tap to speak',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            
            // Show transcription
            if (_spokenText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 80),
                padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.text_fields, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            'Transcription:',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _spokenText,
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 10),
          
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isLoading || _spokenText.isEmpty) ? null : _submitAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B46C1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Submit Answer',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          
            // Switch to text mode
            TextButton(
              onPressed: () => setState(() => _useVoiceMode = false),
              child: Text(
                'Switch to text mode',
                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _answerController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Type your answer here...',
              hintStyle: GoogleFonts.inter(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6B46C1),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            style: GoogleFonts.inter(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_speechEnabled)
                IconButton(
                  onPressed: () => setState(() => _useVoiceMode = true),
                  icon: const Icon(Icons.mic),
                  tooltip: 'Switch to voice mode',
                                            color: const Color(0xFF6B46C1),
                ),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Submit Answer',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
        ],
      ),
    );
  }

  Widget _buildDetailedFeedbackCard() {
    if (_lastFeedback == null || _lastFeedback!.detailedAnalysis == null) {
      return const SizedBox.shrink();
    }

    final analysis = _lastFeedback!.detailedAnalysis!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getScoreColor(_lastFeedback!.score).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getScoreColor(_lastFeedback!.score),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isFeedbackExpanded = !_isFeedbackExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.assessment,
                      color: _getScoreColor(_lastFeedback!.score),
                    ),
                    const SizedBox(width: 8),
                                  Text(
                      'Overall Score: ${_lastFeedback!.score.toStringAsFixed(0)}/100',
                                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(_lastFeedback!.score),
                                    ),
                                  ),
                                ],
                              ),
                Row(
                  children: [
                    if (_isSpeaking)
                      IconButton(
                        icon: const Icon(Icons.stop, size: 20),
                        onPressed: _stopSpeaking,
                        color: Colors.red,
                      )
                    else if (_useVoiceMode)
                      IconButton(
                        icon: const Icon(Icons.volume_up, size: 20),
                        onPressed: () => _speak(_lastFeedback!.overallFeedback),
                        color: const Color(0xFF6B46C1),
                      ),
                    Icon(
                      _isFeedbackExpanded ? Icons.expand_less : Icons.expand_more,
                      color: _getScoreColor(_lastFeedback!.score),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          if (_isFeedbackExpanded) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            
            _buildAnalysisCategory(
              'Communication',
              analysis.communicationScore,
              analysis.communicationFeedback,
              Icons.chat_bubble_outline,
            ),
            const SizedBox(height: 12),
            
            _buildAnalysisCategory(
              'Structure',
              analysis.structureScore,
              analysis.structureFeedback,
              Icons.format_list_bulleted,
            ),
            const SizedBox(height: 12),
            
            _buildAnalysisCategory(
              'Examples',
              analysis.examplesScore,
              analysis.examplesFeedback,
              Icons.lightbulb_outline,
            ),
            const SizedBox(height: 12),
            
            _buildAnalysisCategory(
              'Role Relevance',
              analysis.roleRelevanceScore,
              analysis.roleRelevanceFeedback,
              Icons.work_outline,
            ),
              ],
            ],
          ),
        );
  }

  Widget _buildAnalysisCategory(
    String title,
    double score,
    String feedback,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _getScoreColor(score)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getScoreColor(score).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${score.toStringAsFixed(0)}/100',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getScoreColor(score),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  feedback,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Build intro response area - for acknowledging interviewer intro
  Widget _buildIntroResponseArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
          children: [
            Text(
            '👋 The interviewer has introduced themselves',
                style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _messages.add(InterviewMessage(
                    role: 'user',
                    content: '💬 You\n\nThank you for having me. I\'m ready to begin.',
                  ));
                  _isWaitingForAnswer = false;
                });
                _continueSimulation();
              },
              icon: const Icon(Icons.play_arrow),
              label: Text(
                'Ready - Start Interview',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B46C1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build next question button with simulation awareness
  Widget _buildNextQuestionButton() {
    final isLastQuestion = _questionNumber >= _totalQuestions;
    
    return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
            offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
          if (_useSimulationMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isLastQuestion ? Icons.flag : Icons.arrow_forward,
                    size: 16,
                        color: Colors.grey[600],
                      ),
                  const SizedBox(width: 8),
                  Text(
                    isLastQuestion 
                        ? 'Final question completed!'
                        : 'Question $_questionNumber of $_totalQuestions completed',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
                  SizedBox(
                    width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _nextQuestion,
              icon: Icon(isLastQuestion ? Icons.summarize : Icons.navigate_next),
              label: Text(
                isLastQuestion ? 'End Interview & Get Report' : 'Next Question',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
                      style: ElevatedButton.styleFrom(
                backgroundColor: isLastQuestion ? const Color(0xFF059669) : Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  // Build report actions after interview ends
  Widget _buildReportActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
                  ),
                ],
              ),
      child: Column(
        children: [
          // Verdict badge
            Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _getVerdictColor(_finalReport!.verdict).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getVerdictColor(_finalReport!.verdict),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getVerdictIcon(_finalReport!.verdict),
                  color: _getVerdictColor(_finalReport!.verdict),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_finalReport!.verdict} • ${_finalReport!.averageScore.toStringAsFixed(0)}/100',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: _getVerdictColor(_finalReport!.verdict),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _restartInterview,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Practice Again'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getVerdictColor(String verdict) {
    switch (verdict) {
      case 'Strong Hire':
        return const Color(0xFF059669);
      case 'Hire':
        return const Color(0xFF10B981);
      case 'Maybe':
        return const Color(0xFFF59E0B);
      case 'No Hire':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  IconData _getVerdictIcon(String verdict) {
    switch (verdict) {
      case 'Strong Hire':
        return Icons.star;
      case 'Hire':
        return Icons.thumb_up;
      case 'Maybe':
        return Icons.help_outline;
      case 'No Hire':
        return Icons.thumb_down;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _useSimulationMode 
                  ? 'Interview with $_interviewerName'
                  : 'Mock Interview Practice',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            if (widget.position != null)
              Text(
                widget.position!,
                    style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_interviewStage != 'intro' && _interviewStage != 'report') {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Leave Interview?'),
                  content: const Text('Your progress will be lost. Are you sure you want to leave?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Stay'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('Leave', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (_isSpeaking)
            IconButton(
              icon: const Icon(Icons.stop_circle),
              onPressed: _stopSpeaking,
              color: Colors.red,
            ),
          if (_interviewStage == 'report')
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // Could implement share functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report saved!')),
                );
              },
              color: const Color(0xFF6B46C1),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 800;
          
          if (isWideScreen) {
            // Side-by-side layout for wide screens
            return Row(
              children: [
                // Left side - Interview controls
                Container(
                  width: 400,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a2e),
                    border: Border(
                      right: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildInterviewHeader(),
                      _buildSpeechMetrics(),
                      const Spacer(),
                      // Input Area
                      if (_interviewStage == 'intro' && _isWaitingForAnswer && !_isLoading)
                        _buildIntroResponseArea()
                      else if (_isWaitingForAnswer)
                        _useVoiceMode ? _buildVoiceInputArea() : _buildTextInputArea()
                      else if (!_isLoading && _lastFeedback != null && _interviewStage != 'report')
                        _buildNextQuestionButton()
                      else if (_interviewStage == 'report' && _finalReport != null)
                        _buildReportActions(),
                    ],
                  ),
                ),
                // Right side - Chat and feedback
                Expanded(
                  child: Container(
                    color: Colors.grey[50],
                    child: Column(
                      children: [
                        // Feedback Card
                        if (_lastFeedback != null) _buildDetailedFeedbackCard(),
                        // Chat Messages
                        Expanded(
                          child: _buildChatArea(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          
          // Stacked layout for narrow screens
          return Column(
            children: [
              _buildInterviewHeader(),
              _buildSpeechMetrics(),
              if (_lastFeedback != null) _buildDetailedFeedbackCard(),
              Expanded(child: _buildChatArea()),
              if (_interviewStage == 'intro' && _isWaitingForAnswer && !_isLoading)
                _buildIntroResponseArea()
              else if (_isWaitingForAnswer)
                _useVoiceMode ? _buildVoiceInputArea() : _buildTextInputArea()
              else if (!_isLoading && _lastFeedback != null && _interviewStage != 'report')
                _buildNextQuestionButton()
              else if (_interviewStage == 'report' && _finalReport != null)
                _buildReportActions(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChatArea() {
    return _messages.isEmpty
        ? Center(
            child: _isLoading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _useSimulationMode 
                            ? 'Connecting to interviewer...'
                            : 'Starting interview...',
                        style: GoogleFonts.inter(color: Colors.grey[600]),
                      ),
                    ],
                  )
                : const Text('Starting interview...'),
          )
        : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(
                          _interviewStage == 'closing' 
                              ? 'Generating interview report...'
                              : 'Interviewer is thinking...',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final message = _messages[index];
              return _buildMessageBubble(message);
            },
          );
  }

  Widget _buildMessageBubble(InterviewMessage message) {
    final isUser = message.role == 'user';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF6B46C1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('🎙️', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onTap: !isUser && _useVoiceMode ? () => _speak(message.content) : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser ? const Color(0xFF6B46C1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: GoogleFonts.inter(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    if (!isUser && _useVoiceMode) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.volume_up,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to hear',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('👤', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
