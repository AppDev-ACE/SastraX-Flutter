import 'dart:async'; // Added for Timer/Future.delayed
import 'dart:convert';
import 'dart:ui'; // For ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ApiEndpoints.dart'; // Ensure this path is correct
import 'FeeDuePage.dart'; // Ensure this path is correct
import 'more_options_page.dart'; // Ensure this path is correct
import 'subject_wise_attendance.dart'; // Ensure this path is correct
import '../components/timetable_widget.dart'; // Ensure this path is correct
import '../models/theme_model.dart'; // Ensure this path is correct
import '../components/theme_toggle_button.dart'; // Ensure this path is correct
import '../components/neon_container.dart'; // Ensure this path is correct
import '../components/attendance_pie_chart.dart'; // Ensure this path is correct
import 'profile_page.dart'; // Ensure this path is correct
import 'calendar_page.dart'; // Ensure this path is correct
import 'community_page.dart'; // Ensure this path is correct
import 'mess_menu_page.dart'; // Ensure this path is correct
import 'captcha_dialog.dart'; // Ensure this path is correct

// --- HomePage Code (Unchanged) ---
class HomePage extends StatefulWidget {
  final String token; final String url; final String regNo;
  const HomePage({super.key, required this.token, required this.url, required this.regNo});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int _currentIndex = 2; late List<Widget> _pages; late String _currentToken;
  @override void initState() { super.initState(); _currentToken = widget.token; if (_currentToken.isEmpty && widget.regNo.isNotEmpty) { print("Error: HomePage initState invalid token"); _currentToken = ""; } _buildPages(); }
  void _buildPages() { if (_currentToken.isEmpty && widget.regNo.isNotEmpty) { print("Error: _buildPages invalid token"); _pages = List.generate(5, (_) => const Center(child: Text("Error: Invalid Session"))); return; } _pages = [ CalendarPage(token: _currentToken), const CommunityPage(), DashboardScreen(key: ValueKey('DashboardScreen_${widget.regNo}_$_currentToken'), token: _currentToken, url: widget.url, regNo: widget.regNo, onTokenUpdated: _updateToken), MessMenuPage(url: widget.url), MoreOptionsScreen(token: _currentToken, url: widget.url, regNo: widget.regNo) ]; }
  Future<void> _updateToken(String newToken) async { final prefs = await SharedPreferences.getInstance(); await prefs.setString('authToken', newToken); if (mounted) { setState(() { _currentToken = newToken; _buildPages(); }); } }
  @override Widget build(BuildContext context) { if (_currentToken.isEmpty && widget.regNo.isNotEmpty) { return Scaffold(appBar: AppBar(title: const Text("Error")), body: const Center(child: Text("Invalid session state."))); } final screenWidth = MediaQuery.of(context).size.width; final appBarHeight = screenWidth * 0.2; return Consumer<ThemeProvider>( builder: (_, theme, __) => Scaffold( backgroundColor: theme.isDarkMode ? AppTheme.darkBackground : Colors.white, appBar: AppBar( leadingWidth: appBarHeight, toolbarHeight: appBarHeight, automaticallyImplyLeading: false, leading: Padding(padding: const EdgeInsets.all(8.0), child: Image.asset('assets/icon/Logo.png', fit: BoxFit.contain)), title: const FittedBox(fit: BoxFit.scaleDown, child: Text('SastraX', style: TextStyle(fontWeight: FontWeight.bold))), centerTitle: true, backgroundColor: theme.isDarkMode ? AppTheme.darkBackground : AppTheme.primaryBlue, elevation: 0, actions: [ Padding(padding: const EdgeInsets.only(right: 16), child: ThemeToggleButton(isDarkMode: theme.isDarkMode, onToggle: theme.toggleTheme)) ] ), body: IndexedStack(index: _currentIndex, children: _pages), bottomNavigationBar: BottomNavigationBar( currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i), type: BottomNavigationBarType.fixed, backgroundColor: theme.isDarkMode ? AppTheme.darkSurface : Colors.white, selectedItemColor: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue, unselectedItemColor: Colors.grey, items: const [ BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'), BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'), BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'), BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Mess'), BottomNavigationBarItem(icon: Icon(Icons.more_horiz_outlined), label: 'More') ] ) ) ); }
}


// -------------------- DashboardScreen (Using Polling Logic) --------------------
class DashboardScreen extends StatefulWidget {
  final String token;
  final String url;
  final String regNo;
  final Function(String) onTokenUpdated;

  const DashboardScreen({
    super.key,
    required this.token,
    required this.url,
    required this.regNo,
    required this.onTokenUpdated,
  });

  static Map<String, dynamic>? dashboardCache;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // UI State
  bool showExamSchedule = false;
  String? _error;
  bool _isLoading = true; // Tracks overall loading state
  bool _isRefreshing = false; // Tracks API fetch/refresh state

  // Data State (Restored state variables)
  double attendancePercent = 0;
  int attendedClasses = 0;
  int totalClasses = 0;
  String? cgpa;
  bool isBirthday = false;
  String? studentName;
  int feeDue = 0;
  int bunks = 0; // Requires 'bunkdata' from Firestore
  List timetableData = [];
  List hourWiseAttendanceData = [];
  List subjectAttendanceData = [];
  List courseMapData = [];
  List semGradesData = []; // Added for processing

  // Controllers
  late final ApiEndpoints api;
  late ConfettiController _confettiController;

  // Define essential keys needed before showing the main UI
  final List<String> _essentialKeys = ['profile', 'semGrades', 'cgpa']; // Add 'bunkdata' if needed for bunks calc

  @override
  void initState() {
    super.initState();
    api = ApiEndpoints(widget.url);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    print("DashboardScreen initState: Received token = '${widget.token}'");
    _loadInitialData(); // Async check and load process
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // --- REVISED: Checks Firestore ONCE, fetches if needed, then polls ---
  Future<void> _loadInitialData() async {
    if (mounted) setState(() { _isLoading = true; _error = null; }); // Start loading

    // Handle Invalid Session
    if (widget.token.isEmpty || widget.regNo.isEmpty) {
      if(mounted) setState(() { _error = "Invalid session."; _isLoading = false; });
      return;
    }

    // 1. Check Cache
    if (DashboardScreen.dashboardCache != null) {
      print("DashboardScreen _loadInitialData: Checking cache.");
      bool cacheComplete = _essentialKeys.every((key) => DashboardScreen.dashboardCache!.containsKey(key));
      if (cacheComplete) {
        print("DashboardScreen _loadInitialData: Loading from complete cache.");
        _processFirestoreData(DashboardScreen.dashboardCache!); // Process cached data
        if (CalendarPage.firebaseEventsCache == null) CalendarPage.loadFirebaseEvents(context).then((_) { if (mounted) setState(() {}); });
        if(mounted) setState(() => _isLoading = false); // Use valid cache, loading done
        return;
      } else {
        print("DashboardScreen _loadInitialData: Cache incomplete. Invalidating.");
        DashboardScreen.dashboardCache = null; // Invalidate incomplete cache
      }
    }

    // 2. Check Firestore Document ONCE
    bool shouldFetchFromApi = false;
    DocumentSnapshot<Map<String, dynamic>>? initialDoc;
    try {
      print("DashboardScreen _loadInitialData: Checking Firestore once...");
      initialDoc = await FirebaseFirestore.instance.collection('studentDetails').doc(widget.regNo).get();

      if (!initialDoc.exists) {
        print("DashboardScreen _loadInitialData: Document NOT found. Triggering initial API fetch.");
        shouldFetchFromApi = true;
      } else {
        final data = initialDoc.data();
        bool dataComplete = data != null && _essentialKeys.every((key) => data.containsKey(key));
        if (!dataComplete) {
          print("DashboardScreen _loadInitialData: Document FOUND but incomplete. Triggering API fetch.");
          shouldFetchFromApi = true;
        } else {
          print("DashboardScreen _loadInitialData: Document FOUND and complete. Processing Firestore data.");
          _processFirestoreData(data!); // Process existing complete data
          if(mounted) setState(() => _isLoading = false); // Loading done
          if (CalendarPage.firebaseEventsCache == null) CalendarPage.loadFirebaseEvents(context).then((_) { if (mounted) setState(() {}); });
          return; // Don't fetch if data is complete
        }
      }
    } catch (e) {
      print("DashboardScreen _loadInitialData: Error checking Firestore: $e");
      if (mounted) setState(() { _error = "DB Connection Error."; _isLoading = false; });
      return; // Stop if DB check failed
    }

    // 3. Trigger API Fetch and Poll (if needed)
    if (shouldFetchFromApi) {
      print("DashboardScreen _loadInitialData: Triggering API fetch and polling.");
      await _fetchAndPollData(isInitialFetch: true); // Start fetch and poll process
      // _isLoading will be set to false inside _fetchAndPollData
    }
  }

  // --- Processes Firestore data and updates state variables ---
  void _processFirestoreData(Map<String, dynamic> data) {
    if (!mounted) return;
    print("DashboardScreen _processFirestoreData: Processing data...");

    setState(() {
      studentName = data['profile']?['name'] ?? 'Student';
      timetableData = data['timetable'] as List? ?? [];
      hourWiseAttendanceData = data['hourWiseAttendance'] as List? ?? [];
      subjectAttendanceData = data['subjectAttendance'] as List? ?? [];
      courseMapData = data['courseMap'] as List? ?? [];
      semGradesData = data['semGrades'] as List? ?? []; // Process sem grades if needed
      // bunkDataMap = data['bunkdata'] as Map<String, dynamic>? ?? {}; // Process bunk data if needed

      final cgpaList = data['cgpa'] as List? ?? [];
      cgpa = cgpaList.isNotEmpty ? (cgpaList[0]['cgpa'] ?? "N/A") : "N/A";

      final sastraDueRaw = data['sastraDue']?.toString() ?? "0";
      final hostelDueRaw = data['totalDue']?.toString() ?? "0";
      int parseFee(String raw) => int.tryParse(raw.replaceAll(',', '').split('.')[0]) ?? 0;
      feeDue = parseFee(sastraDueRaw) + parseFee(hostelDueRaw);

      attendancePercent = 0; attendedClasses = 0; totalClasses = 0; bunks = 0;
      if (subjectAttendanceData.isNotEmpty) {
        int totalHrs = 0, attendedHrs = 0;
        for (final subject in subjectAttendanceData) {
          totalHrs += int.tryParse(subject['totalHrs']?.toString() ?? '0') ?? 0;
          attendedHrs += int.tryParse(subject['presentHrs']?.toString() ?? '0') ?? 0;
        }
        totalClasses = totalHrs; attendedClasses = attendedHrs;
        attendancePercent = totalClasses > 0 ? (attendedClasses / totalClasses) * 100 : 0;
        // Bunks calculation requires 'bunkdata' - add if needed
        // int totalAbsences = totalClasses - attendedClasses; int maxAllowedAbsences = 0;
        // final perSem20 = bunkDataMap['perSem20'] as Map<String, dynamic>? ?? {};
        // perSem20.forEach((key, value) { maxAllowedAbsences += (value as num).toInt(); });
        // bunks = maxAllowedAbsences - totalAbsences;
      }

      isBirthday = false;
      final dobList = data['dob'] as List? ?? [];
      final dobData = dobList.isNotEmpty ? dobList[0]['dob'] : null;
      if (dobData != null && dobData is String && dobData.isNotEmpty) {
        try {
          final parsed = DateFormat('dd-MM-yyyy').parse(dobData);
          final today = DateTime.now();
          if (parsed.day == today.day && parsed.month == today.month) {
            isBirthday = true;
            if (_confettiController.state != ConfettiControllerState.playing) {
              WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _confettiController.play(); });
            }
          }
        } catch (_) {}
      }
      _error = null; // Clear error on successful processing
      _isLoading = false; // Mark loading as complete
    });
    // Update cache
    DashboardScreen.dashboardCache = data;
  }

  // --- Fetches from API then Polls Firestore ---
  Future<void> _fetchAndPollData({bool isInitialFetch = false, String? updatedToken}) async {
    // Use updatedToken if provided (from refresh), otherwise use current state token
    final effectiveToken = updatedToken ?? widget.token;

    if (_isRefreshing && !isInitialFetch) { // Prevent re-entry during manual refresh
      print("_fetchAndPollData: Skipped (already refreshing).");
      return;
    }

    print("_fetchAndPollData: Starting API fetch (isInitial: $isInitialFetch)...");
    if (mounted) setState(() { _isRefreshing = true; _error = null; }); // Indicate API fetch is running

    try {
      // --- Trigger API Calls ---
      print("_fetchAndPollData: Starting parallel fetches...");
      final List<Future<http.Response>> parallelFutures = [
        http.post(Uri.parse(api.profile), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken})),
        http.post(Uri.parse(api.profilePic), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken})),
        http.post(Uri.parse(api.cgpa), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken})),
        http.post(Uri.parse(api.subjectWiseAttendance), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken})),
        http.post(Uri.parse(api.timetable), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken})),
        http.post(Uri.parse(api.hourWiseAttendance), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken})),
        http.post(Uri.parse(api.sastraDue), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken})),
        http.post(Uri.parse(api.hostelDue), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken})),
        http.post(Uri.parse(api.courseMap), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken})),
        http.post(Uri.parse(api.dob), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken})),
        http.post(Uri.parse(api.semGrades), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken})),
        // Add bunk call here if needed
      ];
      if (isInitialFetch) { // Only fetch calendar on initial load maybe?
        final calendarFuture = CalendarPage.loadFirebaseEvents(context);
        await Future.wait([calendarFuture, ...parallelFutures]);
      } else {
        await Future.wait(parallelFutures);
      }
      print("_fetchAndPollData: Parallel fetches complete.");
      // --- API Calls Triggered ---

      // --- Start Polling Firestore ---
      print("_fetchAndPollData: Starting Firestore poll...");
      Map<String, dynamic>? fetchedData;
      const maxRetries = 10; // Poll for 10 seconds (10 * 1000ms)
      for (int i = 0; i < maxRetries; i++) {
        if (!mounted) return; // Exit if widget is disposed during polling

        final doc = await FirebaseFirestore.instance.collection('studentDetails').doc(widget.regNo).get();
        final data = doc.data();

        // Check if essential data is now present
        if (doc.exists && data != null && _essentialKeys.every((key) => data.containsKey(key))) {
          print("_fetchAndPollData: Complete data found in Firestore on attempt ${i + 1}.");
          fetchedData = data;
          break; // Success!
        }

        // Wait before retrying
        print("_fetchAndPollData: Data incomplete, retrying... (Attempt ${i + 1}/$maxRetries)");
        await Future.delayed(const Duration(milliseconds: 1000));
      }
      // --- Polling Finished ---

      if (!mounted) return;

      if (fetchedData != null) {
        _processFirestoreData(fetchedData); // Update UI with fetched data
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isInitialFetch ? 'Initial data loaded!' : 'Data refreshed!'), backgroundColor: Colors.green)
        );
      } else {
        print("_fetchAndPollData: Polling timed out. Essential data not found.");
        throw Exception("Failed to load complete data after fetch (timeout).");
      }

    } catch (e) {
      print("_fetchAndPollData: Error during fetch/poll: $e");
      if (mounted) {
        setState(() { _error = e.toString(); _isLoading = false; }); // Show error, stop loading
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_error!), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) {
        // Ensure both loading indicators are false after attempt
        setState(() { _isRefreshing = false; _isLoading = false; });
      }
      print("✅ _fetchAndPollData: Process completed.");
    }
  }

  // --- Forces CAPTCHA then Calls _fetchAndPollData ---
  Future<void> _refreshFromApi() async {
    if (_isRefreshing || widget.regNo.isEmpty || widget.token.isEmpty) { return; }
    print("DashboardScreen _refreshFromApi: Starting FORCED re-login refresh...");

    setState(() { _isLoading = true; _isRefreshing = true; _error = null; }); // Show loader

    String? effectiveToken = widget.token;
    bool reloginSuccess = false;

    try {
      // --- CAPTCHA FLOW ---
      if (!mounted) throw Exception("Widget unmounted during refresh");
      final String? newToken = await showDialog<String>( context: context, barrierDismissible: false, builder: (context) => CaptchaDialog(token: effectiveToken!, apiUrl: widget.url), );

      if (newToken != null && newToken.isNotEmpty) {
        await widget.onTokenUpdated(newToken); // Update token in parent/global state
        effectiveToken = newToken; // Use the new token for this refresh
        reloginSuccess = true;
      } else {
        throw Exception("Session refresh cancelled or failed.");
      }
      // --- END CAPTCHA ---

      // --- Trigger Fetch and Poll using the NEW token ---
      // Calendar cache invalidation can happen here or within fetchAndPoll
      CalendarPage.firebaseEventsCache = null;
      await _fetchAndPollData(isInitialFetch: false, updatedToken: effectiveToken); // Pass new token


    } catch (e) {
      print("DashboardScreen _refreshFromApi Error: $e");
      if (mounted) {
        // _fetchAndPollData handles setting error state and snackbar on poll failure
        // Only set error here if CAPTCHA/token update itself failed
        if (_error == null) { // Avoid overwriting specific poll error
          setState(() { _error = e.toString(); });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error!), backgroundColor: Colors.red));
        }
        // Ensure loading stops even if CAPTCHA fails
        setState(() { _isRefreshing = false; _isLoading = false; });
      }
    }
    // 'finally' block in _fetchAndPollData handles setting _isRefreshing and _isLoading to false on success/timeout
    print("✅ DashboardScreen _refreshFromApi: Refresh process initiated.");
  }


  String _getNextExamInfo() { /* ... Unchanged ... */
    final eventsCache = CalendarPage.firebaseEventsCache; if (eventsCache == null || eventsCache.isEmpty) return "Loading Schedule..."; final today = DateTime.now(); final todayDateOnly = DateTime(today.year, today.month, today.day); DateTime? findFirstEventDate(RegExp regex) { final sortedDates = eventsCache.keys.toList()..sort(); for (final dateKey in sortedDates) { final eventDate = DateTime.tryParse(dateKey); if (eventDate == null || eventDate.isBefore(todayDateOnly)) continue; final events = eventsCache[dateKey]!; if (events.any((event) => regex.hasMatch(event))) return eventDate; } return null; } final examTypes = [ MapEntry("CIA I", RegExp(r'cia\s+i\b', caseSensitive: false)), MapEntry("CIA II", RegExp(r'cia\s+ii\b', caseSensitive: false)), MapEntry("CIA III", RegExp(r'cia\s+iii\b', caseSensitive: false)), MapEntry("Lab Exam", RegExp(r'lab exam', caseSensitive: false)), MapEntry("End Semester Exam", RegExp(r'(even|odd|end)?\s*semester\s+exam\s+starts', caseSensitive: false)), ]; final upcomingExams = <MapEntry<String, DateTime>>[]; for (final exam in examTypes) { final examDate = findFirstEventDate(exam.value); if (examDate != null) upcomingExams.add(MapEntry(exam.key, examDate)); } if (upcomingExams.isEmpty) return "No upcoming exams"; upcomingExams.sort((a, b) => a.value.compareTo(b.value)); final nextExam = upcomingExams.first; final daysRemaining = nextExam.value.difference(todayDateOnly).inDays; if (daysRemaining == 0) return "${nextExam.key} is Today!"; if (daysRemaining == 1) return "${nextExam.key} is Tomorrow!"; return "${nextExam.key} in $daysRemaining days";
  }

  // --- Builds the main UI using STATE variables ---
  Widget _buildDashboardUI(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    // This Column is wrapped by Padding and the Stack in _buildConditionalContent/build
    return Padding(
      padding: const EdgeInsets.all(16.0), // Keep internal padding for content spacing
      child: Column(
        mainAxisSize: MainAxisSize.min, // Fit content vertically
        children: [
          // Error Banner (Show non-critical errors here if needed)
          if (_error != null && !_isLoading) // Show error banner if not in loading state
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: MaterialBanner(
                padding: const EdgeInsets.all(10),
                content: Text(_error!, style: const TextStyle(color: Colors.white)),
                backgroundColor: Colors.orange.shade800, // Use orange for non-fatal errors
                forceActionsBelow: true,
                actions: [
                  TextButton(
                      onPressed: () => setState(() => _error = null),
                      child: const Text('DISMISS', style: TextStyle(color: Colors.white)))
                ],
              ),
            ),

          // Welcome Header
          GestureDetector(
            onTap: () { Navigator.push( context, MaterialPageRoute(builder: (_) => ProfilePage(token: widget.token, url: widget.url, regNo: widget.regNo))); },
            child: NeonContainer(
              borderColor: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue,
              child: Row(
                children: [
                  CircleAvatar( radius: 28, backgroundColor: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue, child: Icon(Icons.person, color: theme.isDarkMode ? Colors.black : Colors.white) ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isBirthday) const FittedBox(fit: BoxFit.scaleDown, child: Text('🎉 Happy Birthday! 🎉', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber)))
                        else FittedBox( fit: BoxFit.scaleDown, child: Text( (studentName != null && studentName!.isNotEmpty ? 'Welcome, $studentName!' : 'Welcome Back!'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue) ), ),
                        FittedBox(fit: BoxFit.scaleDown, child: Text('Student Dashboard', style: TextStyle(color: theme.isDarkMode ? Colors.white70 : Colors.grey[600]))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Attendance Chart
          GestureDetector(
            onTap: () { Navigator.push( context, MaterialPageRoute( builder: (_) => SubjectWiseAttendancePage( regNo: widget.regNo, token: widget.token, url: widget.url, initialSubjectAttendance: subjectAttendanceData, initialHourWiseAttendance: hourWiseAttendanceData, timetable: timetableData, courseMap: courseMapData, ), ), ); },
            child: AttendancePieChart(
              attendancePercentage: attendancePercent,
              attendedClasses: attendedClasses,
              totalClasses: totalClasses,
              bunkingDaysLeft: bunks,
            ),
          ),
          const SizedBox(height: 16),

          // Fee and GPA Tiles
          Row( crossAxisAlignment: CrossAxisAlignment.start, children: [ Expanded(child: _buildFeeDueTile(theme, feeDue)), const SizedBox(width: 12), Expanded(child: _buildGpaExamTile(theme, cgpa ?? 'N/A')), ], ), // Use state cgpa
          const SizedBox(height: 16),

          // Timetable
          SizedBox( height: 300, child: TimetableWidget( timetable: timetableData, isLoading: false, // Loading handled by parent
            hourWiseAttendance: hourWiseAttendanceData, courseMap: courseMapData, ), ),
        ],
      ),
    );
  }

  // --- Main build method (Uses Polling State) ---
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    // Outer structure ensures RefreshIndicator is always available
    return RefreshIndicator(
      onRefresh: _refreshFromApi,
      color: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue,
      backgroundColor: theme.isDarkMode ? AppTheme.darkSurface : Colors.white,
      child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center( // Center the content vertically
                  child: _buildConditionalContent(context, theme), // Delegate content building
                ),
              ),
            );
          }
      ),
    );
  }

  // --- Helper method to build content based on state (Polling Version) ---
  Widget _buildConditionalContent(BuildContext context, ThemeProvider theme) {
    // 1. Show Loading Indicator if initial load or refresh is in progress
    if (_isLoading) {
      print("DashboardScreen build: Loading data...");
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: CircularProgressIndicator(color: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue),
      );
    }

    // 2. Show Error if an error occurred and we are not loading
    if (_error != null) {
      print("DashboardScreen build: Displaying error - $_error");
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _loadInitialData, child: const Text("Retry Load"))
          ],
        ),
      );
    }

    // 3. If no error and not loading, data should be ready (or cache was used)
    // Build the main UI. Wrap in Stack for Confetti.
    print("DashboardScreen build: Data loaded, building UI.");
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        _buildDashboardUI(context), // Uses state variables populated by _processFirestoreData
        _buildConfettiIfNeeded(), // Uses state variable 'isBirthday'
      ],
    );
  }

  // --- Helper to conditionally build Confetti (Uses state variable) ---
  Widget _buildConfettiIfNeeded() {
    return isBirthday // Directly use the state variable
        ? Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive),
    )
        : const SizedBox.shrink();
  }


  // --- Helper widget for Fee Due Tile ---
  Widget _buildFeeDueTile(ThemeProvider theme, int feeDue) {
    final hasDue = feeDue > 0;
    final isDark = theme.isDarkMode;
    return GestureDetector( onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => FeeDueStatusPage())); }, child: SizedBox( width: 180, height: 150, child: NeonContainer( borderColor: hasDue ? Colors.red.shade400 : (isDark ? AppTheme.neonBlue : AppTheme.primaryBlue), padding: const EdgeInsets.all(12), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.account_balance_wallet, size: 40, color: hasDue ? Colors.red.shade400 : (isDark ? AppTheme.neonBlue : AppTheme.primaryBlue)), const SizedBox(height: 8), const FittedBox(fit: BoxFit.scaleDown, child: Text('Fee Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), const SizedBox(height: 4), FittedBox(fit: BoxFit.scaleDown, child: Text( (hasDue ? '₹$feeDue' : 'Paid'), style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600]))), ], ), ), ), );
  }

  // --- Helper widget for GPA/Exam Tile ---
  Widget _buildGpaExamTile(ThemeProvider theme, String cgpa) {
    final isDark = theme.isDarkMode;
    return GestureDetector( onDoubleTap: () => setState(() => showExamSchedule = !showExamSchedule), child: SizedBox( width: 180, height: 150, child: NeonContainer( borderColor: isDark ? AppTheme.neonBlue : AppTheme.primaryBlue, padding: const EdgeInsets.all(12), child: AnimatedSwitcher( duration: const Duration(milliseconds: 300), child: showExamSchedule ? Column( key: const ValueKey('exam'), mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.event, size: 40, color: isDark ? AppTheme.neonBlue : AppTheme.primaryBlue), const SizedBox(height: 10), const FittedBox(fit: BoxFit.scaleDown, child: Text('Exam Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), const SizedBox(height: 4), FittedBox(fit: BoxFit.scaleDown, child: Text(_getNextExamInfo(), style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600]), textAlign: TextAlign.center,)), ]) : Column( key: const ValueKey('gpa'), mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.grade, size: 40, color: isDark ? AppTheme.neonBlue : Colors.orange), const SizedBox(height: 10), const FittedBox(fit: BoxFit.scaleDown, child: Text('CGPA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), FittedBox(fit: BoxFit.scaleDown, child: Text('$cgpa / 10', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600]))), ]), ), ), ), );
  }
}