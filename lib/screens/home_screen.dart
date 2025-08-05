import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/default_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String _userName = 'User';
  String _userProfileUrl = '';
  bool _isLoading = true;

  // Time data
  DateTime _currentTime = DateTime.now();
  String _timeRemaining = '';

  // Timer for updates
  Timer? _timeTimer;

  // Notifications data
  final int _groupChats = 3;
  final int _personalChats = 6;

  // Daily usage data (mock data for chart)
  final List<double> _usageData = [0.3, 0.6, 0.4, 0.8, 0.7, 0.9, 0.5];

  // Reminder/Todo items
  final List<ReminderItem> _reminders = [
    ReminderItem(title: 'Jogging', completed: true),
    ReminderItem(title: 'Diet Plan', completed: true),
    ReminderItem(title: 'Workout', completed: true),
    ReminderItem(title: 'Study', completed: false),
    ReminderItem(title: 'Motivation', completed: false),
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: AppTheme.longAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _loadUserData();
    _startTimeUpdater();
    _fadeController.forward();
  }

  void _startTimeUpdater() {
    _updateTime();
    _timeTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTime();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateTime() {
    if (!mounted) return;

    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final timeLeft = endOfDay.difference(now);

    setState(() {
      _currentTime = now;
      _timeRemaining = _formatTimeRemaining(timeLeft);
    });
  }

  String _formatTimeRemaining(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (mounted) {
          if (userData.exists) {
            setState(() {
              _userName =
                  userData.data()?['username'] ?? user.displayName ?? 'User';
              _userProfileUrl =
                  userData.data()?['profileImageUrl'] ?? user.photoURL ?? '';
              _isLoading = false;
            });
          } else {
            setState(() {
              _userName = user.displayName ?? 'User';
              _userProfileUrl = user.photoURL ?? '';
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting Section
                _buildGreetingSection(),

                SizedBox(height: 20),

                // Top Row: Analog Clock and Digital Time
                Row(
                  children: [
                    // Analog Clock
                    _buildAnalogClock(),
                    SizedBox(width: 20),
                    // Digital Time Display
                    Expanded(child: _buildDigitalTimeCard()),
                  ],
                ),

                SizedBox(height: 20),

                // Middle Row: Notification Cards (Vertical) and Usage Analytics (Side by side)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification Cards Column (Left)
                    _buildNotificationCards(),

                    SizedBox(width: 16),

                    // Usage Analytics Card (Right)
                    Expanded(child: _buildUsageAnalyticsCard()),
                  ],
                ),

                SizedBox(height: 20),

                // Reminders Section
                Expanded(child: _buildRemindersSection()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    String greeting = _getGreeting();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 4),
              Text(
                _isLoading ? 'Loading...' : _userName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Profile Picture
        _buildProfilePicture(),
      ],
    );
  }

  Widget _buildProfilePicture() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[700]!, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: _userProfileUrl.isNotEmpty
            ? ColorFiltered(
                colorFilter: ColorFilter.matrix([
                  0.2126, 0.7152, 0.0722, 0, 0, // Red channel
                  0.2126, 0.7152, 0.0722, 0, 0, // Green channel
                  0.2126, 0.7152, 0.0722, 0, 0, // Blue channel
                  0, 0, 0, 1, 0, // Alpha channel
                ]),
                child: Image.network(
                  _userProfileUrl,
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultProfileIcon();
                  },
                ),
              )
            : _buildDefaultProfileIcon(),
      ),
    );
  }

  Widget _buildDefaultProfileIcon() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(23),
      ),
      child: Icon(Icons.person, color: Colors.white, size: 28),
    );
  }

  String _getGreeting() {
    final hour = _currentTime.hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Widget _buildAnalogClock() {
    return SizedBox(
      width: 140,
      height: 140,
      child: CustomPaint(
        painter: AnalogClockPainter(time: _currentTime, isDarkTheme: true),
      ),
    );
  }

  Widget _buildDigitalTimeCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _timeRemaining,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          SizedBox(height: 4),
          Text(
            'left today',
            style: TextStyle(
              color: Color.fromRGBO(77, 94, 128, 1), // RGB(77, 94, 128)
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCards() {
    return Column(
      children: [
        _buildNotificationCard(
          imagePath: 'assets/home/message.png',
          count: _groupChats,
          label: 'Groups',
        ),
        SizedBox(height: 12),
        _buildNotificationCard(
          imagePath: 'assets/home/sms.png',
          count: _personalChats,
          label: 'Chats',
        ),
      ],
    );
  }

  Widget _buildNotificationCard({
    required String imagePath,
    required int count,
    required String label,
  }) {
    return Container(
      width: 110,
      height: 60,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Image.asset(
              imagePath,
              width: 20,
              height: 20,
              color: Color.fromRGBO(77, 94, 128, 1),
              errorBuilder: (context, error, stackTrace) {
                // Fallback to icons if images not found
                return Icon(
                  label == 'Groups'
                      ? Icons.group_rounded
                      : Icons.person_rounded,
                  color: Color.fromRGBO(77, 94, 128, 1),
                  size: 20,
                );
              },
            ),
          ),
          SizedBox(width: 10),
          Text(
            count.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageAnalyticsCard() {
    return Container(
      height: 132, // Match the height of two notification cards + gap
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Usage',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Today',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: Container(
              child: CustomPaint(
                painter: UsageChartPainter(data: _usageData),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reminder',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: _showAddReminderDialog,
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: _reminders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, color: Colors.grey[600], size: 48),
                        SizedBox(height: 12),
                        Text(
                          'No reminders yet',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap + to add your first reminder',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = _reminders[index];
                      return _buildReminderItem(reminder, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(ReminderItem reminder, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleReminder(index),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: reminder.completed ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: reminder.completed ? Colors.white : Colors.grey[600]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: reminder.completed
                  ? Icon(Icons.check, color: Colors.black, size: 14)
                  : null,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              reminder.title,
              style: TextStyle(
                color: reminder.completed ? Colors.grey[500] : Colors.white,
                fontSize: 16,
                decoration: reminder.completed
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _deleteReminder(index),
            child: Container(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.delete_outline,
                color: Colors.grey[600],
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleReminder(int index) {
    if (!mounted) return;

    setState(() {
      _reminders[index] = ReminderItem(
        title: _reminders[index].title,
        completed: !_reminders[index].completed,
      );
    });
  }

  void _deleteReminder(int index) {
    if (!mounted) return;

    setState(() {
      _reminders.removeAt(index);
    });
  }

  void _showAddReminderDialog() {
    final TextEditingController reminderController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[700]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Reminder',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.grey[400],
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Input field
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 0.5),
                ),
                child: TextField(
                  controller: reminderController,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Enter your reminder...',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    prefixIcon: Container(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.edit,
                        color: Color.fromRGBO(77, 94, 128, 1),
                        size: 20,
                      ),
                    ),
                  ),
                  autofocus: true,
                  maxLines: 1,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _addReminder(value.trim());
                      Navigator.pop(context);
                    }
                  },
                ),
              ),

              SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[600]!,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  // Add button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (reminderController.text.trim().isNotEmpty) {
                          _addReminder(reminderController.text.trim());
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Add Reminder',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addReminder(String title) {
    if (!mounted) return;

    setState(() {
      _reminders.add(ReminderItem(title: title, completed: false));
    });
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }
}

// Analog Clock Painter
class AnalogClockPainter extends CustomPainter {
  final DateTime time;
  final bool isDarkTheme;

  AnalogClockPainter({required this.time, this.isDarkTheme = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw clock face
    final facePaint = Paint()
      ..color = Colors.grey[900]!
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius - 2, facePaint);
    canvas.drawCircle(center, radius - 2, borderPaint);

    // Draw hour markers
    final markerPaint = Paint()
      ..color = Colors.grey[500]!
      ..strokeWidth = 2;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final startRadius = radius - 15;
      final endRadius = radius - 8;

      final start = Offset(
        center.dx + startRadius * math.cos(angle - math.pi / 2),
        center.dy + startRadius * math.sin(angle - math.pi / 2),
      );

      final end = Offset(
        center.dx + endRadius * math.cos(angle - math.pi / 2),
        center.dy + endRadius * math.sin(angle - math.pi / 2),
      );

      canvas.drawLine(start, end, markerPaint);
    }

    // Calculate angles
    final hourAngle = (time.hour % 12 + time.minute / 60) * 30 * math.pi / 180;
    final minuteAngle = time.minute * 6 * math.pi / 180;
    final secondAngle = time.second * 6 * math.pi / 180;

    // Draw hour hand
    final hourPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final hourEnd = Offset(
      center.dx + (radius * 0.5) * math.cos(hourAngle - math.pi / 2),
      center.dy + (radius * 0.5) * math.sin(hourAngle - math.pi / 2),
    );
    canvas.drawLine(center, hourEnd, hourPaint);

    // Draw minute hand
    final minutePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final minuteEnd = Offset(
      center.dx + (radius * 0.7) * math.cos(minuteAngle - math.pi / 2),
      center.dy + (radius * 0.7) * math.sin(minuteAngle - math.pi / 2),
    );
    canvas.drawLine(center, minuteEnd, minutePaint);

    // Draw second hand
    final secondPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    final secondEnd = Offset(
      center.dx + (radius * 0.8) * math.cos(secondAngle - math.pi / 2),
      center.dy + (radius * 0.8) * math.sin(secondAngle - math.pi / 2),
    );
    canvas.drawLine(center, secondEnd, secondPaint);

    // Draw center dot
    final centerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 4, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Usage Chart Painter
class UsageChartPainter extends CustomPainter {
  final List<double> data;

  UsageChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (data.length - 1);

    // Create the curve path
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Complete the fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw fill and stroke
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw data points
    final pointPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] * size.height);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Data Model
class ReminderItem {
  final String title;
  final bool completed;

  ReminderItem({required this.title, required this.completed});
}
