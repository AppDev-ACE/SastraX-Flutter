import 'dart:async';
import 'dart:convert';
import 'dart:ui';
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
import 'internals_page.dart'; // Required for the new bottom nav item

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
  // ❌ REMOVED: The _pages list is no longer a state variable.
  // late List<Widget> _pages;
  late String _currentToken;

  @override
  void initState() {
    super.initState();
    _currentToken = widget.token;
    if (_currentToken.isEmpty && widget.regNo.isNotEmpty) {
      print("Error: HomePage initState invalid token");
      _currentToken = "";
    }
    // ❌ REMOVED: _buildPages() call is no longer needed here.
  }

  // ❌ REMOVED: The _buildPages method is no longer needed.

  Future<void> _updateToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', newToken);
    if (mounted) {
      setState(() {
        _currentToken = newToken;
        // No need to call _buildPages(), the build method will handle it.
      });
    }
  }

  void _onDataLoaded() {
    if (mounted) {
      print("HomePage: Data loaded signal received. Triggering UI rebuild.");
      setState(() {
        // This empty call forces HomePage to rebuild, which in turn will
        // rebuild all child pages with the latest data from the cache.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentToken.isEmpty && widget.regNo.isNotEmpty) {
      return Scaffold(
          appBar: AppBar(title: const Text("Error")),
          body: const Center(child: Text("Invalid session state.")));
    }

    // ✅ ADDED: The list of pages is now built here, inside the build method.
    // This ensures that when HomePage rebuilds, it creates fresh instances
    // of its children, allowing them to read the updated cache.
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
          token: _currentToken, url: widget.url, regNo: widget.regNo),
      MoreOptionsScreen(
          token: _currentToken, url: widget.url, regNo: widget.regNo)
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final appBarHeight = screenWidth * 0.2;
    return Consumer<ThemeProvider>(
        builder: (_, theme, __) => Scaffold(
            backgroundColor:
            theme.isDarkMode ? AppTheme.darkBackground : Colors.white,
            appBar: AppBar(
                leadingWidth: appBarHeight,
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
                    ? AppTheme.darkBackground
                    : AppTheme.primaryBlue,
                elevation: 0,
                actions: [
                  Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: ThemeToggleButton(
                          isDarkMode: theme.isDarkMode,
                          onToggle: theme.toggleTheme))
                ]),
            // Use the locally defined 'pages' list.
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
                ])));
  }
}

// --- The rest of DashboardScreen remains unchanged as its logic is correct ---
// It correctly calls `onDataLoaded` which now triggers the desired effect.

/// -------------------- DashboardScreen (Using Polling Logic) --------------------
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

  static Map<String, dynamic>? dashboardCache;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ... (Implementation remains the same as your last correct version) ...
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
  final List<String> _essentialKeys = [
    'profile',
    'semGrades',
    'cgpa',
    'studentStatus'
  ];

  @override
  void initState() {
    super.initState();
    api = ApiEndpoints(widget.url);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    print("DashboardScreen initState: Received token = '${widget.token}'");
    _loadInitialData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (mounted) setState(() { _isLoading = true; _error = null; });
    if (widget.token.isEmpty || widget.regNo.isEmpty) {
      if(mounted) setState(() { _error = "Invalid session."; _isLoading = false; });
      return;
    }
    if (DashboardScreen.dashboardCache != null) {
      bool cacheComplete = _essentialKeys.every((key) => DashboardScreen.dashboardCache!.containsKey(key)) &&
          DashboardScreen.dashboardCache!.containsKey('studentInfo');
      if (cacheComplete) {
        print("DashboardScreen _loadInitialData: Loading from complete cache.");
        _processFirestoreData(DashboardScreen.dashboardCache!);
        if (CalendarPage.firebaseEventsCache == null) CalendarPage.loadFirebaseEvents(context).then((_) { if (mounted) setState(() {}); });
        if(mounted) setState(() => _isLoading = false);
        return;
      } else {
        print("DashboardScreen _loadInitialData: Cache incomplete. Invalidating.");
        DashboardScreen.dashboardCache = null;
      }
    }
    bool shouldFetchFromApi = false;
    try {
      final initialDoc = await FirebaseFirestore.instance.collection('studentDetails').doc(widget.regNo).get();
      if (!initialDoc.exists) {
        shouldFetchFromApi = true;
      } else {
        final data = initialDoc.data();
        bool dataComplete = data != null && _essentialKeys.every((key) => data.containsKey(key));
        if (!dataComplete) {
          shouldFetchFromApi = true;
        } else {
          _processFirestoreData(data!);
          if(mounted) setState(() => _isLoading = false);
          if (CalendarPage.firebaseEventsCache == null) CalendarPage.loadFirebaseEvents(context).then((_) { if (mounted) setState(() {}); });
          return;
        }
      }
    } catch (e) {
      if (mounted) setState(() { _error = "DB Connection Error."; _isLoading = false; });
      return;
    }
    if (shouldFetchFromApi) {
      await _fetchAndPollData(isInitialFetch: true);
    }
  }

  void _processFirestoreData(Map<String, dynamic> data) {
    if (!mounted) return;
    print("DashboardScreen _processFirestoreData: Processing data...");

    Map<String, String> parsedStudentInfo = {'status': 'Unknown', 'gender': 'Unknown'};
    if (data['studentStatus'] is List && (data['studentStatus'] as List).length >= 2) {
      List<dynamic> statusList = data['studentStatus'];
      if (statusList[0] is Map && statusList[0].containsKey('status')) {
        parsedStudentInfo['status'] = statusList[0]['status']?.toString() ?? 'Unknown';
      }
      if (statusList[1] is Map && statusList[1].containsKey('gender')) {
        parsedStudentInfo['gender'] = statusList[1]['gender']?.toString() ?? 'Unknown';
      }
    }

    final updatedCacheData = Map<String, dynamic>.from(data);
    updatedCacheData['studentInfo'] = parsedStudentInfo;
    DashboardScreen.dashboardCache = updatedCacheData;
    print("DashboardScreen: Updated cache synchronously with studentInfo: ${DashboardScreen.dashboardCache?['studentInfo']}");

    setState(() {
      studentName = data['profile']?['name'] ?? 'Student';
      timetableData = data['timetable'] as List? ?? [];
      hourWiseAttendanceData = data['hourWiseAttendance'] as List? ?? [];
      subjectAttendanceData = data['subjectAttendance'] as List? ?? [];
      courseMapData = data['courseMap'] as List? ?? [];
      semGradesData = data['semGrades'] as List? ?? [];
      studentInfo = parsedStudentInfo;
      final cgpaList = data['cgpa'] as List? ?? [];
      cgpa = cgpaList.isNotEmpty ? (cgpaList[0]['cgpa'] ?? "N/A") : "N/A";
      final sastraDueRaw = data['sastraDue']?.toString() ?? "0";
      final hostelDueRaw = data['totalDue']?.toString() ?? "0";
      feeDue = (int.tryParse(sastraDueRaw.replaceAll(',', '').split('.')[0]) ?? 0) + (int.tryParse(hostelDueRaw.replaceAll(',', '').split('.')[0]) ?? 0);
      attendancePercent = 0.0; attendedClasses = 0; totalClasses = 0; bunks = 0;
      if (subjectAttendanceData.isNotEmpty) {
        int totalHrs = 0, attendedHrs = 0;
        for (final subject in subjectAttendanceData) {
          totalHrs += int.tryParse(subject['totalHrs']?.toString() ?? '0') ?? 0;
          attendedHrs += int.tryParse(subject['presentHrs']?.toString() ?? '0') ?? 0;
        }
        totalClasses = totalHrs;
        attendedClasses = attendedHrs;
        attendancePercent = totalClasses > 0 ? (attendedClasses / totalClasses) * 100 : 0.0;
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
      _error = null;
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onDataLoaded();
      }
    });
  }

  Future<void> _fetchAndPollData({bool isInitialFetch = false, String? updatedToken}) async {
    final effectiveToken = updatedToken ?? widget.token;
    if (_isRefreshing && !isInitialFetch) { return; }
    if (mounted) setState(() { _isRefreshing = true; _error = null; });
    try {
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
        http.post(Uri.parse(api.studentStatus), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'token': effectiveToken})),
      ];
      if (isInitialFetch) {
        final calendarFuture = CalendarPage.loadFirebaseEvents(context);
        await Future.wait([calendarFuture, ...parallelFutures]);
      } else {
        await Future.wait(parallelFutures);
      }
      Map<String, dynamic>? fetchedData;
      const maxRetries = 10;
      for (int i = 0; i < maxRetries; i++) {
        if (!mounted) return;
        final doc = await FirebaseFirestore.instance.collection('studentDetails').doc(widget.regNo).get();
        final data = doc.data();
        if (doc.exists && data != null && _essentialKeys.every((key) => data.containsKey(key))) {
          fetchedData = data;
          break;
        }
        await Future.delayed(const Duration(milliseconds: 1000));
      }
      if (!mounted) return;
      if (fetchedData != null) {
        _processFirestoreData(fetchedData);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isInitialFetch ? 'Initial data loaded!' : 'Data refreshed!'), backgroundColor: Colors.green));
      } else {
        throw Exception("Failed to load complete data after fetch (timeout).");
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error!), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() { _isRefreshing = false; _isLoading = false; });
      }
    }
  }

  Future<void> _refreshFromApi() async {
    if (_isRefreshing || widget.regNo.isEmpty || widget.token.isEmpty) { return; }
    setState(() { _isLoading = true; _isRefreshing = true; _error = null; });
    try {
      if (!mounted) throw Exception("Widget unmounted during refresh");
      final String? newToken = await showDialog<String>( context: context, barrierDismissible: false, builder: (context) => CaptchaDialog(token: widget.token, apiUrl: widget.url), );
      if (newToken != null && newToken.isNotEmpty) {
        await widget.onTokenUpdated(newToken);
        CalendarPage.firebaseEventsCache = null;
        await _fetchAndPollData(isInitialFetch: false, updatedToken: newToken);
      } else {
        throw Exception("Session refresh cancelled or failed.");
      }
    } catch (e) {
      if (mounted) {
        if (_error == null) {
          setState(() { _error = e.toString(); });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error!), backgroundColor: Colors.red));
        }
        setState(() { _isRefreshing = false; _isLoading = false; });
      }
    }
  }

  String _getNextExamInfo() { final eventsCache = CalendarPage.firebaseEventsCache; if (eventsCache == null || eventsCache.isEmpty) return "Loading Schedule..."; final today = DateTime.now(); final todayDateOnly = DateTime(today.year, today.month, today.day); DateTime? findFirstEventDate(RegExp regex) { final sortedDates = eventsCache.keys.toList()..sort(); for (final dateKey in sortedDates) { final eventDate = DateTime.tryParse(dateKey); if (eventDate == null || eventDate.isBefore(todayDateOnly)) continue; final events = eventsCache[dateKey]!; if (events.any((event) => regex.hasMatch(event))) return eventDate; } return null; } final examTypes = [ MapEntry("CIA I", RegExp(r'cia\s+i\b', caseSensitive: false)), MapEntry("CIA II", RegExp(r'cia\s+ii\b', caseSensitive: false)), MapEntry("CIA III", RegExp(r'cia\s+iii\b', caseSensitive: false)), MapEntry("Lab Exam", RegExp(r'lab exam', caseSensitive: false)), MapEntry("End Semester Exam", RegExp(r'(even|odd|end)?\s*semester\s+exam\s+starts', caseSensitive: false)), ]; final upcomingExams = <MapEntry<String, DateTime>>[]; for (final exam in examTypes) { final examDate = findFirstEventDate(exam.value); if (examDate != null) upcomingExams.add(MapEntry(exam.key, examDate)); } if (upcomingExams.isEmpty) return "No upcoming exams"; upcomingExams.sort((a, b) => a.value.compareTo(b.value)); final nextExam = upcomingExams.first; final daysRemaining = nextExam.value.difference(todayDateOnly).inDays; if (daysRemaining == 0) return "${nextExam.key} is Today!"; if (daysRemaining == 1) return "${nextExam.key} is Tomorrow!"; return "${nextExam.key} in $daysRemaining days"; }
  Widget _buildDashboardUI(BuildContext context) { final theme = Provider.of<ThemeProvider>(context); return Padding( padding: const EdgeInsets.all(16.0), child: Column( mainAxisSize: MainAxisSize.min, children: [ if (_error != null && !_isLoading) Padding( padding: const EdgeInsets.only(bottom: 10.0), child: MaterialBanner( padding: const EdgeInsets.all(10), content: Text(_error!, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.orange.shade800, forceActionsBelow: true, actions: [ TextButton( onPressed: () => setState(() => _error = null), child: const Text('DISMISS', style: TextStyle(color: Colors.white))) ], ), ), GestureDetector( onTap: () { Navigator.push( context, MaterialPageRoute(builder: (_) => ProfilePage(token: widget.token, url: widget.url, regNo: widget.regNo))); }, child: NeonContainer( borderColor: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue, child: Row( children: [ CircleAvatar( radius: 28, backgroundColor: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue, child: Icon(Icons.person, color: theme.isDarkMode ? Colors.black : Colors.white) ), const SizedBox(width: 16), Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ if (isBirthday) const FittedBox(fit: BoxFit.scaleDown, child: Text('🎉 Happy Birthday! 🎉', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber))) else FittedBox( fit: BoxFit.scaleDown, child: Text( (studentName != null && studentName!.isNotEmpty ? 'Welcome, $studentName!' : 'Welcome Back!'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue) ), ), FittedBox(fit: BoxFit.scaleDown, child: Text('Student Dashboard', style: TextStyle(color: theme.isDarkMode ? Colors.white70 : Colors.grey[600]))), ], ), ), ], ), ), ), const SizedBox(height: 16), GestureDetector( onTap: () { Navigator.push( context, MaterialPageRoute( builder: (_) => SubjectWiseAttendancePage( regNo: widget.regNo, token: widget.token, url: widget.url, initialSubjectAttendance: subjectAttendanceData, initialHourWiseAttendance: hourWiseAttendanceData, timetable: timetableData, courseMap: courseMapData, ), ), ); }, child: AttendancePieChart( attendancePercentage: attendancePercent, attendedClasses: attendedClasses, totalClasses: totalClasses, bunkingDaysLeft: bunks, ), ), const SizedBox(height: 16), Row( crossAxisAlignment: CrossAxisAlignment.start, children: [ Expanded(child: _buildFeeDueTile(theme, feeDue)), const SizedBox(width: 12), Expanded(child: _buildGpaExamTile(theme, cgpa ?? 'N/A')), ], ), const SizedBox(height: 16), SizedBox( height: 300, child: TimetableWidget( timetable: timetableData, isLoading: false, hourWiseAttendance: hourWiseAttendanceData, courseMap: courseMapData, ), ), ], ), ); }
  @override Widget build(BuildContext context) { final theme = Provider.of<ThemeProvider>(context); return RefreshIndicator( onRefresh: _refreshFromApi, color: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue, backgroundColor: theme.isDarkMode ? AppTheme.darkSurface : Colors.white, child: LayoutBuilder( builder: (context, constraints) { return SingleChildScrollView( physics: const AlwaysScrollableScrollPhysics(), child: ConstrainedBox( constraints: BoxConstraints(minHeight: constraints.maxHeight), child: Center( child: _buildConditionalContent(context, theme), ), ), ); } ), ); }
  Widget _buildConditionalContent(BuildContext context, ThemeProvider theme) { if (_isLoading) { return Padding( padding: const EdgeInsets.all(32.0), child: CircularProgressIndicator(color: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue), ); } if (_error != null) { return Padding( padding: const EdgeInsets.all(20.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)), const SizedBox(height: 10), ElevatedButton(onPressed: _loadInitialData, child: const Text("Retry Load")) ], ), ); } return Stack( alignment: Alignment.topCenter, children: [ _buildDashboardUI(context), _buildConfettiIfNeeded(), ], ); }
  Widget _buildConfettiIfNeeded() { return isBirthday ? Align( alignment: Alignment.topCenter, child: ConfettiWidget( confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive), ) : const SizedBox.shrink(); }
  Widget _buildFeeDueTile(ThemeProvider theme, int feeDue) { final hasDue = feeDue > 0; final isDark = theme.isDarkMode; return GestureDetector( onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => FeeDueStatusPage())); }, child: SizedBox( width: 180, height: 150, child: NeonContainer( borderColor: hasDue ? Colors.red.shade400 : (isDark ? AppTheme.neonBlue : AppTheme.primaryBlue), padding: const EdgeInsets.all(12), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.account_balance_wallet, size: 40, color: hasDue ? Colors.red.shade400 : (isDark ? AppTheme.neonBlue : AppTheme.primaryBlue)), const SizedBox(height: 8), const FittedBox(fit: BoxFit.scaleDown, child: Text('Fee Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), const SizedBox(height: 4), FittedBox(fit: BoxFit.scaleDown, child: Text( (hasDue ? '₹$feeDue' : 'Paid'), style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600]))), ], ), ), ), ); }
  Widget _buildGpaExamTile(ThemeProvider theme, String cgpa) { final isDark = theme.isDarkMode; return GestureDetector( onDoubleTap: () => setState(() => showExamSchedule = !showExamSchedule), child: SizedBox( width: 180, height: 150, child: NeonContainer( borderColor: isDark ? AppTheme.neonBlue : AppTheme.primaryBlue, padding: const EdgeInsets.all(12), child: AnimatedSwitcher( duration: const Duration(milliseconds: 300), child: showExamSchedule ? Column( key: const ValueKey('exam'), mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.event, size: 40, color: isDark ? AppTheme.neonBlue : AppTheme.primaryBlue), const SizedBox(height: 10), const FittedBox(fit: BoxFit.scaleDown, child: Text('Exam Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), const SizedBox(height: 4), FittedBox(fit: BoxFit.scaleDown, child: Text(_getNextExamInfo(), style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600]), textAlign: TextAlign.center,)), ]) : Column( key: const ValueKey('gpa'), mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.grade, size: 40, color: isDark ? AppTheme.neonBlue : Colors.orange), const SizedBox(height: 10), const FittedBox(fit: BoxFit.scaleDown, child: Text('CGPA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), FittedBox(fit: BoxFit.scaleDown, child: Text('$cgpa / 10', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600]))), ]), ), ), ), ); }
}

