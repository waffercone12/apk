// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/community_screen.dart';
import 'services/auth_service.dart';
import 'services/voice_assistant_service.dart';
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
      ],
      child: MaterialApp(
        title: 'BBBD - Building Barriers. Building Dreams.',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: AuthWrapper(),
        routes: {
          '/login': (context) => LoginScreen(),
          '/signup': (context) => SignupScreen(),
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
          return Scaffold(
            backgroundColor: AppTheme.getBackgroundColor(context),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: AppTheme.getLogoContainerDecoration(context),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.circularRadius),
                      child: Image.asset(
                        'assets/app_icon/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.mic_rounded,
                            size: 60,
                            color: AppTheme.microphoneColor,
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: AppTheme.largeSpacing),
                  
                  // App Title
                  Text(
                    'BBBD',
                    style: AppTheme.getLogoTextStyle(context),
                  ),
                  SizedBox(height: AppTheme.smallSpacing),
                  
                  // Subtitle
                  Text(
                    'Building Barriers. Building Dreams.',
                    style: AppTheme.subtitleTextStyle,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppTheme.extraLargeSpacing),
                  
                  // Loading indicator
                  CircularProgressIndicator(
                    color: AppTheme.getPrimaryColor(context),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: AppTheme.mediumSpacing),
                  
                  Text(
                    'Initializing Voice Assistant...',
                    style: AppTheme.subtitleTextStyle,
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          return MainScreen();
        }

        return LoginScreen();
      },
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

  final List<String> _screenTitles = [
    'Home',
    'Calendar',
    'Community',
    'Menu',
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
  }

  Future<void> _initializeVoiceAssistant() async {
    try {
      final voiceService = Provider.of<VoiceAssistantService>(context, listen: false);
      await voiceService.initialize();
      
      if (mounted) {
        // Show a subtle notification that voice assistant is ready
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.mic, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Voice Assistant Ready! 🎤'),
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

// Enhanced Menu Screen with Voice Settings
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
          // Voice Assistant Quick Access
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppTheme.largeSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              _buildProfileSection(),
              SizedBox(height: AppTheme.largeSpacing),

              // Voice Assistant Status
              _buildVoiceAssistantStatus(),
              SizedBox(height: AppTheme.largeSpacing),

              // Menu Items
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
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy & Security',
                  subtitle: 'Manage your privacy settings',
                  onTap: () => _showPrivacySettings(),
                ),
              ]),

              _buildMenuSection('Voice & AI', [
                MenuItemData(
                  icon: Icons.mic_outlined,
                  title: 'Voice Settings',
                  subtitle: 'Adjust voice recognition and speech',
                  onTap: () => _showVoiceSettings(),
                ),
                MenuItemData(
                  icon: Icons.smart_toy_outlined,
                  title: 'AI Preferences',
                  subtitle: 'Customize Gemini AI behavior',
                  onTap: () => _showAISettings(),
                ),
                MenuItemData(
                  icon: Icons.history,
                  title: 'Voice History',
                  subtitle: 'View past conversations',
                  onTap: () => _showVoiceHistory(),
                ),
              ]),

              _buildMenuSection('Support', [
                MenuItemData(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get help and contact us',
                  onTap: () => _showHelpSupport(),
                ),
                MenuItemData(
                  icon: Icons.feedback_outlined,
                  title: 'Send Feedback',
                  subtitle: 'Help us improve the app',
                  onTap: () => _showFeedback(),
                ),
                MenuItemData(
                  icon: Icons.info_outline,
                  title: 'About BBBD',
                  subtitle: 'Version 1.0.0',
                  onTap: () => _showAbout(),
                ),
              ]),

              SizedBox(height: AppTheme.largeSpacing),

              // Sign Out Button
              _buildSignOutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
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
                      user?.displayName ?? 'User',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    Text(
                      user?.email ?? 'user@example.com',
                      style: AppTheme.subtitleTextStyle,
                    ),
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

  Widget _buildVoiceAssistantStatus() {
    return Consumer<VoiceAssistantService>(
      builder: (context, voiceService, child) {
        return AppTheme.buildThemedCard(
          context: context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.mic,
                    color: voiceService.isInitialized 
                        ? Colors.green 
                        : Colors.orange,
                    size: 24,
                  ),
                  SizedBox(width: AppTheme.smallSpacing),
                  Text(
                    'Voice Assistant',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: voiceService.isInitialized 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      voiceService.isInitialized ? 'ACTIVE' : 'INITIALIZING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: voiceService.isInitialized ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.smallSpacing),
              Text(
                voiceService.isInitialized 
                    ? 'Ready to assist you with voice commands'
                    : 'Setting up speech recognition...',
                style: AppTheme.subtitleTextStyle,
              ),
              SizedBox(height: AppTheme.mediumSpacing),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => voiceService.testVoice(),
                      icon: Icon(Icons.play_arrow, size: 16),
                      label: Text('Test Voice'),
                      style: AppTheme.getPrimaryButtonStyle(context).copyWith(
                        padding: WidgetStateProperty.all(
                          EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.smallSpacing),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showVoiceSettings(),
                      icon: Icon(Icons.settings, size: 16),
                      label: Text('Settings'),
                      style: AppTheme.getSecondaryButtonStyle(context).copyWith(
                        padding: WidgetStateProperty.all(
                          EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
            await authService.signOut();
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

  // Action Methods
  void _quickVoiceAction(VoiceAssistantService voiceService) async {
    await voiceService.processQuickAction('help');
  }

  void _showVoiceSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceSettingsDialog(),
    );
  }

  void _showProfileSettings() {
    _showComingSoon('Profile Settings');
  }

  void _showNotificationSettings() {
    _showComingSoon('Notification Settings');
  }

  void _showPrivacySettings() {
    _showComingSoon('Privacy Settings');
  }

  void _showAISettings() {
    _showComingSoon('AI Preferences');
  }

  void _showVoiceHistory() {
    _showComingSoon('Voice History');
  }

  void _showHelpSupport() {
    _showComingSoon('Help & Support');
  }

  void _showFeedback() {
    _showComingSoon('Send Feedback');
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.getPrimaryColor(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.mic,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: AppTheme.mediumSpacing),
            Text('About BBBD'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Building Barriers. Building Dreams.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            SizedBox(height: AppTheme.mediumSpacing),
            Text('Version: 1.0.0'),
            Text('Build: 1 (Voice Assistant Enabled)'),
            SizedBox(height: AppTheme.mediumSpacing),
            Text(
              'A comprehensive productivity and communication app with AI-powered voice assistant.',
              style: AppTheme.subtitleTextStyle,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon! 🚀'),
        backgroundColor: AppTheme.getPrimaryColor(context),
        behavior: SnackBarBehavior.floating,
      ),
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

// Voice Settings Dialog (Simple version)
class VoiceSettingsDialog extends StatelessWidget {
  const VoiceSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
              'Voice Settings',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
          ),
          
          // Settings content
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.largeSpacing),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.volume_up),
                    title: Text('Speech Volume'),
                    subtitle: Text('Adjust voice output level'),
                    trailing: Text('80%'),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Icon(Icons.speed),
                    title: Text('Speech Rate'),
                    subtitle: Text('How fast the assistant speaks'),
                    trailing: Text('Normal'),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Icon(Icons.language),
                    title: Text('Language'),
                    subtitle: Text('Voice recognition language'),
                    trailing: Text('English (US)'),
                    onTap: () {},
                  ),
                  SizedBox(height: AppTheme.largeSpacing),
                  Consumer<VoiceAssistantService>(
                    builder: (context, voiceService, child) {
                      return ElevatedButton.icon(
                        onPressed: () => voiceService.testVoice(),
                        icon: Icon(Icons.play_arrow),
                        label: Text('Test Voice'),
                        style: AppTheme.getPrimaryButtonStyle(context),
                      );
                    },
                  ),
                ],
              ),
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