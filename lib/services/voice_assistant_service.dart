// File: lib/services/voice_assistant_service.dart
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

  // Gemini AI Configuration
  static const String _geminiApiKey =
      'AIzaSyAttKUwx_e82ExDmyIHVgK_YZM_ayjS52c'; // Replace with your API key
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
        listenFor: Duration(seconds: 10), // Maximum listening duration
        pauseFor: Duration(seconds: 5),   // Pause duration to detect end of speech
        partialResults: true,             // Get partial results while speaking
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
  print('Speech result: \${result.recognizedWords} (confidence: \${result.confidence})');
  _lastWords = result.recognizedWords;
  _confidence = result.confidence;
  notifyListeners();

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
    // The level ranges from 0.0 to 1.0
    print('Sound level: $level');
  }

  // Process voice command using Gemini AI
  Future<void> _processVoiceCommand(String command) async {
    if (command.trim().isEmpty) return;

    print('Processing voice command: $command');

    _isProcessing = true;
    _currentResponse = '';
    notifyListeners();

    try {
      // Send to Gemini AI or use fallback
      final response = await _sendToGemini(command);

      if (response != null && response.isNotEmpty) {
        _currentResponse = response;
        notifyListeners();

        print('AI Response: $response');

        // Speak the response
        Future.microtask(() => _speakResponse(response));
      } else {
        await _speakResponse('I\'m sorry, I couldn\'t process that request.');
      }
    } catch (e) {
      print('Error processing voice command: $e');
      await _speakResponse('I encountered an error processing your request.');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Send command to Gemini AI
  Future<String?> _sendToGemini(String prompt) async {
  return await compute(_sendToGeminiWorker, prompt);
    // If no API key is set, return a fallback response
    if (_geminiApiKey == 'AIzaSyAttKUwx_e82ExDmyIHVgK_YZM_ayjS52c') {
      print('Using fallback responses (replace with your Gemini API key)');
      return _getFallbackResponse(prompt);
    }

    try {
      print('Sending request to Gemini AI...');

      // Enhanced prompt with context about BBBD app
      final enhancedPrompt = '''
You are BBBD Assistant, a helpful voice assistant for the BBBD app (Building Barriers. Building Dreams).

BBBD is a productivity and communication app with the following features:
- Home dashboard with reminders and daily usage analytics
- Calendar integration with Google Calendar for events and tasks
- Community features with group chats and personal messaging
- Voice assistant (you) for hands-free interaction

User's voice command: "$prompt"

Please provide a helpful, concise response (max 50 words) that:
1. Addresses their request directly
2. Uses context about BBBD app features when relevant
3. Speaks in a friendly, conversational tone
4. Suggests specific actions they can take in the app if applicable

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
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 150,
        },
      };

      final response = await http
          .post(
            Uri.parse('$_geminiApiUrl?key=$_geminiApiKey'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final candidates = data['candidates'] as List?;

        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final aiResponse = parts[0]['text']?.toString().trim();
            print('Gemini AI response received: $aiResponse');
            return aiResponse;
          }
        }
      } else {
        print('Gemini API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error calling Gemini API: $e');
    }

    print('Falling back to local responses');
    return _getFallbackResponse(prompt);
  }

  // Fallback responses when Gemini AI is not available
  String _getFallbackResponse(String prompt) {
    final lowerPrompt = prompt.toLowerCase();

    if (lowerPrompt.contains('calendar') || lowerPrompt.contains('schedule')) {
      return 'I can help you check your calendar! Go to the Calendar tab to view your events and add new ones.';
    } else if (lowerPrompt.contains('reminder') || lowerPrompt.contains('remind')) {
      return 'I\'ll help you create a reminder! You can add reminders from the Home screen or Calendar tab.';
    } else if (lowerPrompt.contains('message') || lowerPrompt.contains('chat')) {
      return 'You can send messages in the Community tab! Check your groups and personal chats there.';
    } else if (lowerPrompt.contains('notification')) {
      return 'Check the Community tab for your latest notifications and messages from groups and friends.';
    } else if (lowerPrompt.contains('weather')) {
      return 'I can\'t check weather directly, but you can ask me about your calendar, reminders, or app features!';
    } else if (lowerPrompt.contains('hello') || lowerPrompt.contains('hi')) {
      return 'Hello! I\'m your BBBD assistant. I can help you with calendar events, reminders, and messages. What would you like to do?';
    } else if (lowerPrompt.contains('help')) {
      return 'I can help you with calendar management, creating reminders, sending messages, and navigating the app. Just ask me naturally!';
    } else if (lowerPrompt.contains('task') || lowerPrompt.contains('todo')) {
      return 'You can create tasks and todos in the Calendar section. I\'ll help you stay organized!';
    } else if (lowerPrompt.contains('meeting')) {
      return 'For meetings, check your Calendar tab. You can view, create, and manage all your meetings there.';
    } else {
      return 'I\'m here to help! Try asking me about your calendar, creating reminders, or sending messages in the app.';
    }
  }

  // Speak the AI response using Text-to-Speech
  Future<void> _speakResponse(String text) async {
    if (text.isEmpty) return;

    try {
      print('Speaking response: $text');

      // Stop any current speech
      await _flutterTts.stop();

      // Speak the text
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

  // Get available languages
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return languages.cast<String>();
    } catch (e) {
      print('Error getting available languages: $e');
      // Return default languages
      return [
        'en-US',
        'en-GB',
        'es-ES',
        'fr-FR',
        'de-DE',
        'it-IT',
        'pt-BR',
        'ja-JP',
        'ko-KR',
        'zh-CN',
        'hi-IN',
        'ar-SA',
        'ru-RU',
      ];
    }
  }

  // Get available speech-to-text locales
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!_speechEnabled) return [];
    
    try {
      return await _speech.locales();
    } catch (e) {
      print('Error getting available locales: $e');
      return [];
    }
  }

  // Quick actions for common commands
  Future<void> processQuickAction(String action) async {
    print('Processing quick action: $action');

    String response = '';

    switch (action.toLowerCase()) {
      case 'ideas':
        response =
            'Here are some things you can try: "Add a reminder", "Check my calendar", "Send a message", or "What\'s my schedule today?"';
        break;
      case 'help':
        response =
            'I can help you with reminders, calendar events, messages, and general questions. Just speak naturally and I\'ll do my best to assist!';
        break;
      case 'settings':
        response =
            'You can adjust my voice settings, speech rate, and language preferences in the voice settings menu.';
        break;
      case 'history':
        response =
            'Your recent voice commands are saved locally. You can view them in the voice history section.';
        break;
      default:
        response =
            'I\'m here to help! Try asking me about your calendar, reminders, or any questions you have.';
    }

    _currentResponse = response;
    notifyListeners();
    Future.microtask(() => _speakResponse(response));
  }

  // Test voice output
  Future<void> testVoice() async {
    print('Testing voice output...');
    await _speakResponse(
      'Hello! I\'m your BBBD voice assistant. How can I help you today?',
    );
  }

  // Direct command processing (for quick action buttons)
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

  // Check if speech recognition is available
  Future<bool> checkSpeechAvailability() async {
    if (!_isInitialized) return false;
    return await _speech.hasPermission;
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
String _sendToGeminiWorker(String prompt) {
  // Simulate Gemini processing logic
  // Move the Gemini API logic here from _sendToGemini
  // For example purposes, return a dummy response
  return 'Processed response for: \$prompt';
}
