// File: lib/screens/community_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../theme/default_theme.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  // Encryption setup
  final _encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromSecureRandom(32)));
  final _iv = encrypt.IV.fromSecureRandom(16);
  
  // Tab management
  int _selectedTab = 0; // 0: Groups, 1: Personal Chats
  
  // Data streams
  StreamSubscription? _announcementsSubscription;
  StreamSubscription? _groupsSubscription;
  StreamSubscription? _chatsSubscription;
  
  // Data lists
  List<AnnouncementModel> _announcements = [];
  List<GroupModel> _groups = [];
  List<ChatModel> _personalChats = [];
  List<UserModel> _communityMembers = [];
  
  // Loading states
  bool _isLoading = true;
  bool _isCreatingGroup = false;
  
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupRealtimeListeners();
    _loadCommunityMembers();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  void _setupRealtimeListeners() {
    // Listen to announcements
    _announcementsSubscription = _database
        .child('announcements')
        .orderByChild('timestamp')
        .onValue
        .listen(_onAnnouncementsChanged);

    // Listen to groups
    _groupsSubscription = _database
        .child('groups')
        .onValue
        .listen(_onGroupsChanged);

    // Listen to personal chats
    _chatsSubscription = _database
        .child('chats')
        .orderByChild('participants/$_currentUserId')
        .equalTo(true)
        .onValue
        .listen(_onChatsChanged);
  }

  void _onAnnouncementsChanged(DatabaseEvent event) {
    if (event.snapshot.value != null) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        _announcements = data.entries
            .map((e) => AnnouncementModel.fromMap(e.key, e.value))
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _isLoading = false;
      });
    } else {
      setState(() {
        _announcements = [];
        _isLoading = false;
      });
    }
  }

  void _onGroupsChanged(DatabaseEvent event) {
    if (event.snapshot.value != null) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        _groups = data.entries
            .map((e) => GroupModel.fromMap(e.key, e.value))
            .where((group) => group.members.contains(_currentUserId))
            .toList()
          ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      });
    } else {
      setState(() {
        _groups = [];
      });
    }
  }

  void _onChatsChanged(DatabaseEvent event) {
    if (event.snapshot.value != null) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        _personalChats = data.entries
            .map((e) => ChatModel.fromMap(e.key, e.value))
            .toList()
          ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      });
    } else {
      setState(() {
        _personalChats = [];
      });
    }
  }

  Future<void> _loadCommunityMembers() async {
    try {
      print('Loading community members...'); // Debug log
      
      final snapshot = await _database.child('users').once();
      print('Firebase snapshot received: ${snapshot.snapshot.value != null}'); // Debug log
      
      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        print('Users data keys: ${data.keys.toList()}'); // Debug log
        print('Current user ID: $_currentUserId'); // Debug log
        
        final members = data.entries
            .map((e) => UserModel.fromMap(e.key, e.value))
            .where((user) => user.uid != _currentUserId)
            .toList();
            
        print('Loaded ${members.length} community members'); // Debug log
        
        setState(() {
          _communityMembers = members;
        });
        
        // Also create sample users if none exist (for testing)
        if (members.isEmpty) {
          print('No members found, creating sample users...'); // Debug log
          await _createSampleUsers();
        }
      } else {
        print('No users found in database, creating sample users...'); // Debug log
        await _createSampleUsers();
      }
    } catch (e) {
      print('Error loading community members: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading community members: $e')),
      );
      
      // Create sample users as fallback
      await _createSampleUsers();
    }
  }

  // Helper method to create sample users for testing
  Future<void> _createSampleUsers() async {
    try {
      print('Creating sample users...'); // Debug log
      
      final sampleUsers = [
        {
          'uid': 'sample_user_1',
          'username': 'Alice Johnson',
          'email': 'alice@example.com',
          'profileImageUrl': '',
          'phoneNumber': '+1234567890',
          'age': 25,
          'createdAt': ServerValue.timestamp,
        },
        {
          'uid': 'sample_user_2',
          'username': 'Bob Smith',
          'email': 'bob@example.com',
          'profileImageUrl': '',
          'phoneNumber': '+1234567891',
          'age': 30,
          'createdAt': ServerValue.timestamp,
        },
        {
          'uid': 'sample_user_3',
          'username': 'Carol Davis',
          'email': 'carol@example.com',
          'profileImageUrl': '',
          'phoneNumber': '+1234567892',
          'age': 28,
          'createdAt': ServerValue.timestamp,
        },
        {
          'uid': 'sample_user_4',
          'username': 'David Wilson',
          'email': 'david@example.com',
          'profileImageUrl': '',
          'phoneNumber': '+1234567893',
          'age': 32,
          'createdAt': ServerValue.timestamp,
        },
      ];

      // Add sample users to database
      for (final user in sampleUsers) {
        await _database.child('users').child(user['uid'] as String).set(user);
      }
      
      // Also ensure current user is in the database
      await _ensureCurrentUserInDatabase();
      
      print('Sample users created successfully');
      
      // Reload members
      await _loadCommunityMembers();
      
    } catch (e) {
      print('Error creating sample users: $e');
    }
  }

  // Ensure current user exists in the database
  Future<void> _ensureCurrentUserInDatabase() async {
    try {
      if (_currentUserId.isEmpty) return;
      
      final userSnapshot = await _database.child('users').child(_currentUserId).once();
      
      if (!userSnapshot.snapshot.exists) {
        print('Current user not in database, adding...'); // Debug log
        
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final userData = {
            'uid': _currentUserId,
            'username': currentUser.displayName ?? 'Current User',
            'email': currentUser.email ?? 'user@example.com',
            'profileImageUrl': currentUser.photoURL ?? '',
            'phoneNumber': currentUser.phoneNumber ?? '',
            'age': 25,
            'createdAt': ServerValue.timestamp,
            'lastLoginAt': ServerValue.timestamp,
          };
          
          await _database.child('users').child(_currentUserId).set(userData);
          print('Current user added to database');
        }
      }
    } catch (e) {
      print('Error ensuring current user in database: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Community',
          style: AppTheme.getAppBarTitleStyle(context),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showSearchDialog,
            icon: Icon(
              Icons.search,
              color: AppTheme.getIconColor(context),
            ),
          ),
          // Debug button to check members and reload
          IconButton(
            onPressed: () async {
              print('=== DEBUG INFO ===');
              print('Current User ID: $_currentUserId');
              print('Community Members Count: ${_communityMembers.length}');
              print('Members: ${_communityMembers.map((m) => m.username).toList()}');
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Members: ${_communityMembers.length}. Check console for details.'),
                  duration: Duration(seconds: 2),
                ),
              );
              
              // Reload members
              await _loadCommunityMembers();
            },
            icon: Icon(
              Icons.refresh,
              color: AppTheme.getIconColor(context),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: AppTheme.getIconColor(context),
            ),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'create_announcement', child: Text('Create Announcement')),
              PopupMenuItem(value: 'community_settings', child: Text('Community Settings')),
              PopupMenuItem(value: 'member_list', child: Text('View Members')),
              PopupMenuItem(value: 'debug_info', child: Text('🐛 Debug Info')),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refreshData,
                color: AppTheme.getPrimaryColor(context),
                child: CustomScrollView(
                  slivers: [
                    // Announcements Section
                    _buildAnnouncementsSection(),
                    
                    // Tab Selector
                    _buildTabSelector(),
                    
                    // Content based on selected tab
                    _selectedTab == 0 
                        ? _buildGroupsSection()
                        : _buildPersonalChatsSection(),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectedTab == 0 ? _showCreateGroupDialog : _showCreateChatDialog,
        backgroundColor: Colors.black,  // Changed to black
        foregroundColor: Colors.white,  // Changed to white icon
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildAnnouncementsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(AppTheme.mediumSpacing),
        child: AppTheme.buildThemedCard(
          context: context,
          padding: EdgeInsets.all(AppTheme.mediumSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Announcements',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  if (_announcements.isNotEmpty)
                    Text(
                      '${_announcements.length}',
                      style: TextStyle(
                        color: AppTheme.getSubtitleColor(context),
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppTheme.mediumSpacing),
              _announcements.isEmpty
                  ? Container(
                      padding: EdgeInsets.all(AppTheme.largeSpacing),
                      child: Column(
                        children: [
                          Icon(
                            Icons.campaign_outlined,
                            size: 48,
                            color: AppTheme.getSubtitleColor(context),
                          ),
                          SizedBox(height: AppTheme.smallSpacing),
                          Text(
                            'No announcements yet',
                            style: TextStyle(
                              color: AppTheme.getSubtitleColor(context),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: _announcements.take(3).map((announcement) {
                        return _buildAnnouncementItem(announcement);
                      }).toList(),
                    ),
              if (_announcements.length > 3)
                TextButton(
                  onPressed: _showAllAnnouncements,
                  child: Text('View All Announcements'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementItem(AnnouncementModel announcement) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.smallSpacing),
      padding: EdgeInsets.all(AppTheme.mediumSpacing),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(
          color: AppTheme.getDividerColor(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.campaign,
                size: 16,
                color: AppTheme.getPrimaryColor(context),
              ),
              SizedBox(width: AppTheme.smallSpacing),
              Expanded(
                child: Text(
                  announcement.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ),
              Text(
                _formatTimestamp(announcement.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getSubtitleColor(context),
                ),
              ),
            ],
          ),
          if (announcement.content.isNotEmpty) ...[
            SizedBox(height: AppTheme.smallSpacing),
            Text(
              announcement.content,
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: AppTheme.mediumSpacing),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 0),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: AppTheme.mediumSpacing),
                    decoration: BoxDecoration(
                      color: _selectedTab == 0 
                          ? Colors.black  // Changed to black when selected
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                    ),
                    child: Center(
                      child: Text(
                        'Groups',
                        style: TextStyle(
                          color: _selectedTab == 0 
                              ? Colors.white  // White text on black background
                              : AppTheme.getTextColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 1),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: AppTheme.mediumSpacing),
                    decoration: BoxDecoration(
                      color: _selectedTab == 1 
                          ? Colors.black  // Changed to black when selected
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                    ),
                    child: Center(
                      child: Text(
                        'Chats',
                        style: TextStyle(
                          color: _selectedTab == 1 
                              ? Colors.white  // White text on black background
                              : AppTheme.getTextColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsSection() {
    final filteredGroups = _searchQuery.isEmpty
        ? _groups
        : _groups.where((group) =>
            group.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return SliverPadding(
      padding: EdgeInsets.all(AppTheme.mediumSpacing),
      sliver: filteredGroups.isEmpty
          ? SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(AppTheme.extraLargeSpacing),
                child: Column(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 64,
                      color: AppTheme.getSubtitleColor(context),
                    ),
                    SizedBox(height: AppTheme.mediumSpacing),
                    Text(
                      'No groups yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    SizedBox(height: AppTheme.smallSpacing),
                    Text(
                      'Create a group to start chatting with multiple people',
                      style: TextStyle(
                        color: AppTheme.getSubtitleColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final group = filteredGroups[index];
                  return _buildGroupItem(group);
                },
                childCount: filteredGroups.length,
              ),
            ),
    );
  }

  Widget _buildGroupItem(GroupModel group) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.mediumSpacing),
      child: AppTheme.buildThemedCard(
        context: context,
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: AppTheme.getPrimaryColor(context),
            child: group.imageUrl?.isNotEmpty == true
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.network(
                      group.imageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.group,
                        color: AppTheme.microphoneColor,
                      ),
                    ),
                  )
                : Icon(
                    Icons.group,
                    color: AppTheme.microphoneColor,
                  ),
          ),
          title: Text(
            group.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.lastMessage.isNotEmpty 
                    ? _decryptMessage(group.lastMessage)
                    : 'No messages yet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.getSubtitleColor(context),
                ),
              ),
              SizedBox(height: 2),
              Text(
                '${group.members.length} members',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getSubtitleColor(context),
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTimestamp(group.lastMessageTime),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getSubtitleColor(context),
                ),
              ),
              if (group.unreadCount > 0) ...[
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.getPrimaryColor(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${group.unreadCount}',
                    style: TextStyle(
                      color: AppTheme.microphoneColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () => _openGroupChat(group),
          onLongPress: () => _showGroupOptions(group),
        ),
      ),
    );
  }

  Widget _buildPersonalChatsSection() {
    final filteredChats = _searchQuery.isEmpty
        ? _personalChats
        : _personalChats.where((chat) {
            final otherUser = _getOtherUserFromChat(chat);
            return otherUser.username.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

    return SliverPadding(
      padding: EdgeInsets.all(AppTheme.mediumSpacing),
      sliver: filteredChats.isEmpty
          ? SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(AppTheme.extraLargeSpacing),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_outlined,
                      size: 64,
                      color: AppTheme.getSubtitleColor(context),
                    ),
                    SizedBox(height: AppTheme.mediumSpacing),
                    Text(
                      'No chats yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    SizedBox(height: AppTheme.smallSpacing),
                    Text(
                      'Start a conversation with someone from the community',
                      style: TextStyle(
                        color: AppTheme.getSubtitleColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final chat = filteredChats[index];
                  return _buildChatItem(chat);
                },
                childCount: filteredChats.length,
              ),
            ),
    );
  }

  Widget _buildChatItem(ChatModel chat) {
    final otherUser = _getOtherUserFromChat(chat);
    
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.mediumSpacing),
      child: AppTheme.buildThemedCard(
        context: context,
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: AppTheme.getPrimaryColor(context),
            backgroundImage: otherUser.profileImageUrl?.isNotEmpty == true
                ? NetworkImage(otherUser.profileImageUrl!)
                : null,
            child: otherUser.profileImageUrl?.isEmpty != false
                ? Icon(
                    Icons.person,
                    color: AppTheme.microphoneColor,
                  )
                : null,
          ),
          title: Text(
            otherUser.username,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
          ),
          subtitle: Text(
            chat.lastMessage.isNotEmpty 
                ? _decryptMessage(chat.lastMessage)
                : 'No messages yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.getSubtitleColor(context),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTimestamp(chat.lastMessageTime),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getSubtitleColor(context),
                ),
              ),
              if (chat.unreadCount > 0) ...[
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.getPrimaryColor(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${chat.unreadCount}',
                    style: TextStyle(
                      color: AppTheme.microphoneColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () => _openPersonalChat(chat),
          onLongPress: () => _showChatOptions(chat),
        ),
      ),
    );
  }

  // Dialog Methods
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search'),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: _selectedTab == 0 ? 'Search groups...' : 'Search chats...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    List<String> selectedMembers = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Create Group'),
          contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6, // Limit height to 60% of screen
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Group Name',
                      hintText: 'Enter group name',
                    ),
                  ),
                  SizedBox(height: AppTheme.mediumSpacing),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Enter group description',
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: AppTheme.mediumSpacing),
                  SizedBox(
                    height: 150, // Fixed height for member list
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Members:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: AppTheme.smallSpacing),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _communityMembers.isEmpty
                                ? Center(
                                    child: Text(
                                      'Loading members...',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _communityMembers.length,
                                    itemBuilder: (context, index) {
                                      final member = _communityMembers[index];
                                      final isSelected = selectedMembers.contains(member.uid);
                                      
                                      return SizedBox(
                                        height: 48, // Fixed height for each item
                                        child: CheckboxListTile(
                                          dense: true,
                                          value: isSelected,
                                          title: Text(
                                            member.username,
                                            style: TextStyle(fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: Text(
                                            member.email,
                                            style: TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          onChanged: (bool? value) {
                                            setDialogState(() {
                                              if (value == true) {
                                                selectedMembers.add(member.uid);
                                              } else {
                                                selectedMembers.remove(member.uid);
                                              }
                                            });
                                          },
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selectedMembers.isNotEmpty) ...[
                    SizedBox(height: AppTheme.smallSpacing),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${selectedMembers.length} member(s) selected',
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: nameController.text.isNotEmpty
                  ? () async {
                      if (nameController.text.trim().isNotEmpty) {
                        Navigator.pop(context); // Close dialog first
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Center(
                            child: Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.getSurfaceColor(context),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Creating group...'),
                                ],
                              ),
                            ),
                          ),
                        );
                        
                        await _createGroup(
                          nameController.text.trim(),
                          descriptionController.text.trim(),
                          selectedMembers,
                        );
                        
                        Navigator.pop(context); // Close loading dialog
                      }
                    }
                  : null,
              child: Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start New Chat'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _communityMembers.length,
            itemBuilder: (context, index) {
              final member = _communityMembers[index];
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: member.profileImageUrl?.isNotEmpty == true
                      ? NetworkImage(member.profileImageUrl!)
                      : null,
                  child: member.profileImageUrl?.isEmpty != false
                      ? Icon(Icons.person)
                      : null,
                ),
                title: Text(member.username),
                subtitle: Text(member.email),
                onTap: () async {
                  await _createPersonalChat(member.uid);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Navigation Methods
  void _openGroupChat(GroupModel group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatScreen(group: group),
      ),
    );
  }

  void _openPersonalChat(ChatModel chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonalChatScreen(chat: chat),
      ),
    );
  }

  // CRUD Operations
  Future<void> _createGroup(String name, String description, List<String> memberIds) async {
    try {
      setState(() => _isCreatingGroup = true);
      
      final groupRef = _database.child('groups').push();
      final groupId = groupRef.key!;
      
      final members = [_currentUserId, ...memberIds];
      
      final groupData = {
        'id': groupId,
        'name': name,
        'description': description,
        'createdBy': _currentUserId,
        'createdAt': ServerValue.timestamp,
        'lastMessageTime': ServerValue.timestamp,
        'lastMessage': '',
        'members': {for (String uid in members) uid: true},
        'admins': {_currentUserId: true},
        'imageUrl': '',
        'unreadCount': 0,
      };
      
      await groupRef.set(groupData);
      
      // Send system message
      await _sendMessage(
        groupId,
        'Welcome to $name! 🎉',
        MessageType.system,
        isGroup: true,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group created successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating group: $e')),
      );
    } finally {
      setState(() => _isCreatingGroup = false);
    }
  }

  Future<void> _createPersonalChat(String otherUserId) async {
    try {
      // Check if chat already exists
      final existingChat = _personalChats.firstWhere(
        (chat) => chat.participants.contains(otherUserId),
        orElse: () => ChatModel(
          id: '',
          participants: [],
          lastMessage: '',
          lastMessageTime: 0,
          unreadCount: 0,
        ),
      );
      
      if (existingChat.id.isNotEmpty) {
        _openPersonalChat(existingChat);
        return;
      }
      
      final chatRef = _database.child('chats').push();
      final chatId = chatRef.key!;
      
      final chatData = {
        'id': chatId,
        'participants': {
          _currentUserId: true,
          otherUserId: true,
        },
        'createdAt': ServerValue.timestamp,
        'lastMessageTime': ServerValue.timestamp,
        'lastMessage': '',
        'unreadCount': 0,
      };
      
      await chatRef.set(chatData);
      
      // Navigate to chat
      final newChat = ChatModel.fromMap(chatId, chatData);
      _openPersonalChat(newChat);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating chat: $e')),
      );
    }
  }

  Future<void> _sendMessage(
    String chatId,
    String message,
    MessageType type, {
    bool isGroup = false,
  }) async {
    try {
      final messageRef = _database
          .child(isGroup ? 'group_messages' : 'chat_messages')
          .child(chatId)
          .push();
      
      final encryptedMessage = _encryptMessage(message);
      
      final messageData = {
        'id': messageRef.key,
        'senderId': _currentUserId,
        'message': encryptedMessage,
        'timestamp': ServerValue.timestamp,
        'type': type.toString().split('.').last,
        'edited': false,
        'deleted': false,
      };
      
      await messageRef.set(messageData);
      
      // Update chat/group with last message
      final updateData = {
        'lastMessage': encryptedMessage,
        'lastMessageTime': ServerValue.timestamp,
      };
      
      await _database
          .child(isGroup ? 'groups' : 'chats')
          .child(chatId)
          .update(updateData);
          
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  // Options and Actions
  void _showGroupOptions(GroupModel group) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit Group'),
              onTap: () {
                Navigator.pop(context);
                _showEditGroupDialog(group);
              },
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Manage Members'),
              onTap: () {
                Navigator.pop(context);
                _showManageMembersDialog(group);
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('Group Info'),
              onTap: () {
                Navigator.pop(context);
                _showGroupInfoDialog(group);
              },
            ),
            if (group.admins.contains(_currentUserId))
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete Group', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteGroup(group);
                },
              ),
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.orange),
              title: Text('Leave Group', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
                _confirmLeaveGroup(group);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChatOptions(ChatModel chat) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.info),
              title: Text('Chat Info'),
              onTap: () {
                Navigator.pop(context);
                _showChatInfoDialog(chat);
              },
            ),
            ListTile(
              leading: Icon(Icons.block, color: Colors.orange),
              title: Text('Block User', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
                _confirmBlockUser(chat);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Chat', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteChat(chat);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGroupDialog(GroupModel group) {
    final nameController = TextEditingController(text: group.name);
    final descriptionController = TextEditingController(text: group.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Group Name'),
            ),
            SizedBox(height: AppTheme.mediumSpacing),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
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
              await _updateGroup(
                group.id,
                nameController.text.trim(),
                descriptionController.text.trim(),
              );
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showManageMembersDialog(GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage Members'),
        contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current members
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: group.members.length,
                    itemBuilder: (context, index) {
                      final memberId = group.members[index];
                      final member = _communityMembers.firstWhere(
                        (user) => user.uid == memberId,
                        orElse: () => UserModel(
                          uid: memberId,
                          username: 'Unknown User',
                          email: '',
                        ),
                      );
                      final isAdmin = group.admins.contains(memberId);
                      final canRemove = group.admins.contains(_currentUserId) && 
                                      memberId != _currentUserId;

                      return SizedBox(
                        height: 64,
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundImage: member.profileImageUrl?.isNotEmpty == true
                                ? NetworkImage(member.profileImageUrl!)
                                : null,
                            child: member.profileImageUrl?.isEmpty != false
                                ? Icon(Icons.person, size: 16)
                                : null,
                          ),
                          title: Text(
                            member.username,
                            style: TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            isAdmin ? 'Admin' : 'Member',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: canRemove
                              ? PopupMenuButton<String>(
                                  onSelected: (action) async {
                                    if (action == 'remove') {
                                      await _removeMemberFromGroup(group.id, memberId);
                                    } else if (action == 'make_admin') {
                                      await _makeGroupAdmin(group.id, memberId);
                                    } else if (action == 'remove_admin') {
                                      await _removeGroupAdmin(group.id, memberId);
                                    }
                                    Navigator.pop(context); // Refresh the dialog
                                  },
                                  itemBuilder: (context) => [
                                    if (!isAdmin)
                                      PopupMenuItem(
                                        value: 'make_admin',
                                        child: Text('Make Admin'),
                                      ),
                                    if (isAdmin && group.admins.length > 1)
                                      PopupMenuItem(
                                        value: 'remove_admin',
                                        child: Text('Remove Admin'),
                                      ),
                                    PopupMenuItem(
                                      value: 'remove',
                                      child: Text('Remove from Group'),
                                    ),
                                  ],
                                )
                              : isAdmin
                                  ? Icon(Icons.admin_panel_settings, color: Colors.orange, size: 20)
                                  : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: AppTheme.mediumSpacing),
              // Add new members button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddMembersDialog(group);
                  },
                  icon: Icon(Icons.person_add),
                  label: Text('Add Members'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showAddMembersDialog(GroupModel group) {
    final availableMembers = _communityMembers
        .where((user) => !group.members.contains(user.uid))
        .toList();

    if (availableMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All community members are already in the group')),
      );
      return;
    }

    List<String> selectedMembers = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Members'),
          contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedMembers.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${selectedMembers.length} member(s) selected',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getPrimaryColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: AppTheme.smallSpacing),
                ],
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableMembers.length,
                      itemBuilder: (context, index) {
                        final member = availableMembers[index];
                        final isSelected = selectedMembers.contains(member.uid);
                        
                        return SizedBox(
                          height: 56,
                          child: CheckboxListTile(
                            dense: true,
                            value: isSelected,
                            title: Text(
                              member.username,
                              style: TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              member.email,
                              style: TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  selectedMembers.add(member.uid);
                                } else {
                                  selectedMembers.remove(member.uid);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedMembers.isNotEmpty
                  ? () async {
                      Navigator.pop(context);
                      await _addMembersToGroup(group.id, selectedMembers);
                    }
                  : null,
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // Group Management Methods
  Future<void> _updateGroup(String groupId, String name, String description) async {
    try {
      await _database.child('groups').child(groupId).update({
        'name': name,
        'description': description,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating group: $e')),
      );
    }
  }

  Future<void> _addMembersToGroup(String groupId, List<String> memberIds) async {
    try {
      final updates = <String, dynamic>{};
      for (String memberId in memberIds) {
        updates['members/$memberId'] = true;
      }
      
      await _database.child('groups').child(groupId).update(updates);
      
      // Send system message
      await _sendMessage(
        groupId,
        '${memberIds.length} new member(s) added to the group',
        MessageType.system,
        isGroup: true,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Members added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding members: $e')),
      );
    }
  }

  Future<void> _removeMemberFromGroup(String groupId, String memberId) async {
    try {
      await _database.child('groups').child(groupId).child('members').child(memberId).remove();
      await _database.child('groups').child(groupId).child('admins').child(memberId).remove();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing member: $e')),
      );
    }
  }

  Future<void> _makeGroupAdmin(String groupId, String memberId) async {
    try {
      await _database.child('groups').child(groupId).child('admins').child(memberId).set(true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member promoted to admin')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error making admin: $e')),
      );
    }
  }

  Future<void> _removeGroupAdmin(String groupId, String memberId) async {
    try {
      await _database.child('groups').child(groupId).child('admins').child(memberId).remove();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admin privileges removed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing admin: $e')),
      );
    }
  }

  // Confirmation Dialogs
  void _confirmDeleteGroup(GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Group'),
        content: Text('Are you sure you want to delete "${group.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _deleteGroup(group.id);
              Navigator.pop(context);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveGroup(GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave Group'),
        content: Text('Are you sure you want to leave "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              await _leaveGroup(group.id);
              Navigator.pop(context);
            },
            child: Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteChat(ChatModel chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Chat'),
        content: Text('Are you sure you want to delete this chat? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _deleteChat(chat.id);
              Navigator.pop(context);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmBlockUser(ChatModel chat) {
    final otherUser = _getOtherUserFromChat(chat);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block User'),
        content: Text('Are you sure you want to block ${otherUser.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              await _blockUser(otherUser.uid);
              Navigator.pop(context);
            },
            child: Text('Block'),
          ),
        ],
      ),
    );
  }

  // Delete/Leave/Block Operations
  Future<void> _deleteGroup(String groupId) async {
    try {
      await _database.child('groups').child(groupId).remove();
      await _database.child('group_messages').child(groupId).remove();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting group: $e')),
      );
    }
  }

  Future<void> _leaveGroup(String groupId) async {
    try {
      await _database.child('groups').child(groupId).child('members').child(_currentUserId).remove();
      await _database.child('groups').child(groupId).child('admins').child(_currentUserId).remove();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Left group successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving group: $e')),
      );
    }
  }

  Future<void> _deleteChat(String chatId) async {
    try {
      await _database.child('chats').child(chatId).remove();
      await _database.child('chat_messages').child(chatId).remove();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting chat: $e')),
      );
    }
  }

  Future<void> _blockUser(String userId) async {
    try {
      await _database.child('users').child(_currentUserId).child('blockedUsers').child(userId).set(true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User blocked successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error blocking user: $e')),
      );
    }
  }

  // Info Dialogs
  void _showGroupInfoDialog(GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group.description.isNotEmpty) ...[
              Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(group.description),
              SizedBox(height: AppTheme.mediumSpacing),
            ],
            Text('Members: ${group.members.length}'),
            Text('Created: ${_formatTimestamp(group.createdAt)}'),
            Text('Admins: ${group.admins.length}'),
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

  void _showChatInfoDialog(ChatModel chat) {
    final otherUser = _getOtherUserFromChat(chat);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chat Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: otherUser.profileImageUrl?.isNotEmpty == true
                    ? NetworkImage(otherUser.profileImageUrl!)
                    : null,
                child: otherUser.profileImageUrl?.isEmpty != false
                    ? Icon(Icons.person)
                    : null,
              ),
              title: Text(otherUser.username),
              subtitle: Text(otherUser.email),
            ),
            SizedBox(height: AppTheme.mediumSpacing),
            Text('Chat started: ${_formatTimestamp(chat.createdAt ?? 0)}'),
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

  // Menu Actions
  void _handleMenuAction(String action) {
    switch (action) {
      case 'create_announcement':
        _showCreateAnnouncementDialog();
        break;
      case 'community_settings':
        _showCommunitySettings();
        break;
      case 'member_list':
        _showMemberList();
        break;
      case 'debug_info':
        _showDebugInfo();
        break;
    }
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🐛 Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current User ID:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_currentUserId.isEmpty ? 'Not logged in' : _currentUserId),
              SizedBox(height: 16),
              Text('Community Members:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Count: ${_communityMembers.length}'),
              SizedBox(height: 8),
              if (_communityMembers.isEmpty)
                Text('❌ No members found!')
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _communityMembers.map((member) => 
                    Text('• ${member.username} (${member.email})')
                  ).toList(),
                ),
              SizedBox(height: 16),
              Text('Database Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Loading: $_isLoading'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _loadCommunityMembers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reloaded community members')),
                  );
                },
                child: Text('🔄 Reload Members'),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _createSampleUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Created sample users')),
                  );
                },
                child: Text('➕ Create Sample Users'),
              ),
            ],
          ),
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

  void _showCreateAnnouncementDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'Enter announcement title',
              ),
            ),
            SizedBox(height: AppTheme.mediumSpacing),
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                labelText: 'Content',
                hintText: 'Enter announcement content',
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: titleController.text.isNotEmpty
                ? () async {
                    await _createAnnouncement(
                      titleController.text.trim(),
                      contentController.text.trim(),
                    );
                    Navigator.pop(context);
                  }
                : null,
            child: Text('Post'),
          ),
        ],
      ),
    );
  }

  Future<void> _createAnnouncement(String title, String content) async {
    try {
      final announcementRef = _database.child('announcements').push();
      
      final announcementData = {
        'id': announcementRef.key,
        'title': title,
        'content': content,
        'createdBy': _currentUserId,
        'timestamp': ServerValue.timestamp,
      };
      
      await announcementRef.set(announcementData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Announcement posted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting announcement: $e')),
      );
    }
  }

  void _showCommunitySettings() {
    // Implement community settings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Community settings coming soon')),
    );
  }

  void _showMemberList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Community Members'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _communityMembers.length,
            itemBuilder: (context, index) {
              final member = _communityMembers[index];
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: member.profileImageUrl?.isNotEmpty == true
                      ? NetworkImage(member.profileImageUrl!)
                      : null,
                  child: member.profileImageUrl?.isEmpty != false
                      ? Icon(Icons.person)
                      : null,
                ),
                title: Text(member.username),
                subtitle: Text(member.email),
                trailing: IconButton(
                  icon: Icon(Icons.chat),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _createPersonalChat(member.uid);
                  },
                ),
              );
            },
          ),
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

  void _showAllAnnouncements() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementsScreen(announcements: _announcements),
      ),
    );
  }

  // Utility Methods
  UserModel _getOtherUserFromChat(ChatModel chat) {
    final otherUserId = chat.participants.firstWhere(
      (id) => id != _currentUserId,
      orElse: () => '',
    );
    
    return _communityMembers.firstWhere(
      (user) => user.uid == otherUserId,
      orElse: () => UserModel(
        uid: otherUserId,
        username: 'Unknown User',
        email: '',
      ),
    );
  }

  String _encryptMessage(String message) {
    try {
      return _encrypter.encrypt(message, iv: _iv).base64;
    } catch (e) {
      return message; // Fallback to plain text if encryption fails
    }
  }

  String _decryptMessage(String encryptedMessage) {
    try {
      return _encrypter.decrypt64(encryptedMessage, iv: _iv);
    } catch (e) {
      return encryptedMessage; // Return as-is if decryption fails
    }
  }

  String _formatTimestamp(int timestamp) {
    if (timestamp == 0) return '';
    
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _refreshData() async {
    // Refresh is handled by real-time listeners
    await Future.delayed(Duration(seconds: 1));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _announcementsSubscription?.cancel();
    _groupsSubscription?.cancel();
    _chatsSubscription?.cancel();
    super.dispose();
  }
}

// Data Models
class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String createdBy;
  final int timestamp;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdBy,
    required this.timestamp,
  });

  factory AnnouncementModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return AnnouncementModel(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdBy: map['createdBy'] ?? '',
      timestamp: map['timestamp'] ?? 0,
    );
  }
}

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final int createdAt;
  final int lastMessageTime;
  final String lastMessage;
  final List<String> members;
  final List<String> admins;
  final String? imageUrl;
  final int unreadCount;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.lastMessageTime,
    required this.lastMessage,
    required this.members,
    required this.admins,
    this.imageUrl,
    required this.unreadCount,
  });

  factory GroupModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final membersMap = map['members'] as Map<dynamic, dynamic>? ?? {};
    final adminsMap = map['admins'] as Map<dynamic, dynamic>? ?? {};
    
    return GroupModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] ?? 0,
      lastMessageTime: map['lastMessageTime'] ?? 0,
      lastMessage: map['lastMessage'] ?? '',
      members: membersMap.keys.cast<String>().toList(),
      admins: adminsMap.keys.cast<String>().toList(),
      imageUrl: map['imageUrl'],
      unreadCount: map['unreadCount'] ?? 0,
    );
  }
}

class ChatModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final int lastMessageTime;
  final int unreadCount;
  final int? createdAt;

  ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    this.createdAt,
  });

  factory ChatModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final participantsMap = map['participants'] as Map<dynamic, dynamic>? ?? {};
    
    return ChatModel(
      id: id,
      participants: participantsMap.keys.cast<String>().toList(),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'] ?? 0,
      unreadCount: map['unreadCount'] ?? 0,
      createdAt: map['createdAt'],
    );
  }
}

class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? profileImageUrl;
  final String? phoneNumber;
  final int? age;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.phoneNumber,
    this.age,
  });

  factory UserModel.fromMap(String uid, Map<dynamic, dynamic> map) {
    return UserModel(
      uid: uid,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      phoneNumber: map['phoneNumber'],
      age: map['age'],
    );
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String message;
  final int timestamp;
  final MessageType type;
  final bool edited;
  final bool deleted;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.edited,
    required this.deleted,
  });

  factory MessageModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => MessageType.text,
      ),
      edited: map['edited'] ?? false,
      deleted: map['deleted'] ?? false,
    );
  }
}

enum MessageType {
  text,
  image,
  voice,
  file,
  system,
}

// Additional Screens

class GroupChatScreen extends StatefulWidget {
  final GroupModel group;

  const GroupChatScreen({super.key, required this.group});

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final _encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromSecureRandom(32)));
  final _iv = encrypt.IV.fromSecureRandom(16);
  
  List<MessageModel> _messages = [];
  StreamSubscription? _messagesSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupMessageListener();
    _markAsRead();
  }

  void _setupMessageListener() {
    _messagesSubscription = _database
        .child('group_messages')
        .child(widget.group.id)
        .orderByChild('timestamp')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _messages = data.entries
              .map((e) => MessageModel.fromMap(e.key, e.value))
              .toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        setState(() {
          _messages = [];
          _isLoading = false;
        });
      }
    });
  }

  void _markAsRead() async {
    await _database
        .child('groups')
        .child(widget.group.id)
        .child('unreadCount')
        .set(0);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.group.name,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              '${widget.group.members.length} members',
              style: TextStyle(fontSize: 12, color: AppTheme.getSubtitleColor(context)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: _showGroupInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(AppTheme.mediumSpacing),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final isOwnMessage = message.senderId == _currentUserId;
    final decryptedMessage = _decryptMessage(message.message);
    
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.smallSpacing),
      child: Row(
        mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isOwnMessage) ...[
            CircleAvatar(
              radius: 16,
              child: Icon(Icons.person, size: 16),
            ),
            SizedBox(width: AppTheme.smallSpacing),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.mediumSpacing,
                vertical: AppTheme.smallSpacing,
              ),
              decoration: BoxDecoration(
                color: isOwnMessage
                    ? AppTheme.getPrimaryColor(context)
                    : AppTheme.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isOwnMessage && message.type != MessageType.system)
                    Text(
                      'User', // You'd get the actual username here
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getSubtitleColor(context),
                      ),
                    ),
                  Text(
                    decryptedMessage,
                    style: TextStyle(
                      color: isOwnMessage
                          ? AppTheme.microphoneColor
                          : AppTheme.getTextColor(context),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    _formatTimestamp(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isOwnMessage
                          ? AppTheme.microphoneColor.withOpacity(0.7)
                          : AppTheme.getSubtitleColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isOwnMessage) ...[
            SizedBox(width: AppTheme.smallSpacing),
            CircleAvatar(
              radius: 16,
              child: Icon(Icons.person, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(AppTheme.mediumSpacing),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        border: Border(
          top: BorderSide(
            color: AppTheme.getDividerColor(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.largeRadius),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppTheme.mediumSpacing,
                  vertical: AppTheme.smallSpacing,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: AppTheme.smallSpacing),
          IconButton(
            onPressed: _sendMessage,
            icon: Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.getPrimaryColor(context),
              foregroundColor: AppTheme.microphoneColor,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      final messageRef = _database
          .child('group_messages')
          .child(widget.group.id)
          .push();
      
      final encryptedMessage = _encryptMessage(message);
      
      final messageData = {
        'id': messageRef.key,
        'senderId': _currentUserId,
        'message': encryptedMessage,
        'timestamp': ServerValue.timestamp,
        'type': MessageType.text.toString().split('.').last,
        'edited': false,
        'deleted': false,
      };
      
      await messageRef.set(messageData);
      
      // Update group with last message
      await _database.child('groups').child(widget.group.id).update({
        'lastMessage': encryptedMessage,
        'lastMessageTime': ServerValue.timestamp,
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _showGroupInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.group.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.group.description.isNotEmpty) ...[
              Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.group.description),
              SizedBox(height: AppTheme.mediumSpacing),
            ],
            Text('Members: ${widget.group.members.length}'),
            Text('Admins: ${widget.group.admins.length}'),
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

  String _encryptMessage(String message) {
    try {
      return _encrypter.encrypt(message, iv: _iv).base64;
    } catch (e) {
      return message;
    }
  }

  String _decryptMessage(String encryptedMessage) {
    try {
      return _encrypter.decrypt64(encryptedMessage, iv: _iv);
    } catch (e) {
      return encryptedMessage;
    }
  }

  String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    
    if (dateTime.day == now.day &&
        dateTime.month == now.month &&
        dateTime.year == now.year) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}

class PersonalChatScreen extends StatefulWidget {
  final ChatModel chat;

  const PersonalChatScreen({super.key, required this.chat});

  @override
  _PersonalChatScreenState createState() => _PersonalChatScreenState();
}

class _PersonalChatScreenState extends State<PersonalChatScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final _encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromSecureRandom(32)));
  final _iv = encrypt.IV.fromSecureRandom(16);
  
  List<MessageModel> _messages = [];
  StreamSubscription? _messagesSubscription;
  bool _isLoading = true;
  UserModel? _otherUser;

  @override
  void initState() {
    super.initState();
    _loadOtherUser();
    _setupMessageListener();
    _markAsRead();
  }

  void _loadOtherUser() async {
    final otherUserId = widget.chat.participants.firstWhere(
      (id) => id != _currentUserId,
      orElse: () => '',
    );
    
    if (otherUserId.isNotEmpty) {
      try {
        final snapshot = await _database.child('users').child(otherUserId).once();
        if (snapshot.snapshot.value != null) {
          setState(() {
            _otherUser = UserModel.fromMap(
              otherUserId,
              Map<String, dynamic>.from(snapshot.snapshot.value as Map),
            );
          });
        }
      } catch (e) {
        print('Error loading other user: $e');
      }
    }
  }

  void _setupMessageListener() {
    _messagesSubscription = _database
        .child('chat_messages')
        .child(widget.chat.id)
        .orderByChild('timestamp')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _messages = data.entries
              .map((e) => MessageModel.fromMap(e.key, e.value))
              .toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        setState(() {
          _messages = [];
          _isLoading = false;
        });
      }
    });
  }

  void _markAsRead() async {
    await _database
        .child('chats')
        .child(widget.chat.id)
        .child('unreadCount')
        .set(0);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: _otherUser?.profileImageUrl?.isNotEmpty == true
                  ? NetworkImage(_otherUser!.profileImageUrl!)
                  : null,
              child: _otherUser?.profileImageUrl?.isEmpty != false
                  ? Icon(Icons.person)
                  : null,
            ),
            SizedBox(width: AppTheme.smallSpacing),
            Expanded(
              child: Text(
                _otherUser?.username ?? 'Unknown User',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: _showChatInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(AppTheme.mediumSpacing),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final isOwnMessage = message.senderId == _currentUserId;
    final decryptedMessage = _decryptMessage(message.message);
    
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.smallSpacing),
      child: Row(
        mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.mediumSpacing,
                vertical: AppTheme.smallSpacing,
              ),
              decoration: BoxDecoration(
                color: isOwnMessage
                    ? AppTheme.getPrimaryColor(context)
                    : AppTheme.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    decryptedMessage,
                    style: TextStyle(
                      color: isOwnMessage
                          ? AppTheme.microphoneColor
                          : AppTheme.getTextColor(context),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    _formatTimestamp(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isOwnMessage
                          ? AppTheme.microphoneColor.withOpacity(0.7)
                          : AppTheme.getSubtitleColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(AppTheme.mediumSpacing),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        border: Border(
          top: BorderSide(
            color: AppTheme.getDividerColor(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.largeRadius),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppTheme.mediumSpacing,
                  vertical: AppTheme.smallSpacing,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: AppTheme.smallSpacing),
          IconButton(
            onPressed: _sendMessage,
            icon: Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.getPrimaryColor(context),
              foregroundColor: AppTheme.microphoneColor,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      final messageRef = _database
          .child('chat_messages')
          .child(widget.chat.id)
          .push();
      
      final encryptedMessage = _encryptMessage(message);
      
      final messageData = {
        'id': messageRef.key,
        'senderId': _currentUserId,
        'message': encryptedMessage,
        'timestamp': ServerValue.timestamp,
        'type': MessageType.text.toString().split('.').last,
        'edited': false,
        'deleted': false,
      };
      
      await messageRef.set(messageData);
      
      // Update chat with last message
      await _database.child('chats').child(widget.chat.id).update({
        'lastMessage': encryptedMessage,
        'lastMessageTime': ServerValue.timestamp,
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _showChatInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chat Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_otherUser != null) ...[
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: _otherUser!.profileImageUrl?.isNotEmpty == true
                      ? NetworkImage(_otherUser!.profileImageUrl!)
                      : null,
                  child: _otherUser!.profileImageUrl?.isEmpty != false
                      ? Icon(Icons.person)
                      : null,
                ),
                title: Text(_otherUser!.username),
                subtitle: Text(_otherUser!.email),
              ),
              SizedBox(height: AppTheme.mediumSpacing),
            ],
            Text('Chat started: ${_formatTimestamp(widget.chat.createdAt ?? 0)}'),
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

  String _encryptMessage(String message) {
    try {
      return _encrypter.encrypt(message, iv: _iv).base64;
    } catch (e) {
      return message;
    }
  }

  String _decryptMessage(String encryptedMessage) {
    try {
      return _encrypter.decrypt64(encryptedMessage, iv: _iv);
    } catch (e) {
      return encryptedMessage;
    }
  }

  String _formatTimestamp(int timestamp) {
    if (timestamp == 0) return '';
    
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    
    if (dateTime.day == now.day &&
        dateTime.month == now.month &&
        dateTime.year == now.year) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}

class AnnouncementsScreen extends StatelessWidget {
  final List<AnnouncementModel> announcements;

  const AnnouncementsScreen({super.key, required this.announcements});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Announcements'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(AppTheme.mediumSpacing),
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final announcement = announcements[index];
          return Container(
            margin: EdgeInsets.only(bottom: AppTheme.mediumSpacing),
            child: AppTheme.buildThemedCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.campaign,
                        color: AppTheme.getPrimaryColor(context),
                      ),
                      SizedBox(width: AppTheme.smallSpacing),
                      Expanded(
                        child: Text(
                          announcement.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.mediumSpacing),
                  Text(
                    announcement.content,
                    style: TextStyle(
                      color: AppTheme.getTextColor(context),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: AppTheme.mediumSpacing),
                  Text(
                    _formatTimestamp(announcement.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getSubtitleColor(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}