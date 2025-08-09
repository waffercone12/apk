import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isEditing = false;
  
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
          _usernameController.text = _userData?['username'] ?? '';
          _ageController.text = _userData?['age']?.toString() ?? '';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = _auth.currentUser;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: user?.photoURL != null 
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      backgroundColor: Colors.white,
                      child: user?.photoURL == null
                          ? Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                    SizedBox(height: 16),
                    Text(
                      _userData?['username'] ?? 'User',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(_isEditing ? Icons.check : Icons.edit),
                onPressed: _isEditing ? _saveChanges : _toggleEditing,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsSection(),
                  SizedBox(height: 30),
                  _buildPersonalInfoSection(),
                  SizedBox(height: 30),
                  _buildGoalsSection(),
                  SizedBox(height: 30),
                  _buildAssistantSection(),
                  SizedBox(height: 30),
                  _buildSettingsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildStatItem('Streak', '12', 'Days', Icons.local_fire_department, Colors.orange)),
              Container(width: 1, height: 60, color: Theme.of(context).dividerColor),
              Expanded(child: _buildStatItem('Goals', '8', 'Completed', Icons.task_alt, Colors.green)),
              Container(width: 1, height: 60, color: Theme.of(context).dividerColor),
              Expanded(child: _buildStatItem('Score', '850', 'Points', Icons.star, Colors.blue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, String subtitle, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          _buildInfoItem(
            'Username',
            _isEditing,
            controller: _usernameController,
            value: _userData?['username'] ?? 'Not set',
            icon: Icons.person,
          ),
          SizedBox(height: 16),
          _buildInfoItem(
            'Age',
            _isEditing,
            controller: _ageController,
            value: _userData?['age']?.toString() ?? 'Not set',
            icon: Icons.cake,
          ),
          SizedBox(height: 16),
          _buildInfoItem(
            'Email',
            false,
            value: _auth.currentUser?.email ?? 'Not set',
            icon: Icons.email,
          ),
          SizedBox(height: 16),
          _buildInfoItem(
            'Member Since',
            false,
            value: _formatDate(_userData?['createdAt']),
            icon: Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection() {
    final goals = List<String>.from(_userData?['goals'] ?? []);
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Goals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: _showEditGoalsDialog,
              ),
            ],
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: goals.map((goal) => Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Text(
                goal,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Assistant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.blue.shade400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.psychology, color: Colors.white, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData?['assistantName'] ?? 'Assistant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Tone: ${_userData?['assistantTone']?.toString().capitalize() ?? 'Friendly'}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: _showAssistantSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildSettingsItem(
            'Notifications',
            Icons.notifications,
            () => _showNotificationSettings(),
          ),
          _buildSettingsItem(
            'Privacy',
            Icons.privacy_tip,
            () => _showPrivacySettings(),
          ),
          _buildSettingsItem(
            'Data & Storage',
            Icons.storage,
            () => _showDataSettings(),
          ),
          _buildSettingsItem(
            'Help & Support',
            Icons.help,
            () => _showHelpSupport(),
          ),
          Divider(),
          _buildSettingsItem(
            'Sign Out',
            Icons.logout,
            _signOut,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    bool isEditable, {
    TextEditingController? controller,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              SizedBox(height: 4),
              isEditable && controller != null
                  ? TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        border: UnderlineInputBorder(),
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveChanges() async {
    final user = _auth.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'username': _usernameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? _userData?['age'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadUserData();
      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  void _showEditGoalsDialog() {
    final goals = List<String>.from(_userData?['goals'] ?? []);
    final availableGoals = [
      'Build Routine',
      'Detoxification', 
      'Fitness & Health',
      'Mental Wellness',
      'Productivity',
      'Learning & Growth',
      'Career Development',
      'Relationship Building',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Goals'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: availableGoals.map((goal) {
                final isSelected = goals.contains(goal);
                return CheckboxListTile(
                  title: Text(goal),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        goals.add(goal);
                      } else {
                        goals.remove(goal);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updateGoals(goals);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateGoals(List<String> goals) async {
    final user = _auth.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'goals': goals,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadUserData();
    }
  }

  void _showAssistantSettings() {
    showDialog(
      context: context,
      builder: (context) => AssistantSettingsDialog(
        currentName: _userData?['assistantName'] ?? 'Assistant',
        currentTone: _userData?['assistantTone'] ?? 'friendly',
        onSave: (name, tone) async {
          final user = _auth.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
              'assistantName': name,
              'assistantTone': tone,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            await _loadUserData();
          }
        },
      ),
    );
  }

  void _showNotificationSettings() {
    // Implementation for notification settings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification settings coming soon!')),
    );
  }

  void _showPrivacySettings() {
    // Implementation for privacy settings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Privacy settings coming soon!')),
    );
  }

  void _showDataSettings() {
    // Implementation for data settings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data settings coming soon!')),
    );
  }

  void _showHelpSupport() {
    // Implementation for help & support
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Help & support coming soon!')),
    );
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _auth.signOut();
              await _googleSignIn.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    final date = timestamp is Timestamp ? timestamp.toDate() : DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}

class AssistantSettingsDialog extends StatefulWidget {
  final String currentName;
  final String currentTone;
  final Function(String, String) onSave;

  const AssistantSettingsDialog({super.key, 
    required this.currentName,
    required this.currentTone,
    required this.onSave,
  });

  @override
  _AssistantSettingsDialogState createState() => _AssistantSettingsDialogState();
}

class _AssistantSettingsDialogState extends State<AssistantSettingsDialog> {
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
    _nameController = TextEditingController(text: widget.currentName);
    _selectedTone = widget.currentTone;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Assistant Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_nameController.text.trim(), _selectedTone);
            Navigator.pop(context);
          },
          child: Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}