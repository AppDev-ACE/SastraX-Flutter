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
import '../Components/timetable_widget.dart';
import '../models/theme_model.dart';
import '../components/theme_toggle_button.dart';
import '../components/neon_container.dart';
import '../components/attendance_pie_chart.dart';
import '../components/fee_due_card.dart';
import 'profile_page.dart';
import 'calendar_page.dart';
import 'community_page.dart';
import 'mess_menu_page.dart';

class HomePage extends StatefulWidget {
  final String regNo;
  final String url;
  const HomePage({super.key, required this.regNo, required this.url});

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
      DashboardScreen(regNo: widget.regNo, url: widget.url),
      CalendarPage(regNo: widget.regNo),
      const CommunityPage(),
      MessMenuPage(url: widget.url),
      const MoreOptionsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double appBarHeight = screenWidth * 0.2;

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
          backgroundColor:
          theme.isDarkMode ? AppTheme.darkBackground : AppTheme.primaryBlue,
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
          backgroundColor:
          theme.isDarkMode ? AppTheme.darkSurface : Colors.white,
          selectedItemColor:
          theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today), label: 'Calendar'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Mess'),
            BottomNavigationBarItem(
                icon: Icon(Icons.more_horiz_outlined), label: 'More'),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final String regNo;
  final String url;
  const DashboardScreen({super.key, required this.regNo, required this.url});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool showFeeDue = false;
  double attendancePercent = -1;
  int attendedClasses = 0;
  int totalClasses = 0;
  String? cgpa;
  bool isCgpaLoading = true;
  bool isBirthday = false;
  String? studentName;
  int feeDue = 0; // tuition + hostel combined
  int bunks = 0; // total bunk hours
  List assignments = [];
  bool isTimetableLoading = true;
  List timetableData = [];

  late final ApiEndpoints api;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    api = ApiEndpoints(widget.url);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    // Refactored to fetch data sequentially
    _fetchDashboardDataSequentially();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardDataSequentially() async {
    // Fetch Profile first, as it's the most common entry point.
    await _fetchProfile();

    // Add a short delay to give the backend time to stabilize its session.
    await Future.delayed(const Duration(seconds: 1));

    // Fetch Attendance.
    await _fetchAttendance();

    // Add another short delay.
    await Future.delayed(const Duration(seconds: 1));

    // Fetch CGPA.
    await _fetchCGPA();

    // Add another short delay.
    await Future.delayed(const Duration(seconds: 1));

    // Fetch Fee Due (which includes two sub-calls).
    await _fetchFeeDue();

    // Add another short delay.
    await Future.delayed(const Duration(seconds: 1));

    // Fetch Bunks.
    await _fetchBunks();

    // Add another short delay.
    await Future.delayed(const Duration(seconds: 1));

    // Fetch Timetable.
    await _fetchTimetable();

    // Check birthday last, as it does not rely on the Puppeteer session.
    await _checkBirthday();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await http.post(
        Uri.parse(api.profile),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': false, 'regNo': widget.regNo}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            studentName = data['profile']?['name'] ?? data['profileData']?['name'];
          });
        }
      }
    } catch (_) {
      setState(() => studentName = null);
    }
  }

  Future<void> _checkBirthday() async {
    try {
      final res = await http.post(
        Uri.parse(api.dob),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': false, 'regNo': widget.regNo}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final dob = data['dob']?[0]?['dob'];
        if (dob != null && dob.isNotEmpty) {
          final parsed = DateFormat('dd-MM-yyyy').parse(dob);
          final today = DateTime.now();
          if (parsed.day == today.day && parsed.month == today.month) {
            setState(() => isBirthday = true);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _confettiController.play();
            });
          }
        }
      } else {
        setState(() => isBirthday = false);
      }
    } catch (_) {
      setState(() => isBirthday = false);
    }
  }

  Future<void> _fetchAttendance() async {
    try {
      final res = await http.post(
        Uri.parse(api.attendance),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': false, 'regNo': widget.regNo}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final raw = data['attendance'] ?? "0%";
        final percentMatch = RegExp(r'(\d+(?:\.\d+)?)%').firstMatch(raw);
        final pairMatch = RegExp(r'\((\d+)/(\d+)\)').firstMatch(raw);

        setState(() {
          attendancePercent = double.tryParse(percentMatch?[1] ?? '0') ?? 0;
          attendedClasses = int.tryParse(pairMatch?[1] ?? '0') ?? 0;
          totalClasses = int.tryParse(pairMatch?[2] ?? '0') ?? 0;
        });
      }
    } catch (_) {
      setState(() {
        attendancePercent = 0;
        attendedClasses = 0;
        totalClasses = 0;
      });
    }
  }

  Future<void> _fetchCGPA() async {
    try {
      final res = await http.post(
        Uri.parse(api.cgpa),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': false, 'regNo': widget.regNo}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final cgpaList = data['cgpa'] ?? data['cgpaData'];
        if (cgpaList != null && cgpaList.isNotEmpty) {
          setState(() {
            cgpa = cgpaList[0]['cgpa'] ?? "N/A";
            isCgpaLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() {
      cgpa = "N/A";
      isCgpaLoading = false;
    });
  }

  Future<void> _fetchFeeDue() async {
    try {
      // Fetch Sastra due first, then hostel due.
      final sastraRes = await http.post(
        Uri.parse(api.sastraDue),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': false, 'regNo': widget.regNo}),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      final hostelRes = await http.post(
        Uri.parse(api.hostelDue),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': false, 'regNo': widget.regNo}),
      );

      if (sastraRes.statusCode == 200 && hostelRes.statusCode == 200) {
        final sastraData = jsonDecode(sastraRes.body);
        final hostelData = jsonDecode(hostelRes.body);

        if (sastraData['success'] == true && hostelData['success'] == true) {
          final sastraDueStr = (sastraData['sastraDue'] ?? sastraData['totalSastraDue'] ?? "0")
              .toString()
              .replaceAll(RegExp(r'[^0-9]'), '');
          final hostelDueStr = (hostelData['hostelDue'] ?? hostelData['totalHostelDue'] ?? "0")
              .toString()
              .replaceAll(RegExp(r'[^0-9]'), '');

          final sastraDue = int.tryParse(sastraDueStr) ?? 0;
          final hostelDue = int.tryParse(hostelDueStr) ?? 0;

          setState(() {
            feeDue = sastraDue + hostelDue;
          });
        }
      }
    } catch (_) {
      setState(() => feeDue = 0);
    }
  }

  Future<void> _fetchBunks() async {
    try {
      final res = await http.get(
        Uri.parse(api.bunk),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final bunkData = data['bunkdata'];
          final total = (bunkData as Map).values.fold<int>(
            0,
                (sum, val) => sum + (val as int),
          );

          setState(() {
            bunks = total;
          });
        }
      }
    } catch (_) {
      setState(() => bunks = 0);
    }
  }

  Future<void> _fetchTimetable() async {
    setState(() {
      isTimetableLoading = true;
    });
    try {
      final res = await http.post(
        Uri.parse(api.timetable),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': false, 'regNo': widget.regNo}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            timetableData = data['timetable'];
          });
        }
      }
    } catch (_) {
      // Handle error if necessary
    } finally {
      setState(() {
        isTimetableLoading = false;
      });
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
                // Profile Section
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProfilePage(regNo: widget.regNo, url: widget.url),
                    ),
                  ),
                  child: NeonContainer(
                    borderColor: theme.isDarkMode
                        ? AppTheme.neonBlue
                        : AppTheme.primaryBlue,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: theme.isDarkMode
                              ? AppTheme.neonBlue
                              : AppTheme.primaryBlue,
                          child: Icon(Icons.person,
                              color: theme.isDarkMode
                                  ? Colors.black
                                  : Colors.white),
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
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                )
                              else
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    studentName != null
                                        ? 'Welcome, $studentName!'
                                        : 'Welcome Back!',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: theme.isDarkMode
                                          ? AppTheme.neonBlue
                                          : AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Student Dashboard',
                                    style: TextStyle(
                                        color: theme.isDarkMode
                                            ? Colors.white70
                                            : Colors.grey[600])),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Attendance Chart
                attendancePercent < 0
                    ? const Center(child: CircularProgressIndicator())
                    : GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SubjectWiseAttendancePage()),
                  ),
                  child: AttendancePieChart(
                    attendancePercentage: attendancePercent,
                    attendedClasses: attendedClasses,
                    totalClasses: totalClasses,
                    bunkingDaysLeft: bunks,
                  ),
                ),
                const SizedBox(height: 16),
                // Assignments and GPA/Fee Dues containers
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildAssignmentsTile(theme)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildGpaFeeTile(theme)),
                  ],
                ),
                const SizedBox(height: 16),
                // Timetable
                TimetableWidget(timetable: timetableData, isLoading: isTimetableLoading),
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

  Widget _buildAssignmentsTile(ThemeProvider theme) {
    return SizedBox(
      width: 180,
      height: 150,
      child: NeonContainer(
        borderColor:
        theme.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in,
                size: 40,
                color: theme.isDarkMode
                    ? AppTheme.neonBlue
                    : AppTheme.primaryBlue),
            const SizedBox(height: 10),
            const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Assignments',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${assignments.length} Pending',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpaFeeTile(ThemeProvider theme) {
    return GestureDetector(
      onDoubleTap: () => setState(() => showFeeDue = !showFeeDue),
      onTap: () {
        if (showFeeDue) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FeeDuePage()),
          );
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: showFeeDue
            ? SizedBox(
          width: 180,
          height: 150,
          child: FeeDueCard(
            key: const ValueKey('fee'),
            feeDue: feeDue.toDouble(),
          ),
        )
            : SizedBox(
          width: 180,
          height: 150,
          child: NeonContainer(
            key: const ValueKey('gpa'),
            borderColor: theme.isDarkMode
                ? AppTheme.neonBlue
                : AppTheme.primaryBlue,
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.grade,
                  size: 40,
                  color: theme.isDarkMode
                      ? AppTheme.electricBlue
                      : Colors.orange,
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
                      color: theme.isDarkMode
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
