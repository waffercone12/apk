// File: lib/services/voice_assistant_service.dart (Updated)
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_recognition_error.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/assistant_personality.dart';

class VoiceAssistantService extends ChangeNotifier {
  // Speech-to-Text and Text-to-Speech instances
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;

  // State management
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;
  bool _speechEnabled = false;
  String _lastWords = '';
  String _currentResponse = '';
  double _confidence = 0.0;

  // Assistant personality and settings
  AssistantPersonality _currentPersonality = AssistantPersonality.supportiveFriend;
  String _assistantName = 'Coach';
  String _wakeWord = 'hey coach';

  // Voice testing callback
  Function(String)? onVoiceTestResult;

  // Gemini AI Configuration
  static const String _geminiApiKey = 'AIzaSyAttKUwx_e82ExDmyIHVgK_YZM_ayjS52c';
  static const String _geminiApiUrl = 
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

  // Voice settings
  double _speechRate = 0.5;
  double _speechVolume = 0.8;
  double _speechPitch = 1.0;
  String _speechLanguage = 'en-US';

  // Timer for listening timeout
  Timer? _listeningTimer;

  // Getters
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;
  bool get speechEnabled => _speechEnabled;
  String get lastWords => _lastWords;
  String get currentResponse => _currentResponse;
  double get confidence => _confidence;
  double get speechRate => _speechRate;
  double get speechVolume => _speechVolume;
  double get speechPitch => _speechPitch;
  String get speechLanguage => _speechLanguage;
  AssistantPersonality get currentPersonality => _currentPersonality;
  String get assistantName => _assistantName;
  String get wakeWord => _wakeWord;

  VoiceState get currentState {
    if (_isListening) return VoiceState.listening;
    if (_isProcessing) return VoiceState.processing;
    if (_isSpeaking) return VoiceState.responding;
    return VoiceState.idle;
  }

  // Initialize the voice assistant
  Future<bool> initialize() async {
    try {
      print('Initializing BBBD Voice Assistant...');

      // Request microphone permission
      await _requestMicrophonePermission();

      // Initialize Speech-to-Text
      _speech = stt.SpeechToText();
      _speechEnabled = await _speech.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
        debugLogging: kDebugMode,
      );

      if (!_speechEnabled) {
        print('Speech recognition not available');
        return false;
      }

      // Initialize Text-to-Speech
      _flutterTts = FlutterTts();
      await _initializeTts();

      _isInitialized = true;
      notifyListeners();

      print('Voice Assistant initialized successfully!');
      return true;
    } catch (e) {
      print('Voice Assistant initialization error: $e');
      return false;
    }
  }

  // Set assistant personality
  void setPersonality(AssistantPersonality personality) {
    _currentPersonality = personality;
    _updateTtsSettingsForPersonality();
    notifyListeners();
    print('Assistant personality set to: ${personality.info.name}');
  }

  // Set wake word and assistant name
  void setWakeWord(String name) {
    _assistantName = name;
    _wakeWord = 'hey ${name.toLowerCase()}';
    notifyListeners();
    print('Wake word set to: $_wakeWord');
  }

  // Update TTS settings based on personality
  void _updateTtsSettingsForPersonality() {
    switch (_currentPersonality) {
      case AssistantPersonality.toughLove:
        _speechRate = 0.6; // Slightly faster
        _speechPitch = 0.9; // Slightly lower pitch
        break;
      case AssistantPersonality.supportiveFriend:
        _speechRate = 0.5; // Normal pace
        _speechPitch = 1.1; // Slightly higher pitch
        break;
      case AssistantPersonality.motivationalCoach:
        _speechRate = 0.7; // Faster, energetic
        _speechPitch = 1.2; // Higher pitch
        break;
      case AssistantPersonality.wiseMentor:
        _speechRate = 0.4; // Slower, thoughtful
        _speechPitch = 0.8; // Lower pitch
        break;
      case AssistantPersonality.cheerfulCompanion:
        _speechRate = 0.6; // Upbeat pace
        _speechPitch = 1.3; // Higher, cheerful pitch
        break;
    }
    
    // Apply the new settings
    if (_isInitialized) {
      _flutterTts.setSpeechRate(_speechRate);
      _flutterTts.setPitch(_speechPitch);
    }
  }

  // Speak with personality-specific response
  Future<void> speakWithPersonality(String text, AssistantPersonality personality) async {
    final previousPersonality = _currentPersonality;
    setPersonality(personality);
    await _speakResponse(text);
    setPersonality(previousPersonality);
  }

  // Request microphone permission
  Future<void> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission is required for voice input');
    }
  }

  // Initialize Text-to-Speech
  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage(_speechLanguage);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_speechVolume);
    await _flutterTts.setPitch(_speechPitch);

    // Set up TTS callbacks
    _flutterTts.setStartHandler(() {
      print('TTS Started');
      _isSpeaking = true;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      print('TTS Completed');
      _isSpeaking = false;
      notifyListeners();
    });

    _flutterTts.setCancelHandler(() {
      print('TTS Cancelled');
      _isSpeaking = false;
      notifyListeners();
    });

    _flutterTts.setErrorHandler((message) {
      print('TTS Error: $message');
      _isSpeaking = false;
      notifyListeners();
    });

    // Platform-specific settings
    if (Platform.isAndroid) {
      await _flutterTts.setEngine('com.google.android.tts');
    } else if (Platform.isIOS) {
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
      );
    }
  }

  // Start listening for voice input
  Future<void> startListening() async {
    if (!_isInitialized || !_speechEnabled || _isListening || _isProcessing || _isSpeaking) {
      print(
        'Cannot start listening: isInitialized=$_isInitialized, speechEnabled=$_speechEnabled, isListening=$_isListening, isProcessing=$_isProcessing, isSpeaking=$_isSpeaking',
      );
      return;
    }

    try {
      print('Starting voice recognition...');

      // Clear previous results
      _lastWords = '';
      _currentResponse = '';
      _confidence = 0.0;

      _isListening = true;
      notifyListeners();

      // Start listening with speech-to-text
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: Duration(seconds: 10),
        pauseFor: Duration(seconds: 5),
        partialResults: true,
        localeId: _speechLanguage,
        onSoundLevelChange: _onSoundLevelChange,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      // Set a timeout for listening
      _listeningTimer = Timer(Duration(seconds: 10), () {
        if (_isListening) {
          stopListening();
        }
      });

    } catch (e) {
      print('Error starting speech recognition: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    print('Stopping voice recognition...');

    _listeningTimer?.cancel();
    
    try {
      await _speech.stop();
    } catch (e) {
      print('Error stopping speech recognition: $e');
    }

    _isListening = false;
    notifyListeners();

    // Process the final result if we have words
    if (_lastWords.isNotEmpty) {
      await _processVoiceCommand(_lastWords);
    }
  }

  // Handle speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    print('Speech result: ${result.recognizedWords} (confidence: ${result.confidence})');
    _lastWords = result.recognizedWords;
    _confidence = result.confidence;
    notifyListeners();

    // Check for wake word during voice testing
    if (onVoiceTestResult != null) {
      onVoiceTestResult!(result.recognizedWords);
    }

    // Check for wake word in normal operation
    if (result.recognizedWords.toLowerCase().contains(_wakeWord)) {
      print('Wake word detected: $_wakeWord');
    }

    if (result.finalResult && result.confidence > 0.5) {
      Timer(Duration(milliseconds: 500), () {
        if (_isListening) {
          stopListening();
        }
      });
    }
  }

  // Handle speech recognition errors
  void _onSpeechError(stt.SpeechRecognitionError error) {
    print('Speech recognition error: ${error.errorMsg}');
    _isListening = false;
    notifyListeners();
  }

  // Handle speech recognition status changes
  void _onSpeechStatus(String status) {
    print('Speech recognition status: $status');
    
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      notifyListeners();
    }
  }

  // Handle sound level changes (for visualization)
  void _onSoundLevelChange(double level) {
    // You can use this for voice wave visualization
    print('Sound level: $level');
  }

  // Process voice command using Gemini AI with personality context
  Future<void> _processVoiceCommand(String command) async {
    if (command.trim().isEmpty) return;

    print('Processing voice command: $command');

    _isProcessing = true;
    _currentResponse = '';
    notifyListeners();

    try {
      // Send to Gemini AI with personality context
      final response = await _sendToGeminiWithPersonality(command);

      if (response != null && response.isNotEmpty) {
        _currentResponse = response;
        notifyListeners();

        print('AI Response: $response');

        // Speak the response with current personality
        await _speakResponse(response);
      } else {
        await _speakResponse(_currentPersonality.getResponseForContext('error'));
      }
    } catch (e) {
      print('Error processing voice command: $e');
      await _speakResponse(_currentPersonality.getResponseForContext('error'));
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Send command to Gemini AI with personality context
  Future<String?> _sendToGeminiWithPersonality(String prompt) async {
    if (_geminiApiKey == 'zaSyAttKUwx_e82ExDmyIHVgK_YZM_ayjS52c' || _geminiApiKey.isEmpty) {
      print('Using fallback responses (Please set your actual Gemini API key)');
      return _getFallbackResponseWithPersonality(prompt);
    }

    try {
      print('Sending request to Gemini AI with personality context...');

      // Enhanced prompt with personality and assistant context
      final personalityInfo = _currentPersonality.info;
      final enhancedPrompt = '''
You are $_assistantName, an AI life coach with a ${personalityInfo.name} personality.

Your personality traits:
- Name: ${personalityInfo.name} (${personalityInfo.emoji})
- Style: ${personalityInfo.description}
- Communication: ${personalityInfo.responseStyles['greeting']}

IMPORTANT: Always respond in character as ${personalityInfo.name}. Match the tone, energy level, and communication style described above.

Context: You're helping someone overcome challenges and build better habits. The user's primary challenge is their personal growth journey.

User's voice command: "$prompt"

Respond as $_assistantName with your ${personalityInfo.name} personality. Keep responses conversational, supportive, and under 50 words. Use the speaking style and energy level that matches your personality.

Response:''';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': enhancedPrompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.8,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 150,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
        ],
      };

      final response = await http
          .post(
            Uri.parse('$_geminiApiUrl?key=$_geminiApiKey'),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'BBBD-Voice-Assistant/1.0',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: 15));

      print('Gemini API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['error'] != null) {
          print('Gemini API error: ${data['error']}');
          return _getFallbackResponseWithPersonality(prompt);
        }

        final candidates = data['candidates'] as List?;

        if (candidates != null && candidates.isNotEmpty) {
          final candidate = candidates[0];
          
          if (candidate['finishReason'] == 'SAFETY') {
            print('Response blocked by safety filters');
            return _getFallbackResponseWithPersonality(prompt);
          }

          final parts = candidate['content']['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final aiResponse = parts[0]['text']?.toString().trim();
            if (aiResponse != null && aiResponse.isNotEmpty) {
              print('Gemini AI response received: $aiResponse');
              return aiResponse;
            }
          }
        }
      } else {
        print('Gemini API HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception calling Gemini API: $e');
    }

    return _getFallbackResponseWithPersonality(prompt);
  }

  // Fallback responses with personality
  String _getFallbackResponseWithPersonality(String prompt) {
    final lowerPrompt = prompt.toLowerCase();

    // Check for specific topics first
    if (lowerPrompt.contains('calendar') || lowerPrompt.contains('schedule')) {
      switch (_currentPersonality) {
        case AssistantPersonality.toughLove:
          return 'Stop procrastinating. Check your Calendar tab and plan your day properly.';
        case AssistantPersonality.supportiveFriend:
          return 'I\'d love to help you with your schedule! Check the Calendar tab to see what\'s coming up.';
        case AssistantPersonality.motivationalCoach:
          return 'TIME to ORGANIZE and DOMINATE your schedule! Hit that Calendar tab!';
        case AssistantPersonality.wiseMentor:
          return 'Time is your most valuable resource. Review your Calendar tab to use it wisely.';
        case AssistantPersonality.cheerfulCompanion:
          return 'Let\'s get organized! Pop over to the Calendar tab and see what awesome things you have planned!';
      }
    }

    if (lowerPrompt.contains('motivation') || lowerPrompt.contains('help')) {
      return _currentPersonality.getMotivationalPhrase();
    }

    if (lowerPrompt.contains('hello') || lowerPrompt.contains('hi')) {
      return _currentPersonality.getResponseForContext('greeting');
    }

    // Default response based on personality
    return _currentPersonality.getResponseForContext('greeting');
  }

  // Speak the AI response using Text-to-Speech
  Future<void> _speakResponse(String text) async {
    if (text.isEmpty) return;

    try {
      print('Speaking response: $text');

      // Stop any current speech
      await _flutterTts.stop();

      // Speak the text with current personality settings
      await _flutterTts.speak(text);

    } catch (e) {
      print('Error speaking response: $e');
      _isSpeaking = false;
      notifyListeners();
    }
  }

  // Stop current speech output
  Future<void> stopSpeaking() async {
    try {
      print('Stopping speech output');
      await _flutterTts.stop();
      _isSpeaking = false;
      notifyListeners();
    } catch (e) {
      print('Error stopping speech: $e');
    }
  }

  // Voice settings methods
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 1.0);
    await _flutterTts.setSpeechRate(_speechRate);
    print('Speech rate set to: $_speechRate');
    notifyListeners();
  }

  Future<void> setSpeechVolume(double volume) async {
    _speechVolume = volume.clamp(0.0, 1.0);
    await _flutterTts.setVolume(_speechVolume);
    print('Speech volume set to: $_speechVolume');
    notifyListeners();
  }

  Future<void> setSpeechPitch(double pitch) async {
    _speechPitch = pitch.clamp(0.5, 2.0);
    await _flutterTts.setPitch(_speechPitch);
    print('Speech pitch set to: $_speechPitch');
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    _speechLanguage = language;
    await _flutterTts.setLanguage(_speechLanguage);
    print('Speech language set to: $_speechLanguage');
    notifyListeners();
  }

  // Quick actions with personality
  Future<void> processQuickAction(String action) async {
    print('Processing quick action: $action');

    String response = '';

    switch (action.toLowerCase()) {
      case 'ideas':
        response = _currentPersonality.getMotivationalPhrase();
        break;
      case 'help':
        response = _currentPersonality.getResponseForContext('greeting');
        break;
      case 'settings':
        response = 'You can adjust my settings in the voice menu. What would you like to change?';
        break;
      default:
        response = _currentPersonality.getCheckInPhrase();
    }

    _currentResponse = response;
    notifyListeners();
    await _speakResponse(response);
  }

  // Test voice output with current personality
  Future<void> testVoice() async {
    print('Testing voice output with ${_currentPersonality.info.name} personality...');
    await _speakResponse(_currentPersonality.info.samplePhrase);
  }

  // Direct command processing
  Future<void> processDirectCommand(String command) async {
    print('Processing direct command: $command');
    _lastWords = command;
    _confidence = 1.0;
    notifyListeners();
    await _processVoiceCommand(command);
  }

  // Clear current session
  void clearSession() {
    _lastWords = '';
    _currentResponse = '';
    _confidence = 0.0;
    notifyListeners();
    print('Voice session cleared');
  }

  // Get current status for debugging
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'speechEnabled': _speechEnabled,
      'isListening': _isListening,
      'isProcessing': _isProcessing,
      'isSpeaking': _isSpeaking,
      'lastWords': _lastWords,
      'currentResponse': _currentResponse,
      'confidence': _confidence,
      'speechRate': _speechRate,
      'speechVolume': _speechVolume,
      'speechPitch': _speechPitch,
      'speechLanguage': _speechLanguage,
      'personality': _currentPersonality.info.name,
      'assistantName': _assistantName,
      'wakeWord': _wakeWord,
    };
  }

  // Dispose resources
  @override
  void dispose() {
    _listeningTimer?.cancel();
    
    // Stop and dispose speech recognition
    if (_speechEnabled) {
      _speech.stop();
    }
    
    // Stop and dispose text-to-speech
    _flutterTts.stop();
    
    super.dispose();
    print('Voice Assistant Service disposed');
  }
}

// Voice state enum
enum VoiceState { idle, listening, processing, responding }