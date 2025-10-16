import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/ApiEndpoints.dart';
import '../models/theme_model.dart';
import '../components/theme_toggle_button.dart';
import 'attendance_views/monthly_view.dart';
import 'attendance_views/subject_view.dart';
import 'attendance_views/analytics_view.dart';

class SubjectWiseAttendancePage extends StatefulWidget {
  final String regNo;
  final String token;
  final String url;
  final List<dynamic> initialSubjectAttendance;
  final List<dynamic> initialHourWiseAttendance;

  const SubjectWiseAttendancePage({
    Key? key,
    required this.regNo,
    required this.token,
    required this.url,
    required this.initialSubjectAttendance,
    required this.initialHourWiseAttendance,
  }) : super(key: key);

  @override
  State<SubjectWiseAttendancePage> createState() => _SubjectWiseAttendancePageState();
}

class _SubjectWiseAttendancePageState extends State<SubjectWiseAttendancePage> with TickerProviderStateMixin {
  late TabController _tabController;
  late final ApiEndpoints _api;

  bool _isLoading = false;
  String? _error;

  Map<DateTime, Map<String, String>> _attendanceData = {};
  Map<String, Map<String, dynamic>> _subjectAttendance = {};
  int _currentStreak = 0;

  static const Color primaryBlue = Color(0xFF1e3a8a);

  @override
  void initState() {
    super.initState();
    _api = ApiEndpoints(widget.url);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));

    _processData(
      subjectData: widget.initialSubjectAttendance,
      hourData: widget.initialHourWiseAttendance,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFromApi() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      await Future.wait([
        http.post(
          Uri.parse('${widget.url}/subjectWiseAttendance'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'token': widget.token, 'refresh': true}),
        ),
        http.post(
          Uri.parse('${widget.url}/hourWiseAttendance'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'token': widget.token, 'refresh': true}),
        ),
      ]);
      final docRef = FirebaseFirestore.instance.collection('studentDetails').doc(widget.regNo);
      final freshDoc = await docRef.get();
      if (freshDoc.exists && freshDoc.data() != null) {
        final data = freshDoc.data()!;
        _processData(
          subjectData: data['subjectWiseAttendance'] ?? [],
          hourData: data['hourWiseAttendance'] ?? [],
        );
      } else {
        throw Exception("Failed to find refreshed data.");
      }
    } catch (e) {
      if (mounted) setState(() => _error = "Failed to refresh: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ✅ THIS METHOD IS UPDATED TO CORRECTLY PARSE THE DATE
  void _processData({required List<dynamic> subjectData, required List<dynamic> hourData}) {
    final newSubjectAttendance = <String, Map<String, dynamic>>{};
    final codeToNameMap = <String, String>{};

    for (var item in subjectData) {
      final subjectName = item['subject'] as String? ?? 'Unknown';
      final courseCode = item['code'] as String? ?? '';
      if (subjectName != 'Unknown' && courseCode.isNotEmpty) {
        codeToNameMap[courseCode] = subjectName;
      }
      newSubjectAttendance[subjectName] = {
        'percentage': double.tryParse(item['percentage']?.toString() ?? '0.0') ?? 0.0,
        'totalClasses': int.tryParse(item['totalHrs']?.toString() ?? '0') ?? 0,
        'present': int.tryParse(item['presentHrs']?.toString() ?? '0') ?? 0,
        'absent': int.tryParse(item['absentHrs']?.toString() ?? '0') ?? 0,
        'od': 0,
      };
    }

    final newAttendanceData = <DateTime, Map<String, String>>{};
    final hourKeys = ['hour1', 'hour2', 'hour3', 'hour4', 'hour5', 'hour6', 'hour7', 'hour8'];

    for (var dayData in hourData) {
      try {
        final dateStringWithDay = dayData['dateDay'] as String?;
        if (dateStringWithDay == null) continue;

        // FIX: Split the string to isolate the date part before parsing.
        // "15-Oct-2025 Wednesday" becomes "15-Oct-2025"
        final dateString = dateStringWithDay.split(' ')[0];

        final date = DateFormat('dd-MMM-yyyy').parse(dateString);
        final dayKey = DateTime(date.year, date.month, date.day);

        final dailyAttendance = <String, String>{};
        for (var hourKey in hourKeys) {
          final statusData = dayData[hourKey] as String? ?? '';
          if (statusData.isEmpty) continue;

          final match = RegExp(r'([PA])\((.*?)\)').firstMatch(statusData);
          if (match != null) {
            final status = match.group(1) == 'P' ? 'present' : 'absent';
            final courseCode = match.group(2) ?? '';
            final subjectName = codeToNameMap[courseCode] ?? courseCode;
            dailyAttendance[subjectName] = status;
          }
          else if (statusData.toUpperCase() == 'P') {
            dailyAttendance['Class ${hourKey.substring(4)}'] = 'present';
          } else if (statusData.toUpperCase() == 'A') {
            dailyAttendance['Class ${hourKey.substring(4)}'] = 'absent';
          } else if (statusData.toUpperCase() == 'OD') {
            dailyAttendance['On-Duty'] = 'OD';
          }
        }
        if(dailyAttendance.isNotEmpty) newAttendanceData[dayKey] = dailyAttendance;
      } catch (e) {
        debugPrint("Error parsing data for entry: ${dayData['dateDay']} - $e");
      }
    }

    setState(() {
      _subjectAttendance = newSubjectAttendance;
      _attendanceData = newAttendanceData;
      _calculateCurrentStreak();
    });
  }

  bool _isDayPresentOrOd(DateTime day) {
    final dayKey = DateTime(day.year, day.month, day.day);
    if (!_attendanceData.containsKey(dayKey)) return false;
    return !_attendanceData[dayKey]!.values.any((status) => status == 'absent');
  }

  void _calculateCurrentStreak() {
    final sortedDates = _attendanceData.keys.toList()..sort((a, b) => b.compareTo(a));
    if (sortedDates.isEmpty) {
      setState(() => _currentStreak = 0);
      return;
    }
    final today = DateTime.now();
    final mostRecentAttendanceDay = sortedDates.first;
    int daysDifference = today.difference(mostRecentAttendanceDay).inDays;

    if (today.weekday == DateTime.monday && mostRecentAttendanceDay.weekday == DateTime.friday) {
      daysDifference = 1;
    }

    if (daysDifference > 1 && !_isDayPresentOrOd(mostRecentAttendanceDay)) {
      setState(() => _currentStreak = 0);
      return;
    }

    int streak = 0;
    DateTime? previousDate;
    for (final date in sortedDates) {
      if (_isDayPresentOrOd(date)) {
        if (previousDate == null) {
          streak = 1;
        } else {
          final difference = previousDate.difference(date).inDays;
          if (difference == 1) {
            streak++;
          } else if (previousDate.weekday == DateTime.monday && date.weekday == DateTime.friday && difference <= 3) {
            streak++;
          } else {
            break;
          }
        }
        previousDate = date;
      } else {
        break;
      }
    }
    setState(() => _currentStreak = streak);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('Attendance', style: TextStyle(color: Colors.white)),
        backgroundColor: isDark ? Colors.black12 : primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ThemeToggleButton(isDarkMode: isDark, onToggle: themeProvider.toggleTheme),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: ['Monthly View', 'Subject View', 'Analytics']
              .asMap()
              .entries
              .map((entry) => Tab(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _tabController.index == entry.key ? Colors.white.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                entry.value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _tabController.index == entry.key ? 16 : 14,
                  fontWeight: _tabController.index == entry.key ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ))
              .toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_error!)))
          : TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: _fetchFromApi,
            child: MonthlyView(
              attendanceData: _attendanceData,
              currentStreak: _currentStreak,
            ),
          ),
          RefreshIndicator(
            onRefresh: _fetchFromApi,
            child: SubjectView(
              subjectAttendance: _subjectAttendance,
            ),
          ),
          RefreshIndicator(
            onRefresh: _fetchFromApi,
            child: AnalyticsView(
              subjectAttendance: _subjectAttendance,
            ),
          ),
        ],
      ),
    );
  }
}