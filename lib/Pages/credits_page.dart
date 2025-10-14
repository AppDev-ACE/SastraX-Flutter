import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/theme_model.dart';
import '../services/ApiEndpoints.dart'; // Make sure this path is correct

class CreditsScreen extends StatefulWidget {
  final String url;
  final String token;
  const CreditsScreen({super.key, required this.url, required this.token});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen>
    with TickerProviderStateMixin {
  int _selectedSemester = 0; // 0 for overall
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  // State variables for fetched data
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _semesterData = [];
  int _currentSemester = 0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fetchAndProcessGrades();
  }

  // --- DATA FETCHING AND PROCESSING ---
  Future<void> _fetchAndProcessGrades() async {
    try {
      final api = ApiEndpoints(widget.url);
      final response = await http.post(
        Uri.parse(api.semGrades), // Make sure api.semGrades is correct
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': widget.token, 'refresh': false}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawGrades = data['semGrades'] ?? data['gradeData'];

        if (rawGrades != null && rawGrades is List && rawGrades.isNotEmpty) {
          _processBackendData(rawGrades);
        } else {
          setState(() => _error = "No grade data found.");
        }
      } else {
        setState(() => _error = "Failed to load grades. Status: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "An error occurred: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processBackendData(List<dynamic> rawGrades) {
    final Map<int, List<Map<String, dynamic>>> groupedBySem = {};
    for (var grade in rawGrades) {
      final int sem = int.tryParse(grade['sem']?.toString() ?? '0') ?? 0;
      if (sem > 0) {
        if (!groupedBySem.containsKey(sem)) {
          groupedBySem[sem] = [];
        }
        groupedBySem[sem]!.add({
          'name': grade['subject'] ?? 'Unknown',
          'credits': int.tryParse(grade['credit']?.toString() ?? '0') ?? 0,
          'grade': grade['grade'] ?? 'N/A',
        });
      }
    }

    if (groupedBySem.isEmpty) {
      setState(() => _error = "Could not parse any semester data.");
      return;
    }

    final int maxSemester = groupedBySem.keys.reduce(math.max);
    final List<Map<String, dynamic>> processedData = [];

    for (var i = 1; i <= maxSemester; i++) {
      final subjects = groupedBySem[i] ?? [];
      if (subjects.isEmpty) continue;

      double totalGradePoints = 0;
      int totalCredits = 0;
      int earnedCredits = 0;

      for (var subject in subjects) {
        final int credits = subject['credits'];
        final String grade = subject['grade'];

        totalCredits += credits;
        totalGradePoints += (_getGradePoint(grade) * credits);

        if (_isGradePassed(grade)) {
          earnedCredits += credits;
        }
      }

      final double sgpa = totalCredits > 0 ? totalGradePoints / totalCredits : 0.0;

      processedData.add({
        'semester': i,
        'totalCredits': totalCredits,
        'earnedCredits': earnedCredits,
        'gpa': sgpa,
        'subjects': subjects,
      });
    }

    setState(() {
      _semesterData = processedData;
      _currentSemester = maxSemester;
    });
  }

  // ✅ CORRECTED GRADE POINT LOGIC
  double _getGradePoint(String grade) {
    switch (grade.toUpperCase()) {
      case 'S': return 10.0;
      case 'A+': return 9.0;
      case 'A': return 8.0;
      case 'B': return 7.0;
      case 'C': return 6.0;
      case 'D': return 5.0;
      case 'F': return 2.0; // F is 2 points for calculation
      default: return 0.0; // RA, W, U, Absent etc. are 0
    }
  }

  bool _isGradePassed(String grade) {
    // Only F, U, W, RA, Absent are considered fail/incomplete
    final failedGrades = ['F', 'U', 'RA', 'ABSENT', 'W'];
    return !failedGrades.contains(grade.toUpperCase());
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  double get _totalCredits {
    if (_semesterData.isEmpty) return 0.0;
    return _semesterData.fold(0.0, (sum, sem) => sum + sem['earnedCredits']);
  }

  double get _overallGPA {
    if (_semesterData.isEmpty) return 0.0;
    double totalGradePoints = 0;
    int totalCreditsAttempted = 0;
    for (var sem in _semesterData) {
      for (var sub in sem['subjects']) {
        final int credits = sub['credits'];
        totalCreditsAttempted += credits;
        totalGradePoints += (_getGradePoint(sub['grade']) * credits);
      }
    }
    return totalCreditsAttempted > 0 ? totalGradePoints / totalCreditsAttempted : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    const double baseWidth = 375.0;
    final double scaleFactor = screenWidth / baseWidth;

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        title: Text(
          'Academic Credits',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22 * scaleFactor.clamp(0.9, 1.2),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(_error!, textAlign: TextAlign.center),
      ))
          : Padding(
        padding: EdgeInsets.all(16 * scaleFactor),
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: _buildCreditsCircleLayout(),
            ),
            Expanded(
              child: _buildDetailsSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditsCircleLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final centerRadius = size * 0.15;
        final smallRadius = size * 0.1;
        final orbitRadius = size * 0.38;

        return AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            return SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: orbitRadius * 2,
                    height: orbitRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryPurple.withOpacity(0.1),
                        width: 2,
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                  ...List.generate(8, (index) {
                    final angle = (index * 2 * math.pi / 8) +
                        (_rotationController.value * 2 * math.pi * 0.1);
                    final x = orbitRadius * math.cos(angle);
                    final y = orbitRadius * math.sin(angle);
                    final semesterNumber = index + 1;

                    return Transform.translate(
                      offset: Offset(x, y),
                      child: semesterNumber > _currentSemester
                          ? _buildFutureSemesterCircle(semesterNumber, smallRadius)
                          : _buildSemesterCircle(semesterNumber, smallRadius),
                    );
                  }),
                  _buildCenterCircle(centerRadius),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCenterCircle(double radius) {
    final isSelected = _selectedSemester == 0;
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => setState(() => _selectedSemester = 0),
          child: Transform.scale(
            scale: isSelected ? 1.0 + (_pulseController.value * 0.1) : 1.0,
            child: Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? AppTheme.primaryGradient
                    : LinearGradient(
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.7),
                    AppTheme.accentAqua.withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                    blurRadius: isSelected ? 20 : 10,
                    spreadRadius: isSelected ? 5 : 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_totalCredits.toInt()}',
                    style: TextStyle(
                      fontSize: radius * 0.4,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: radius * 0.05),
                  Text(
                    'CGPA: ${_overallGPA.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: radius * 0.25,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).animate().scale(delay: 1000.ms, curve: Curves.elasticOut);
  }

  Widget _buildSemesterCircle(int semester, double radius) {
    final semesterData = _semesterData.firstWhere((s) => s['semester'] == semester);
    final isSelected = _selectedSemester == semester;
    final colors = [
      Colors.red, Colors.orange, Colors.yellow.shade700,
      Colors.green, Colors.blue, Colors.indigo,
      Colors.purple, Colors.pink,
    ];
    final color = colors[semester - 1];

    return GestureDetector(
      onTap: () => setState(() => _selectedSemester = semester),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? color : color.withOpacity(0.7),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: isSelected ? 15 : 8,
              spreadRadius: isSelected ? 3 : 1,
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'S$semester',
                style: TextStyle(
                  fontSize: radius * 0.6,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${semesterData['earnedCredits']}',
                style: TextStyle(
                  fontSize: radius * 0.5,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(delay: (semester * 100).ms, curve: Curves.elasticOut);
  }

  Widget _buildFutureSemesterCircle(int semester, double radius) {
    return GestureDetector(
      onTap: () => setState(() => _selectedSemester = semester),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _selectedSemester == semester ? Colors.grey[700] : Colors.grey[800],
          border: Border.all(color: Colors.grey[600]!, width: 1),
        ),
        child: Center(
          child: Text(
            'S$semester',
            style: TextStyle(
              fontSize: radius * 0.6,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.3),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _selectedSemester == 0
          ? _buildOverallDetails()
          : _selectedSemester > _currentSemester
          ? _buildFutureSemesterDetails()
          : _buildSemesterDetails(_selectedSemester),
    );
  }

  Widget _buildFutureSemesterDetails() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Container(
      key: ValueKey('futureDetails$_selectedSemester'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: themeProvider.isDarkMode
            ? Border.all(color: Colors.grey.withOpacity(0.3))
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty_rounded, size: 40, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Semester $_selectedSemester',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Data for this upcoming semester is not yet available.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallDetails() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      key: const ValueKey('overallDetails'),
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: themeProvider.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: themeProvider.isDarkMode ? null : AppTheme.cardShadow,
        border: themeProvider.isDarkMode
            ? Border.all(color: AppTheme.primaryPurple.withOpacity(0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics,
                color: AppTheme.primaryPurple,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Overall Performance',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                    'Total Credits', '${_totalCredits.toInt()}', AppTheme.successGreen),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: _buildStatCard('Overall CGPA',
                    _overallGPA.toStringAsFixed(4), AppTheme.accentAqua),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: _buildStatCard(
                    'Semesters', '${_semesterData.length}', AppTheme.primaryPurple),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterDetails(int semester) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final semesterData = _semesterData.firstWhere((s) => s['semester'] == semester);
    final subjects = semesterData['subjects'] as List<Map<String, dynamic>>;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      key: ValueKey('semesterDetails$semester'),
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: themeProvider.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: themeProvider.isDarkMode ? null : AppTheme.cardShadow,
        border: themeProvider.isDarkMode
            ? Border.all(color: AppTheme.primaryPurple.withOpacity(0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'SEM $semester',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Semester $semester Details',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                    'Credits',
                    '${semesterData['earnedCredits']}/${semesterData['totalCredits']}',
                    AppTheme.successGreen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                    'SGPA', '${(semesterData['gpa'] as double).toStringAsFixed(4)}', AppTheme.accentAqua),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                    'Subjects', '${subjects.length}', AppTheme.primaryPurple),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Expanded(
            child: ListView.builder(
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? AppTheme.darkSurface.withOpacity(0.7)
                        : AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _getGradeColor(subject['grade']).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject['name'],
                              style: TextStyle(
                                fontSize: screenWidth * 0.032,
                                fontWeight: FontWeight.w600,
                                color: themeProvider.textColor,
                              ),
                            ),
                            Text(
                              'Credits: ${subject['credits']}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.028,
                                color: themeProvider.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getGradeColor(subject['grade'])
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          subject['grade'],
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            fontWeight: FontWeight.bold,
                            color: _getGradeColor(subject['grade']),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().slideX(delay: (index * 50).ms, begin: 0.3, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: screenWidth * 0.01),
          Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.025,
              color: themeProvider.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'S':
        return AppTheme.successGreen;
      case 'A+':
      case 'A':
        return AppTheme.primaryBlue;
      case 'B':
        return AppTheme.accentAqua;
      case 'C':
      case 'D':
        return AppTheme.warningOrange;
      default:
        return AppTheme.errorRed;
    }
  }
}