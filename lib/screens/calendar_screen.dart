import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../theme/default_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool _showCalendar = true;

  // Google Calendar integration
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.events',
    ],
  );

  calendar.CalendarApi? _calendarApi;
  bool _isLoadingEvents = false;
  bool _isConnected = false;
  String _connectionError = '';

  // Events data
  Map<DateTime, List<CalendarEvent>> _events = {};
  List<CalendarEvent> _selectedEvents = [];

  // Todo items for today
  List<TodoItem> _todayTodos = [];
  final TextEditingController _todoController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Search and filter
  final bool _isSearching = false;
  final List<CalendarEvent> _searchResults = [];
  List<TodoItem> _filteredTodos = [];

  // Completer to track async operations
  final List<Completer> _activeCompleters = [];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );

    _slideController = AnimationController(
      duration: AppTheme.longAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _initializeCalendar();
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _initializeCalendar() async {
    if (!mounted) return;

    await _checkGoogleCalendarConnection();
    _loadTodayTodos();
    if (_isConnected && mounted) {
      _loadCalendarEvents();
    }
  }

  Future<void> _checkGoogleCalendarConnection() async {
    if (!mounted) return;

    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null && mounted) {
        final authHeaders = await account.authHeaders;
        final authenticateClient = GoogleAuthClient(authHeaders);
        _calendarApi = calendar.CalendarApi(authenticateClient);

        if (mounted) {
          setState(() {
            _isConnected = true;
            _connectionError = '';
          });
        }
      }
    } catch (e) {
      print('Error checking Google Calendar connection: $e');
      if (mounted) {
        setState(() {
          _isConnected = false;
          _connectionError = e.toString();
        });
      }
    }
  }

  Future<void> _connectGoogleCalendar() async {
    if (!mounted) return;

    final completer = Completer<void>();
    _activeCompleters.add(completer);

    try {
      if (mounted) {
        setState(() {
          _isLoadingEvents = true;
          _connectionError = '';
        });
      }

      // Sign out first to clear any cached authentication issues
      await _googleSignIn.signOut();

      // Then sign in with fresh credentials
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        if (mounted) {
          setState(() => _isLoadingEvents = false);
          _showSnackBar('Sign-in cancelled', AppTheme.warningColor);
        }
        completer.complete();
        return;
      }

      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      _calendarApi = calendar.CalendarApi(authenticateClient);

      // Test the connection with a simple API call
      try {
        await _calendarApi!.calendarList.list();

        if (mounted) {
          setState(() {
            _isConnected = true;
            _connectionError = '';
          });

          await _loadCalendarEvents();
          _showSnackBar(
            'Google Calendar connected successfully!',
            AppTheme.successColor,
          );
        }
      } catch (apiError) {
        // Handle specific API errors
        if (mounted) {
          setState(() {
            _isConnected = false;
            _connectionError = _handleApiError(apiError);
          });
          _showApiErrorDialog(apiError);
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingEvents = false;
          _connectionError = 'Platform error: ${e.message}';
        });
        _showSnackBar('Platform error: ${e.message}', AppTheme.errorColor);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingEvents = false;
          _connectionError = e.toString();
        });
        _showSnackBar(
          'Connection failed: ${e.toString()}',
          AppTheme.errorColor,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingEvents = false);
      }
      completer.complete();
    }
  }

  String _handleApiError(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('403')) {
      if (errorString.contains('Calendar API has not been used')) {
        return 'Google Calendar API not enabled. Please enable it in Google Cloud Console.';
      } else if (errorString.contains('insufficient permissions')) {
        return 'Insufficient permissions. Please check OAuth scopes.';
      } else {
        return 'Access denied. Please check your API credentials.';
      }
    } else if (errorString.contains('401')) {
      return 'Authentication failed. Please sign in again.';
    } else if (errorString.contains('404')) {
      return 'Calendar not found or inaccessible.';
    } else if (errorString.contains('429')) {
      return 'Too many requests. Please try again later.';
    } else if (errorString.contains('500')) {
      return 'Google Calendar service temporarily unavailable.';
    }

    return 'Calendar connection error: $errorString';
  }

  void _showApiErrorDialog(dynamic error) {
    if (!mounted) return;

    final errorString = error.toString();
    String title = 'Connection Error';
    String message = 'Unable to connect to Google Calendar.';
    String action = 'Try Again';
    VoidCallback? actionCallback;

    if (errorString.contains('Calendar API has not been used')) {
      title = 'API Not Enabled';
      message =
          'The Google Calendar API needs to be enabled in your Google Cloud Console.\n\n'
          'Steps to fix:\n'
          '1. Go to Google Cloud Console\n'
          '2. Navigate to APIs & Services → Library\n'
          '3. Search for "Google Calendar API"\n'
          '4. Click "Enable"\n'
          '5. Wait 2-3 minutes and try again';
      action = 'Open Console';
      actionCallback = () {
        _showSnackBar(
          'Please enable Google Calendar API in Cloud Console',
          AppTheme.warningColor,
        );
      };
    } else if (errorString.contains('403')) {
      title = 'Access Denied';
      message =
          'Your app doesn\'t have the required permissions.\n\n'
          'This might be because:\n'
          '• API quotas exceeded\n'
          '• OAuth scopes are incorrect\n'
          '• App verification is required';
      action = 'Check Settings';
    } else if (errorString.contains('401')) {
      title = 'Authentication Failed';
      message = 'Please sign out and sign in again with your Google account.';
      action = 'Sign In Again';
      actionCallback = () => _connectGoogleCalendar();
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Error Details:\n${errorString.length > 200 ? '${errorString.substring(0, 200)}...' : errorString}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.grey[600],
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
                onPressed: () {
                  Navigator.pop(context);
                  if (actionCallback != null) {
                    actionCallback();
                  } else {
                    _connectGoogleCalendar();
                  }
                },
                child: Text(action),
              ),
            ],
          ),
    );
  }

  Future<void> _loadCalendarEvents() async {
    if (_calendarApi == null || !mounted) return;

    final completer = Completer<void>();
    _activeCompleters.add(completer);

    if (mounted) {
      setState(() => _isLoadingEvents = true);
    }

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: startOfMonth.toUtc(),
        timeMax: endOfMonth.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
        maxResults: 100,
      );

      if (!mounted) {
        completer.complete();
        return;
      }

      final Map<DateTime, List<CalendarEvent>> eventMap = {};

      for (final event in events.items ?? []) {
        if (event.start?.dateTime != null || event.start?.date != null) {
          final eventDate =
              event.start?.dateTime?.toLocal() ??
              DateTime.parse(event.start!.date!);
          final dayKey = DateTime(
            eventDate.year,
            eventDate.month,
            eventDate.day,
          );

          final calendarEvent = CalendarEvent(
            id: event.id ?? '',
            title: event.summary ?? 'No title',
            description: event.description ?? '',
            startTime: eventDate,
            endTime:
                event.end?.dateTime?.toLocal() ??
                DateTime.parse(event.end?.date ?? event.start!.date!),
            isAllDay: event.start?.date != null,
            location: event.location ?? '',
            attendees:
                event.attendees?.map((a) => a.email ?? '').toList() ?? [],
          );

          if (eventMap[dayKey] == null) {
            eventMap[dayKey] = [];
          }
          eventMap[dayKey]!.add(calendarEvent);
        }
      }

      if (mounted) {
        setState(() {
          _events = eventMap;
          _selectedEvents = _getEventsForDay(_selectedDay);
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingEvents = false);
        _showSnackBar('Failed to load events: $e', AppTheme.errorColor);
      }
      print('Error loading calendar events: $e');
    } finally {
      completer.complete();
    }
  }

  void _loadTodayTodos() {
    if (!mounted) return;

    final today = DateTime.now();

    setState(() {
      _todayTodos = [
        TodoItem(
          id: '1',
          title: 'Morning voice training session',
          completed: false,
          createdAt: DateTime.now(),
          dueDate: today,
          priority: TodoPriority.high,
          category: 'Health',
        ),
        TodoItem(
          id: '2',
          title: 'Review calendar appointments',
          completed: true,
          createdAt: DateTime.now(),
          dueDate: today,
          priority: TodoPriority.medium,
          category: 'Work',
        ),
        TodoItem(
          id: '3',
          title: 'Community interaction check',
          completed: false,
          createdAt: DateTime.now(),
          dueDate: today,
          priority: TodoPriority.low,
          category: 'Social',
        ),
        TodoItem(
          id: '4',
          title: 'Update project documentation',
          completed: false,
          createdAt: DateTime.now(),
          dueDate: today.add(Duration(days: 1)),
          priority: TodoPriority.medium,
          category: 'Work',
        ),
      ];
      _filteredTodos = List.from(_todayTodos);
    });
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final dayKey = DateTime(day.year, day.month, day.day);
    return _events[dayKey] ?? [];
  }

  Future<void> _addTodoItem(
    String title, {
    TodoPriority priority = TodoPriority.medium,
    String category = 'General',
  }) async {
    if (title.trim().isEmpty || !mounted) return;

    final newTodo = TodoItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      completed: false,
      createdAt: DateTime.now(),
      dueDate: DateTime.now(),
      priority: priority,
      category: category,
    );

    if (mounted) {
      setState(() {
        _todayTodos.add(newTodo);
        _filteredTodos = List.from(_todayTodos);
      });
    }

    // Sync to Google Calendar if connected
    if (_isConnected && mounted) {
      await _syncTodoToGoogleCalendar(newTodo);
    }
  }

  Future<void> _syncTodoToGoogleCalendar(TodoItem todo) async {
    if (_calendarApi == null || !mounted) return;

    try {
      final event = calendar.Event(
        summary: '📝 ${todo.title}',
        description:
            'Todo item created in BBBD app\nCategory: ${todo.category}\nPriority: ${todo.priority.toString().split('.').last}',
        start: calendar.EventDateTime(dateTime: todo.dueDate.toUtc()),
        end: calendar.EventDateTime(
          dateTime: todo.dueDate.add(Duration(hours: 1)).toUtc(),
        ),
        colorId: _getPriorityColorId(todo.priority),
      );

      await _calendarApi!.events.insert(event, 'primary');

      if (mounted) {
        await _loadCalendarEvents(); // Refresh events
        _showSnackBar('Todo synced to Google Calendar', AppTheme.successColor);
      }
    } catch (e) {
      print('Error syncing todo to Google Calendar: $e');
      if (mounted) {
        _showSnackBar('Failed to sync todo: $e', AppTheme.errorColor);
      }
    }
  }

  String _getPriorityColorId(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return '11'; // Red
      case TodoPriority.medium:
        return '5'; // Yellow
      case TodoPriority.low:
        return '2'; // Green
    }
  }

  void _toggleTodoItem(String id) {
    if (!mounted) return;

    setState(() {
      final index = _todayTodos.indexWhere((todo) => todo.id == id);
      if (index != -1) {
        _todayTodos[index] = _todayTodos[index].copyWith(
          completed: !_todayTodos[index].completed,
        );
        _filteredTodos = List.from(_todayTodos);
      }
    });
  }

  void _deleteTodoItem(String id) {
    if (!mounted) return;

    setState(() {
      _todayTodos.removeWhere((todo) => todo.id == id);
      _filteredTodos = List.from(_todayTodos);
    });
  }

  void _searchTodos(String query) {
    if (!mounted) return;

    setState(() {
      if (query.isEmpty) {
        _filteredTodos = List.from(_todayTodos);
      } else {
        _filteredTodos =
            _todayTodos
                .where(
                  (todo) =>
                      todo.title.toLowerCase().contains(query.toLowerCase()) ||
                      todo.category.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  void _filterTodosByCategory(String? category) {
    if (!mounted) return;

    setState(() {
      if (category == null || category == 'All') {
        _filteredTodos = List.from(_todayTodos);
      } else {
        _filteredTodos =
            _todayTodos.where((todo) => todo.category == category).toList();
      }
    });
  }

  Future<void> _refreshCalendar() async {
    if (!mounted) return;

    if (_isConnected) {
      await _loadCalendarEvents();
    }
    _loadTodayTodos();
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: _refreshCalendar,
            color: AppTheme.getPrimaryColor(context),
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(AppTheme.mediumSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connection Status
                  if (!_isConnected) _buildConnectionPrompt(),

                  // Search Bar (when in tasks view)
                  if (!_showCalendar) _buildSearchBar(),

                  // Calendar or Tasks based on toggle
                  if (_showCalendar) ...[
                    _buildCalendarWidget(),
                    SizedBox(height: AppTheme.largeSpacing),
                    _buildSelectedDayEvents(),
                  ] else ...[
                    _buildTodayHeader(),
                    SizedBox(height: AppTheme.mediumSpacing),
                    _buildCategoryFilter(),
                    SizedBox(height: AppTheme.mediumSpacing),
                    _buildTodayTodoSection(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCalendar ? _showAddEventDialog : _showAddTodoDialog,
        backgroundColor: AppTheme.getPrimaryColor(context),
        foregroundColor: AppTheme.microphoneColor,
        tooltip: _showCalendar ? 'Add Event' : 'Add Task',
        child: Icon(_showCalendar ? Icons.event : Icons.add_task),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Calendar & Tasks',
        style: AppTheme.getAppBarTitleStyle(context),
      ),
      centerTitle: true,
      actions: [
        // Calendar/Tasks toggle
        IconButton(
          onPressed: () {
            if (mounted) {
              setState(() {
                _showCalendar = !_showCalendar;
              });
            }
          },
          icon: AnimatedSwitcher(
            duration: AppTheme.shortAnimation,
            child: Icon(
              _showCalendar ? Icons.list : Icons.calendar_month,
              key: ValueKey(_showCalendar),
              color: AppTheme.getIconColor(context),
            ),
          ),
          tooltip: _showCalendar ? 'Show Tasks' : 'Show Calendar',
        ),
        // Connection status indicator
        if (_isConnected)
          Container(
            margin: EdgeInsets.only(right: 8),
            child: _buildConnectionStatus(),
          ),
        // Menu
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder:
              (context) => [
                if (!_isConnected)
                  PopupMenuItem(
                    value: 'connect',
                    child: Row(
                      children: [
                        Icon(Icons.link, size: 20),
                        SizedBox(width: 8),
                        Text('Connect Google Calendar'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text('Refresh'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, size: 20),
                      SizedBox(width: 8),
                      Text('Settings'),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Widget _buildConnectionPrompt() {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.largeSpacing),
      child: AppTheme.buildThemedCard(
        context: context,
        child: Column(
          children: [
            Icon(
              Icons.cloud_off,
              size: AppTheme.largeIcon,
              color: AppTheme.warningColor,
            ),
            SizedBox(height: AppTheme.smallSpacing),
            Text(
              'Google Calendar Not Connected',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextColor(context),
              ),
            ),
            SizedBox(height: AppTheme.smallSpacing),
            Text(
              'Connect your Google Calendar to sync events and todos',
              style: AppTheme.subtitleTextStyle,
              textAlign: TextAlign.center,
            ),
            if (_connectionError.isNotEmpty) ...[
              SizedBox(height: AppTheme.smallSpacing),
              Container(
                padding: EdgeInsets.all(AppTheme.smallSpacing),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                ),
                child: Text(
                  'Error: $_connectionError',
                  style: TextStyle(fontSize: 12, color: AppTheme.errorColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            SizedBox(height: AppTheme.smallSpacing),
            Container(
              padding: EdgeInsets.all(AppTheme.smallSpacing),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.smallRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.warningColor,
                    size: 16,
                  ),
                  SizedBox(width: AppTheme.smallSpacing),
                  Expanded(
                    child: Text(
                      'Make sure Google Calendar API is enabled in your Google Cloud Console',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppTheme.mediumSpacing),
            ElevatedButton.icon(
              onPressed: _isLoadingEvents ? null : _connectGoogleCalendar,
              icon:
                  _isLoadingEvents
                      ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Icon(Icons.link),
              label: Text(
                _isLoadingEvents ? 'Connecting...' : 'Connect Google Calendar',
              ),
              style: AppTheme.getPrimaryButtonStyle(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.smallSpacing,
        vertical: AppTheme.tinySpacing,
      ),
      decoration: BoxDecoration(
        color:
            _isConnected
                ? AppTheme.successColor.withOpacity(0.1)
                : AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isConnected ? Icons.check_circle : Icons.cloud_off,
            size: 16,
            color: _isConnected ? AppTheme.successColor : AppTheme.warningColor,
          ),
          SizedBox(width: AppTheme.tinySpacing),
          Text(
            _isConnected ? 'Synced' : 'Offline',
            style: TextStyle(
              color:
                  _isConnected ? AppTheme.successColor : AppTheme.warningColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.mediumSpacing),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          prefixIcon: Icon(Icons.search),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _searchTodos('');
                    },
                  )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
          ),
        ),
        onChanged: _searchTodos,
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', ...Set.from(_todayTodos.map((t) => t.category))];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == 'All';

          return Container(
            margin: EdgeInsets.only(right: AppTheme.smallSpacing),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) => _filterTodosByCategory(category),
              backgroundColor: AppTheme.greyLight,
              selectedColor: AppTheme.getPrimaryColor(context).withOpacity(0.2),
              checkmarkColor: AppTheme.getPrimaryColor(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodayHeader() {
    final today = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d').format(today);
    final completedCount = _filteredTodos.where((t) => t.completed).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            Text(formattedDate, style: AppTheme.subtitleTextStyle),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$completedCount/${_filteredTodos.length}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.getPrimaryColor(context),
              ),
            ),
            Text('completed', style: AppTheme.subtitleTextStyle),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarWidget() {
    return AppTheme.buildThemedCard(
      context: context,
      child: TableCalendar<CalendarEvent>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(color: AppTheme.getTextColor(context)),
          selectedDecoration: BoxDecoration(
            gradient: AppTheme.getPrimaryGradient(context),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppTheme.getPrimaryColor(context).withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          defaultTextStyle: TextStyle(color: AppTheme.getTextColor(context)),
          markerDecoration: BoxDecoration(
            color: AppTheme.getPrimaryColor(context),
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonDecoration: BoxDecoration(
            color: AppTheme.getPrimaryColor(context),
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          ),
          formatButtonTextStyle: TextStyle(
            color: AppTheme.microphoneColor,
            fontWeight: FontWeight.w600,
          ),
          titleTextStyle: TextStyle(
            color: AppTheme.getTextColor(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay) && mounted) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              _selectedEvents = _getEventsForDay(selectedDay);
            });
          }
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format && mounted) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          if (_isConnected && mounted) {
            _loadCalendarEvents();
          }
        },
      ),
    );
  }

  Widget _buildSelectedDayEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Events for ${DateFormat('MMMM d, y').format(_selectedDay)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            if (_isLoadingEvents)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.getPrimaryColor(context),
                ),
              ),
          ],
        ),
        SizedBox(height: AppTheme.mediumSpacing),
        if (_selectedEvents.isEmpty)
          AppTheme.buildThemedCard(
            context: context,
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_available,
                    size: AppTheme.largeIcon,
                    color: AppTheme.getIconColor(context),
                  ),
                  SizedBox(height: AppTheme.smallSpacing),
                  Text(
                    'No events for this day',
                    style: AppTheme.subtitleTextStyle,
                  ),
                  SizedBox(height: AppTheme.smallSpacing),
                  TextButton(
                    onPressed: _showAddEventDialog,
                    child: Text('Add an event'),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _selectedEvents.length,
            itemBuilder: (context, index) {
              final event = _selectedEvents[index];
              return Container(
                margin: EdgeInsets.only(bottom: AppTheme.smallSpacing),
                child: AppTheme.buildThemedCard(
                  context: context,
                  padding: EdgeInsets.all(AppTheme.mediumSpacing),
                  child: InkWell(
                    onTap: () => _showEventDetails(event),
                    borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppTheme.getPrimaryColor(context),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(width: AppTheme.mediumSpacing),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.getTextColor(context),
                                ),
                              ),
                              if (event.description.isNotEmpty) ...[
                                SizedBox(height: AppTheme.tinySpacing),
                                Text(
                                  event.description,
                                  style: AppTheme.subtitleTextStyle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              SizedBox(height: AppTheme.tinySpacing),
                              Row(
                                children: [
                                  Icon(
                                    event.isAllDay
                                        ? Icons.calendar_today
                                        : Icons.access_time,
                                    size: 16,
                                    color: AppTheme.getIconColor(context),
                                  ),
                                  SizedBox(width: AppTheme.tinySpacing),
                                  Text(
                                    event.isAllDay
                                        ? 'All day'
                                        : '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppTheme.getIconColor(context),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTodayTodoSection() {
    return AppTheme.buildThemedCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tasks',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              Row(
                children: [
                  if (_isConnected)
                    Icon(Icons.sync, size: 16, color: AppTheme.successColor),
                  SizedBox(width: AppTheme.smallSpacing),
                  IconButton(
                    onPressed: _showAddTodoDialog,
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: AppTheme.getPrimaryColor(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: AppTheme.mediumSpacing),
          if (_filteredTodos.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.task_alt,
                    size: AppTheme.largeIcon,
                    color: AppTheme.getIconColor(context),
                  ),
                  SizedBox(height: AppTheme.smallSpacing),
                  Text(
                    _searchController.text.isNotEmpty
                        ? 'No tasks match your search'
                        : 'No tasks for today',
                    style: AppTheme.subtitleTextStyle,
                  ),
                  SizedBox(height: AppTheme.smallSpacing),
                  TextButton(
                    onPressed: _showAddTodoDialog,
                    child: Text('Add your first task'),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _filteredTodos.length,
              separatorBuilder:
                  (context, index) =>
                      Divider(color: AppTheme.getDividerColor(context)),
              itemBuilder: (context, index) {
                final todo = _filteredTodos[index];
                return _buildTodoItem(todo);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTodoItem(TodoItem todo) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: todo.completed,
        onChanged: (value) => _toggleTodoItem(todo.id),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration:
              todo.completed ? TextDecoration.lineThrough : TextDecoration.none,
          color:
              todo.completed
                  ? AppTheme.getSubtitleColor(context)
                  : AppTheme.getTextColor(context),
          fontWeight: todo.completed ? FontWeight.w400 : FontWeight.w500,
        ),
      ),
      subtitle: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getPriorityColor(todo.priority).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            ),
            child: Text(
              todo.priority.toString().split('.').last.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _getPriorityColor(todo.priority),
              ),
            ),
          ),
          SizedBox(width: AppTheme.smallSpacing),
          Text(todo.category, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isConnected)
            IconButton(
              onPressed: () => _syncTodoToGoogleCalendar(todo),
              icon: Icon(
                Icons.sync,
                color: AppTheme.getIconColor(context),
                size: 20,
              ),
              tooltip: 'Sync to Google Calendar',
            ),
          IconButton(
            onPressed: () => _deleteTodoItem(todo.id),
            icon: Icon(
              Icons.delete_outline,
              color: AppTheme.errorColor,
              size: 20,
            ),
            tooltip: 'Delete task',
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return Colors.red;
      case TodoPriority.medium:
        return Colors.orange;
      case TodoPriority.low:
        return Colors.green;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'connect':
        _connectGoogleCalendar();
        break;
      case 'refresh':
        _refreshCalendar();
        break;
      case 'settings':
        _showCalendarSettings();
        break;
    }
  }

  void _showAddTodoDialog() {
    final titleController = TextEditingController();
    TodoPriority selectedPriority = TodoPriority.medium;
    String selectedCategory = 'General';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('Add New Task'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: 'Enter your task...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.mediumRadius,
                            ),
                          ),
                        ),
                        autofocus: true,
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            _addTodoItem(
                              value,
                              priority: selectedPriority,
                              category: selectedCategory,
                            );
                            Navigator.pop(context);
                          }
                        },
                      ),
                      SizedBox(height: AppTheme.mediumSpacing),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<TodoPriority>(
                              value: selectedPriority,
                              decoration: InputDecoration(
                                labelText: 'Priority',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.mediumRadius,
                                  ),
                                ),
                              ),
                              items:
                                  TodoPriority.values.map((priority) {
                                    return DropdownMenuItem(
                                      value: priority,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: _getPriorityColor(
                                                priority,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            priority
                                                .toString()
                                                .split('.')
                                                .last
                                                .toUpperCase(),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedPriority = value!;
                                });
                              },
                            ),
                          ),
                          SizedBox(width: AppTheme.mediumSpacing),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'Category',
                                hintText: 'Work, Personal...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.mediumRadius,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                selectedCategory =
                                    value.isNotEmpty ? value : 'General';
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (titleController.text.trim().isNotEmpty) {
                          _addTodoItem(
                            titleController.text.trim(),
                            priority: selectedPriority,
                            category: selectedCategory,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: Text('Add Task'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AddEventDialog(
            onEventAdded: (
              title,
              description,
              startTime,
              endTime,
              location,
            ) async {
              await _addGoogleCalendarEvent(
                title,
                description,
                startTime,
                endTime,
                location,
              );
            },
          ),
    );
  }

  void _showEventDetails(CalendarEvent event) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(event.title),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (event.description.isNotEmpty) ...[
                    Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(event.description),
                    SizedBox(height: 16),
                  ],
                  Text('Time:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(
                    event.isAllDay
                        ? 'All day'
                        : '${DateFormat('MMM d, y • HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                  ),
                  if (event.location.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      'Location:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(event.location),
                  ],
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

  Future<void> _addGoogleCalendarEvent(
    String title,
    String description,
    DateTime startTime,
    DateTime endTime,
    String location,
  ) async {
    if (_calendarApi == null || !mounted) {
      _showSnackBar(
        'Please connect Google Calendar first',
        AppTheme.warningColor,
      );
      return;
    }

    try {
      final event = calendar.Event(
        summary: title,
        description: description,
        location: location,
        start: calendar.EventDateTime(dateTime: startTime.toUtc()),
        end: calendar.EventDateTime(dateTime: endTime.toUtc()),
      );

      await _calendarApi!.events.insert(event, 'primary');

      if (mounted) {
        await _loadCalendarEvents();
        _showSnackBar('Event added to Google Calendar', AppTheme.successColor);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to add event: $e', AppTheme.errorColor);
      }
    }
  }

  void _showCalendarSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(AppTheme.largeSpacing),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calendar Settings',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppTheme.largeSpacing),
                SwitchListTile(
                  title: Text('Auto-sync with Google Calendar'),
                  subtitle: Text('Automatically sync events and tasks'),
                  value: _isConnected,
                  onChanged: (value) {
                    if (value) {
                      _connectGoogleCalendar();
                    } else {
                      _disconnectGoogleCalendar();
                    }
                  },
                ),
                ListTile(
                  title: Text('Default Calendar View'),
                  subtitle: Text('Choose your preferred calendar view'),
                  trailing: DropdownButton<CalendarFormat>(
                    value: _calendarFormat,
                    onChanged: (CalendarFormat? newValue) {
                      if (newValue != null && mounted) {
                        setState(() {
                          _calendarFormat = newValue;
                        });
                        Navigator.pop(context);
                      }
                    },
                    items:
                        CalendarFormat.values
                            .map<DropdownMenuItem<CalendarFormat>>((
                              CalendarFormat value,
                            ) {
                              return DropdownMenuItem<CalendarFormat>(
                                value: value,
                                child: Text(value.name.toUpperCase()),
                              );
                            })
                            .toList(),
                  ),
                ),
                if (_isConnected) ...[
                  SizedBox(height: AppTheme.largeSpacing),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _disconnectGoogleCalendar,
                      icon: Icon(Icons.link_off, color: Colors.red),
                      label: Text(
                        'Disconnect Google Calendar',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
    );
  }

  Future<void> _disconnectGoogleCalendar() async {
    try {
      await _googleSignIn.signOut();
      if (mounted) {
        setState(() {
          _isConnected = false;
          _calendarApi = null;
          _events.clear();
          _selectedEvents.clear();
        });
        _showSnackBar('Google Calendar disconnected', AppTheme.warningColor);
      }
    } catch (e) {
      print('Error disconnecting Google Calendar: $e');
    }
  }

  @override
  void dispose() {
    // Cancel any active operations
    for (final completer in _activeCompleters) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _activeCompleters.clear();

    // Dispose controllers and animations
    _fadeController.dispose();
    _slideController.dispose();
    _todoController.dispose();
    _searchController.dispose();

    super.dispose();
  }
}

// Data models
class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final String location;
  final List<String> attendees;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.isAllDay,
    this.location = '',
    this.attendees = const [],
  });
}

enum TodoPriority { high, medium, low }

class TodoItem {
  final String id;
  final String title;
  final bool completed;
  final DateTime createdAt;
  final DateTime dueDate;
  final TodoPriority priority;
  final String category;

  TodoItem({
    required this.id,
    required this.title,
    required this.completed,
    required this.createdAt,
    required this.dueDate,
    required this.priority,
    required this.category,
  });

  TodoItem copyWith({
    String? id,
    String? title,
    bool? completed,
    DateTime? createdAt,
    DateTime? dueDate,
    TodoPriority? priority,
    String? category,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      category: category ?? this.category,
    );
  }
}

// Add Event Dialog
class AddEventDialog extends StatefulWidget {
  final Function(String, String, DateTime, DateTime, String) onEventAdded;

  const AddEventDialog({super.key, required this.onEventAdded});

  @override
  _AddEventDialogState createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(Duration(hours: 1));
  bool _isAllDay = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add New Event'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Event Title *',
                hintText: 'Enter event title...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                ),
              ),
            ),
            SizedBox(height: AppTheme.mediumSpacing),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Enter description...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                ),
              ),
              maxLines: 3,
            ),
            SizedBox(height: AppTheme.mediumSpacing),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                hintText: 'Enter location...',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                ),
              ),
            ),
            SizedBox(height: AppTheme.mediumSpacing),
            SwitchListTile(
              title: Text('All Day'),
              value: _isAllDay,
              onChanged: (value) {
                setState(() {
                  _isAllDay = value;
                  if (_isAllDay) {
                    _startTime = DateTime(
                      _startTime.year,
                      _startTime.month,
                      _startTime.day,
                    );
                    _endTime = DateTime(
                      _endTime.year,
                      _endTime.month,
                      _endTime.day,
                      23,
                      59,
                    );
                  }
                });
              },
            ),
            if (!_isAllDay) ...[
              ListTile(
                title: Text('Start Time'),
                subtitle: Text(
                  DateFormat('MMM d, y • HH:mm').format(_startTime),
                ),
                trailing: Icon(Icons.access_time),
                onTap: () => _selectDateTime(true),
              ),
              ListTile(
                title: Text('End Time'),
                subtitle: Text(DateFormat('MMM d, y • HH:mm').format(_endTime)),
                trailing: Icon(Icons.access_time),
                onTap: () => _selectDateTime(false),
              ),
            ] else ...[
              ListTile(
                title: Text('Date'),
                subtitle: Text(DateFormat('MMM d, y').format(_startTime)),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(),
              ),
            ],
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
            if (_titleController.text.trim().isNotEmpty) {
              widget.onEventAdded(
                _titleController.text.trim(),
                _descriptionController.text.trim(),
                _startTime,
                _endTime,
                _locationController.text.trim(),
              );
              Navigator.pop(context);
            }
          },
          child: Text('Add Event'),
        ),
      ],
    );
  }

  Future<void> _selectDateTime(bool isStartTime) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartTime ? _startTime : _endTime,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          isStartTime ? _startTime : _endTime,
        ),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        setState(() {
          if (isStartTime) {
            _startTime = dateTime;
            if (_endTime.isBefore(_startTime)) {
              _endTime = _startTime.add(Duration(hours: 1));
            }
          } else {
            if (dateTime.isAfter(_startTime)) {
              _endTime = dateTime;
            }
          }
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _startTime = DateTime(date.year, date.month, date.day);
        _endTime = DateTime(date.year, date.month, date.day, 23, 59);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}

// Google Auth Client
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}
