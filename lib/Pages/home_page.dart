import 'dart:async';
import 'dart:convert';
import 'dart:math'; // Keep math import if needed elsewhere, like AppBar height
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
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
import 'internals_page.dart'; // Still needed for navigation

class HomePage extends StatefulWidget {
  final String token;
  final String url;
  final String regNo;
  const HomePage(
      {super.key,
        required this.token,
        required this.url,
        required this.regNo});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2;
  late String _currentToken;

  @override
  void initState() {
    super.initState();
    _currentToken = widget.token;
    if (_currentToken.isEmpty && widget.regNo.isNotEmpty) {
      print("Error: HomePage initState invalid token");
      _currentToken = ""; // Consider navigating back to login
    }
  }

  Future<void> _updateToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', newToken);
    if (mounted) {
      setState(() {
        _currentToken = newToken;
      });
    }
  }

  void _onDataLoaded() {
    if (mounted) {
      print("HomePage: Data loaded signal received. Triggering UI rebuild.");
      setState(() {
        // Rebuilds HomePage, might update passed tokens if needed
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentToken.isEmpty && widget.regNo.isNotEmpty) {
      return Scaffold(
          appBar: AppBar(title: const Text("Error")),
          body: const Center(child: Text("Invalid session state. Please log in again.")));
    }

    final List<Widget> pages = [
      CalendarPage(token: _currentToken),
      const CommunityPage(),
      DashboardScreen(
        key: ValueKey('DashboardScreen_${widget.regNo}_$_currentToken'),
        token: _currentToken,
        url: widget.url,
        regNo: widget.regNo,
        onTokenUpdated: _updateToken,
        onDataLoaded: _onDataLoaded,
      ),
      InternalsPage(
        token: _currentToken,
        url: widget.url,
        regNo: widget.regNo,
      ),
      MoreOptionsScreen(
          token: _currentToken, url: widget.url, regNo: widget.regNo)
    ];

    // --- Standard HomePage UI ---
    final screenWidth = MediaQuery.of(context).size.width;
    final appBarHeight = max(kToolbarHeight, screenWidth * 0.18);

    return Consumer<ThemeProvider>(
        builder: (_, theme, __) => Scaffold(
            backgroundColor:
            theme.isDarkMode ? AppTheme.darkBackground : Colors.grey[100],
            appBar: AppBar(
                leadingWidth: appBarHeight * 1.2,
                toolbarHeight: appBarHeight,
                automaticallyImplyLeading: false,
                leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset('assets/icon/Logo.png',
                        fit: BoxFit.contain)),
                title: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('SastraX',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                centerTitle: true,
                backgroundColor: theme.isDarkMode
                    ? AppTheme.darkSurface
                    : AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                actions: [
                  Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: ThemeToggleButton(
                          isDarkMode: theme.isDarkMode,
                          onToggle: theme.toggleTheme))
                ]),
            body: IndexedStack(index: _currentIndex, children: pages),
            bottomNavigationBar: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
                type: BottomNavigationBarType.fixed,
                backgroundColor:
                theme.isDarkMode ? AppTheme.darkSurface : Colors.white,
                selectedItemColor: theme.isDarkMode
                    ? AppTheme.neonBlue
                    : AppTheme.primaryBlue,
                unselectedItemColor: Colors.grey,
                items: const [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.calendar_today), label: 'Calendar'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.people), label: 'Community'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.home), label: 'Home'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.assessment), label: 'Internals'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.more_horiz_outlined), label: 'More')
                ]))
    );
    // --- End of HomePage UI ---
  }
}

/// ==========================================================================
/// DashboardScreen (Handles Fetching, Caching, and UI for the Home Tab)
/// ==========================================================================
class DashboardScreen extends StatefulWidget {
  final String token;
  final String url;
  final String regNo;
  final Function(String) onTokenUpdated;
  final VoidCallback onDataLoaded;

  const DashboardScreen({
    super.key,
    required this.token,
    required this.url,
    required this.regNo,
    required this.onTokenUpdated,
    required this.onDataLoaded,
  });

  // Static cache to hold data across rebuilds (but not app restarts)
  static Map<String, dynamic>? dashboardCache;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- State Variables ---
  bool showExamSchedule = false;
  String? _error;
  bool _isLoading = true;
  bool _isRefreshing = false;
  double attendancePercent = 0.0;
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
  List semGradesData = [];
  Map<String, String> studentInfo = {};
  late final ApiEndpoints api;
  late ConfettiController _confettiController;
  String? _specialEventLottiePath;
  // --- End State Variables ---

  // List of keys *expected* to be written by the backend to Firestore
  final List<String> _essentialKeys = [
    'profile', 'semGrades', 'cgpa', 'studentStatus', 'attendance',
    'timetable', 'hourWiseAttendance', 'subjectAttendance', 'courseMap',
    'totalDue', 'dob', 'profilePic' // Ensure profilePic is checked too if essential
  ];

  // Keys that must also be non-empty lists for the data to be considered valid
  final List<String> _apiTriggerKeys = [
    'timetable',
    'subjectAttendance'
  ];


  @override
  void initState() {
    super.initState();
    api = ApiEndpoints(widget.url);
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    print("[${DateTime.now()}] DashboardScreen initState: Received token = '${widget.token.substring(0, min(10, widget.token.length))}...'");
    _loadInitialData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  /// Loads initial data: Checks Cache -> Checks Firestore -> Fetches API if necessary.
  Future<void> _loadInitialData() async {
    if (!mounted) return;
    print("[${DateTime.now()}] DashboardScreen: Starting _loadInitialData...");
    setState(() { _isLoading = true; _error = null; });

    if (widget.token.isEmpty || widget.regNo.isEmpty) {
      if(mounted) setState(() { _error = "Invalid session."; _isLoading = false; });
      return;
    }

    // 1. Check Static Cache
    if (DashboardScreen.dashboardCache != null) {
      bool cacheComplete = _checkDataCompleteness(DashboardScreen.dashboardCache!);
      bool triggerKeysPopulated = _checkTriggerKeysPopulated(DashboardScreen.dashboardCache!);

      if (cacheComplete && triggerKeysPopulated) {
        print("[${DateTime.now()}] DashboardScreen: Loading from complete static cache.");
        _processAndCacheData(DashboardScreen.dashboardCache!);
        _loadSecondaryData();
        if(mounted) setState(() => _isLoading = false);
        return;
      } else {
        print("[${DateTime.now()}] DashboardScreen: Static cache incomplete or trigger key empty. Invalidating.");
        DashboardScreen.dashboardCache = null;
      }
    }

    // 2. Check Firestore
    bool shouldFetchFromApi = false;
    Map<String, dynamic>? firestoreData;
    try {
      print("[${DateTime.now()}] DashboardScreen: Checking Firestore...");
      final initialDoc = await FirebaseFirestore.instance.collection('studentDetails').doc(widget.regNo).get()
          .timeout(const Duration(seconds: 10));

      if (!initialDoc.exists) {
        print("[${DateTime.now()}] DashboardScreen: Firestore document doesn't exist. Need API fetch.");
        shouldFetchFromApi = true;
      } else {
        print("[${DateTime.now()}] DashboardScreen: Firestore document found. Loading from Firestore.");
        firestoreData = initialDoc.data();
        _processAndCacheData(firestoreData!); // Process whatever data is there
        _loadSecondaryData();
        if(mounted) setState(() => _isLoading = false);
        return; // Stop here, don't fetch from API
      }

    } catch (e) {
      print("[${DateTime.now()}] DashboardScreen: Firestore check error: $e");
      shouldFetchFromApi = true; // Error checking, so fallback to API
      if (mounted) {
        _error = DashboardScreen.dashboardCache == null ? "Couldn't connect to database. Trying live fetch..." : "Couldn't check database updates. Showing cached data.";
      }
    }

    // 3. Fetch from API (if needed)
    if (shouldFetchFromApi) {
      print("[${DateTime.now()}] DashboardScreen: Fetching data from API...");
      if (DashboardScreen.dashboardCache != null && mounted) {
        // If we have old cache data (e.g., from a previous session), show it while refreshing
        _processAndCacheData(DashboardScreen.dashboardCache!);
        setState(() { _isLoading = false; _isRefreshing = true; });
      }
      await _fetchAndPollData(isInitialFetch: true);
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
    print("[${DateTime.now()}] DashboardScreen: _loadInitialData finished.");
  }

  /// Helper to check if a data map contains all essential keys written by the backend.
  bool _checkDataCompleteness(Map<String, dynamic>? data) {
    // Handle potential null data from incomplete Firestore doc
    if (data == null) {
      print("[DEBUG] _checkDataCompleteness: Failed (data is null)");
      return false;
    }
    // Check if all keys *expected from the backend* are present.
    // We REMOVED the check for 'studentInfo' because it's derived locally in the app.
    bool allKeysPresent = _essentialKeys.every((key) {
      bool hasKey = data.containsKey(key);
      if (!hasKey) {
        print("[DEBUG] _checkDataCompleteness: Failed (missing essential key: '$key')");
      }
      return hasKey;
    });
    // Optional: Log success
    // if (allKeysPresent) {
    //     print("[DEBUG] _checkDataCompleteness: Passed (all essential keys found)");
    // }
    return allKeysPresent;
  }


  /// Helper to check if specific trigger keys are present AND non-empty lists.
  bool _checkTriggerKeysPopulated(Map<String, dynamic>? data) {
    if (data == null) {
      print("[DEBUG] _checkTriggerKeysPopulated: Failed (data is null)");
      return false;
    }
    bool allTriggersPopulated = _apiTriggerKeys.every((key) {
      final value = data[key];
      bool isPopulated = data.containsKey(key) && value != null && (value is! List || value.isNotEmpty);
      if (!isPopulated) {
        print("[DEBUG] _checkTriggerKeysPopulated: Failed (key '$key' is missing, null, or an empty list)");
      }
      return isPopulated;
    });
    // Optional: Log success
    // if (allTriggersPopulated) {
    //     print("[DEBUG] _checkTriggerKeysPopulated: Passed (all trigger keys populated)");
    // }
    return allTriggersPopulated;
  }


  /// Loads secondary data like calendar events.
  void _loadSecondaryData() {
    if (CalendarPage.firebaseEventsCache == null) {
      CalendarPage.loadFirebaseEvents(context).then((_) { if(mounted) _checkHolidayStatus(); });
    } else { _checkHolidayStatus(); }
  }


  /// Processes data, updates static cache, and updates local UI state.
  void _processAndCacheData(Map<String, dynamic> data) {
    if (!mounted) return;
    print("[${DateTime.now()}] DashboardScreen: Processing and caching data...");

    // --- Parsing Logic (with added safety) ---
    Map<String, String> parsedStudentInfo = {'status': 'Unknown', 'gender': 'Unknown'};
    // Use putIfAbsent for safer access to potentially missing studentStatus
    dynamic statusRaw = data.putIfAbsent('studentStatus', () => []);
    if (statusRaw is List && statusRaw.length >= 2) {
      if (statusRaw[0] is Map && statusRaw[0].containsKey('status')) {
        parsedStudentInfo['status'] = statusRaw[0]['status']?.toString() ?? 'Unknown';
      }
      if (statusRaw[1] is Map && statusRaw[1].containsKey('gender')) {
        parsedStudentInfo['gender'] = statusRaw[1]['gender']?.toString() ?? 'Unknown';
      }
    } else {
      print("[WARN] studentStatus data missing or malformed in Firestore data during processing.");
    }

    // Update static cache *before* setState
    final updatedCacheData = Map<String, dynamic>.from(data);
    updatedCacheData['studentInfo'] = parsedStudentInfo; // Add derived info to cache
    DashboardScreen.dashboardCache = updatedCacheData;

    // --- Update Local State (with added safety) ---
    setState(() {
      studentName = (data.putIfAbsent('profile', () => {}) is Map && data['profile']['name'] != null)
          ? data['profile']['name'].toString()
          : 'Student';

      timetableData = _getAsList(data['timetable']);
      hourWiseAttendanceData = _getAsList(data['hourWiseAttendance']);
      subjectAttendanceData = _getAsList(data['subjectAttendance']);
      courseMapData = _getAsList(data['courseMap']);
      semGradesData = _getAsList(data['semGrades']);

      studentInfo = parsedStudentInfo; // Use the derived info

      final cgpaList = _getAsList(data['cgpa']);
      cgpa = (cgpaList.isNotEmpty && cgpaList[0] is Map) ? (cgpaList[0]['cgpa']?.toString() ?? "N/A") : "N/A";

      // Use putIfAbsent for fee keys too
      feeDue = (_parseFee(data.putIfAbsent('sastraDue', () => 0)) ?? 0) +
          (_parseFee(data.putIfAbsent('totalDue', () => 0)) ?? 0);

      // --- Attendance Calculation ---
      attendancePercent = 0.0; attendedClasses = 0; totalClasses = 0; bunks = 0;
      int tempTotalHrs = 0; int tempAttendedHrs = 0;
      for (final subject in subjectAttendanceData) { // subjectAttendanceData might be empty if check failed
        if (subject is Map) {
          tempTotalHrs += int.tryParse(subject['totalHrs']?.toString() ?? '0') ?? 0;
          tempAttendedHrs += int.tryParse(subject['presentHrs']?.toString() ?? '0') ?? 0;
        }
      }
      totalClasses = tempTotalHrs;
      attendedClasses = tempAttendedHrs;
      attendancePercent = totalClasses > 0 ? (attendedClasses / totalClasses) * 100 : 0.0;
      // --- End Attendance Calculation ---

      // --- Birthday Check ---
      isBirthday = false;
      final dobList = _getAsList(data['dob']);
      final dobData = (dobList.isNotEmpty && dobList[0] is Map) ? dobList[0]['dob'] : null;
      if (dobData is String && dobData.isNotEmpty) {
        try {
          final parsed = DateFormat('dd-MM-yyyy').parseStrict(dobData);
          final today = DateTime.now();
          if (parsed.day == today.day && parsed.month == today.month) {
            isBirthday = true;
            if (_confettiController.state != ConfettiControllerState.playing) {
              WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _confettiController.play(); });
            }
          }
        } catch (e) { print("Error parsing DOB '$dobData': $e"); }
      }
      // --- End Birthday Check ---

      _error = null; // Clear error on successful processing
      _isLoading = false; // Mark loading as complete
    });
    print("[${DateTime.now()}] DashboardScreen: State updated.");

    _checkHolidayStatus(); // Check for special events

    // Notify HomePage to rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onDataLoaded();
        print("[${DateTime.now()}] DashboardScreen: onDataLoaded callback invoked.");
      }
    });
  }

  /// Safely casts dynamic data to a List<dynamic>, returning empty list on failure.
  List<dynamic> _getAsList(dynamic data) {
    if (data is List) {
      return data;
    }
    return []; // Return empty list if null or not a list
  }

  /// Safely parses fee strings (handles commas, decimals). Returns 0 if null or unparsable.
  int? _parseFee(dynamic feeData) {
    if (feeData == null) return 0; // Default to 0 if key is missing
    final feeString = feeData.toString().replaceAll(',', '').split('.')[0];
    return int.tryParse(feeString) ?? 0; // Default to 0 if parsing fails
  }


  /// Fetches data from API endpoints and polls Firestore for completion.
  Future<void> _fetchAndPollData({bool isInitialFetch = false, String? updatedToken}) async {
    final effectiveToken = updatedToken ?? widget.token;

    if (mounted) setState(() {
      _isRefreshing = true;
      _isLoading = DashboardScreen.dashboardCache == null; // Only show full loading spinner if no cache
      _error = null;
    });

    const apiTimeout = Duration(seconds: 80); // Increased timeout

    try {
      print("[${DateTime.now()}] DashboardScreen: Starting API calls (timeout: ${apiTimeout.inSeconds}s)...");

      final List<Future<http.Response>> parallelFutures = [
        http.post( Uri.parse(api.profile), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken}), ).timeout(apiTimeout),
        http.post( Uri.parse(api.profilePic), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken}), ).timeout(apiTimeout),
        http.post( Uri.parse(api.cgpa), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken}), ).timeout(apiTimeout),
        http.post( Uri.parse(api.subjectWiseAttendance), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken}), ).timeout(apiTimeout),
        http.post( Uri.parse(api.timetable), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken}), ).timeout(apiTimeout),
        http.post( Uri.parse(api.hourWiseAttendance), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken}), ).timeout(apiTimeout),
        http.post( Uri.parse(api.hostelDue), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken}), ).timeout(apiTimeout),
        http.post( Uri.parse(api.courseMap), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken}), ).timeout(apiTimeout),
        http.post( Uri.parse(api.dob), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken}), ).timeout(apiTimeout),
        http.post( Uri.parse(api.semGrades), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken}), ).timeout(apiTimeout),
        http.post( Uri.parse(api.studentStatus), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken}), ).timeout(apiTimeout),
        http.post( Uri.parse(api.attendance), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken}), ).timeout(apiTimeout),
      ];

      // Handle API call errors gracefully
      final results = await Future.wait(parallelFutures.map((f) => f.catchError((e) {
        print("API Call Error: $e");
        return http.Response('{"error": "Timeout or connection error"}', 500);
      })));

      bool allFailed = results.every((res) => res.statusCode != 200);
      if (allFailed) {
        print("[${DateTime.now()}] DashboardScreen: All API calls failed or timed out.");
      } else {
        print("[${DateTime.now()}] DashboardScreen: API calls finished (some may have failed).");
      }

      await Future.delayed(const Duration(milliseconds: 2500)); // Wait for backend write

      Map<String, dynamic>? polledData;
      const maxRetries = 70; // Increased retries
      print("[${DateTime.now()}] DashboardScreen: Starting Firestore polling (max $maxRetries tries)...");
      for (int i = 0; i < maxRetries; i++) {
        if (!mounted) return;
        DocumentSnapshot? doc;
        Map<String, dynamic>? data;
        bool dataComplete = false;
        bool triggerKeysPopulated = false;

        try {
          // Fetch fresh data in each loop iteration
          doc = await FirebaseFirestore.instance.collection('studentDetails').doc(widget.regNo).get()
              .timeout(const Duration(seconds: 5));
          data = doc.data() as Map<String, dynamic>?; // Cast safely

          if (doc.exists && data != null) {
            // Perform checks on the freshly fetched data
            dataComplete = _checkDataCompleteness(data);
            triggerKeysPopulated = _checkTriggerKeysPopulated(data);
          } else {
            print("[DEBUG] Poll try ${i + 1}: Document doesn't exist or data is null.");
          }

        } catch (pollError) {
          print("[${DateTime.now()}] DashboardScreen: Error during Firestore poll try ${i + 1}: $pollError");
          // Continue to next retry
        }

        // Check conditions *after* fetching and potential errors
        if (dataComplete && triggerKeysPopulated) {
          print("[${DateTime.now()}] DashboardScreen: Polling successful on try ${i + 1}.");
          polledData = data; // Assign the validated data
          break; // Exit loop on success
        } else {
          // More detailed log on failure
          print("[${DateTime.now()}] DashboardScreen: Poll try ${i + 1}: Data check failed (complete: $dataComplete, triggers: $triggerKeysPopulated).");
        }

        // Delay before next retry
        if (i < maxRetries - 1) await Future.delayed(const Duration(milliseconds: 1200));
      }


      if (!mounted) return;

      if (polledData != null) {
        // Success!
        _processAndCacheData(polledData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isInitialFetch ? 'Data loaded!' : 'Data refreshed!'), backgroundColor: Colors.green, duration: Duration(seconds: 2)));
        }
      } else {
        // Polling timed out
        print("[${DateTime.now()}] DashboardScreen: Polling timed out after $maxRetries tries.");
        if(DashboardScreen.dashboardCache != null){
          print("[${DateTime.now()}] DashboardScreen: Polling failed, using existing cache.");
          _processAndCacheData(DashboardScreen.dashboardCache!); // Reset to cache
          throw Exception("Failed to refresh all data (polling timeout). Showing last known data.");
        } else {
          throw Exception("Failed to load initial data (polling timeout).");
        }
      }
    } catch (e) {
      print("[${DateTime.now()}] DashboardScreen: Error during fetch/poll: $e");
      if (mounted) {
        setState(() { _error = e.toString(); _isLoading = false; });
        if (!e.toString().contains("Showing last known data")) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error!), backgroundColor: Colors.red));
        }
      }
    } finally {
      if (mounted) { setState(() { _isRefreshing = false; _isLoading = false; }); }
      print("[${DateTime.now()}] DashboardScreen: Fetch/poll process finished.");
    }
  }


  /// Handles manual refresh action.
  Future<void> _refreshFromApi() async {
    if (_isRefreshing || widget.regNo.isEmpty || widget.token.isEmpty) return;

    print("[${DateTime.now()}] DashboardScreen: DEBUG: _refreshFromApi CALLED.");
    print("[${DateTime.now()}] DashboardScreen: Starting manual refresh...");
    setState(() { _isLoading = DashboardScreen.dashboardCache == null; _isRefreshing = true; _error = null; });

    try {
      if (!mounted) throw Exception("Widget unmounted during refresh");
      print("[${DateTime.now()}] DashboardScreen: Showing CaptchaDialog...");
      final String? newToken = await showDialog<String>( context: context, barrierDismissible: false, builder: (context) => CaptchaDialog(token: widget.token, apiUrl: widget.url), );

      if (newToken != null && newToken.isNotEmpty) {
        print("[${DateTime.now()}] DashboardScreen: DEBUG: New token received: '$newToken'");
        print("[${DateTime.now()}] DashboardScreen: Got new token. Fetching data with new token...");
        CalendarPage.firebaseEventsCache = null; // Clear calendar cache on refresh

        // 1. FETCH DATA FIRST
        await _fetchAndPollData(isInitialFetch: false, updatedToken: newToken);

        // 2. UPDATE PARENT TOKEN SECOND
        print("[${DateTime.now()}] DashboardScreen: Data fetch complete. Updating parent token.");
        await widget.onTokenUpdated(newToken);

      } else {
        print("[${DateTime.now()}] DashboardScreen: Captcha cancelled or failed.");
        if (mounted) { setState(() { _isRefreshing = false; _isLoading = false; }); }
      }
    } catch (e) {
      print("[${DateTime.now()}] DashboardScreen: Error during refresh: $e");
      if (mounted) {
        if (_error == null) { setState(() { _error = e.toString(); }); }
        setState(() { _isRefreshing = false; _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error!), backgroundColor: Colors.red));
      }
    } finally {
      // Ensure flags are reset even if errors occurred before fetch completed
      if (mounted && (_isRefreshing || _isLoading)) {
        setState(() { _isRefreshing = false; _isLoading = false; });
      }
      print("[${DateTime.now()}] DashboardScreen: Manual refresh process finished.");
    }
  }


  // --- Helper methods (_getNextExamInfo, _getSpecialEventToday, _checkHolidayStatus, _buildSpecialEventLottie) ---
  // (Keep these unchanged)
  String _getNextExamInfo() { final eventsCache = CalendarPage.firebaseEventsCache; if (eventsCache == null || eventsCache.isEmpty) return "Loading Schedule..."; final today = DateTime.now(); final todayDateOnly = DateTime(today.year, today.month, today.day); DateTime? findFirstEventDate(RegExp regex) { final sortedDates = eventsCache.keys.toList()..sort(); for (final dateKey in sortedDates) { final eventDate = DateTime.tryParse(dateKey); if (eventDate == null || eventDate.isBefore(todayDateOnly)) continue; final events = eventsCache[dateKey]!; if (events.any((event) => regex.hasMatch(event))) return eventDate; } return null; } final examTypes = [ MapEntry("CIA I", RegExp(r'cia\s+i\b', caseSensitive: false)), MapEntry("CIA II", RegExp(r'cia\s+ii\b', caseSensitive: false)), MapEntry("CIA III", RegExp(r'cia\s+iii\b', caseSensitive: false)), MapEntry("Lab Exam", RegExp(r'lab exam', caseSensitive: false)), MapEntry("End Semester Exam", RegExp(r'(even|odd|end)?\s*semester\s+exam\s+starts', caseSensitive: false)), ]; final upcomingExams = <MapEntry<String, DateTime>>[]; for (final exam in examTypes) { final examDate = findFirstEventDate(exam.value); if (examDate != null) upcomingExams.add(MapEntry(exam.key, examDate)); } if (upcomingExams.isEmpty) return "No upcoming exams"; upcomingExams.sort((a, b) => a.value.compareTo(b.value)); final nextExam = upcomingExams.first; final daysRemaining = nextExam.value.difference(todayDateOnly).inDays; if (daysRemaining == 0) return "${nextExam.key} is Today!"; if (daysRemaining == 1) return "${nextExam.key} is Tomorrow!"; return "${nextExam.key} in $daysRemaining days"; }
  String? _getSpecialEventToday() { final eventsCache = CalendarPage.firebaseEventsCache; if (eventsCache == null || eventsCache.isEmpty) { return null; } final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now()); final events = eventsCache[todayKey]; if (events != null && events.isNotEmpty) { const eventMap = { 'tamil new year': 'assets/lottieJson/tamilNewYear.json', 'deepavali': 'assets/lottieJson/diwaliOne.json', 'independence day': 'assets/lottieJson/independence.json', 'christmas': 'assets/lottieJson/christmas.json', 'new year': 'assets/lottieJson/newYear.json', 'republic day': 'assets/lottieJson/republic.json', 'boghi': 'assets/lottieJson/boghi.json', 'pongal': 'assets/lottieJson/pongal.json', }; for (final event in events) { final lowerEvent = event.toLowerCase(); for (final entry in eventMap.entries) { if (lowerEvent.contains(entry.key)) { return entry.value; } } } const String examLottiePath = 'assets/lottieJson/cia.json'; const ciaRegex = r'cia\s+(i|ii|iii)\b'; for (final event in events) { final lowerEvent = event.toLowerCase(); if (RegExp(ciaRegex, caseSensitive: false).hasMatch(lowerEvent)) { return examLottiePath; } } } return null; }
  void _checkHolidayStatus() { if (_specialEventLottiePath != null) return; final lottiePath = _getSpecialEventToday(); if (mounted && lottiePath != null) { setState(() { _specialEventLottiePath = lottiePath; }); } }
  Widget _buildSpecialEventLottie(String lottiePath) { String title = "Happy Holidays!"; if (lottiePath.contains('diwali')) { title = "🪔 Happy Diwali! 🪔"; } else if (lottiePath.contains('independence')) { title = "🇮🇳 Happy Independence Day! 🇮🇳"; } else if (lottiePath.contains('christmas')) { title = "🎄 Merry Christmas! 🎄"; } else if (lottiePath.contains('newYear')) { title = "🎉 Happy New Year! 🎉"; } else if (lottiePath.contains('republic')) { title = "🇮🇳 Happy Republic Day! 🇮🇳"; } else if (lottiePath.contains('tamilNewYear')) { title = "🎉 Happy Tamil New Year! 🎉"; } else if (lottiePath.contains('boghi')) { title = "🔥 Happy Boghi! 🔥"; } else if (lottiePath.contains('pongal')) { title = "🌾 Happy Pongal! 🌾"; } else if (lottiePath.contains('exam')) { title = "CIA Exam Today! 📚"; } return Lottie.asset( lottiePath, frameBuilder: (context, child, composition) { if (composition != null) { return ClipRRect( borderRadius: BorderRadius.circular(12.0), child: child, ); } else { return Container( decoration: BoxDecoration( color: Colors.black, borderRadius: BorderRadius.circular(12.0), ), child: Center( child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ const CircularProgressIndicator(color: Colors.amber), const SizedBox(height: 20), Text( title, style: const TextStyle( color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, ), textAlign: TextAlign.center, ), ], ), ), ); } }, ); }
  // --- End Helper methods ---

  // --- Build methods ---
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
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
                child: Center(
                  child: _buildConditionalContent(context, theme),
                ),
              ),
            );
          }
      ),
    );
  }

  Widget _buildConditionalContent(BuildContext context, ThemeProvider theme) {
    // Show loading indicator only if cache is null AND we are actively loading/refreshing
    if ((_isLoading || _isRefreshing) && DashboardScreen.dashboardCache == null) {
      return Padding( padding: const EdgeInsets.all(32.0), child: CircularProgressIndicator(color: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue), );
    }
    // Show error only if cache is null AND there's an error
    if (_error != null && DashboardScreen.dashboardCache == null) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 50),
            const SizedBox(height: 15),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loadInitialData, child: const Text("Retry Load"))
          ],
        ),
      );
    }
    // Otherwise, build the dashboard (using cache if available)
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        _buildDashboardUI(context),
        _buildConfettiIfNeeded(),
        // Optional: Show a subtle refresh indicator while _isRefreshing is true
        if (_isRefreshing && DashboardScreen.dashboardCache != null)
          Positioned(
            top: 10,
            child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(15)
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    SizedBox(width: 8),
                    Text("Refreshing...", style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                )
            ),
          )
      ],
    );
  }


  Widget _buildDashboardUI(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    // Use cached data if available, otherwise expect state variables to be populated
    final dataToDisplay = DashboardScreen.dashboardCache ?? {};

    // Recalculate based on dataToDisplay to ensure consistency, using defaults if keys missing
    final currentStudentName = (dataToDisplay.putIfAbsent('profile', () => {}) is Map && dataToDisplay['profile']['name'] != null)
        ? dataToDisplay['profile']['name'].toString()
        : 'Student';
    final currentTimetableData = _getAsList(dataToDisplay['timetable']);
    final currentHourWiseAttendanceData = _getAsList(dataToDisplay['hourWiseAttendance']);
    final currentSubjectAttendanceData = _getAsList(dataToDisplay['subjectAttendance']);
    final currentCourseMapData = _getAsList(dataToDisplay['courseMap']);
    // final currentSemGradesData = _getAsList(dataToDisplay['semGrades']); // Not directly used in UI?
    final currentCgpaList = _getAsList(dataToDisplay['cgpa']);
    final currentCgpa = (currentCgpaList.isNotEmpty && currentCgpaList[0] is Map) ? (currentCgpaList[0]['cgpa']?.toString() ?? "N/A") : "N/A";
    final currentFeeDue = (_parseFee(dataToDisplay.putIfAbsent('sastraDue', () => 0)) ?? 0) +
        (_parseFee(dataToDisplay.putIfAbsent('totalDue', () => 0)) ?? 0);

    // Recalculate attendance locally for display consistency
    double currentAttendancePercent = 0.0;
    int currentAttendedClasses = 0;
    int currentTotalClasses = 0;
    for (final subject in currentSubjectAttendanceData) {
      if (subject is Map) {
        currentTotalClasses += int.tryParse(subject['totalHrs']?.toString() ?? '0') ?? 0;
        currentAttendedClasses += int.tryParse(subject['presentHrs']?.toString() ?? '0') ?? 0;
      }
    }
    currentAttendancePercent = currentTotalClasses > 0 ? (currentAttendedClasses / currentTotalClasses) * 100 : 0.0;
    // Note: 'bunks' calculation might need adjustment based on its logic


    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show error banner *over* the cached content if refresh failed
          if (_error != null && !_isLoading) // Show error banner if error exists and not initial loading
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: MaterialBanner(
                padding: const EdgeInsets.all(10),
                content: Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                backgroundColor: Colors.orange.shade800,
                forceActionsBelow: true,
                actions: [ TextButton( onPressed: () => setState(() => _error = null), child: const Text('DISMISS', style: TextStyle(color: Colors.white))) ],
              ),
            ),
          GestureDetector( /* ... Profile Container ... */
            onTap: () { Navigator.push( context, MaterialPageRoute(builder: (_) => ProfilePage(token: widget.token, url: widget.url, regNo: widget.regNo))); }, child: NeonContainer( borderColor: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue, child: Row( children: [ CircleAvatar( radius: 28, backgroundColor: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue, child: Icon(Icons.person, color: theme.isDarkMode ? Colors.black : Colors.white) ), const SizedBox(width: 16), Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ if (isBirthday) const FittedBox(fit: BoxFit.scaleDown, child: Text('🎉 Happy Birthday! 🎉', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber))) else FittedBox( fit: BoxFit.scaleDown, child: Text( (currentStudentName.isNotEmpty ? 'Welcome, $currentStudentName!' : 'Welcome Back!'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue) ), ), FittedBox(fit: BoxFit.scaleDown, child: Text('Student Dashboard', style: TextStyle(color: theme.isDarkMode ? Colors.white70 : Colors.grey[600]))), ], ), ), ], ), ),
          ),
          const SizedBox(height: 16),
          GestureDetector( /* ... Attendance Pie Chart ... */
            onTap: () { Navigator.push( context, MaterialPageRoute( builder: (_) => SubjectWiseAttendancePage( regNo: widget.regNo, token: widget.token, url: widget.url, initialSubjectAttendance: currentSubjectAttendanceData, initialHourWiseAttendance: currentHourWiseAttendanceData, timetable: currentTimetableData, courseMap: currentCourseMapData, ), ), ); },
            child: AttendancePieChart(
              attendancePercentage: currentAttendancePercent, // Use calculated value
              attendedClasses: currentAttendedClasses, // Use calculated value
              totalClasses: currentTotalClasses, // Use calculated value
              bunkingDaysLeft: bunks, // bunks calculation needs review if it depends on state only
            ),
          ),
          const SizedBox(height: 16),
          Row( /* ... Fee and GPA Tiles ... */
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _buildFeeDueTile(theme, currentFeeDue)), // Use calculated value
            const SizedBox(width: 12),
            Expanded(child: _buildGpaExamTile(theme, currentCgpa)), // Use calculated value
          ],
          ),
          const SizedBox(height: 16),
          SizedBox( // Timetable or Lottie Container
            height: 300,
            child: _specialEventLottiePath != null
                ? _buildSpecialEventLottie(_specialEventLottiePath!)
                : TimetableWidget(
              timetable: currentTimetableData, // Use calculated value
              // Show loading only if absolutely no data and initial fetch is happening
              isLoading: _isLoading && DashboardScreen.dashboardCache == null,
              hourWiseAttendance: currentHourWiseAttendanceData, // Use calculated value
              courseMap: currentCourseMapData, // Use calculated value
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildConfettiIfNeeded() {
    return isBirthday ? Align( alignment: Alignment.topCenter, child: ConfettiWidget( confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive), ) : const SizedBox.shrink();
  }

  Widget _buildFeeDueTile(ThemeProvider theme, int feeDue) {
    final hasDue = feeDue > 0; final isDark = theme.isDarkMode; return GestureDetector( onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => FeeDueScreen( url: widget.url, token: widget.token))); }, child: SizedBox( width: 180, height: 150, child: NeonContainer( borderColor: hasDue ? Colors.red.shade400 : (isDark ? AppTheme.neonBlue : AppTheme.primaryBlue), padding: const EdgeInsets.all(12), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.account_balance_wallet, size: 40, color: hasDue ? Colors.red.shade400 : (isDark ? AppTheme.neonBlue : AppTheme.primaryBlue)), const SizedBox(height: 8), const FittedBox(fit: BoxFit.scaleDown, child: Text('Fee Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), const SizedBox(height: 4), FittedBox(fit: BoxFit.scaleDown, child: Text( (hasDue ? '₹$feeDue Due' : 'Paid'), style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600]))), ], ), ), ), );
  }

  Widget _buildGpaExamTile(ThemeProvider theme, String cgpa) {
    final isDark = theme.isDarkMode; return GestureDetector( onDoubleTap: () => setState(() => showExamSchedule = !showExamSchedule), child: SizedBox( width: 180, height: 150, child: NeonContainer( borderColor: isDark ? AppTheme.neonBlue : AppTheme.primaryBlue, padding: const EdgeInsets.all(12), child: AnimatedSwitcher( duration: const Duration(milliseconds: 300), child: showExamSchedule ? Column( key: const ValueKey('exam'), mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.event, size: 40, color: isDark ? AppTheme.neonBlue : AppTheme.primaryBlue), const SizedBox(height: 10), const FittedBox(fit: BoxFit.scaleDown, child: Text('Exam Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), const SizedBox(height: 4), FittedBox(fit: BoxFit.scaleDown, child: Text(_getNextExamInfo(), style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600]), textAlign: TextAlign.center,)), ]) : Column( key: const ValueKey('gpa'), mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.grade, size: 40, color: isDark ? AppTheme.neonBlue : Colors.orange), const SizedBox(height: 10), const FittedBox(fit: BoxFit.scaleDown, child: Text('CGPA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), FittedBox(fit: BoxFit.scaleDown, child: Text('$cgpa / 10', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600]))), ]), ), ), ), );
  }
// --- End Build methods ---

} // End _DashboardScreenState