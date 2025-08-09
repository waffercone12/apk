import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _postController = TextEditingController();
  List<CommunityPost> _posts = [];
  List<ChallengeData> _challenges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCommunityData();
  }

  Future<void> _loadCommunityData() async {
    await Future.wait([
      _loadPosts(),
      _loadChallenges(),
    ]);
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadPosts() async {
    final postsSnapshot = await FirebaseFirestore.instance
        .collection('community_posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    final posts = await Future.wait(
      postsSnapshot.docs.map((doc) async {
        final data = doc.data();
        
        // Get user info
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(data['userId'])
            .get();
        
        final userData = userDoc.data();
        
        return CommunityPost(
          id: doc.id,
          userId: data['userId'],
          username: userData?['username'] ?? 'Unknown User',
          userPhoto: userData?['photoURL'],
          content: data['content'],
          likes: List<String>.from(data['likes'] ?? []),
          comments: List<String>.from(data['comments'] ?? []),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }),
    );

    setState(() {
      _posts = posts;
    });
  }

  Future<void> _loadChallenges() async {
    final challengesSnapshot = await FirebaseFirestore.instance
        .collection('community_challenges')
        .where('isActive', isEqualTo: true)
        .get();

    setState(() {
      _challenges = challengesSnapshot.docs.map((doc) {
        final data = doc.data();
        return ChallengeData(
          id: doc.id,
          title: data['title'],
          description: data['description'],
          category: data['category'],
          participants: List<String>.from(data['participants'] ?? []),
          startDate: (data['startDate'] as Timestamp).toDate(),
          endDate: (data['endDate'] as Timestamp).toDate(),
          reward: data['reward'],
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('Community'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Feed', icon: Icon(Icons.home_outlined)),
            Tab(text: 'Challenges', icon: Icon(Icons.emoji_events_outlined)),
            Tab(text: 'Groups', icon: Icon(Icons.groups_outlined)),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFeedTab(),
                _buildChallengesTab(),
                _buildGroupsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildFeedTab() {
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return _buildPostCard(_posts[index]);
        },
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isLiked = post.likes.contains(currentUser?.uid);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
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
          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: post.userPhoto != null
                    ? NetworkImage(post.userPhoto!)
                    : null,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: post.userPhoto == null
                    ? Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.username,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _formatTimeAgo(post.createdAt),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.more_vert),
                onPressed: () => _showPostOptions(post),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          // Post content
          Text(
            post.content,
            style: TextStyle(fontSize: 15),
          ),
          SizedBox(height: 16),
          
          // Actions
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleLike(post),
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      post.likes.length.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 20),
              GestureDetector(
                onTap: () => _showCommentsDialog(post),
                child: Row(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      post.comments.length.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.share, size: 20),
                onPressed: () => _sharePost(post),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _challenges.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildChallengeStats();
        }
        return _buildChallengeCard(_challenges[index - 1]);
      },
    );
  }

  Widget _buildChallengeStats() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.red.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Your Challenge Stats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatItem('Completed', '12', Icons.check_circle)),
              Container(width: 1, height: 40, color: Colors.white30),
              Expanded(child: _buildStatItem('Active', '3', Icons.play_circle)),
              Container(width: 1, height: 40, color: Colors.white30),
              Expanded(child: _buildStatItem('Points', '450', Icons.star)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(ChallengeData challenge) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isParticipating = challenge.participants.contains(currentUser?.uid);
    final daysLeft = challenge.endDate.difference(DateTime.now()).inDays;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getCategoryColor(challenge.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(challenge.category),
                  color: _getCategoryColor(challenge.category),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  challenge.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: daysLeft > 0 ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  daysLeft > 0 ? '$daysLeft days left' : 'Expired',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            challenge.description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.people,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              SizedBox(width: 4),
              Text(
                '${challenge.participants.length} participants',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              Spacer(),
              if (challenge.reward.isNotEmpty) ...[
                Icon(
                  Icons.emoji_events,
                  size: 16,
                  color: Colors.orange,
                ),
                SizedBox(width: 4),
                Text(
                  challenge.reward,
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: daysLeft > 0 ? () => _toggleChallengeParticipation(challenge) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isParticipating 
                    ? Colors.green 
                    : Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                isParticipating ? 'Participating' : 'Join Challenge',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          SizedBox(height: 16),
          Text(
            'Groups Coming Soon!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Connect with like-minded individuals\nworking towards similar goals.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share Your Progress'),
        content: TextField(
          controller: _postController,
          decoration: InputDecoration(
            hintText: 'What\'s on your mind?',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _createPost,
            child: Text('Post'),
          ),
        ],
      ),
    );
  }

  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('community_posts').add({
        'userId': user.uid,
        'content': _postController.text.trim(),
        'likes': [],
        'comments': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      _postController.clear();
      Navigator.pop(context);
      _loadPosts();
    }
  }

  Future<void> _toggleLike(CommunityPost post) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isLiked = post.likes.contains(user.uid);
    List<String> newLikes = List.from(post.likes);

    if (isLiked) {
      newLikes.remove(user.uid);
    } else {
      newLikes.add(user.uid);
    }

    await FirebaseFirestore.instance
        .collection('community_posts')
        .doc(post.id)
        .update({'likes': newLikes});

    setState(() {
      post.likes = newLikes;
    });
  }

  Future<void> _toggleChallengeParticipation(ChallengeData challenge) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isParticipating = challenge.participants.contains(user.uid);
    List<String> newParticipants = List.from(challenge.participants);

    if (isParticipating) {
      newParticipants.remove(user.uid);
    } else {
      newParticipants.add(user.uid);
    }

    await FirebaseFirestore.instance
        .collection('community_challenges')
        .doc(challenge.id)
        .update({'participants': newParticipants});

    setState(() {
      challenge.participants = newParticipants;
    });
  }

  void _showPostOptions(CommunityPost post) {
    // Implementation for post options (report, etc.)
  }

  void _showCommentsDialog(CommunityPost post) {
    // Implementation for comments dialog
  }

  void _sharePost(CommunityPost post) {
    // Implementation for sharing posts
  }

  String _formatTimeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    
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

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'fitness':
        return Colors.red;
      case 'mindfulness':
        return Colors.purple;
      case 'productivity':
        return Colors.blue;
      case 'learning':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fitness':
        return Icons.fitness_center;
      case 'mindfulness':
        return Icons.self_improvement;
      case 'productivity':
        return Icons.trending_up;
      case 'learning':
        return Icons.school;
      default:
        return Icons.emoji_events;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postController.dispose();
    super.dispose();
  }
}

class CommunityPost {
  final String id;
  final String userId;
  final String username;
  final String? userPhoto;
  final String content;
  List<String> likes;
  final List<String> comments;
  final DateTime createdAt;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.username,
    this.userPhoto,
    required this.content,
    required this.likes,
    required this.comments,
    required this.createdAt,
  });
}

class ChallengeData {
  final String id;
  final String title;
  final String description;
  final String category;
  List<String> participants;
  final DateTime startDate;
  final DateTime endDate;
  final String reward;

  ChallengeData({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.participants,
    required this.startDate,
    required this.endDate,
    required this.reward,
  });
}