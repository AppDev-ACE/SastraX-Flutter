import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
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
  late final ApiEndpoints api;

  @override
  void initState() {
    super.initState();
    api = ApiEndpoints(widget.url);
    _pages = [
      DashboardScreen(token: widget.token, url: widget.url, regNo: widget.regNo),
      CalendarPage(token: widget.token),
      const CommunityPage(),
      MessMenuPage(url: widget.url),
      MoreOptionsScreen(token: widget.token, url: widget.url),
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
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: appBarHeight * 0.9,
              width: appBarHeight * 0.9,
              child: Image.asset(
                'assets/icon/Logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'SastraX',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          centerTitle: true,
          backgroundColor: theme.isDarkMode ? AppTheme.darkBackground : AppTheme.primaryBlue,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ThemeToggleButton(
                isDarkMode: theme.isDarkMode,
                onToggle: theme.toggleTheme,
              ),
            ),
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
  bool showAssignments = false;
  double attendancePercent = -1;
  int attendedClasses = 0;
  int totalClasses = 0;
  String? cgpa;
  bool isCgpaLoading = true;
  bool isBirthday = false;
  String? studentName;
  int feeDue = 0;
  int bunks = 0;
  List assignments = [];
  bool isTimetableLoading = true;
  List timetableData = [];
  List hourWiseAttendanceData = [];

  late final ApiEndpoints api;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    api = ApiEndpoints(widget.url);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _fetchDashboardDataSequentially();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardDataSequentially() async {
    if (!mounted) return;
    try {
      await Future.wait([
        _fetchProfile(),
        _fetchSubjectWiseAttendanceAndSum(),
        _fetchCGPA(),
        _fetchFeeDue(),
        _fetchBunks(),
        _fetchTimetable(),
        _fetchHourWiseAttendance(),
        _checkBirthday(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching initial data: $e')),
        );
      }
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await http.post(
        Uri.parse(api.profile),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': false, 'token': widget.token}),
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            studentName = data['profile']?['name'] ?? data['profileData']?['name'];
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => studentName = null);
    }
  }

  Future<void> _checkBirthday() async {
    try {
      final res = await http.post(
        Uri.parse(api.dob),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': false, 'token': widget.token}),
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final dob = data['dob']?[0]?['dob'];
        if (dob != null && dob.isNotEmpty) {
          final parsed = DateFormat('dd-MM-yyyy').parse(dob);
          final today = DateTime.now();
          if (parsed.day == today.day && parsed.month == today.month) {
            setState(() => isBirthday = true);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _confettiController.play();
            });
          }
        }
      }
    } catch (_) {
      if (mounted) setState(() => isBirthday = false);
    }
  }

  Future<void> _fetchSubjectWiseAttendanceAndSum() async {
    try {
      final res = await http.post(
        Uri.parse('${widget.url}/subjectWiseAttendance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': widget.token, 'refresh': false}),
      );

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final subjects = data['subjectWiseAttendance'] ?? data['subjectAttendance'];
        if (subjects != null && subjects is List) {
          int totalHrs = 0;
          int attendedHrs = 0;

          for (final subject in subjects) {
            final total = int.tryParse(subject['totalHrs']?.toString() ?? '0') ?? 0;
            final present = int.tryParse(subject['presentHrs']?.toString() ?? '0') ?? 0;
            totalHrs += total;
            attendedHrs += present;
          }

          double percent = totalHrs > 0 ? (attendedHrs / totalHrs) * 100 : 0;

          setState(() {
            totalClasses = totalHrs;
            attendedClasses = attendedHrs;
            attendancePercent = double.parse(percent.toStringAsFixed(2));
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => attendancePercent = 0);
    }
  }

  Future<void> _fetchCGPA() async {
    if (!mounted) return;
    setState(() => isCgpaLoading = true);
    try {
      final res = await http.post(
        Uri.parse(api.cgpa),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': false, 'token': widget.token}),
      );

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final cgpaList = data['cgpa'] ?? data['cgpaData'];
        if (cgpaList != null && cgpaList is List && cgpaList.isNotEmpty) {
          final fetchedCgpa = cgpaList[0]['cgpa'];
          if (fetchedCgpa != null && fetchedCgpa.toString().isNotEmpty) {
            setState(() => cgpa = fetchedCgpa.toString());
          } else {
            setState(() => cgpa = "N/A");
          }
        } else {
          setState(() => cgpa = "N/A");
        }
      }
    } catch (_) {
      if (mounted) setState(() => cgpa = "N/A");
    } finally {
      if (mounted) setState(() => isCgpaLoading = false);
    }
  }

  Future<void> _fetchFeeDue() async {
    try {
      final responses = await Future.wait([
        http.post(
          Uri.parse(api.sastraDue),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh': false, 'token': widget.token}),
        ),
        http.post(
          Uri.parse(api.hostelDue),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh': false, 'token': widget.token}),
        )
      ]);

      final sastraRes = responses[0];
      final hostelRes = responses[1];

      if (sastraRes.statusCode == 200 && hostelRes.statusCode == 200 && mounted) {
        final sastraData = jsonDecode(sastraRes.body);
        final hostelData = jsonDecode(hostelRes.body);

        int sastraDue = 0;
        int hostelDue = 0;

        int parseFee(String rawValue) {
          if (rawValue.toLowerCase().contains('no records found')) return 0;
          final cleanStr = rawValue.replaceAll(',', '').split('.')[0];
          return int.tryParse(cleanStr) ?? 0;
        }

        if (sastraData['success'] == true) {
          final rawSastraDue = (sastraData['sastraDue'] ?? sastraData['totalSastraDue'] ?? "0").toString();
          sastraDue = parseFee(rawSastraDue);
        }

        if (hostelData['success'] == true) {
          final rawHostelDue = (hostelData['hostelDue'] ?? hostelData['totalHostelDue'] ?? "0").toString();
          hostelDue = parseFee(rawHostelDue);
        }

        setState(() => feeDue = sastraDue + hostelDue);
      }
    } catch (_) {
      if (mounted) setState(() => feeDue = 0);
    }
  }

  Future<void> _fetchBunks() async {
    try {
      final response = await http.post(
        Uri.parse(api.bunk),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'regNo': widget.regNo}),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['skippableClasses'] != null) {
          final totalBunks = data['skippableClasses'] as int;
          setState(() => bunks = totalBunks);
        }
      }
    } catch (e) {
      if (mounted) setState(() => bunks = 0);
    }
  }

  Future<void> _fetchTimetable() async {
    if (!mounted) return;
    setState(() => isTimetableLoading = true);
    try {
      final res = await http.post(
        Uri.parse(api.timetable),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': false, 'token': widget.token}),
      );

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final fetchedTimetable = data['timetable'] ?? data['timeTable'];

        if (fetchedTimetable != null && fetchedTimetable is List && fetchedTimetable.isNotEmpty) {
          setState(() => timetableData = fetchedTimetable);
        } else {
          setState(() => timetableData = []);
        }
      } else {
        if (mounted) setState(() => timetableData = []);
      }
    } catch (e) {
      if (mounted) setState(() => timetableData = []);
    } finally {
      if (mounted) setState(() => isTimetableLoading = false);
    }
  }

  Future<void> _fetchHourWiseAttendance() async {
    if (!mounted) return;
    try {
      final res = await http.post(
        Uri.parse('${widget.url}/hourWiseAttendance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': true, 'token': widget.token}),
      );

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final fetchedAttendance = data['hourWiseAttendance'];

        if (fetchedAttendance != null && fetchedAttendance is List) {
          setState(() => hourWiseAttendanceData = fetchedAttendance);
        }
      }
    } catch (e) {
      if (mounted) setState(() => hourWiseAttendanceData = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfilePage(token: widget.token, url: widget.url)),
                  ),
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
                                const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '🎉 Happy Birthday! 🎉',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
                                  ),
                                )
                              else
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    studentName != null ? 'Welcome, $studentName!' : 'Welcome Back!',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Student Dashboard',
                                  style: TextStyle(color: theme.isDarkMode ? Colors.white70 : Colors.grey[600]),
                                ),
                              )
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
                    : GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SubjectWiseAttendancePage(regNo: widget.regNo,token: widget.token,url: widget.url)),
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
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isBirthday)
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 30,
                maxBlastForce: 25,
                minBlastForce: 8,
                gravity: 0.4,
                shouldLoop: false,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeeDueTile(ThemeProvider theme) {
    final hasDue = feeDue > 0;
    final isDark = theme.isDarkMode;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FeeDuePage()),
        );
      },
      child: SizedBox(
        width: 180,
        height: 150,
        child: NeonContainer(
          borderColor: hasDue
              ? Colors.red.shade400
              : (isDark ? AppTheme.neonBlue : AppTheme.primaryBlue),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet,
                  size: 40,
                  color: hasDue
                      ? Colors.red.shade400
                      : (isDark ? AppTheme.neonBlue : AppTheme.primaryBlue)),
              const SizedBox(height: 8),
              const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Fee Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  hasDue ? '₹$feeDue' : 'Paid',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ),
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
                Icon(Icons.assignment_turned_in,
                    size: 40,
                    color: isDark
                        ? AppTheme.neonBlue
                        : AppTheme.primaryBlue),
                const SizedBox(height: 10),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Assignments',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${assignments.length} Pending',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            )
                : Column(
              key: const ValueKey('gpa'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.grade,
                  size: 40,
                  color: isDark ? AppTheme.electricBlue : Colors.orange,
                ),
                const SizedBox(height: 10),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'CGPA',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                isCgpaLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$cgpa / 10',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white70
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}