import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  _AssistantScreenState createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen>
    with TickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _recorder = AudioRecorder();
  
  final List<ChatMessage> _messages = [];
  bool _isListening = false;
  bool _isProcessing = false;
  bool _speechEnabled = false;
  String _assistantName = 'Assistant';
  String _assistantTone = 'friendly';
  String? _audioFilePath;
  
  late AnimationController _pulseController;
  late AnimationController _waveController;
  
  // Replace with your Google Cloud API key
  final String _googleCloudApiKey = 'AIzaSyCaah_onKe1bubdYGNT2W1OY3qHItOI57E';
  
  // Replace with your Gemini API key
  final String _geminiApiKey = 'AIzaSyB6dq0ID5u5XjmwlJEmX18juCXqLzp7S0E';
  
  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _initializeTTS();
    _loadUserPreferences();
    _setupAnimations();
    _addWelcomeMessage();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  Future<void> _initializeRecorder() async {
    final permission = await Permission.microphone.request();
    if (permission.isGranted) {
      setState(() {
        _speechEnabled = true;
      });
    }
  }

  Future<void> _initializeTTS() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _loadUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _assistantName = data['assistantName'] ?? 'Assistant';
          _assistantTone = data['assistantTone'] ?? 'friendly';
        });
      }
    }
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        text: "Hi! I'm $_assistantName, your personal AI assistant. How can I help you break barriers and build dreams today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.blue.shade400],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _assistantName,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  _isProcessing ? 'Thinking...' : _isListening ? 'Listening...' : 'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isProcessing ? Colors.orange : _isListening ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _showAssistantSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.blue.shade400],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology, color: Colors.white, size: 16),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: (message.isUser
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface)
                          .withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                maxLines: null,
                onSubmitted: (text) => _sendMessage(text),
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: _speechEnabled ? _toggleListening : null,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isListening
                            ? [Colors.red.shade400, Colors.red.shade600]
                            : [Colors.purple.shade400, Colors.blue.shade400],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: _isListening
                          ? [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 10 + (_pulseController.value * 10),
                                spreadRadius: _pulseController.value * 5,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(_messageController.text),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleListening() async {
    if (_isListening) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (!_speechEnabled) return;

    try {
      // Check if the recorder is already recording
      if (await _recorder.isRecording()) {
        return;
      }

      // Get temporary directory for audio file
      final directory = await getTemporaryDirectory();
      _audioFilePath = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';

      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        bitRate: 128000,
      );

      await _recorder.start(config, path: _audioFilePath!);

      setState(() {
        _isListening = true;
      });
      _pulseController.repeat();

      // Auto-stop after 30 seconds
      Timer(Duration(seconds: 30), () {
        if (_isListening) {
          _stopRecording();
        }
      });
    } catch (e) {
      print('Error starting recording: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (!_isListening) return;

    try {
      final path = await _recorder.stop();
      setState(() {
        _isListening = false;
      });
      _pulseController.stop();

      if (path != null && path.isNotEmpty) {
        await _processAudioFile(path);
      } else if (_audioFilePath != null) {
        await _processAudioFile(_audioFilePath!);
      }
    } catch (e) {
      print('Error stopping recording: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<void> _processAudioFile(String filePath) async {
    try {
      final transcription = await _transcribeAudio(filePath);
      if (transcription.isNotEmpty) {
        _sendMessage(transcription);
      }
    } catch (e) {
      print('Error processing audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process audio. Please try again.')),
      );
    } finally {
      // Clean up temporary file
      if (await File(filePath).exists()) {
        await File(filePath).delete();
      }
    }
  }

  Future<String> _transcribeAudio(String filePath) async {
    final file = File(filePath);
    final audioBytes = await file.readAsBytes();
    final base64Audio = base64Encode(audioBytes);

    final url = 'https://speech.googleapis.com/v1/speech:recognize?key=$_googleCloudApiKey';
    
    final requestBody = {
      'config': {
        'encoding': 'LINEAR16',
        'sampleRateHertz': 16000,
        'languageCode': 'en-US',
        'enableAutomaticPunctuation': true,
        'model': 'latest_long',
      },
      'audio': {
        'content': base64Audio,
      },
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List?;
      
      if (results != null && results.isNotEmpty) {
        final alternatives = results[0]['alternatives'] as List;
        if (alternatives.isNotEmpty) {
          return alternatives[0]['transcript'] as String;
        }
      }
      return '';
    } else {
      print('Speech-to-Text API error: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to transcribe audio: ${response.statusCode}');
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isProcessing = true;
    });

    _scrollToBottom();

    try {
      final response = await _getGeminiResponse(text.trim());
      final assistantMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(assistantMessage);
        _isProcessing = false;
      });

      // Speak the response
      await _flutterTts.speak(response);
      
      _scrollToBottom();
    } catch (e) {
      final errorMessage = ChatMessage(
        text: "I'm sorry, I encountered an error. Please try again.",
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(errorMessage);
        _isProcessing = false;
      });
    }
  }

  Future<String> _getGeminiResponse(String message) async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_geminiApiKey';
    
    final systemPrompt = _getSystemPrompt();
    final fullPrompt = '$systemPrompt\n\nUser: $message\n\nAssistant:';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [{
          'parts': [{
            'text': fullPrompt,
          }]
        }],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Failed to get response from Gemini API');
    }
  }

  String _getSystemPrompt() {
    String toneDescription = '';
    switch (_assistantTone) {
      case 'friendly':
        toneDescription = 'warm, supportive, and encouraging';
        break;
      case 'professional':
        toneDescription = 'formal, precise, and business-like';
        break;
      case 'motivational':
        toneDescription = 'energetic, inspiring, and uplifting';
        break;
      case 'calm':
        toneDescription = 'peaceful, soothing, and mindful';
        break;
    }

    return '''You are $_assistantName, a personal AI assistant for the BBBD (Breaking Barriers. Building Dreams) app. 
Your role is to help users achieve their personal goals and overcome challenges.

Your tone should be $toneDescription.

You specialize in:
- Goal setting and achievement
- Building healthy routines
- Personal development
- Mental wellness and mindfulness
- Productivity improvement
- Motivational support

Keep responses concise, actionable, and supportive. Always encourage the user and provide practical advice.''';
  }

  void _showAssistantSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AssistantSettingsSheet(
        assistantName: _assistantName,
        assistantTone: _assistantTone,
        onSettingsChanged: (name, tone) {
          setState(() {
            _assistantName = name;
            _assistantTone = tone;
          });
        },
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _recorder.dispose();
    _flutterTts.stop();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AssistantSettingsSheet extends StatefulWidget {
  final String assistantName;
  final String assistantTone;
  final Function(String, String) onSettingsChanged;

  const AssistantSettingsSheet({super.key, 
    required this.assistantName,
    required this.assistantTone,
    required this.onSettingsChanged,
  });

  @override
  _AssistantSettingsSheetState createState() => _AssistantSettingsSheetState();
}

class _AssistantSettingsSheetState extends State<AssistantSettingsSheet> {
  late TextEditingController _nameController;
  late String _selectedTone;

  final List<Map<String, String>> _tones = [
    {'name': 'Friendly', 'value': 'friendly', 'description': 'Warm and supportive'},
    {'name': 'Professional', 'value': 'professional', 'description': 'Formal and precise'},
    {'name': 'Motivational', 'value': 'motivational', 'description': 'Energetic and inspiring'},
    {'name': 'Calm', 'value': 'calm', 'description': 'Peaceful and soothing'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.assistantName);
    _selectedTone = widget.assistantTone;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assistant Settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Assistant Name',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Assistant Tone',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 10),
          ...(_tones.map((tone) => RadioListTile<String>(
                title: Text(tone['name']!),
                subtitle: Text(tone['description']!),
                value: tone['value']!,
                groupValue: _selectedTone,
                onChanged: (value) {
                  setState(() {
                    _selectedTone = value!;
                  });
                },
              ))),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              child: Text('Save Changes'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'assistantName': _nameController.text.trim(),
        'assistantTone': _selectedTone,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      widget.onSettingsChanged(_nameController.text.trim(), _selectedTone);
      Navigator.pop(context);
    }
  }
}