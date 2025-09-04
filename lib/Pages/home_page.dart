import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../services/ApiEndpoints.dart';
import 'FeeDuePage.dart';
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
import 'more_options_page.dart';

class HomePage extends StatefulWidget {
  final String regNo;
  final String url; // Add this line
  const HomePage({super.key, required this.regNo, required this.url});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  late final ApiEndpoints api; // Add a field for the API class

  @override
  void initState() {
    super.initState();
    api = ApiEndpoints(widget.url); // Initialize the API class
    _pages = [
      DashboardScreen(regNo: widget.regNo, url: widget.url), // Pass url here
      CalendarPage(regNo: widget.regNo),
      const CommunityPage(),
      MessMenuPage(url: widget.url), // Pass url here
      const MoreOptionsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Correctly placed inside the build method
    final screenWidth = MediaQuery.of(context).size.width;
    final double appBarHeight = screenWidth * 0.2; // Adjusted height for a larger logo

    return Consumer<ThemeProvider>(
      builder: (_, theme, __) => Scaffold(
        backgroundColor: theme.isDarkMode
            ? AppTheme.darkBackground
            : Colors.white,
        appBar: AppBar(
          toolbarHeight: appBarHeight, // Set the AppBar's height dynamically
          automaticallyImplyLeading: false,
          leading: SizedBox(
            height: appBarHeight, // Use the same dynamic height here
            width: appBarHeight, // And here
            child: Image.asset('assets/icon/Logo.png'),
          ),
          title: const Text('SastraX',
              style: TextStyle(fontWeight: FontWeight.bold)),
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
  bool _birthdayChecked = false;
  late final ApiEndpoints api; // Add a field for the API class

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    api = ApiEndpoints(widget.url); // Initialize the API class
    _fetchAttendance();
    _fetchCGPA();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_birthdayChecked) {
      _checkBirthday();
      _birthdayChecked = true;
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _checkBirthday() async {
    try {
      final res = await http.get(
        // URL updated with widget.url
        Uri.parse('${api.baseUrl}/dob?regNo=${widget.regNo}'),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final dob = data['dobData']?[0]?['dob'];
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
    if (attendancePercent >= 0 && totalClasses > 0) return;

    try {
      final res = await http.post(
        // URL updated with widget.url
        Uri.parse(api.attendance),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': false, 'regNo': widget.regNo}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final raw = data['attendanceHTML'] ?? data['attendance'] ?? '0%';
        final percentMatch = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(raw);
        final pairMatch =
        RegExp(r'\(\s*(\d+)\s*/\s*(\d+)\s*\)').firstMatch(raw);

        setState(() {
          attendancePercent =
              double.tryParse(percentMatch?[1] ?? '0') ?? 0.0;
          attendedClasses = int.tryParse(pairMatch?[1] ?? '0') ?? 0;
          totalClasses = int.tryParse(pairMatch?[2] ?? '0') ?? 0;
        });
      } else {
        setState(() => attendancePercent = 0);
      }
    } catch (_) {
      setState(() => attendancePercent = 0);
    }
  }

  Future<void> _fetchCGPA() async {
    if (cgpa != null && cgpa != 'N/A') {
      setState(() => isCgpaLoading = false);
      return;
    }

    try {
      final res = await http.post(
        // URL updated with widget.url
        Uri.parse(api.cgpa),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': false}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final cgpaList = data['cgpaData'] ?? data['cgpa'];
        if (cgpaList != null && cgpaList.isNotEmpty) {
          setState(() {
            cgpa = cgpaList[0]['cgpa'];
            isCgpaLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() {
      cgpa = 'N/A';
      isCgpaLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final bunkLeft = totalClasses == 0
        ? 0
        : (attendancePercent / 100 * totalClasses - 0.75 * totalClasses)
        .floor()
        .clamp(0, totalClasses);

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
                        builder: (_) => ProfilePage(regNo: widget.regNo, url: widget.url)), // Pass url here
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
                                const Text(
                                  '🎉 Happy Birthday! 🎉',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                )
                              else
                                Text(
                                  'Welcome Back!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: theme.isDarkMode
                                        ? AppTheme.neonBlue
                                        : AppTheme.primaryBlue,
                                  ),
                                ),
                              Text('Student Dashboard',
                                  style: TextStyle(
                                      color: theme.isDarkMode
                                          ? Colors.white70
                                          : Colors.grey[600]))
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Attendance Chart
                NeonContainer(
                  borderColor: theme.isDarkMode
                      ? AppTheme.neonBlue
                      : AppTheme.primaryBlue,
                  padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: attendancePercent < 0
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
                      bunkingDaysLeft: bunkLeft,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Assignments and GPA/Fee Dues containers
                Row(
                  children: [
                    Expanded(
                      child: _buildAssignmentsTile(theme),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGpaFeeTile(theme),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Timetable
                NeonContainer(
                  borderColor: theme.isDarkMode
                      ? AppTheme.neonBlue
                      : AppTheme.primaryBlue,
                  padding: EdgeInsets.zero,
                  child: TimetableWidget(regNo: widget.regNo, url: widget.url),
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
                blastDirectionality:
                BlastDirectionality.explosive,
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
      height: 180, // Increased height for a larger, uniform container
      child: NeonContainer(
        borderColor: theme.isDarkMode
            ? AppTheme.neonBlue
            : AppTheme.primaryBlue,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in,
                size: 40, // Slightly larger icon
                color: theme.isDarkMode
                    ? AppTheme.neonBlue
                    : AppTheme.primaryBlue),
            const SizedBox(height: 10),
            const Text('Assignments',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('12 Pending',
                style: TextStyle(
                    fontSize: 14,
                    color: theme.isDarkMode
                        ? Colors.white70
                        : Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildGpaFeeTile(ThemeProvider theme) {
    return GestureDetector(
      onDoubleTap: () => setState(() => showFeeDue = !showFeeDue),
      onTap: () {
        // Navigate to FeeDuePage only if the container is showing the FeeDueCard
        if (showFeeDue) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FeeDuePage()),
          );
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: SizedBox(
          height: 180, // Use the same height as the Assignments container
          width: 180, // Use the same width as the Assignments container
          key: ValueKey(showFeeDue), // Important for AnimatedSwitcher to identify children
          child: showFeeDue
              ? FeeDueCard(
            key: ValueKey('fee'),
            feeDue: 12000, // Example fee, replace with a dynamic value if available
          )
              : NeonContainer(
            key: ValueKey('gpa'),
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
                  color: theme.isDarkMode ? AppTheme.electricBlue : Colors.orange,
                ),
                const SizedBox(height: 10),
                const Text(
                  'GPA',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                isCgpaLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(
                  '$cgpa / 10',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.isDarkMode ? Colors.white70 : Colors.grey[600],
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