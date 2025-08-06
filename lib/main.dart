// File: lib/main.dart (Updated)
import 'package:BBBD/models/assistant_personality.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/voice_onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/community_screen.dart';
import 'services/auth_service.dart';
import 'services/voice_assistant_service.dart';
import 'services/user_profile_service.dart';
import 'theme/default_theme.dart';
import 'widgets/nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => VoiceAssistantService()),
        ChangeNotifierProvider(create: (_) => UserProfileService()),
      ],
      child: MaterialApp(
        title: 'BBBD - Building Barriers. Building Dreams.',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: AuthWrapper(),
        routes: {
          '/login': (context) => LoginScreen(),
          '/onboarding': (context) => VoiceOnboardingScreen(),
          '/home': (context) => MainScreen(),
          '/calendar': (context) => CalendarScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen(context);
        }

        if (snapshot.hasData) {
          // User is authenticated, check onboarding status
          return OnboardingChecker();
        }

        // User not authenticated, show login
        return LoginScreen();
      },
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey[300]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.asset(
                  'assets/app_icon/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.mic_rounded,
                      size: 60,
                      color: Colors.black,
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: AppTheme.largeSpacing),
            
            // App Title
            Text(
              'BBBD',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: AppTheme.smallSpacing),
            
            // Subtitle
            Text(
              'Building Barriers. Building Dreams.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.extraLargeSpacing),
            
            // Loading indicator
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            SizedBox(height: AppTheme.mediumSpacing),
            
            Text(
              'Initializing AI Coach...',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingChecker extends StatefulWidget {
  const OnboardingChecker({super.key});

  @override
  _OnboardingCheckerState createState() => _OnboardingCheckerState();
}

class _OnboardingCheckerState extends State<OnboardingChecker> {
  bool _isChecking = true;
  
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final userProfileService = Provider.of<UserProfileService>(context, listen: false);
      final hasCompleted = await userProfileService.checkUserOnboardingStatus();
      
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
        
        // Navigate based on onboarding status
        await Future.delayed(Duration(milliseconds: 500)); // Small delay for smooth transition
        
        if (hasCompleted) {
          // Load user's assistant personality and settings
          final profile = userProfileService.currentProfile;
          if (profile != null) {
            final voiceService = Provider.of<VoiceAssistantService>(context, listen: false);
            voiceService.setPersonality(profile.personality);
            voiceService.setWakeWord(profile.assistantName);
          }
          
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainScreen()),
            );
          }
        } else {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => VoiceOnboardingScreen()),
            );
          }
        }
      }
    } catch (e) {
      print('Error checking onboarding status: $e');
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
        
        // Default to onboarding screen on error
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => VoiceOnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              SizedBox(height: AppTheme.largeSpacing),
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
              SizedBox(height: AppTheme.mediumSpacing),
              Text(
                'Setting up your AI coach...',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // This should not be reached, but return loading screen as fallback
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;

  final List<Widget> _screens = [
    HomeScreen(),
    CalendarScreen(),
    CommunityScreen(),
    MenuScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _animationController = AnimationController(
      duration: AppTheme.shortAnimation,
      vsync: this,
    );
    
    // Initialize voice assistant when main screen loads
    _initializeVoiceAssistant();
    
    // Update user's last active timestamp
    _updateLastActive();
  }

  Future<void> _initializeVoiceAssistant() async {
    try {
      final voiceService = Provider.of<VoiceAssistantService>(context, listen: false);
      await voiceService.initialize();
      
      // Load user's personality settings
      final userProfileService = Provider.of<UserProfileService>(context, listen: false);
      final profile = userProfileService.currentProfile;
      
      if (profile != null) {
        voiceService.setPersonality(profile.personality);
        voiceService.setWakeWord(profile.assistantName);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.mic, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('${profile?.assistantName ?? 'AI Coach'} is ready! 🎤'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error initializing voice assistant: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Voice Assistant unavailable'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateLastActive() async {
    try {
      final userProfileService = Provider.of<UserProfileService>(context, listen: false);
      await userProfileService.updateLastActive();
    } catch (e) {
      print('Error updating last active: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: PageView(
        controller: _pageController,
        children: _screens,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          _animationController.forward().then((_) {
            _animationController.reset();
          });
        },
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: AppTheme.mediumAnimation,
            curve: Curves.easeInOutCubic,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

// Enhanced Menu Screen with Profile Management
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Menu',
          style: AppTheme.getAppBarTitleStyle(context),
        ),
        centerTitle: true,
        actions: [
          Consumer<VoiceAssistantService>(
            builder: (context, voiceService, child) {
              return IconButton(
                onPressed: voiceService.isInitialized 
                    ? () => _quickVoiceAction(voiceService)
                    : null,
                icon: Icon(
                  Icons.mic,
                  color: voiceService.isInitialized 
                      ? AppTheme.getPrimaryColor(context)
                      : AppTheme.greyMedium,
                ),
                tooltip: 'Quick Voice Command',
              );
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer2<UserProfileService, VoiceAssistantService>(
          builder: (context, profileService, voiceService, child) {
            final profile = profileService.currentProfile;
            
            return SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.largeSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  _buildProfileSection(profile),
                  SizedBox(height: AppTheme.largeSpacing),

                  // AI Assistant Status
                  _buildAIAssistantStatus(profile, voiceService),
                  SizedBox(height: AppTheme.largeSpacing),

                  // Menu Items
                  _buildMenuSection('AI Coach', [
                    MenuItemData(
                      icon: Icons.psychology,
                      title: 'Change Personality',
                      subtitle: 'Switch ${profile?.assistantName ?? 'AI'} personality style',
                      onTap: () => _showPersonalitySettings(profile, voiceService),
                    ),
                    MenuItemData(
                      icon: Icons.drive_file_rename_outline,
                      title: 'Rename Assistant',
                      subtitle: 'Change your AI coach\'s name',
                      onTap: () => _showRenameAssistant(profile, voiceService),
                    ),
                    MenuItemData(
                      icon: Icons.mic_outlined,
                      title: 'Voice Settings',
                      subtitle: 'Adjust speech and recognition',
                      onTap: () => _showVoiceSettings(),
                    ),
                  ]),

                  _buildMenuSection('Progress', [
                    MenuItemData(
                      icon: Icons.trending_up,
                      title: 'My Progress',
                      subtitle: 'View your growth journey',
                      onTap: () => _showProgress(profileService),
                    ),
                    MenuItemData(
                      icon: Icons.local_fire_department,
                      title: 'Streak & Goals',
                      subtitle: 'Track daily consistency',
                      onTap: () => _showStreakGoals(profile),
                    ),
                  ]),

                  _buildMenuSection('General', [
                    MenuItemData(
                      icon: Icons.person_outline,
                      title: 'Profile Settings',
                      subtitle: 'Manage your account',
                      onTap: () => _showProfileSettings(),
                    ),
                    MenuItemData(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      subtitle: 'Configure alerts and reminders',
                      onTap: () => _showNotificationSettings(),
                    ),
                    MenuItemData(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'Get help and contact us',
                      onTap: () => _showHelpSupport(),
                    ),
                  ]),

                  SizedBox(height: AppTheme.largeSpacing),

                  // Sign Out Button
                  _buildSignOutButton(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileSection(UserProfile? profile) {
    return AppTheme.buildThemedCard(
      context: context,
      child: Consumer<AuthService>(
        builder: (context, authService, child) {
          final user = authService.currentUser;
          return Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: AppTheme.getLogoContainerDecoration(context),
                child: user?.photoURL != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.network(
                          user!.photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              color: AppTheme.microphoneColor,
                              size: 30,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: AppTheme.microphoneColor,
                        size: 30,
                      ),
              ),
              SizedBox(width: AppTheme.mediumSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.name ?? user?.displayName ?? 'User',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    Text(
                      user?.email ?? 'user@example.com',
                      style: AppTheme.subtitleTextStyle,
                    ),
                    if (profile?.primaryChallenge != null) ...[
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Focus: ${profile!.primaryChallenge}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getPrimaryColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showProfileSettings(),
                icon: Icon(
                  Icons.edit,
                  color: AppTheme.getIconColor(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAIAssistantStatus(UserProfile? profile, VoiceAssistantService voiceService) {
    final assistantName = profile?.assistantName ?? 'AI Coach';
    final personality = profile?.personality ?? AssistantPersonality.supportiveFriend;
    
    return AppTheme.buildThemedCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                personality.info.emoji,
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(width: AppTheme.smallSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assistantName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    Text(
                      '${personality.info.name} personality',
                      style: AppTheme.subtitleTextStyle,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: voiceService.isInitialized 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      voiceService.isInitialized ? Icons.check_circle : Icons.pending,
                      size: 12,
                      color: voiceService.isInitialized ? Colors.green : Colors.grey,
                    ),
                    SizedBox(width: 4),
                    Text(
                      voiceService.isInitialized ? 'READY' : 'LOADING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: voiceService.isInitialized ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.mediumSpacing),
          
          // Wake word display
          Container(
            padding: EdgeInsets.all(AppTheme.smallSpacing),
            decoration: BoxDecoration(
              color: AppTheme.getBackgroundColor(context),
              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            ),
            child: Row(
              children: [
                Icon(Icons.record_voice_over, size: 16, color: AppTheme.getIconColor(context)),
                SizedBox(width: AppTheme.smallSpacing),
                Text(
                  'Say "Hey $assistantName" to wake up',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getSubtitleColor(context),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: AppTheme.mediumSpacing),
          
          // Quick test button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: voiceService.isInitialized ? () => voiceService.testVoice() : null,
              icon: Icon(Icons.play_arrow, size: 16),
              label: Text('Test Voice'),
              style: AppTheme.getPrimaryButtonStyle(context).copyWith(
                padding: WidgetStateProperty.all(
                  EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<MenuItemData> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextColor(context),
          ),
        ),
        SizedBox(height: AppTheme.mediumSpacing),
        AppTheme.buildThemedCard(
          context: context,
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(
              color: AppTheme.getDividerColor(context),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: Icon(
                  item.icon,
                  color: AppTheme.getIconColor(context),
                ),
                title: Text(
                  item.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                subtitle: Text(
                  item.subtitle,
                  style: AppTheme.subtitleTextStyle,
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppTheme.getIconColor(context),
                ),
                onTap: item.onTap,
              );
            },
          ),
        ),
        SizedBox(height: AppTheme.largeSpacing),
      ],
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await _showSignOutConfirmation();
          if (confirmed == true) {
            final authService = Provider.of<AuthService>(context, listen: false);
            final profileService = Provider.of<UserProfileService>(context, listen: false);
            
            await authService.signOut();
            profileService.clearProfile();
          }
        },
        icon: Icon(Icons.logout, color: Colors.red),
        label: Text('Sign Out', style: TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.red),
          padding: EdgeInsets.symmetric(vertical: AppTheme.mediumSpacing),
        ),
      ),
    );
  }

  // Action methods
  void _quickVoiceAction(VoiceAssistantService voiceService) async {
    await voiceService.processQuickAction('help');
  }

  void _showPersonalitySettings(UserProfile? profile, VoiceAssistantService voiceService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PersonalitySettingsDialog(
        currentPersonality: profile?.personality ?? AssistantPersonality.supportiveFriend,
        onPersonalityChanged: (personality) async {
          voiceService.setPersonality(personality);
          
          final profileService = Provider.of<UserProfileService>(context, listen: false);
          await profileService.updateAssistantSettings(personality: personality);
          
          // Test the new personality
          voiceService.testVoice();
        },
      ),
    );
  }

  void _showRenameAssistant(UserProfile? profile, VoiceAssistantService voiceService) {
    final controller = TextEditingController(text: profile?.assistantName ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename Your AI Coach'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Assistant Name',
                hintText: 'Enter a new name...',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'You\'ll say "Hey [Name]" to wake up your coach',
              style: AppTheme.subtitleTextStyle,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                voiceService.setWakeWord(newName);
                
                final profileService = Provider.of<UserProfileService>(context, listen: false);
                await profileService.updateAssistantSettings(assistantName: newName);
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Assistant renamed to $newName')),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showVoiceSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Voice settings coming soon!')),
    );
  }

  void _showProgress(UserProfileService profileService) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Progress tracking coming soon!')),
    );
  }

  void _showStreakGoals(UserProfile? profile) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Streak & Goals coming soon!')),
    );
  }

  void _showProfileSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile settings coming soon!')),
    );
  }

  void _showNotificationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification settings coming soon!')),
    );
  }

  void _showHelpSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Help & Support coming soon!')),
    );
  }

  Future<bool?> _showSignOutConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
}

// Personality Settings Dialog
class PersonalitySettingsDialog extends StatelessWidget {
  final AssistantPersonality currentPersonality;
  final Function(AssistantPersonality) onPersonalityChanged;

  const PersonalitySettingsDialog({
    super.key,
    required this.currentPersonality,
    required this.onPersonalityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.extraLargeRadius),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.symmetric(vertical: AppTheme.mediumSpacing),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.greyMedium,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: EdgeInsets.all(AppTheme.largeSpacing),
            child: Text(
              'Choose Personality',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
          ),
          
          // Personalities list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.largeSpacing),
              itemCount: AssistantPersonality.values.length,
              itemBuilder: (context, index) {
                final personality = AssistantPersonality.values[index];
                final isSelected = personality == currentPersonality;
                
                return Container(
                  margin: EdgeInsets.only(bottom: AppTheme.mediumSpacing),
                  child: GestureDetector(
                    onTap: () {
                      onPersonalityChanged(personality);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.all(AppTheme.mediumSpacing),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.getPrimaryColor(context).withOpacity(0.1)
                            : AppTheme.getBackgroundColor(context),
                        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                        border: Border.all(
                          color: isSelected 
                              ? AppTheme.getPrimaryColor(context)
                              : AppTheme.getDividerColor(context),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            personality.info.emoji,
                            style: TextStyle(fontSize: 32),
                          ),
                          SizedBox(width: AppTheme.mediumSpacing),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  personality.info.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.getTextColor(context),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  personality.info.description,
                                  style: AppTheme.subtitleTextStyle,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '"${personality.info.samplePhrase}"',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.getSubtitleColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.getPrimaryColor(context),
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MenuItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  MenuItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}