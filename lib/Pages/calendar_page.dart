import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class CalendarPage extends StatefulWidget {
  final String regNo;
  const CalendarPage({required this.regNo, super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<String, List<String>> _events = {};
  final TextEditingController _noteController = TextEditingController();
  late SharedPreferences _prefs;
  late String _storageKey;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Enhanced Color scheme - Blue family with white
  final Color _primaryBlue = const Color(0xFF1976D2);
  final Color _lightBlue = const Color(0xFF42A5F5);
  final Color _accentBlue = const Color(0xFF2196F3);
  final Color _darkBlue = const Color(0xFF0D47A1);
  final Color _navyBlue = const Color(0xFF0A2E5E);
  final Color _white = Colors.white;
  final Color _lightGrey = const Color(0xFFF5F5F5);
  final Color _mediumGrey = const Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    _storageKey = 'calendar_events_${widget.regNo}';
    _loadEvents();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadEvents() async {
    _prefs = await SharedPreferences.getInstance();
    final rawJson = _prefs.getString(_storageKey);
    if (rawJson != null) {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      _events = decoded.map((key, value) => MapEntry(key, List<String>.from(value as List)));
    } else {
      _events = {
        '2024-01-15': ['Assignment Due - Mathematics'],
        '2024-01-20': ['Project Presentation - Physics'],
        '2024-01-25': ['Mid-term Exam - Chemistry'],
      };
    }
    setState(() {});
  }

  Future<void> _saveEvents() async {
    await _prefs.setString(_storageKey, jsonEncode(_events));
  }

  List<String> _getEventsForDay(DateTime day) {
    final key = _keyFromDate(day);
    return _events[key] ?? [];
  }

  void _addNote(DateTime day, String note) {
    final key = _keyFromDate(day);
    setState(() {
      _events.putIfAbsent(key, () => []).add(note);
    });
    _saveEvents();
  }

  void _deleteNote(DateTime day, String note) {
    final key = _keyFromDate(day);
    setState(() {
      _events[key]?.remove(note);
      if (_events[key]?.isEmpty ?? false) _events.remove(key);
    });
    _saveEvents();
  }

  String _keyFromDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthName(int m) => const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ][m - 1];

  Future<void> _requestNotificationPermissionAndSchedule(String note) async {
    final bool? granted = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (granted == true) {
      _scheduleNoteNotification(note);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder scheduled!', style: TextStyle(color: _white)),
          backgroundColor: _primaryBlue,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification permission denied', style: TextStyle(color: _white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _scheduleNoteNotification(String note) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'note_channel_id',
      'Notes',
      channelDescription: 'Reminders for your notes',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF1976D2),
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    final DateTime scheduledTime = _selectedDay.add(const Duration(hours: 9));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      note.hashCode,
      'Note Reminder',
      note,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformDetails,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: isDarkMode ? themeProvider.backgroundColor : _lightGrey,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCalendarCard(themeProvider, isDarkMode),
                  const SizedBox(height: 20),
                  _buildEventsCard(themeProvider, isDarkMode),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarCard(ThemeProvider theme, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? theme.cardBackgroundColor : _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(isDarkMode ? 0.2 : 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Enhanced Calendar Header
            _buildEnhancedHeader(theme, isDarkMode),
            const SizedBox(height: 16),
            _buildMiniCalendar(theme, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader(ThemeProvider theme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [_navyBlue, _darkBlue, _primaryBlue]
              : [_primaryBlue, _lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(isDarkMode ? 0.4 : 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left navigation with improved design
          Container(
            decoration: BoxDecoration(
              color: _white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _navIcon(Icons.chevron_left, () {
              setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1));
            }, _white.withOpacity(0.9)),
          ),

          // Month and Year with improved styling
          Column(
            children: [
              Text(
                _monthName(_focusedDay.month).toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _white,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
              Text(
                _focusedDay.year.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: _white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Right navigation with improved design
          Container(
            decoration: BoxDecoration(
              color: _white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _navIcon(Icons.chevron_right, () {
              setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1));
            }, _white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCalendar(ThemeProvider theme, bool isDarkMode) {
    final first = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final last = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final firstWeekday = first.weekday;
    final daysInMonth = last.day;

    return Column(
      children: [
        // Weekday headers with improved styling
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemCount: 7,
          itemBuilder: (_, idx) {
            final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
            return Container(
              margin: const EdgeInsets.all(4),
              child: Center(
                child: Text(
                  weekdays[idx],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? theme.textSecondaryColor : _primaryBlue,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        // Calendar days
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemCount: 42,
          itemBuilder: (_, idx) {
            final dayOffset = idx - (firstWeekday - 1);
            if (dayOffset < 1 || dayOffset > daysInMonth) return Container();
            final current = DateTime(_focusedDay.year, _focusedDay.month, dayOffset);
            final isToday = _isSameDay(current, DateTime.now());
            final isSel = _isSameDay(current, _selectedDay);
            final hasEvt = _getEventsForDay(current).isNotEmpty;

            return GestureDetector(
              onTap: () => setState(() => _selectedDay = current),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSel
                      ? _primaryBlue
                      : isToday
                      ? _lightBlue.withOpacity(0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: hasEvt
                      ? Border.all(color: _accentBlue, width: 2)
                      : isToday
                      ? Border.all(color: _lightBlue, width: 1)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$dayOffset',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSel
                          ? _white
                          : (isDarkMode ? theme.textColor : _darkBlue),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEventsCard(ThemeProvider theme, bool isDarkMode) {
    final events = _getEventsForDay(_selectedDay);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? theme.cardBackgroundColor : _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(isDarkMode ? 0.2 : 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Enhanced Events Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [_navyBlue, _darkBlue, _primaryBlue]
                    : [_primaryBlue, _lightBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: _primaryBlue.withOpacity(isDarkMode ? 0.4 : 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.event_note, color: _white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Events for ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${events.length}',
                    style: TextStyle(
                      color: _white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Events List
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: _emptyState(theme, isDarkMode),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: events.map((event) => _eventTile(event, theme, isDarkMode)).toList(),
              ),
            ),
          // Add Event Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: _white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: () => _showAddNoteDialog(theme, isDarkMode),
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Add New Event',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventTile(String event, ThemeProvider theme, bool isDarkMode) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDarkMode ? theme.cardBackgroundColor : _lightGrey,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _mediumGrey, width: 1),
    ),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: _accentBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? theme.textColor : _darkBlue,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'All day',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? theme.textSecondaryColor : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.notifications_active, color: _accentBlue),
          onPressed: () => _requestNotificationPermissionAndSchedule(event),
          tooltip: 'Set reminder',
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red[300]),
          onPressed: () => _deleteNote(_selectedDay, event),
          tooltip: 'Delete event',
        ),
      ],
    ),
  );

  Widget _emptyState(ThemeProvider theme, bool isDarkMode) => Column(
    children: [
      Icon(
        Icons.event_available,
        size: 60,
        color: isDarkMode ? theme.textSecondaryColor : _mediumGrey,
      ),
      const SizedBox(height: 16),
      Text(
        'No events scheduled',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? theme.textSecondaryColor : Colors.grey[600],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Add your first event to get started!',
        style: TextStyle(
          color: isDarkMode ? theme.textSecondaryColor : Colors.grey[500],
        ),
        textAlign: TextAlign.center,
      ),
    ],
  );

  IconButton _navIcon(IconData icon, VoidCallback cb, Color color) =>
      IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: cb,
        splashRadius: 20,
      );

  void _showAddNoteDialog(ThemeProvider theme, bool isDarkMode) {
    _noteController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? theme.cardBackgroundColor : _white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1.0)),
          child: Padding(
            padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add New Event',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? theme.textColor : _darkBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    style: TextStyle(color: isDarkMode ? theme.textColor : _darkBlue),
                    decoration: InputDecoration(
                      hintText: 'Enter event description...',
                      hintStyle: TextStyle(color: isDarkMode ? theme.textSecondaryColor : Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _mediumGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _primaryBlue, width: 2),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? theme.backgroundColor : _lightGrey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: isDarkMode ? theme.textSecondaryColor : Colors.grey[600],
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: _white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () {
                          if (_noteController.text.trim().isNotEmpty) {
                            _addNote(_selectedDay, _noteController.text.trim());
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Add Event'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}