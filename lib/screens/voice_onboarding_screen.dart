// File: lib/screens/voice_onboarding_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_assistant_service.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../theme/default_theme.dart';
import '../models/assistant_personality.dart';

class VoiceOnboardingScreen extends StatefulWidget {
  const VoiceOnboardingScreen({super.key});

  @override
  _VoiceOnboardingScreenState createState() => _VoiceOnboardingScreenState();
}

class _VoiceOnboardingScreenState extends State<VoiceOnboardingScreen>
    with TickerProviderStateMixin {
  
  int _currentStep = 0;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // User selections
  AssistantPersonality? _selectedPersonality;
  String _assistantName = '';
  String _userName = '';
  String _userChallenge = '';
  int _readinessLevel = 5;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _assistantNameController = TextEditingController();
  bool _isTestingVoice = false;
  bool _canProceed = false;

  // Voice testing
  Timer? _voiceTestTimer;
  bool _voiceTestComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVoiceAssistant();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: AppTheme.longAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(1.0, 0.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
  }

  Future<void> _initializeVoiceAssistant() async {
    final voiceService = Provider.of<VoiceAssistantService>(context, listen: false);
    await voiceService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: EdgeInsets.all(AppTheme.largeSpacing),
              child: Column(
                children: [
                  _buildHeader(),
                  SizedBox(height: AppTheme.largeSpacing),
                  Expanded(
                    child: _buildCurrentStep(),
                  ),
                  _buildNavigationButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final steps = ['Personality', 'Name AI', 'About You', 'Test Voice', 'Ready!'];
    
    return Column(
      children: [
        // App Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey[300]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Icon(
            Icons.mic_rounded,
            size: 40,
            color: Colors.black,
          ),
        ),
        
        SizedBox(height: AppTheme.mediumSpacing),
        
        Text(
          'Meet Your AI Coach',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        SizedBox(height: AppTheme.smallSpacing),
        
        Text(
          steps[_currentStep],
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[400],
          ),
        ),

        SizedBox(height: AppTheme.largeSpacing),

        // Progress indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              width: index == _currentStep ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: index <= _currentStep ? Colors.white : Colors.grey[700],
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalitySelection();
      case 1:
        return _buildNameSelection();
      case 2:
        return _buildUserInfo();
      case 3:
        return _buildVoiceTest();
      case 4:
        return _buildCompletion();
      default:
        return Container();
    }
  }

  Widget _buildPersonalitySelection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your AI Coach Personality',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: AppTheme.smallSpacing),
          
          Text(
            'This affects how your AI coach talks and motivates you',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          
          SizedBox(height: AppTheme.largeSpacing),
          
          ...AssistantPersonality.values.map((personality) {
            return Container(
              margin: EdgeInsets.only(bottom: AppTheme.mediumSpacing),
              child: _buildPersonalityCard(personality),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPersonalityCard(AssistantPersonality personality) {
    final isSelected = _selectedPersonality == personality;
    final info = personality.info;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPersonality = personality;
          _canProceed = true;
        });
        
        // Play sample voice
        _playSampleVoice(personality);
      },
      child: AnimatedContainer(
        duration: AppTheme.shortAnimation,
        padding: EdgeInsets.all(AppTheme.mediumSpacing),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.15) : Colors.grey[900],
          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.grey[700]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey[800],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  info.emoji,
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            
            SizedBox(width: AppTheme.mediumSpacing),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.tinySpacing),
                  
                  Text(
                    info.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameSelection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Name Your AI Coach',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: AppTheme.smallSpacing),
          
          Text(
            'You\'ll say "Hey [Name]" to wake up your coach',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          
          SizedBox(height: AppTheme.largeSpacing),
          
          // Suggested names
          Text(
            'Popular Names:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: AppTheme.mediumSpacing),
          
          Wrap(
            spacing: AppTheme.smallSpacing,
            runSpacing: AppTheme.smallSpacing,
            children: ['Alex', 'Jordan', 'Sam', 'Riley', 'Casey', 'Taylor', 'Morgan', 'Avery'].map((name) {
              return GestureDetector(
                onTap: () => _selectSuggestedName(name),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.mediumSpacing,
                    vertical: AppTheme.smallSpacing,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(AppTheme.largeRadius),
                    border: Border.all(color: Colors.grey[600]!),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          SizedBox(height: AppTheme.largeSpacing),
          
          // Custom name input
          Text(
            'Or choose your own:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: AppTheme.mediumSpacing),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: TextField(
              controller: _assistantNameController,
              style: TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Enter a name...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(AppTheme.mediumSpacing),
                prefixIcon: Icon(Icons.person, color: Colors.grey[400]),
              ),
              onChanged: (value) {
                setState(() {
                  _assistantName = value.trim();
                  _canProceed = _assistantName.isNotEmpty;
                });
              },
            ),
          ),
          
          if (_assistantName.isNotEmpty) ...[
            SizedBox(height: AppTheme.largeSpacing),
            Container(
              padding: EdgeInsets.all(AppTheme.mediumSpacing),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
              ),
              child: Row(
                children: [
                  Icon(Icons.mic, color: Colors.white),
                  SizedBox(width: AppTheme.smallSpacing),
                  Text(
                    'You\'ll say: "Hey $_assistantName"',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell Us About Yourself',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: AppTheme.smallSpacing),
          
          Text(
            'This helps your AI coach understand you better',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          
          SizedBox(height: AppTheme.largeSpacing),
          
          // Name input
          _buildInputField(
            label: 'What\'s your name?',
            controller: _nameController,
            hint: 'Enter your name',
            icon: Icons.person,
            onChanged: (value) {
              setState(() {
                _userName = value.trim();
                _updateCanProceed();
              });
            },
          ),
          
          SizedBox(height: AppTheme.largeSpacing),
          
          // Challenge selection
          Text(
            'What\'s your biggest challenge right now?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: AppTheme.mediumSpacing),
          
          ...['Lack of discipline', 'Depression/anxiety', 'Addiction struggles', 'Relationship issues', 'Career stagnation', 'Physical health'].map((challenge) {
            return Container(
              margin: EdgeInsets.only(bottom: AppTheme.smallSpacing),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _userChallenge = challenge;
                    _updateCanProceed();
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(AppTheme.mediumSpacing),
                  decoration: BoxDecoration(
                    color: _userChallenge == challenge 
                        ? Colors.white.withOpacity(0.15) 
                        : Colors.grey[900],
                    borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                    border: Border.all(
                      color: _userChallenge == challenge ? Colors.white : Colors.grey[700]!,
                      width: _userChallenge == challenge ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _userChallenge == challenge ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: Colors.white,
                      ),
                      SizedBox(width: AppTheme.mediumSpacing),
                      Text(
                        challenge,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          
          SizedBox(height: AppTheme.largeSpacing),
          
          // Readiness level
          Text(
            'How ready are you to change? (1-10)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: AppTheme.mediumSpacing),
          
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.grey[700],
              thumbColor: Colors.white,
              overlayColor: Colors.white.withOpacity(0.2),
            ),
            child: Slider(
              value: _readinessLevel.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _readinessLevel.toString(),
              onChanged: (value) {
                setState(() {
                  _readinessLevel = value.round();
                });
              },
            ),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Not ready', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              Text('Extremely ready', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceTest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Test Your Voice Connection',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: AppTheme.smallSpacing),
        
        Text(
          'Let\'s make sure $_assistantName can hear you clearly',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[400],
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: AppTheme.extraLargeSpacing),
        
        // Voice test button
        Consumer<VoiceAssistantService>(
          builder: (context, voiceService, child) {
            return GestureDetector(
              onTap: _isTestingVoice ? null : () => _startVoiceTest(voiceService),
              child: AnimatedContainer(
                duration: AppTheme.mediumAnimation,
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isTestingVoice 
                        ? [Colors.blue[400]!, Colors.blue[600]!]
                        : [Colors.white, Colors.grey[300]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      spreadRadius: 3,
                      blurRadius: 20,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: Icon(
                  _isTestingVoice ? Icons.mic : Icons.mic_none,
                  color: _isTestingVoice ? Colors.white : Colors.black,
                  size: 60,
                ),
              ),
            );
          },
        ),
        
        SizedBox(height: AppTheme.largeSpacing),
        
        Text(
          _isTestingVoice 
              ? 'Say: "Hey $_assistantName, can you hear me?"'
              : 'Tap the microphone to start',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        
        if (_voiceTestComplete) ...[
          SizedBox(height: AppTheme.largeSpacing),
          Container(
            padding: EdgeInsets.all(AppTheme.mediumSpacing),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: AppTheme.smallSpacing),
                Text(
                  'Voice test successful!',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletion() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[400]!, Colors.green[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            color: Colors.white,
            size: 50,
          ),
        ),
        
        SizedBox(height: AppTheme.largeSpacing),
        
        Text(
          'You\'re All Set!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: AppTheme.mediumSpacing),
        
        Text(
          'Meet $_assistantName, your new AI coach!',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[400],
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: AppTheme.largeSpacing),
        
        Container(
          padding: EdgeInsets.all(AppTheme.largeSpacing),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
          ),
          child: Column(
            children: [
              Text(
                'Quick Tips:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: AppTheme.smallSpacing),
              _buildTip('🗣️', 'Say "Hey $_assistantName" to wake up'),
              _buildTip('💪', 'Ask for motivation when struggling'),
              _buildTip('📅', 'Get daily plans and reminders'),
              _buildTip('🎯', 'Track your progress together'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTip(String emoji, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.tinySpacing),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: AppTheme.smallSpacing),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: AppTheme.smallSpacing),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(AppTheme.mediumSpacing),
              prefixIcon: Icon(icon, color: Colors.grey[400]),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: EdgeInsets.only(top: AppTheme.largeSpacing),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _goToPreviousStep,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white),
                  padding: EdgeInsets.symmetric(vertical: AppTheme.mediumSpacing),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          
          if (_currentStep > 0) SizedBox(width: AppTheme.mediumSpacing),
          
          Expanded(
            flex: _currentStep > 0 ? 2 : 1,
            child: ElevatedButton(
              onPressed: _canProceed ? _goToNextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: AppTheme.mediumSpacing),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                ),
              ),
              child: Text(
                _currentStep == 4 ? 'Start Coaching!' : 'Continue',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectSuggestedName(String name) {
    setState(() {
      _assistantName = name;
      _assistantNameController.text = name;
      _canProceed = true;
    });
  }

  void _updateCanProceed() {
    setState(() {
      _canProceed = _userName.isNotEmpty && _userChallenge.isNotEmpty;
    });
  }

  void _playSampleVoice(AssistantPersonality personality) {
    final voiceService = Provider.of<VoiceAssistantService>(context, listen: false);
    final sampleText = personality.info.samplePhrase;
    voiceService.speakWithPersonality(sampleText, personality);
  }

  Future<void> _startVoiceTest(VoiceAssistantService voiceService) async {
    setState(() {
      _isTestingVoice = true;
      _voiceTestComplete = false;
    });

    try {
      // Start listening for the wake word
      await voiceService.startListening();
      
      // Set up a timer to stop listening after 10 seconds
      _voiceTestTimer = Timer(Duration(seconds: 10), () {
        if (_isTestingVoice) {
          _stopVoiceTest(voiceService);
        }
      });

      // Listen for specific phrases
      voiceService.onVoiceTestResult = (recognized) {
        if (recognized.toLowerCase().contains('hey ${_assistantName.toLowerCase()}')) {
          _completeVoiceTest(voiceService);
        }
      };

    } catch (e) {
      _stopVoiceTest(voiceService);
    }
  }

  void _stopVoiceTest(VoiceAssistantService voiceService) {
    setState(() {
      _isTestingVoice = false;
    });
    _voiceTestTimer?.cancel();
    voiceService.stopListening();
  }

  void _completeVoiceTest(VoiceAssistantService voiceService) {
    setState(() {
      _isTestingVoice = false;
      _voiceTestComplete = true;
      _canProceed = true;
    });
    
    _voiceTestTimer?.cancel();
    voiceService.stopListening();
    
    // AI responds
    final personality = _selectedPersonality!;
    voiceService.speakWithPersonality(
      personality.info.testResponse,
      personality,
    );
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _canProceed = _validateCurrentStep();
      });
      _slideController.reset();
      _slideController.forward();
    }
  }

  void _goToNextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
        _canProceed = _validateCurrentStep();
      });
      _slideController.reset();
      _slideController.forward();
    } else {
      _completeOnboarding();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _selectedPersonality != null;
      case 1:
        return _assistantName.isNotEmpty;
      case 2:
        return _userName.isNotEmpty && _userChallenge.isNotEmpty;
      case 3:
        return _voiceTestComplete;
      case 4:
        return true;
      default:
        return false;
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      // Save user profile
      final userProfileService = Provider.of<UserProfileService>(context, listen: false);
      await userProfileService.createUserProfile(
        name: _userName,
        assistantName: _assistantName,
        personality: _selectedPersonality!,
        primaryChallenge: _userChallenge,
        readinessLevel: _readinessLevel,
      );

      // Configure voice assistant
      final voiceService = Provider.of<VoiceAssistantService>(context, listen: false);
      voiceService.setPersonality(_selectedPersonality!);
      voiceService.setWakeWord(_assistantName);

      // Navigate to main app
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
      
    } catch (e) {
      print('Error completing onboarding: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _assistantNameController.dispose();
    _voiceTestTimer?.cancel();
    super.dispose();
  }
}