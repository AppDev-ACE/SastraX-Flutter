import 'dart:convert';
import 'dart:ui'; // For ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ApiEndpoints.dart';
import 'FeeDuePage.dart';
import 'more_options_page.dart';
import 'subject_wise_attendance.dart';
import '../components/timetable_widget.dart';
import '../models/theme_model.dart';
import '../components/theme_toggle_button.dart';
import '../components/neon_container.dart';
import '../components/attendance_pie_chart.dart';
import 'profile_page.dart';
import 'calendar_page.dart';
import 'community_page.dart';
import 'mess_menu_page.dart';
import 'captcha_dialog.dart'; // Import the captcha dialog

// --- HomePage StatefulWidget and _HomePageState remain the same ---
class HomePage extends StatefulWidget {
  final String token; // Initial token from login
  final String url;
  final String regNo;

  const HomePage({
    super.key,
    required this.token,
    required this.url,
    required this.regNo
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2;
  late List<Widget> _pages;
  late String _currentToken; // State variable to hold the current token

  @override
  void initState() {
    super.initState();
    _currentToken = widget.token;
    print("HomePage initState: Initializing with token = '$_currentToken'");
    // Basic validation for the initial token
    if (_currentToken == null || _currentToken.isEmpty) {
      print("Error: HomePage received invalid token in initState! Check Login Page navigation.");
      _currentToken = ""; // Assign placeholder to prevent immediate crash
      // Consider navigating back to login or showing a persistent error
    }
    _buildPages();
  }

  void _buildPages() {
    // Check token validity before building pages
    if (_currentToken == null || _currentToken.isEmpty) {
      print("Error in _buildPages: _currentToken is invalid!");
      _pages = List.generate(5, (_) => const Center(child: Text("Error: Invalid Session")));
      return;
    }
    _pages = [
      CalendarPage(token: _currentToken),
      const CommunityPage(),
      DashboardScreen(
        key: ValueKey('DashboardScreen_$_currentToken'), // Unique Key ensures rebuild on token change
        token: _currentToken,
        url: widget.url,
        regNo: widget.regNo,
        onTokenUpdated: _updateToken, // Pass callback
      ),
      MessMenuPage(url: widget.url),
      MoreOptionsScreen(
          token: _currentToken,
          url: widget.url,
          regNo: widget.regNo,
      ),
    ];
  }

  Future<void> _updateToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', newToken);
    print("HomePage _updateToken: New token saved and state updated: $newToken");

    if(mounted) {
      setState(() {
        _currentToken = newToken;
        _buildPages(); // Rebuild pages list with new token
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safety check during build phase
    if (_currentToken == null || _currentToken.isEmpty) {
      print("Error in HomePage build: _currentToken is invalid!");
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Invalid session state. Please login again.")),
      );
    }
    print("HomePage build: Building UI with _currentToken = '$_currentToken'");

    final screenWidth = MediaQuery.of(context).size.width;
    final double appBarHeight = screenWidth * 0.2;

    return Consumer<ThemeProvider>(
      builder: (_, theme, __) => Scaffold(
        backgroundColor: theme.isDarkMode ? AppTheme.darkBackground : Colors.white,
        appBar: AppBar(
          leadingWidth: appBarHeight,
          toolbarHeight: appBarHeight,
          automaticallyImplyLeading: false,
          leading: Padding(padding: const EdgeInsets.all(8.0), child: Image.asset('assets/icon/Logo.png', fit: BoxFit.contain)),
          title: const FittedBox(fit: BoxFit.scaleDown, child: Text('SastraX', style: TextStyle(fontWeight: FontWeight.bold))),
          centerTitle: true,
          backgroundColor: theme.isDarkMode ? AppTheme.darkBackground : AppTheme.primaryBlue,
          elevation: 0,
          actions: [
            Padding(padding: const EdgeInsets.only(right: 16), child: ThemeToggleButton(isDarkMode: theme.isDarkMode, onToggle: theme.toggleTheme)),
          ],
        ),
        body: IndexedStack( // Use IndexedStack to preserve state
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.isDarkMode ? AppTheme.darkSurface : Colors.white,
          selectedItemColor: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Mess'),
            BottomNavigationBarItem(icon: Icon(Icons.more_horiz_outlined), label: 'More'),
          ],
        ),
      ),
    );
  }
}

// -------------------- DashboardScreen --------------------
class DashboardScreen extends StatefulWidget {
  final String token;
  final String url;
  final String regNo;
  final Function(String) onTokenUpdated; // Callback function

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
  bool isCgpaLoading = DashboardScreen.dashboardCache == null;
  bool isTimetableLoading = DashboardScreen.dashboardCache == null;
  String? _error;
  bool _isRefreshing = false; // For RefreshIndicator state

  // Data State
  double attendancePercent = -1;
  int attendedClasses = 0;
  int totalClasses = 0;
  String? cgpa;
  bool isBirthday = false;
  String? studentName;
  int feeDue = 0;
  int bunks = 0;
  List timetableData = [];
  List hourWiseAttendanceData = [];
  List subjectAttendanceData = [];
  List courseMapData = [];
  Map<String, dynamic> bunkData = {};


  // Controllers
  late final ApiEndpoints api;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    api = ApiEndpoints(widget.url);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    print("DashboardScreen initState: Received token = '${widget.token}'");
    _loadInitialData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    // Basic validation
    if (widget.token.isEmpty || widget.token == "guest_token") {
      if (widget.regNo.isEmpty) {
        setState(() { _error = "Running in Guest Mode."; });
      } else {
        setState(() { _error = "Invalid session. Please login again."; });
        print("Error: DashboardScreen received invalid token in _loadInitialData: '${widget.token}'");
      }
      isCgpaLoading = false;
      isTimetableLoading = false;
      return;
    }

    // 1. CHECK MEMORY CACHE FIRST
    if (DashboardScreen.dashboardCache != null) {
      print("DashboardScreen _loadInitialData: Loading from memory cache.");
      _processFirestoreData(DashboardScreen.dashboardCache!);
      if (CalendarPage.firebaseEventsCache == null) {
        CalendarPage.loadFirebaseEvents(context).then((_) {
          if (mounted) setState(() {});
        });
      }
      return;
    }

    // 2. IF NO MEMORY CACHE, TRY FIRESTORE
    print("DashboardScreen _loadInitialData: Memory cache empty, trying Firestore...");
    setState(() {
      isCgpaLoading = true;
      isTimetableLoading = true;
    });
    try {
      final docRef = FirebaseFirestore.instance.collection('studentDetails').doc(widget.regNo);
      final doc = await docRef.get();
      final data = doc.data();

      if (doc.exists && data != null && data.containsKey('profile') && data.containsKey('bunkdata')) {
        print("DashboardScreen _loadInitialData: Data found in Firestore, processing...");
        _processFirestoreData(data);
        if (CalendarPage.firebaseEventsCache == null) {
          CalendarPage.loadFirebaseEvents(context).then((_) {
            if (mounted) setState(() {});
          });
        }
        if (mounted) {
          setState(() { isCgpaLoading = false; isTimetableLoading = false; });
        }
        return;
      } else {
        print("DashboardScreen _loadInitialData: No valid data in Firestore.");
      }

      // 3. IF FIRESTORE FAILS OR DATA IS INVALID, FALLBACK TO API REFRESH
      print("DashboardScreen _loadInitialData: Fallback to API refresh (_refreshFromApi).");
      await _refreshFromApi();

    } catch (e) {
      print("DashboardScreen _loadInitialData Error: $e");
      if (mounted) {
        setState(() {
          _error = "Error loading initial data: ${e.toString()}";
          isCgpaLoading = false;
          isTimetableLoading = false;
        });
      }
    }
  }


  void _processFirestoreData(Map<String, dynamic> data) {
    if (!mounted) return;
    print("DashboardScreen _processFirestoreData: Processing data...");

    setState(() {
      // ... (rest of the data processing logic - unchanged) ...
      studentName = data['profile']?['name'] ?? 'Student';
      timetableData = data['timetable'] is List ? data['timetable'] as List : [];
      hourWiseAttendanceData = data['hourWiseAttendance'] is List ? data['hourWiseAttendance'] as List : [];
      subjectAttendanceData = data['subjectAttendance'] is List ? data['subjectAttendance'] as List : [];
      courseMapData = data['courseMap'] is List ? data['courseMap'] as List : [];
      bunkData = data['bunkdata'] is Map<String, dynamic> ? data['bunkdata'] : {};
      final cgpaList = data['cgpa'] is List ? data['cgpa'] as List : [];
      cgpa = cgpaList.isNotEmpty ? (cgpaList[0]['cgpa'] ?? "N/A") : "N/A";
      final sastraDueRaw = data['sastraDue']?.toString() ?? "0";
      final hostelDueRaw = data['hostelDue']?.toString() ?? "0";
      int parseFee(String raw) => int.tryParse(raw.replaceAll(',', '').split('.')[0]) ?? 0;
      feeDue = parseFee(sastraDueRaw) + parseFee(hostelDueRaw);
      if (subjectAttendanceData.isNotEmpty) {
        int totalHrs = 0; int attendedHrs = 0;
        for (final subject in subjectAttendanceData) {
          totalHrs += int.tryParse(subject['totalHrs']?.toString() ?? '0') ?? 0;
          attendedHrs += int.tryParse(subject['presentHrs']?.toString() ?? '0') ?? 0;
        }
        totalClasses = totalHrs; attendedClasses = attendedHrs;
        attendancePercent = totalClasses > 0 ? (attendedClasses / totalClasses) * 100 : 0;
        int totalAbsences = totalClasses - attendedClasses; int maxAllowedAbsences = 0;
        final perSem20 = bunkData['perSem20'] as Map<String, dynamic>? ?? {};
        perSem20.forEach((key, value) { maxAllowedAbsences += (value as num).toInt(); });
        bunks = maxAllowedAbsences - totalAbsences;
      } else { attendancePercent = 0; bunks = 0; }
      final dobList = data['dob'] is List ? data['dob'] as List : [];
      final dobData = dobList.isNotEmpty ? dobList[0]['dob'] : null;
      if (dobData != null && dobData.isNotEmpty) {
        try {
          final parsed = DateFormat('dd-MM-yyyy').parse(dobData);
          final today = DateTime.now();
          if (parsed.day == today.day && parsed.month == today.month) {
            isBirthday = true; _confettiController.play();
          } else { isBirthday = false; }
        } catch (_) { isBirthday = false; }
      }
      isTimetableLoading = false; isCgpaLoading = false;
      _error = null; // Clear error on successful data processing
    });

    DashboardScreen.dashboardCache = data; // Update memory cache
  }

  // --- _refreshFromApi: Forces CAPTCHA on every refresh ---
  Future<void> _refreshFromApi() async {
    if (_isRefreshing) return;
    print("DashboardScreen _refreshFromApi: Starting FORCED re-login refresh with token = '${widget.token}'");

    // Prevent refresh if token is invalid (guest or empty)
    if (widget.token.isEmpty || widget.token == "guest_token") {
      if (mounted) {
        setState(() { _error = "Login required to refresh data."; });
        ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(_error!), backgroundColor: Colors.orange));
      }
      return; // Stop refresh
    }

    setState(() { _isRefreshing = true; _error = null; });

    String? effectiveToken = widget.token; // Start with the *current* token to pass to dialog
    bool reloginSuccess = false;

    try {
      // --- FORCE CAPTCHA FLOW ---
      print("DashboardScreen _refreshFromApi: Forcing CAPTCHA dialog.");
      if (!mounted) return; // Always check mounted before async gap

      final String? newToken = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => CaptchaDialog(
          token: effectiveToken!, // Pass the current token
          apiUrl: widget.url,
        ),
      );
      print("DashboardScreen _refreshFromApi: CAPTCHA dialog returned: $newToken");

      if (newToken != null && newToken.isNotEmpty) {
        // Re-login successful!
        await widget.onTokenUpdated(newToken); // Update token in parent state & SharedPreferences
        effectiveToken = newToken; // Use the new token for THIS refresh
        reloginSuccess = true;
        print("DashboardScreen _refreshFromApi: Re-login successful, new effective token: $effectiveToken");
      } else {
        // Re-login failed or was cancelled
        print("DashboardScreen _refreshFromApi: Re-login failed or cancelled.");
        if(mounted) setState(() { _error = "Session refresh failed. Please try again."; });
        throw Exception("Session refresh required but failed or was cancelled."); // Stop data fetch
      }
      // --- END OF FORCED FLOW ---


      // --- STEP 3: Fetch all data using the new effectiveToken ---
      print("DashboardScreen _refreshFromApi: Proceeding to fetch data with token: $effectiveToken");
      CalendarPage.firebaseEventsCache = null; // Invalidate calendar cache

      // Initialize bunkResponse to null
      http.Response? bunkResponse;
      try {
        // Create futures for all API calls
        final bunkFuture = http.post( Uri.parse(api.bunk), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken}), );
        final List<Future<http.Response>> dataFutures = [
          http.post(Uri.parse(api.profile), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': true, 'token': effectiveToken})),
          http.post(Uri.parse(api.profilePic), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': true, 'token': effectiveToken})),
          http.post(Uri.parse(api.cgpa), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': true, 'token': effectiveToken})),
          http.post(Uri.parse(api.subjectWiseAttendance), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': true, 'token': effectiveToken})),
          http.post(Uri.parse(api.timetable), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': true, 'token': effectiveToken})),
          http.post(Uri.parse(api.hourWiseAttendance), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': true, 'token': effectiveToken})),
          http.post(Uri.parse(api.sastraDue), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': true, 'token': effectiveToken})),
          http.post(Uri.parse(api.hostelDue), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': true, 'token': effectiveToken})),
          http.post(Uri.parse(api.courseMap), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': true, 'token': effectiveToken})),
        ];
        final calendarFuture = CalendarPage.loadFirebaseEvents(context);

        // Await all futures together
        final results = await Future.wait([ calendarFuture, bunkFuture, ...dataFutures ]);
        // Assign bunkResponse after waiting
        bunkResponse = results[1] as http.Response?;
        // Note: You could add error handling for individual API calls here if needed
        print("DashboardScreen _refreshFromApi: All API calls completed.");
      } catch (networkError) {
        print("DashboardScreen _refreshFromApi: Network error during data fetch: $networkError");
        if (mounted) setState(() { _error = "Network error during refresh. Some data might be stale."; });
        // Don't rethrow, let Firestore fetch attempt below
      }

      if (!mounted) return;

      // Process bunk response (handle potential errors)
      if (bunkResponse != null && bunkResponse.statusCode == 200) {
        try {
          final bunkJson = jsonDecode(bunkResponse.body);
          if (bunkJson['success'] == true) {
            await FirebaseFirestore.instance.collection('studentDetails').doc(widget.regNo).set({'bunkdata': bunkJson['bunkdata']}, SetOptions(merge: true));
            print("DashboardScreen _refreshFromApi: Bunk data updated in Firestore.");
          } else { print("Warning: Bunk API call succeeded but returned success:false."); }
        } catch (e) { print("Error processing bunk response: $e"); }
      } else if (bunkResponse != null) { print("Warning: Bunk API call failed with status ${bunkResponse.statusCode}");
      } else { print("Warning: Bunk API call probably failed due to network error."); }


      // --- STEP 4: Refetch main data from Firestore and update UI ---
      print("DashboardScreen _refreshFromApi: Refetching data from Firestore.");
      final doc = await FirebaseFirestore.instance.collection('studentDetails').doc(widget.regNo).get();
      if (doc.exists && doc.data() != null) {
        _processFirestoreData(doc.data()!); // Update UI state
        if (mounted) {
          // Clear error ONLY if data is successfully processed from Firestore
          setState(() { _error = null; });
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(reloginSuccess ? 'Session renewed & Dashboard refreshed!' : 'Dashboard refreshed!'), backgroundColor: Colors.green)
          );
        }
      } else {
        print("Error: Refreshed student data not found in Firestore after updates.");
        // Set specific error if Firestore fails after potentially successful API calls
        if (mounted && (_error == null || !_error!.contains("Network error"))) { setState(() { _error = "Failed to load updated data after refresh."; }); }
        // Throw only if no prior network error occurred
        if(_error == null || !_error!.contains("Network error")) { throw Exception("Refreshed student data not found in database."); }
      }

    } catch (e) {
      print("DashboardScreen _refreshFromApi Main Catch Error: $e");
      if (mounted) {
        // Ensure an error message is set if one wasn't already
        if (_error == null || !_error!.contains("Network error")) {
          setState(() {
            _error = e.toString().contains("Session refresh required")
                ? "Session refresh failed. Please try again."
                : "Refresh failed: ${e.toString()}";
          });
        }
        // Show the current error message
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_error!), backgroundColor: Colors.red)
        );
      }
    } finally {
      // --- ADD PRINT STATEMENT HERE ---
      if (mounted) {
        setState(() {
          _isRefreshing = false; // Stop the RefreshIndicator
        });
        // Print AFTER setting _isRefreshing to false
        print("✅ DashboardScreen _refreshFromApi: Refresh process completed. Final effective token used: $effectiveToken");
      }
      // --- END OF ADDED PRINT ---
    }
  }


  String _getNextExamInfo() {
    // ... (This function remains unchanged) ...
    final eventsCache = CalendarPage.firebaseEventsCache;
    if (eventsCache == null || eventsCache.isEmpty) { return "Loading Schedule..."; }
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    DateTime? findFirstEventDate(RegExp regex) {
      final sortedDates = eventsCache.keys.toList()..sort();
      for (final dateKey in sortedDates) {
        final eventDate = DateTime.tryParse(dateKey);
        if (eventDate == null || eventDate.isBefore(todayDateOnly)) continue;
        final events = eventsCache[dateKey]!;
        if (events.any((event) => regex.hasMatch(event))) return eventDate;
      } return null;
    }
    final List<MapEntry<String, RegExp>> examTypes = [ MapEntry("CIA I", RegExp(r'cia\s+i\b', caseSensitive: false)), MapEntry("CIA II", RegExp(r'cia\s+ii\b', caseSensitive: false)), MapEntry("CIA III", RegExp(r'cia\s+iii\b', caseSensitive: false)), MapEntry("Lab Exam", RegExp(r'lab exam', caseSensitive: false)), MapEntry("End Semester Exam", RegExp(r'(even|odd|end)?\s*semester\s+exam\s+starts', caseSensitive: false)), ];
    final List<MapEntry<String, DateTime>> upcomingExams = [];
    for (final exam in examTypes) { final examDate = findFirstEventDate(exam.value); if (examDate != null) upcomingExams.add(MapEntry(exam.key, examDate)); }
    if (upcomingExams.isEmpty) return "No upcoming exams";
    upcomingExams.sort((a, b) => a.value.compareTo(b.value));
    final nextExam = upcomingExams.first;
    final examName = nextExam.key; final examDate = nextExam.value; final daysRemaining = examDate.difference(todayDateOnly).inDays;
    if (daysRemaining == 0) return "$examName is Today!"; if (daysRemaining == 1) return "$examName is Tomorrow!"; return "$examName in $daysRemaining days";
  }

  @override
  Widget build(BuildContext context) {
    // ... (Build method remains unchanged from the previous correct version) ...
    final theme = Provider.of<ThemeProvider>(context);

    // Initial Error/Loading States (only show if cache is empty)
    if (DashboardScreen.dashboardCache == null) {
      if (_error != null && !_error!.contains("Guest Mode")) {
        return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)), const SizedBox(height: 10), ElevatedButton(onPressed: _loadInitialData, child: const Text("Retry"))])));
      }
      if (isCgpaLoading || isTimetableLoading || (attendancePercent < 0 && widget.regNo.isNotEmpty)) {
        if (_error == null || _error!.contains("Guest Mode")) {
          return Center(child: CircularProgressIndicator(color: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue));
        }
      }
      if (widget.regNo.isEmpty) {
        return const Center(child: Text("Running in Guest Mode.\nSome features unavailable.", textAlign: TextAlign.center));
      }
      return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("Failed to load initial data.", textAlign: TextAlign.center, style: TextStyle(color: Colors.red)), const SizedBox(height: 10), ElevatedButton(onPressed: _loadInitialData, child: const Text("Retry"))])));

    }
    // If cache exists or initial loading is done, build the main UI
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refreshFromApi,
          color: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue,
          backgroundColor: theme.isDarkMode ? AppTheme.darkSurface : Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // Ensure scrolling is always possible for refresh
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // --- Display error as a banner IF cache exists ---
                  if (_error != null && DashboardScreen.dashboardCache != null && !_error!.contains("Guest Mode"))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: MaterialBanner(
                        padding: const EdgeInsets.all(10),
                        content: Text(_error!, style: const TextStyle(color: Colors.white)),
                        backgroundColor: Colors.red.shade700,
                        forceActionsBelow: true,
                        actions: [TextButton(onPressed: ()=>setState(()=>_error=null), child: const Text('DISMISS', style: TextStyle(color: Colors.white)))],
                      ),
                    ),
                  // --- End error banner ---

                  GestureDetector(
                    onTap: () {
                      if (widget.regNo.isNotEmpty && widget.token != "guest_token") {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(token: widget.token, url: widget.url, regNo: widget.regNo)));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile not available in Guest Mode.'), backgroundColor: Colors.orange)
                        );
                      }
                    },
                    child: NeonContainer(
                      borderColor: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue,
                            child: Icon(Icons.person, color: theme.isDarkMode ? Colors.black : Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isBirthday && widget.regNo.isNotEmpty)
                                  const FittedBox(fit: BoxFit.scaleDown, child: Text('🎉 Happy Birthday! 🎉', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber)))
                                else
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                        widget.regNo.isEmpty
                                            ? 'Welcome, Guest!' // Guest mode
                                            : (studentName != null && studentName!.isNotEmpty)
                                            ? 'Welcome, $studentName!' // Logged in with name
                                            : 'Welcome Back!', // Logged in, name missing
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue)),
                                  ),
                                FittedBox(fit: BoxFit.scaleDown, child: Text('Student Dashboard', style: TextStyle(color: theme.isDarkMode ? Colors.white70 : Colors.grey[600]))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      if (widget.regNo.isNotEmpty && widget.token != "guest_token") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubjectWiseAttendancePage(
                              regNo: widget.regNo,
                              token: widget.token,
                              url: widget.url,
                              initialSubjectAttendance: subjectAttendanceData,
                              initialHourWiseAttendance: hourWiseAttendanceData,
                              timetable: timetableData,
                              courseMap: courseMapData,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Attendance not available in Guest Mode.'), backgroundColor: Colors.orange)
                        );
                      }
                    },
                    child: widget.regNo.isEmpty
                        ? Container( // Placeholder for Guest
                        height: 200,
                        decoration: BoxDecoration(color: theme.isDarkMode ? Colors.grey[800] : Colors.grey[200], borderRadius: BorderRadius.circular(16)),
                        alignment: Alignment.center,
                        child: Text("N/A in Guest Mode", style: TextStyle(color: theme.textSecondaryColor)))
                        : AttendancePieChart( // Actual Chart
                      attendancePercentage: attendancePercent >= 0 ? attendancePercent : 0,
                      attendedClasses: attendedClasses,
                      totalClasses: totalClasses,
                      bunkingDaysLeft: bunks,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildFeeDueTile(theme)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildGpaExamTile(theme)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: widget.regNo.isEmpty
                        ? Container( // Placeholder for Guest
                        decoration: BoxDecoration(color: theme.isDarkMode ? Colors.grey[800] : Colors.grey[200], borderRadius: BorderRadius.circular(16)),
                        alignment: Alignment.center,
                        child: Text("N/A in Guest Mode", style: TextStyle(color: theme.textSecondaryColor)))
                        : TimetableWidget( // Actual Widget
                      timetable: timetableData,
                      isLoading: isTimetableLoading && DashboardScreen.dashboardCache == null,
                      hourWiseAttendance: hourWiseAttendanceData,
                      courseMap: courseMapData,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (isBirthday && widget.regNo.isNotEmpty)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive),
          ),
      ],
    );
  }

  Widget _buildFeeDueTile(ThemeProvider theme) {
    // ... (Fee tile remains unchanged) ...
    bool isGuest = widget.regNo.isEmpty;
    final hasDue = !isGuest && feeDue > 0;
    final isDark = theme.isDarkMode;

    return GestureDetector(
      onTap: () {
        if (isGuest) {
          ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Fee status not available in Guest Mode.'), backgroundColor: Colors.orange) );
          return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (context) => FeeDueStatusPage()));
      },
      child: SizedBox( width: 180, height: 150,
        child: NeonContainer(
          borderColor: hasDue ? Colors.red.shade400 : (isDark ? AppTheme.neonBlue : AppTheme.primaryBlue),
          padding: const EdgeInsets.all(12),
          child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.account_balance_wallet, size: 40, color: hasDue ? Colors.red.shade400 : (isDark ? AppTheme.neonBlue : AppTheme.primaryBlue)),
            const SizedBox(height: 8), const FittedBox(fit: BoxFit.scaleDown, child: Text('Fee Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            const SizedBox(height: 4), FittedBox(fit: BoxFit.scaleDown, child: Text(isGuest ? 'N/A' : (hasDue ? '₹$feeDue' : 'Paid'), style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600]))),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildGpaExamTile(ThemeProvider theme) {
    // ... (GPA/Exam tile remains unchanged) ...
    bool isGuest = widget.regNo.isEmpty;
    final isDark = theme.isDarkMode;

    return GestureDetector(
      onDoubleTap: isGuest ? null : () => setState(() => showExamSchedule = !showExamSchedule),
      child: SizedBox( width: 180, height: 150,
        child: NeonContainer(
          borderColor: isDark ? AppTheme.neonBlue : AppTheme.primaryBlue,
          padding: const EdgeInsets.all(12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: showExamSchedule && !isGuest
                ? Column( key: const ValueKey('exam'), mainAxisAlignment: MainAxisAlignment.center, children: [ // Exam Tile
              Icon(Icons.event, size: 40, color: isDark ? AppTheme.neonBlue : AppTheme.primaryBlue),
              const SizedBox(height: 10), const FittedBox(fit: BoxFit.scaleDown, child: Text('Exam Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              const SizedBox(height: 4), FittedBox( fit: BoxFit.scaleDown, child: Text( _getNextExamInfo(), style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600]), textAlign: TextAlign.center, ), ),
            ]
            )
                : Column( key: const ValueKey('gpa'), mainAxisAlignment: MainAxisAlignment.center, children: [ // CGPA Tile
              Icon(Icons.grade, size: 40, color: isDark ? AppTheme.electricBlue : Colors.orange),
              const SizedBox(height: 10), const FittedBox(fit: BoxFit.scaleDown, child: Text('CGPA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              isCgpaLoading && !isGuest && DashboardScreen.dashboardCache == null
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : FittedBox(fit: BoxFit.scaleDown, child: Text(isGuest ? 'N/A' : '${cgpa ?? "N/A"} / 10', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600]))),
            ]
            ),
          ),
        ),
      ),
    );
  }
}