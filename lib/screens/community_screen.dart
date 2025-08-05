// File: lib/screens/community_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
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
  
  // Simplified encryption (using basic encoding instead of AES for now)
  final String _encryptionKey = 'bbbd_community_key_2024';
  
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
    _initializeCommunity();
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

  Future<void> _initializeCommunity() async {
    try {
      print('🚀 Initializing Community Screen...');
      
      // First ensure current user exists in database
      await _ensureCurrentUserInDatabase();
      
      // Load community members
      await _loadCommunityMembers();
      
      // Setup real-time listeners
      _setupRealtimeListeners();
      
      setState(() {
        _isLoading = false;
      });
      
      print('✅ Community Screen initialized successfully');
      
    } catch (e) {
      print('❌ Error initializing community: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading community: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setupRealtimeListeners() {
    print('🔄 Setting up real-time listeners...');
    
    // Listen to announcements
    _announcementsSubscription = _database
        .child('announcements')
        .orderByChild('timestamp')
        .onValue
        .listen(
          _onAnnouncementsChanged,
          onError: (error) {
            print('❌ Announcements listener error: $error');
          },
        );

    // Listen to groups where current user is a member
    _groupsSubscription = _database
        .child('groups')
        .onValue
        .listen(
          _onGroupsChanged,
          onError: (error) {
            print('❌ Groups listener error: $error');
          },
        );

    // Listen to personal chats
    _chatsSubscription = _database
        .child('chats')
        .onValue
        .listen(
          _onChatsChanged,
          onError: (error) {
            print('❌ Chats listener error: $error');
          },
        );
  }

  void _onAnnouncementsChanged(DatabaseEvent event) {
    try {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final announcements = data.entries
            .map((e) => AnnouncementModel.fromMap(e.key, e.value))
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        if (mounted) {
          setState(() {
            _announcements = announcements;
          });
        }
        
        print('📢 Loaded ${announcements.length} announcements');
      } else {
        if (mounted) {
          setState(() {
            _announcements = [];
          });
        }
        print('📢 No announcements found');
      }
    } catch (e) {
      print('❌ Error processing announcements: $e');
    }
  }

  void _onGroupsChanged(DatabaseEvent event) {
    try {
      if (event.snapshot.value != null && _currentUserId.isNotEmpty) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final groups = data.entries
            .map((e) => GroupModel.fromMap(e.key, e.value))
            .where((group) => group.members.contains(_currentUserId))
            .toList()
          ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        
        if (mounted) {
          setState(() {
            _groups = groups;
          });
        }
        
        print('👥 Loaded ${groups.length} groups');
      } else {
        if (mounted) {
          setState(() {
            _groups = [];
          });
        }
        print('👥 No groups found');
      }
    } catch (e) {
      print('❌ Error processing groups: $e');
    }
  }

  void _onChatsChanged(DatabaseEvent event) {
    try {
      if (event.snapshot.value != null && _currentUserId.isNotEmpty) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final chats = data.entries
            .map((e) => ChatModel.fromMap(e.key, e.value))
            .where((chat) => chat.participants.contains(_currentUserId))
            .toList()
          ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        
        if (mounted) {
          setState(() {
            _personalChats = chats;
          });
        }
        
        print('💬 Loaded ${chats.length} personal chats');
      } else {
        if (mounted) {
          setState(() {
            _personalChats = [];
          });
        }
        print('💬 No personal chats found');
      }
    } catch (e) {
      print('❌ Error processing chats: $e');
    }
  }

  Future<void> _loadCommunityMembers() async {
    try {
      print('👥 Loading community members...');
      
      final snapshot = await _database.child('users').once();
      
      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        final members = data.entries
            .map((e) => UserModel.fromMap(e.key, e.value))
            .where((user) => user.uid != _currentUserId)
            .toList();
        
        setState(() {
          _communityMembers = members;
        });
        
        print('✅ Loaded ${members.length} community members');
        
        // If no members exist, create sample users
        if (members.isEmpty) {
          await _createSampleUsers();
        }
      } else {
        print('⚠️ No users found in database, creating sample users...');
        await _createSampleUsers();
      }
    } catch (e) {
      print('❌ Error loading community members: $e');
      // Create sample users as fallback
      await _createSampleUsers();
    }
  }

  Future<void> _createSampleUsers() async {
    try {
      print('👤 Creating sample users...');
      
      final sampleUsers = [
        {
          'uid': 'sample_user_1',
          'username': 'Alice Johnson',
          'email': 'alice@bbbd.com',
          'profileImageUrl': '',
          'phoneNumber': '+1234567890',
          'age': 25,
          'isOnline': true,
          'lastSeen': ServerValue.timestamp,
          'createdAt': ServerValue.timestamp,
        },
        {
          'uid': 'sample_user_2',
          'username': 'Bob Smith',
          'email': 'bob@bbbd.com',
          'profileImageUrl': '',
          'phoneNumber': '+1234567891',
          'age': 30,
          'isOnline': false,
          'lastSeen': DateTime.now().subtract(Duration(hours: 2)).millisecondsSinceEpoch,
          'createdAt': ServerValue.timestamp,
        },
        {
          'uid': 'sample_user_3',
          'username': 'Carol Davis',
          'email': 'carol@bbbd.com',
          'profileImageUrl': '',
          'phoneNumber': '+1234567892',
          'age': 28,
          'isOnline': true,
          'lastSeen': ServerValue.timestamp,
          'createdAt': ServerValue.timestamp,
        },
        {
          'uid': 'sample_user_4',
          'username': 'David Wilson',
          'email': 'david@bbbd.com',
          'profileImageUrl': '',
          'phoneNumber': '+1234567893',
          'age': 32,
          'isOnline': false,
          'lastSeen': DateTime.now().subtract(Duration(minutes: 30)).millisecondsSinceEpoch,
          'createdAt': ServerValue.timestamp,
        },
      ];

      // Add sample users to database
      for (final user in sampleUsers) {
        await _database.child('users').child(user['uid'] as String).set(user);
      }
      
      // Create a sample announcement
      await _createSampleAnnouncement();
      
      print('✅ Sample users created successfully');
      
      // Reload members
      await _loadCommunityMembers();
      
    } catch (e) {
      print('❌ Error creating sample users: $e');
    }
  }

  Future<void> _createSampleAnnouncement() async {
    try {
      final announcementRef = _database.child('announcements').push();
      
      final announcementData = {
        'id': announcementRef.key,
        'title': 'Welcome to BBBD Community! 🎉',
        'content': 'Connect with fellow users, share ideas, and build meaningful relationships. Start by creating groups or sending direct messages!',
        'createdBy': 'system',
        'timestamp': ServerValue.timestamp,
        'priority': 'high',
      };
      
      await announcementRef.set(announcementData);
      print('📢 Sample announcement created');
    } catch (e) {
      print('❌ Error creating sample announcement: $e');
    }
  }

  Future<void> _ensureCurrentUserInDatabase() async {
    try {
      if (_currentUserId.isEmpty) {
        print('⚠️ No current user ID found');
        return;
      }
      
      final userSnapshot = await _database.child('users').child(_currentUserId).once();
      
      if (!userSnapshot.snapshot.exists) {
        print('👤 Current user not in database, adding...');
        
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final userData = {
            'uid': _currentUserId,
            'username': currentUser.displayName ?? 'BBBD User',
            'email': currentUser.email ?? 'user@bbbd.com',
            'profileImageUrl': currentUser.photoURL ?? '',
            'phoneNumber': currentUser.phoneNumber ?? '',
            'age': 25,
            'isOnline': true,
            'lastSeen': ServerValue.timestamp,
            'createdAt': ServerValue.timestamp,
            'lastLoginAt': ServerValue.timestamp,
          };
          
          await _database.child('users').child(_currentUserId).set(userData);
          print('✅ Current user added to database');
        }
      } else {
        // Update last seen
        await _database.child('users').child(_currentUserId).update({
          'lastSeen': ServerValue.timestamp,
          'isOnline': true,
        });
        print('✅ Updated current user presence');
      }
    } catch (e) {
      print('❌ Error ensuring current user in database: $e');
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
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: AppTheme.getIconColor(context),
            ),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'create_announcement',
                child: Row(
                  children: [
                    Icon(Icons.campaign, size: 20),
                    SizedBox(width: 8),
                    Text('Create Announcement'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'member_list',
                child: Row(
                  children: [
                    Icon(Icons.people, size: 20),
                    SizedBox(width: 8),
                    Text('View Members'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'refresh_data',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'debug_info',
                child: Row(
                  children: [
                    Icon(Icons.bug_report, size: 20),
                    SizedBox(width: 8),
                    Text('🐛 Debug Info'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppTheme.getPrimaryColor(context),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading Community...',
                      style: TextStyle(
                        color: AppTheme.getSubtitleColor(context),
                      ),
                    ),
                  ],
                ),
              )
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedTab == 0 ? _showCreateGroupDialog : _showCreateChatDialog,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text(_selectedTab == 0 ? 'New Group' : 'New Chat'),
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
                  Row(
                    children: [
                      Icon(
                        Icons.campaign,
                        color: AppTheme.getPrimaryColor(context),
                        size: 24,
                      ),
                      SizedBox(width: AppTheme.smallSpacing),
                      Text(
                        'Announcements',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                    ],
                  ),
                  if (_announcements.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_announcements.length}',
                        style: TextStyle(
                          color: AppTheme.getPrimaryColor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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
                          SizedBox(height: AppTheme.smallSpacing),
                          Text(
                            'Community updates will appear here',
                            style: TextStyle(
                              color: AppTheme.getSubtitleColor(context),
                              fontSize: 12,
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
              if (_announcements.length > 3) ...[
                SizedBox(height: AppTheme.smallSpacing),
                Center(
                  child: TextButton.icon(
                    onPressed: _showAllAnnouncements,
                    icon: Icon(Icons.expand_more),
                    label: Text('View All (${_announcements.length - 3} more)'),
                  ),
                ),
              ],
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
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.campaign,
                  size: 16,
                  color: AppTheme.getPrimaryColor(context),
                ),
              ),
              SizedBox(width: AppTheme.smallSpacing),
              Expanded(
                child: Text(
                  announcement.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.getTextColor(context),
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                _formatTimestamp(announcement.timestamp),
                style: TextStyle(
                  fontSize: 11,
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
                height: 1.3,
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
        margin: EdgeInsets.symmetric(
          horizontal: AppTheme.mediumSpacing,
          vertical: AppTheme.smallSpacing,
        ),
        child: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
            border: Border.all(
              color: AppTheme.getDividerColor(context),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 0),
                  child: AnimatedContainer(
                    duration: AppTheme.shortAnimation,
                    padding: EdgeInsets.symmetric(vertical: AppTheme.mediumSpacing),
                    decoration: BoxDecoration(
                      color: _selectedTab == 0 
                          ? Colors.black
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group,
                          size: 18,
                          color: _selectedTab == 0 
                              ? Colors.white
                              : AppTheme.getIconColor(context),
                        ),
                        SizedBox(width: AppTheme.tinySpacing),
                        Text(
                          'Groups',
                          style: TextStyle(
                            color: _selectedTab == 0 
                                ? Colors.white
                                : AppTheme.getTextColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_groups.isNotEmpty) ...[
                          SizedBox(width: AppTheme.tinySpacing),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 
                                  ? Colors.white.withOpacity(0.2)
                                  : AppTheme.getPrimaryColor(context).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_groups.length}',
                              style: TextStyle(
                                fontSize: 10,
                                color: _selectedTab == 0 
                                    ? Colors.white
                                    : AppTheme.getPrimaryColor(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = 1),
                  child: AnimatedContainer(
                    duration: AppTheme.shortAnimation,
                    padding: EdgeInsets.symmetric(vertical: AppTheme.mediumSpacing),
                    decoration: BoxDecoration(
                      color: _selectedTab == 1 
                          ? Colors.black
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat,
                          size: 18,
                          color: _selectedTab == 1 
                              ? Colors.white
                              : AppTheme.getIconColor(context),
                        ),
                        SizedBox(width: AppTheme.tinySpacing),
                        Text(
                          'Chats',
                          style: TextStyle(
                            color: _selectedTab == 1 
                                ? Colors.white
                                : AppTheme.getTextColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_personalChats.isNotEmpty) ...[
                          SizedBox(width: AppTheme.tinySpacing),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 
                                  ? Colors.white.withOpacity(0.2)
                                  : AppTheme.getPrimaryColor(context).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_personalChats.length}',
                              style: TextStyle(
                                fontSize: 10,
                                color: _selectedTab == 1 
                                    ? Colors.white
                                    : AppTheme.getPrimaryColor(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
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
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.group_outlined,
                        size: 48,
                        color: AppTheme.getPrimaryColor(context),
                      ),
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
                    SizedBox(height: AppTheme.mediumSpacing),
                    ElevatedButton.icon(
                      onPressed: _showCreateGroupDialog,
                      icon: Icon(Icons.add),
                      label: Text('Create Your First Group'),
                      style: AppTheme.getPrimaryButtonStyle(context),
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
          contentPadding: EdgeInsets.all(AppTheme.mediumSpacing),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.getPrimaryColor(context),
                child: group.imageUrl?.isNotEmpty == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.network(
                          group.imageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.group,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.group,
                        color: Colors.white,
                        size: 28,
                      ),
              ),
              if (group.unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Text(
                      '${group.unreadCount > 99 ? '99+' : group.unreadCount}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            group.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(
                group.lastMessage.isNotEmpty 
                    ? _decryptMessage(group.lastMessage)
                    : 'No messages yet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.getSubtitleColor(context),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 12,
                    color: AppTheme.getSubtitleColor(context),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${group.members.length} members',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getSubtitleColor(context),
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: AppTheme.getSubtitleColor(context),
                  ),
                  SizedBox(width: 4),
                  Text(
                    _formatTimestamp(group.lastMessageTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getSubtitleColor(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: AppTheme.getIconColor(context),
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
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chat_outlined,
                        size: 48,
                        color: AppTheme.getPrimaryColor(context),
                      ),
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
                    SizedBox(height: AppTheme.mediumSpacing),
                    ElevatedButton.icon(
                      onPressed: _showCreateChatDialog,
                      icon: Icon(Icons.person_add),
                      label: Text('Start a Conversation'),
                      style: AppTheme.getPrimaryButtonStyle(context),
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
          contentPadding: EdgeInsets.all(AppTheme.mediumSpacing),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.getPrimaryColor(context),
                backgroundImage: otherUser.profileImageUrl?.isNotEmpty == true
                    ? NetworkImage(otherUser.profileImageUrl!)
                    : null,
                child: otherUser.profileImageUrl?.isEmpty != false
                    ? Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 28,
                      )
                    : null,
              ),
              // Online status indicator
              if (otherUser.isOnline == true)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              if (chat.unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Text(
                      '${chat.unreadCount > 99 ? '99+' : chat.unreadCount}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            otherUser.username,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(
                chat.lastMessage.isNotEmpty 
                    ? _decryptMessage(chat.lastMessage)
                    : 'No messages yet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.getSubtitleColor(context),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    otherUser.isOnline == true ? Icons.circle : Icons.access_time,
                    size: 12,
                    color: otherUser.isOnline == true ? Colors.green : AppTheme.getSubtitleColor(context),
                  ),
                  SizedBox(width: 4),
                  Text(
                    otherUser.isOnline == true 
                        ? 'Online' 
                        : 'Last seen ${_formatTimestamp(otherUser.lastSeen ?? 0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getSubtitleColor(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: AppTheme.getIconColor(context),
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
        title: Text('Search ${_selectedTab == 0 ? 'Groups' : 'Chats'}'),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: _selectedTab == 0 ? 'Search groups...' : 'Search chats...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
            ),
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog() {
    if (_communityMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No community members available to add to group'),
          action: SnackBarAction(
            label: 'Refresh',
            onPressed: () => _loadCommunityMembers(),
          ),
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    List<String> selectedMembers = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.group_add),
              SizedBox(width: 8),
              Text('Create Group'),
            ],
          ),
          contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Group Name *',
                      hintText: 'Enter a creative group name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                      ),
                      prefixIcon: Icon(Icons.group),
                    ),
                  ),
                  SizedBox(height: AppTheme.mediumSpacing),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'What is this group about?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                      ),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: AppTheme.mediumSpacing),
                  Text(
                    'Add Members:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Select people to add to your group',
                    style: TextStyle(
                      color: AppTheme.getSubtitleColor(context),
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: AppTheme.smallSpacing),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.getDividerColor(context)),
                      borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _communityMembers.length,
                      itemBuilder: (context, index) {
                        final member = _communityMembers[index];
                        final isSelected = selectedMembers.contains(member.uid);
                        
                        return CheckboxListTile(
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
                          secondary: CircleAvatar(
                            radius: 16,
                            backgroundImage: member.profileImageUrl?.isNotEmpty == true
                                ? NetworkImage(member.profileImageUrl!)
                                : null,
                            child: member.profileImageUrl?.isEmpty != false
                                ? Icon(Icons.person, size: 16)
                                : null,
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
                        );
                      },
                    ),
                  ),
                  if (selectedMembers.isNotEmpty) ...[
                    SizedBox(height: AppTheme.smallSpacing),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: AppTheme.getPrimaryColor(context),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${selectedMembers.length} member(s) selected',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.getPrimaryColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
            ElevatedButton.icon(
              onPressed: nameController.text.trim().isNotEmpty
                  ? () async {
                      Navigator.pop(context);
                      await _createGroup(
                        nameController.text.trim(),
                        descriptionController.text.trim(),
                        selectedMembers,
                      );
                    }
                  : null,
              icon: Icon(Icons.create),
              label: Text('Create Group'),
              style: AppTheme.getPrimaryButtonStyle(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateChatDialog() {
    if (_communityMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No community members available to chat with'),
          action: SnackBarAction(
            label: 'Refresh',
            onPressed: () => _loadCommunityMembers(),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.chat_bubble_outline),
            SizedBox(width: 8),
            Text('Start New Chat'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Text(
                'Choose someone to start a conversation with:',
                style: TextStyle(
                  color: AppTheme.getSubtitleColor(context),
                ),
              ),
              SizedBox(height: AppTheme.mediumSpacing),
              Expanded(
                child: ListView.builder(
                  itemCount: _communityMembers.length,
                  itemBuilder: (context, index) {
                    final member = _communityMembers[index];
                    
                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundImage: member.profileImageUrl?.isNotEmpty == true
                                ? NetworkImage(member.profileImageUrl!)
                                : null,
                            child: member.profileImageUrl?.isEmpty != false
                                ? Icon(Icons.person)
                                : null,
                          ),
                          if (member.isOnline == true)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(member.username),
                      subtitle: Text(
                        member.isOnline == true 
                            ? 'Online' 
                            : 'Last seen ${_formatTimestamp(member.lastSeen ?? 0)}',
                      ),
                      trailing: Icon(Icons.chat),
                      onTap: () async {
                        Navigator.pop(context);
                        await _createPersonalChat(member.uid);
                      },
                    );
                  },
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
        ],
      ),
    );
  }

  // CRUD Operations
  Future<void> _createGroup(String name, String description, List<String> memberIds) async {
    try {
      // Show loading
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
        'isActive': true,
      };
      
      await groupRef.set(groupData);
      
      // Send system welcome message
      await _sendMessage(
        groupId,
        'Welcome to $name! 🎉 Start chatting with your group members.',
        MessageType.system,
        isGroup: true,
      );
      
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Group "$name" created successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to the new group
      final newGroup = GroupModel.fromMap(groupId, groupData);
      _openGroupChat(newGroup);
      
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      
      print('❌ Error creating group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating group: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      
      // Show loading
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
                Text('Starting chat...'),
              ],
            ),
          ),
        ),
      );
      
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
        'isActive': true,
      };
      
      await chatRef.set(chatData);
      
      Navigator.pop(context); // Close loading dialog
      
      // Navigate to chat
      final newChat = ChatModel.fromMap(chatId, chatData);
      _openPersonalChat(newChat);
      
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if open
      
      print('❌ Error creating chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating chat: $e'),
          backgroundColor: Colors.red,
        ),
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
      print('❌ Error sending message: $e');
    }
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

  // Options and Actions
  void _showGroupOptions(GroupModel group) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.greyMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: AppTheme.mediumSpacing),
            Text(
              group.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppTheme.mediumSpacing),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Group Info'),
              onTap: () {
                Navigator.pop(context);
                _showGroupInfoDialog(group);
              },
            ),
            if (group.admins.contains(_currentUserId)) ...[
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
            ],
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.orange),
              title: Text('Leave Group', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
                _confirmLeaveGroup(group);
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
          ],
        ),
      ),
    );
  }

  void _showChatOptions(ChatModel chat) {
    final otherUser = _getOtherUserFromChat(chat);
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.greyMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: AppTheme.mediumSpacing),
            Text(
              'Chat with ${otherUser.username}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppTheme.mediumSpacing),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Chat Info'),
              onTap: () {
                Navigator.pop(context);
                _showChatInfoDialog(chat);
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

  // Menu Actions
  void _handleMenuAction(String action) {
    switch (action) {
      case 'create_announcement':
        _showCreateAnnouncementDialog();
        break;
      case 'member_list':
        _showMemberList();
        break;
      case 'refresh_data':
        _refreshData();
        break;
      case 'debug_info':
        _showDebugInfo();
        break;
    }
  }

  void _showCreateAnnouncementDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.campaign),
            SizedBox(width: 8),
            Text('Create Announcement'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title *',
                hintText: 'Enter announcement title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                ),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            SizedBox(height: AppTheme.mediumSpacing),
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                labelText: 'Content',
                hintText: 'What would you like to announce?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                ),
                prefixIcon: Icon(Icons.message),
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
          ElevatedButton.icon(
            onPressed: titleController.text.trim().isNotEmpty
                ? () async {
                    Navigator.pop(context);
                    await _createAnnouncement(
                      titleController.text.trim(),
                      contentController.text.trim(),
                    );
                  }
                : null,
            icon: Icon(Icons.send),
            label: Text('Post'),
            style: AppTheme.getPrimaryButtonStyle(context),
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
        'priority': 'normal',
      };
      
      await announcementRef.set(announcementData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Announcement posted successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error posting announcement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error posting announcement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMemberList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.people),
            SizedBox(width: 8),
            Text('Community Members'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: _communityMembers.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: AppTheme.getSubtitleColor(context),
                    ),
                    SizedBox(height: 16),
                    Text('No members found'),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _loadCommunityMembers();
                      },
                      child: Text('Refresh'),
                    ),
                  ],
                )
              : ListView.builder(
                  itemCount: _communityMembers.length,
                  itemBuilder: (context, index) {
                    final member = _communityMembers[index];
                    
                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundImage: member.profileImageUrl?.isNotEmpty == true
                                ? NetworkImage(member.profileImageUrl!)
                                : null,
                            child: member.profileImageUrl?.isEmpty != false
                                ? Icon(Icons.person)
                                : null,
                          ),
                          if (member.isOnline == true)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(member.username),
                      subtitle: Text(
                        member.isOnline == true 
                            ? 'Online' 
                            : 'Last seen ${_formatTimestamp(member.lastSeen ?? 0)}',
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.chat),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _createPersonalChat(member.uid);
                        },
                        tooltip: 'Start chat',
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
              _buildDebugItem('Current User ID', _currentUserId.isEmpty ? 'Not logged in' : _currentUserId),
              _buildDebugItem('Community Members', '${_communityMembers.length} found'),
              _buildDebugItem('Groups', '${_groups.length} joined'),
              _buildDebugItem('Personal Chats', '${_personalChats.length} active'),
              _buildDebugItem('Announcements', '${_announcements.length} loaded'),
              _buildDebugItem('Loading State', _isLoading ? 'Loading...' : 'Loaded'),
              SizedBox(height: 16),
              if (_communityMembers.isNotEmpty) ...[
                Text('Members:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ...(_communityMembers.take(5).map((member) => 
                  Text('• ${member.username} (${member.email})', style: TextStyle(fontSize: 12))
                ).toList()),
                if (_communityMembers.length > 5)
                  Text('... and ${_communityMembers.length - 5} more', style: TextStyle(fontSize: 12)),
              ],
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _loadCommunityMembers();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Members reloaded')),
                      );
                    },
                    icon: Icon(Icons.refresh, size: 16),
                    label: Text('Reload'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(0, 32),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _createSampleUsers();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sample users created')),
                      );
                    },
                    icon: Icon(Icons.person_add, size: 16),
                    label: Text('Add Samples'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(0, 32),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ],
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

  Widget _buildDebugItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12),
            ),
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
            Text('Admins: ${group.admins.length}'),
            Text('Created: ${_formatTimestamp(group.createdAt)}'),
            if (group.lastMessageTime > 0)
              Text('Last Activity: ${_formatTimestamp(group.lastMessageTime)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openGroupChat(group);
            },
            child: Text('Open Chat'),
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
            if (chat.lastMessageTime > 0)
              Text('Last message: ${_formatTimestamp(chat.lastMessageTime)}'),
            Text('Status: ${otherUser.isOnline == true ? 'Online' : 'Offline'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openPersonalChat(chat);
            },
            child: Text('Open Chat'),
          ),
        ],
      ),
    );
  }

  // Confirmation Dialogs
  void _confirmDeleteGroup(GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Group'),
        content: Text('Are you sure you want to delete "${group.name}"? This action cannot be undone and will remove all messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteGroup(group.id);
            },
            child: Text('Delete', style: TextStyle(color: Colors.white)),
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
        content: Text('Are you sure you want to leave "${group.name}"? You can be added back by an admin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(context);
              await _leaveGroup(group.id);
            },
            child: Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteChat(ChatModel chat) {
    final otherUser = _getOtherUserFromChat(chat);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Chat'),
        content: Text('Are you sure you want to delete your chat with ${otherUser.username}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteChat(chat.id);
            },
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Placeholder methods for functionality that would require more complex implementation
  void _showEditGroupDialog(GroupModel group) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit group functionality coming soon!')),
    );
  }

  void _showManageMembersDialog(GroupModel group) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Manage members functionality coming soon!')),
    );
  }

  Future<void> _deleteGroup(String groupId) async {
    try {
      await _database.child('groups').child(groupId).remove();
      await _database.child('group_messages').child(groupId).remove();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error deleting group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _leaveGroup(String groupId) async {
    try {
      await _database.child('groups').child(groupId).child('members').child(_currentUserId).remove();
      await _database.child('groups').child(groupId).child('admins').child(_currentUserId).remove();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Left group successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error leaving group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error leaving group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteChat(String chatId) async {
    try {
      await _database.child('chats').child(chatId).remove();
      await _database.child('chat_messages').child(chatId).remove();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error deleting chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        email: 'unknown@bbbd.com',
      ),
    );
  }

  String _encryptMessage(String message) {
    try {
      // Simple encoding (you can implement proper encryption here)
      final bytes = utf8.encode(message + _encryptionKey);
      final digest = sha256.convert(bytes);
      return base64.encode(utf8.encode(message)) + ':' + digest.toString().substring(0, 8);
    } catch (e) {
      return message; // Fallback to plain text if encryption fails
    }
  }

  String _decryptMessage(String encryptedMessage) {
    try {
      if (encryptedMessage.contains(':')) {
        final parts = encryptedMessage.split(':');
        return utf8.decode(base64.decode(parts[0]));
      }
      return encryptedMessage; // Return as-is if not encrypted
    } catch (e) {
      return encryptedMessage; // Return as-is if decryption fails
    }
  }

  String _formatTimestamp(int timestamp) {
    if (timestamp == 0) return 'Never';
    
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
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
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _loadCommunityMembers();
      await Future.delayed(Duration(seconds: 1)); // Give time for listeners to update
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Community data refreshed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _announcementsSubscription?.cancel();
    _groupsSubscription?.cancel();
    _chatsSubscription?.cancel();
    
    // Update user offline status
    if (_currentUserId.isNotEmpty) {
      _database.child('users').child(_currentUserId).update({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
      });
    }
    
    super.dispose();
  }
}

// Data Models - Updated with additional fields
class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String createdBy;
  final int timestamp;
  final String priority;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdBy,
    required this.timestamp,
    this.priority = 'normal',
  });

  factory AnnouncementModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return AnnouncementModel(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdBy: map['createdBy'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      priority: map['priority'] ?? 'normal',
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
  final bool isActive;

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
    this.isActive = true,
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
      isActive: map['isActive'] ?? true,
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
  final bool isActive;

  ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    this.createdAt,
    this.isActive = true,
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
      isActive: map['isActive'] ?? true,
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
  final bool? isOnline;
  final int? lastSeen;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.phoneNumber,
    this.age,
    this.isOnline,
    this.lastSeen,
  });

  factory UserModel.fromMap(String uid, Map<dynamic, dynamic> map) {
    return UserModel(
      uid: uid,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      phoneNumber: map['phoneNumber'],
      age: map['age'],
      isOnline: map['isOnline'],
      lastSeen: map['lastSeen'],
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

// Simplified Chat Screens (you can enhance these further)
class GroupChatScreen extends StatelessWidget {
  final GroupModel group;

  const GroupChatScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.name, style: TextStyle(fontSize: 16)),
            Text('${group.members.length} members', 
                 style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Group Chat Coming Soon!', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Chat functionality will be implemented here'),
          ],
        ),
      ),
    );
  }
}

class PersonalChatScreen extends StatelessWidget {
  final ChatModel chat;

  const PersonalChatScreen({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personal Chat'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Personal Chat Coming Soon!', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Chat functionality will be implemented here'),
          ],
        ),
      ),
    );
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
        padding: EdgeInsets.all(16),
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final announcement = announcements[index];
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.campaign, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          announcement.title,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(announcement.content),
                  SizedBox(height: 8),
                  Text(
                    _formatTimestamp(announcement.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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