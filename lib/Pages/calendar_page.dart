import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarPage extends StatefulWidget {
  final String token;
  const CalendarPage({required this.token, super.key});

  /// Static cache for Firebase events to prevent re-fetching.
  static Map<String, List<String>>? firebaseEventsCache;

  // --- 1. MOVED HELPER METHOD AND MADE IT STATIC ---
  /// Helper to convert day abbreviations to full names.
  static String _expandDay(String dayAbbr) {
    const dayMap = {
      'Mon': 'Monday',
      'Tue': 'Tuesday',
      'Wed': 'Wednesday',
      'Thu': 'Thursday',
      'Fri': 'Friday',
      'Sat': 'Saturday',
      'Sun': 'Sunday',
    };
    final key = dayMap.keys.firstWhere(
            (k) => k.toLowerCase() == dayAbbr.toLowerCase(),
        orElse: () => '');
    return dayMap[key] ?? dayAbbr;
  }

  // --- 2. MOVED FETCH METHOD AND MADE IT STATIC ---
  /// Fetches academic calendar events from Firebase and populates the cache.
  /// [context] is optional. If provided, it will show a SnackBar on failure.
  static Future<void> loadFirebaseEvents([BuildContext? context]) async {
    // Only fetch if the cache is empty
    if (CalendarPage.firebaseEventsCache != null) {
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('cache')
          .doc('BtechCal')
          .get();

      if (!doc.exists || doc.data() == null) return;

      final data = doc.data()!;
      final eventsArray = data['Events'] as List<dynamic>?;
      if (eventsArray == null || eventsArray.isEmpty) return;

      final eventsMap = eventsArray[0] as Map<String, dynamic>?;
      if (eventsMap == null) return;

      final Map<String, List<String>> fetchedEvents = {};
      final isNumericRegExp = RegExp(r'^-?\d+$');
      final dayRegex = RegExp(r'^\d+\s*-\s*(Mon|Tue|Wed|Thu|Fri|Sat|Sun)$', caseSensitive: false);
      final eventRegex = RegExp(r'^\d+\s*-\s*(.+)$');

      eventsMap.forEach((key, value) {
        final String eventDesc = value.toString().trim();
        String finalEventDesc = eventDesc;

        final matchDay = dayRegex.firstMatch(eventDesc);
        if (matchDay != null) {
          final dayAbbr = matchDay.group(1)!;
          finalEventDesc = _expandDay(dayAbbr); // Use static helper
        } else {
          final matchEvent = eventRegex.firstMatch(eventDesc);
          if (matchEvent != null) {
            finalEventDesc = matchEvent.group(1)!.trim();
          }
        }

        if (finalEventDesc.isNotEmpty && !isNumericRegExp.hasMatch(finalEventDesc)) {
          final parts = key.split('-');
          if (parts.length == 3) {
            final yyyyMMddKey = '${parts[2]}-${parts[1]}-${parts[0]}';
            fetchedEvents.putIfAbsent(yyyyMMddKey, () => []).add(finalEventDesc);
          }
        }
      });

      // Populate the static cache
      CalendarPage.firebaseEventsCache = fetchedEvents;
    } catch (e) {
      // Only show snackbar if context was provided
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load academic calendar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  late SharedPreferences _prefs;
  late String _storageKey;

  // Local user notes, loaded from SharedPreferences
  Map<String, List<String>> localEvents = {};

  // Firebase events, initialized from static cache
  // --- 3. SIMPLIFIED: READS DIRECTLY FROM CACHE ---
  Map<String, List<String>> get _firebaseEvents => CalendarPage.firebaseEventsCache ?? {};
  // Loading state based on cache status
  bool _isFirebaseLoading = CalendarPage.firebaseEventsCache == null;

  final TextEditingController _noteController = TextEditingController();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Color scheme
  final Color _primaryBlue = const Color(0xFF1976D2);
  final Color _lightBlue = const Color(0xFF42A5F5);
  final Color _accentBlue = const Color(0xFF2196F3);
  final Color _darkBlue = const Color(0xFF0D47A1);
  final Color _navyBlue = const Color(0xFF0A2E5E);
  final Color _white = Colors.white;
  final Color _lightGrey = const Color(0xFFF5F5F5);
  final Color _mediumGrey = const Color(0xFFE0E0E0);

  // --- _expandDay helper method REMOVED (it's static now) ---

  @override
  void initState() {
    super.initState();
    final safeToken = widget.token ?? '';
    _storageKey = 'calendar_events_$safeToken';
    _initNotifications(); // Initialize notifications
    _loadAllEvents(); // Load events (checks cache first)
  }

  /// Initializes the local notifications plugin.
  Future<void> _initNotifications() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }


  /// Loads all event data, checking the cache first for Firebase events.
  Future<void> _loadAllEvents() async {
    // Only fetch from Firebase if the cache is empty
    if (CalendarPage.firebaseEventsCache == null) {
      if (mounted) setState(() => _isFirebaseLoading = true);
      await Future.wait([
        _loadLocalEvents(),
        // --- 4. CALLS THE STATIC METHOD ---
        // Pass `context` so it can show an error *on this page* if it fails
        CalendarPage.loadFirebaseEvents(context),
      ]);
      if (mounted) setState(() => _isFirebaseLoading = false);
    } else {
      // Firebase data is cached, just load local notes
      await _loadLocalEvents();
      // No need to call setState, build method will read the cache
    }
  }

  // --- _loadFirebaseEvents METHOD REMOVED (it's static now) ---

  /// Loads user's personal notes from SharedPreferences.
  Future<void> _loadLocalEvents() async {
    _prefs = await SharedPreferences.getInstance();
    final rawJson = _prefs.getString(_storageKey) ?? '{}';
    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      localEvents = decoded.map((key, value) => MapEntry(key, List<String>.from(value as List)));
    } catch (e) {
      localEvents = {};
    }
    // We need setState here to render the loaded local events
    if (mounted) setState(() {});
  }

  /// Saves user's personal notes to SharedPreferences.
  Future<void> _saveLocalEvents() async {
    await _prefs.setString(_storageKey, jsonEncode(localEvents));
  }

  /// Merges Firebase and local events for a given day.
  List<String> _getEventsForDay(DateTime day) {
    final key = _keyFromDate(day);
    // Use the getter which directly reads the static cache
    final firebase = _firebaseEvents[key] ?? [];
    final local = localEvents[key] ?? [];
    return [...firebase, ...local]; // Firebase events first
  }

  /// Adds a personal note for the selected day.
  void _addNote(DateTime day, String note) {
    final key = _keyFromDate(day);
    setState(() {
      localEvents.putIfAbsent(key, () => []).add(note);
    });
    _saveLocalEvents();
  }

  /// Deletes a personal note for the selected day.
  void _deleteNote(DateTime day, String note) {
    final key = _keyFromDate(day);
    setState(() {
      localEvents[key]?.remove(note);
      if (localEvents[key]?.isEmpty ?? false) localEvents.remove(key);
    });
    _saveLocalEvents();
  }

  /// Formats a DateTime into 'yyyy-MM-dd' string.
  String _keyFromDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Checks if two DateTime objects represent the same day.
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Returns the full month name for a given month number (1-12).
  String _monthName(int m) => const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ][m - 1];

  /// Requests notification permissions (primarily for iOS) and schedules a notification.
  Future<void> _requestNotificationPermissionAndSchedule(String note) async {
    final bool? granted = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (granted == true || granted == null) { // Modified check
      _scheduleNoteNotification(note);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder scheduled!', style: TextStyle(color: _white)), backgroundColor: _primaryBlue),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification permission denied', style: TextStyle(color: _white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Schedules a local notification for the given note on the selected day.
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
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: iOSDetails);

    // Schedule for 9:00 AM on the selected day
    final DateTime scheduledTime = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, 9);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      note.hashCode, // Unique ID for the notification
      'Note Reminder', // Title
      note, // Body
      tz.TZDateTime.from(scheduledTime, tz.local), // Scheduled time in local timezone
      platformDetails,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exact, // Use exact timing on Android
    );
  }

  // --- Build Methods (All Unchanged) ---

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
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(isDarkMode ? 0.2 : 0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
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
        gradient: LinearGradient(colors: isDarkMode ? [_navyBlue, _darkBlue, _primaryBlue] : [_primaryBlue, _lightBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _primaryBlue.withOpacity(isDarkMode ? 0.4 : 0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(color: _white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: _navIcon(Icons.chevron_left, () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1)), _white.withOpacity(0.9)),
          ),
          Column(
            children: [
              Text(
                _monthName(_focusedDay.month).toUpperCase(),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _white, letterSpacing: 1.2, shadows: [Shadow(color: Colors.black.withOpacity(0.2), blurRadius: 2, offset: const Offset(1, 1))]),
              ),
              Text(
                _focusedDay.year.toString(),
                style: TextStyle(fontSize: 14, color: _white.withOpacity(0.9), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(color: _white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: _navIcon(Icons.chevron_right, () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1)), _white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCalendar(ThemeProvider theme, bool isDarkMode) {
    final first = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final last = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final firstWeekday = first.weekday % 7; // Adjust Sunday to index 0
    final daysInMonth = last.day;

    return Column(
      children: [
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemCount: 7,
          itemBuilder: (_, idx) {
            final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
            return Container(
              margin: const EdgeInsets.all(4),
              child: Center(child: Text(weekdays[idx], style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? theme.textSecondaryColor : _primaryBlue, fontSize: 12))),
            );
          },
        ),
        const SizedBox(height: 8),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemCount: 42, // Max grid size
          itemBuilder: (_, idx) {
            final dayOffset = idx - firstWeekday;
            if (dayOffset < 0 || dayOffset >= daysInMonth) return Container(); // Empty cells before/after month
            final currentDayNumber = dayOffset + 1;
            final current = DateTime(_focusedDay.year, _focusedDay.month, currentDayNumber);
            final isToday = _isSameDay(current, DateTime.now());
            final isSel = _isSameDay(current, _selectedDay);
            final hasEvt = _getEventsForDay(current).isNotEmpty;

            return GestureDetector(
              onTap: () => setState(() => _selectedDay = current),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSel ? _primaryBlue : (isToday ? _lightBlue.withOpacity(0.3) : Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                  border: hasEvt ? Border.all(color: _accentBlue, width: 2) : (isToday ? Border.all(color: _lightBlue, width: 1) : null),
                ),
                child: Center(
                  child: Text(
                    '$currentDayNumber',
                    style: TextStyle(fontWeight: FontWeight.w600, color: isSel ? _white : (isDarkMode ? theme.textColor : _darkBlue), fontSize: 14),
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
    final localEventsOnDay = localEvents[_keyFromDate(_selectedDay)] ?? [];

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? theme.cardBackgroundColor : _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(isDarkMode ? 0.2 : 0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: isDarkMode ? [_navyBlue, _darkBlue, _primaryBlue] : [_primaryBlue, _lightBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: _primaryBlue.withOpacity(isDarkMode ? 0.4 : 0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _white.withOpacity(0.2), shape: BoxShape.circle), child: Icon(Icons.event_note, color: _white, size: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Events for ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _white, shadows: [Shadow(color: Colors.black.withOpacity(0.2), blurRadius: 2, offset: const Offset(1, 1))]),
                  ),
                ),
                _isFirebaseLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: _white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Text('${events.length}', style: TextStyle(color: _white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ),
          if (events.isEmpty && !_isFirebaseLoading)
            Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: _emptyState(theme, isDarkMode))
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: events.map((event) {
                  final bool isLocal = localEventsOnDay.contains(event);
                  return _eventTile(event, theme, isDarkMode, isLocal);
                }).toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, foregroundColor: _white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 2),
              onPressed: () => _showAddNoteDialog(theme, isDarkMode),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add New Event', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventTile(String event, ThemeProvider theme, bool isDarkMode, bool isLocal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? (isLocal ? theme.cardBackgroundColor : _darkBlue.withOpacity(0.3)) : (isLocal ? _lightGrey : _lightBlue.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isLocal ? _mediumGrey : _primaryBlue.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 40, decoration: BoxDecoration(color: isLocal ? _accentBlue : Colors.orangeAccent, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? theme.textColor : _darkBlue), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(isLocal ? 'Personal Note' : 'Academic Calendar', style: TextStyle(fontSize: 12, color: isDarkMode ? theme.textSecondaryColor : Colors.grey[600])),
              ],
            ),
          ),
          IconButton(icon: Icon(Icons.notifications_active, color: _accentBlue), onPressed: () => _requestNotificationPermissionAndSchedule(event), tooltip: 'Set reminder'),
          if (isLocal)
            IconButton(icon: Icon(Icons.delete_outline, color: Colors.red[300]), onPressed: () => _deleteNote(_selectedDay, event), tooltip: 'Delete event')
          else
            const SizedBox(width: 48), // Spacer to keep alignment
        ],
      ),
    );
  }

  Widget _emptyState(ThemeProvider theme, bool isDarkMode) => Column(
    children: [
      Icon(Icons.event_available, size: 60, color: isDarkMode ? theme.textSecondaryColor : _mediumGrey),
      const SizedBox(height: 16),
      Text('No events scheduled', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isDarkMode ? theme.textSecondaryColor : Colors.grey[600])),
      const SizedBox(height: 8),
      Text('Add your first event to get started!', style: TextStyle(color: isDarkMode ? theme.textSecondaryColor : Colors.grey[500]), textAlign: TextAlign.center),
    ],
  );

  IconButton _navIcon(IconData icon, VoidCallback cb, Color color) => IconButton(icon: Icon(icon, color: color, size: 20), onPressed: cb, splashRadius: 20);

  void _showAddNoteDialog(ThemeProvider theme, bool isDarkMode) {
    _noteController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? theme.cardBackgroundColor : _white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1.0)), // Prevent text scaling
          child: Padding(
            padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom), // Adjust for keyboard
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Add New Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? theme.textColor : _darkBlue)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    style: TextStyle(color: isDarkMode ? theme.textColor : _darkBlue),
                    decoration: InputDecoration(
                      hintText: 'Enter event description...',
                      hintStyle: TextStyle(color: isDarkMode ? theme.textSecondaryColor : Colors.grey[500]),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _mediumGrey)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryBlue, width: 2)),
                      filled: true,
                      fillColor: isDarkMode ? theme.backgroundColor : _lightGrey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), style: TextButton.styleFrom(foregroundColor: isDarkMode ? theme.textSecondaryColor : Colors.grey[600]), child: const Text('Cancel')),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, foregroundColor: _white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
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