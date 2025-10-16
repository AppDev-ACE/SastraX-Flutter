import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class HomePage extends StatefulWidget {
  final String token;
  final String url;
  final String regNo;

  const HomePage({super.key, required this.token, required this.url, required this.regNo});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(token: widget.token, url: widget.url, regNo: widget.regNo),
      CalendarPage(token: widget.token),
      const CommunityPage(),
      MessMenuPage(url: widget.url),
      MoreOptionsScreen(token: widget.token, url: widget.url, regNo: widget.regNo),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.isDarkMode ? AppTheme.darkSurface : Colors.white,
          selectedItemColor: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
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

  const DashboardScreen({super.key, required this.token, required this.url, required this.regNo});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // UI State
  bool showAssignments = false;
  bool isCgpaLoading = true;
  bool isTimetableLoading = true;
  String? _error;

  // Data State
  double attendancePercent = -1;
  int attendedClasses = 0;
  int totalClasses = 0;
  String? cgpa;
  bool isBirthday = false;
  String? studentName;
  int feeDue = 0;
  int bunks = 0;
  List assignments = [];
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
    _loadInitialData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (widget.regNo.isEmpty) {
      setState(() { _error = "Running in Guest Mode."; /* ... */ });
      return;
    }
    try {
      final docRef = FirebaseFirestore.instance.collection('studentDetails').doc(widget.regNo);
      final doc = await docRef.get();
      final data = doc.data();

      if (doc.exists && data != null && data.containsKey('profile') && data.containsKey('bunkdata')) {
        _processFirestoreData(data);
      } else {
        await _refreshFromApi();
      }
    } catch (e) {
      if (mounted) setState(() => _error = "Error loading data: $e");
    }
  }

  void _processFirestoreData(Map<String, dynamic> data) {
    setState(() {
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
        int totalHrs = 0;
        int attendedHrs = 0;
        for (final subject in subjectAttendanceData) {
          totalHrs += int.tryParse(subject['totalHrs']?.toString() ?? '0') ?? 0;
          attendedHrs += int.tryParse(subject['presentHrs']?.toString() ?? '0') ?? 0;
        }
        totalClasses = totalHrs;
        attendedClasses = attendedHrs;
        attendancePercent = totalClasses > 0 ? (attendedClasses / totalClasses) * 100 : 0;

        int totalAbsences = totalClasses - attendedClasses;
        int maxAllowedAbsences = 0;

        final perSem20 = bunkData['perSem20'] as Map<String, dynamic>? ?? {};
        perSem20.forEach((key, value) {
          maxAllowedAbsences += (value as num).toInt();
        });

        bunks = maxAllowedAbsences - totalAbsences;
      } else {
        attendancePercent = 0;
        bunks = 0;
      }

      final dobList = data['dob'] is List ? data['dob'] as List : [];
      final dobData = dobList.isNotEmpty ? dobList[0]['dob'] : null;
      if (dobData != null && dobData.isNotEmpty) {
        try {
          final parsed = DateFormat('dd-MM-yyyy').parse(dobData);
          final today = DateTime.now();
          if (parsed.day == today.day && parsed.month == today.month) {
            isBirthday = true;
            _confettiController.play();
          }
        } catch (_) {}
      }
      isTimetableLoading = false;
      isCgpaLoading = false;
      _error = null;
    });
  }

  Future<void> _refreshFromApi() async {
    setState(() { isTimetableLoading = true; isCgpaLoading = true; });
    try {
      final bunkResponse = await http.post(
        Uri.parse('${widget.url}/bunk'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': widget.token}),
      );

      await Future.wait([
        http.post(Uri.parse(api.profile), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': true, 'token': widget.token})),
        http.post(Uri.parse(api.profilePic), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': true, 'token': widget.token})),
        http.post(Uri.parse(api.cgpa), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': true, 'token': widget.token})),
        http.post(Uri.parse('${widget.url}/subjectWiseAttendance'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': true, 'token': widget.token})),
        http.post(Uri.parse(api.timetable), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': true, 'token': widget.token})),
        http.post(Uri.parse('${widget.url}/hourWiseAttendance'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': true, 'token': widget.token})),
        http.post(Uri.parse(api.sastraDue), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': true, 'token': widget.token})),
        http.post(Uri.parse(api.hostelDue), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': true, 'token': widget.token})),
        http.post(Uri.parse('${widget.url}/courseMap'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh': true, 'token': widget.token})),
      ]);

      if (!mounted) return;

      if (bunkResponse.statusCode == 200) {
        final bunkJson = jsonDecode(bunkResponse.body);
        if (bunkJson['success'] == true) {
          await FirebaseFirestore.instance
              .collection('studentDetails')
              .doc(widget.regNo)
              .set({'bunkdata': bunkJson['bunkdata']}, SetOptions(merge: true));
        }
      }

      final doc = await FirebaseFirestore.instance.collection('studentDetails').doc(widget.regNo).get();
      if (doc.exists && doc.data() != null) {
        _processFirestoreData(doc.data()!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dashboard refreshed!'), backgroundColor: Colors.green));
        }
      } else {
        throw Exception("Refreshed data not found in database.");
      }
    } catch (e) {
      if (mounted) setState(() {
        _error = "Failed to refresh data: $e";
        isTimetableLoading = false;
        isCgpaLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)), const SizedBox(height: 10), ElevatedButton(onPressed: _loadInitialData, child: const Text("Retry"))])));
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refreshFromApi,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(token: widget.token, url: widget.url, regNo: widget.regNo))),
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
                                if (isBirthday)
                                  const FittedBox(fit: BoxFit.scaleDown, child: Text('🎉 Happy Birthday! 🎉', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber)))
                                else
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(studentName != null ? 'Welcome, $studentName!' : 'Welcome Back!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue)),
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
                  attendancePercent < 0
                      ? const Center(child: CircularProgressIndicator())
                  // ✅ FIX: Removed the NeonContainer wrapper
                      : GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubjectWiseAttendancePage(
                          regNo: widget.regNo,
                          token: widget.token,
                          url: widget.url,
                          initialSubjectAttendance: subjectAttendanceData,
                          initialHourWiseAttendance: hourWiseAttendanceData,
                        ),
                      ),
                    ),
                    child: AttendancePieChart(
                      attendancePercentage: attendancePercent,
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
                      Expanded(child: _buildGpaAssignmentTile(theme)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: TimetableWidget(
                      timetable: timetableData,
                      isLoading: isTimetableLoading,
                      hourWiseAttendance: hourWiseAttendanceData,
                      courseMap: courseMapData,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isBirthday)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive),
          ),
      ],
    );
  }

  Widget _buildFeeDueTile(ThemeProvider theme) {
    final hasDue = feeDue > 0;
    final isDark = theme.isDarkMode;
    return GestureDetector(
      onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => FeeDueStatusPage())); },
      child: SizedBox(
        width: 180,
        height: 150,
        child: NeonContainer(
          borderColor: hasDue ? Colors.red.shade400 : (isDark ? AppTheme.neonBlue : AppTheme.primaryBlue),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet, size: 40, color: hasDue ? Colors.red.shade400 : (isDark ? AppTheme.neonBlue : AppTheme.primaryBlue)),
              const SizedBox(height: 8),
              const FittedBox(fit: BoxFit.scaleDown, child: Text('Fee Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              const SizedBox(height: 4),
              FittedBox(fit: BoxFit.scaleDown, child: Text(hasDue ? '₹$feeDue' : 'Paid', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600]))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGpaAssignmentTile(ThemeProvider theme) {
    final isDark = theme.isDarkMode;
    return GestureDetector(
      onDoubleTap: () => setState(() => showAssignments = !showAssignments),
      child: SizedBox(
        width: 180,
        height: 150,
        child: NeonContainer(
          borderColor: isDark ? AppTheme.neonBlue : AppTheme.primaryBlue,
          padding: const EdgeInsets.all(12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: showAssignments
                ? Column(
              key: const ValueKey('assignments'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in, size: 40, color: isDark ? AppTheme.neonBlue : AppTheme.primaryBlue),
                const SizedBox(height: 10),
                const FittedBox(fit: BoxFit.scaleDown, child: Text('Assignments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                FittedBox(fit: BoxFit.scaleDown, child: Text('${assignments.length} Pending', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600]))),
              ],
            )
                : Column(
              key: const ValueKey('gpa'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grade, size: 40, color: isDark ? AppTheme.electricBlue : Colors.orange),
                const SizedBox(height: 10),
                const FittedBox(fit: BoxFit.scaleDown, child: Text('CGPA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                isCgpaLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : FittedBox(fit: BoxFit.scaleDown, child: Text('$cgpa / 10', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600]))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}