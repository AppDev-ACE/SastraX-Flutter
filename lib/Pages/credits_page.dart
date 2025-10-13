import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/theme_model.dart'; // Using your final theme model

class CreditsScreen extends StatefulWidget {
  final String url ;
  final String token ;
  const CreditsScreen({super.key , required this.url , required this.token});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen>
    with TickerProviderStateMixin {
  int _selectedSemester = 0; // 0 means center circle (overall)
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  // Sample data for 8 semesters
  final List<Map<String, dynamic>> _semesterData = [
    {
      'semester': 1,
      'totalCredits': 24,
      'earnedCredits': 22,
      'gpa': 8.5,
      'subjects': [
        {'name': 'Constitutional Law I', 'credits': 4, 'grade': 'A', 'score': 85},
        {'name': 'Legal Methods', 'credits': 3, 'grade': 'A+', 'score': 92},
        {'name': 'Political Science', 'credits': 3, 'grade': 'B+', 'score': 78},
        {'name': 'Economics I', 'credits': 3, 'grade': 'A', 'score': 88},
        {'name': 'English I', 'credits': 2, 'grade': 'A+', 'score': 94},
        {'name': 'History I', 'credits': 3, 'grade': 'B+', 'score': 76},
        {'name': 'Sociology', 'credits': 3, 'grade': 'A', 'score': 82},
        {'name': 'Environmental Studies', 'credits': 3, 'grade': 'A', 'score': 86},
      ],
    },
    {
      'semester': 2,
      'totalCredits': 24,
      'earnedCredits': 24,
      'gpa': 8.8,
      'subjects': [
        {'name': 'Constitutional Law II', 'credits': 4, 'grade': 'A+', 'score': 91},
        {'name': 'Contract Law I', 'credits': 4, 'grade': 'A', 'score': 87},
        {'name': 'Tort Law', 'credits': 3, 'grade': 'A+', 'score': 93},
        {'name': 'Economics II', 'credits': 3, 'grade': 'A', 'score': 85},
        {'name': 'English II', 'credits': 2, 'grade': 'A+', 'score': 96},
        {'name': 'History II', 'credits': 3, 'grade': 'A', 'score': 84},
        {'name': 'Psychology', 'credits': 3, 'grade': 'A', 'score': 89},
        {'name': 'Computer Applications', 'credits': 2, 'grade': 'A+', 'score': 95},
      ],
    },
    // ... other semester data
    {
      'semester': 3,
      'totalCredits': 26,
      'earnedCredits': 25,
      'gpa': 8.2,
      'subjects': [
        {'name': 'Criminal Law I', 'credits': 4, 'grade': 'A', 'score': 88},
        {'name': 'Contract Law II', 'credits': 4, 'grade': 'B+', 'score': 79},
        {'name': 'Property Law I', 'credits': 4, 'grade': 'A', 'score': 86},
        {'name': 'Family Law I', 'credits': 3, 'grade': 'A+', 'score': 92},
        {'name': 'Jurisprudence', 'credits': 3, 'grade': 'A', 'score': 84},
        {'name': 'Legal Writing', 'credits': 2, 'grade': 'A+', 'score': 94},
        {'name': 'Moot Court I', 'credits': 3, 'grade': 'A', 'score': 87},
        {'name': 'Public Administration', 'credits': 3, 'grade': 'B+', 'score': 77},
      ],
    },
    {
      'semester': 4,
      'totalCredits': 26,
      'earnedCredits': 26,
      'gpa': 8.6,
      'subjects': [
        {'name': 'Criminal Law II', 'credits': 4, 'grade': 'A+', 'score': 90},
        {'name': 'Property Law II', 'credits': 4, 'grade': 'A', 'score': 85},
        {'name': 'Family Law II', 'credits': 3, 'grade': 'A', 'score': 88},
        {'name': 'Administrative Law', 'credits': 4, 'grade': 'A+', 'score': 93},
        {'name': 'Company Law I', 'credits': 3, 'grade': 'A', 'score': 86},
        {'name': 'Evidence Law', 'credits': 3, 'grade': 'A', 'score': 89},
        {'name': 'Moot Court II', 'credits': 3, 'grade': 'A+', 'score': 91},
        {'name': 'International Relations', 'credits': 2, 'grade': 'A', 'score': 84},
      ],
    },
    {
      'semester': 5,
      'totalCredits': 28,
      'earnedCredits': 27,
      'gpa': 8.4,
      'subjects': [
        {'name': 'Civil Procedure Code', 'credits': 4, 'grade': 'A', 'score': 87},
        {'name': 'Criminal Procedure Code', 'credits': 4, 'grade': 'A+', 'score': 92},
        {'name': 'Company Law II', 'credits': 4, 'grade': 'A', 'score': 85},
        {'name': 'Labour Law I', 'credits': 3, 'grade': 'A', 'score': 88},
        {'name': 'Intellectual Property Law', 'credits': 3, 'grade': 'A+', 'score': 94},
        {'name': 'Environmental Law', 'credits': 3, 'grade': 'B+', 'score': 78},
        {'name': 'Legal Aid & Paralegal Services', 'credits': 3, 'grade': 'A', 'score': 86},
        {'name': 'Human Rights Law', 'credits': 4, 'grade': 'A', 'score': 89},
      ],
    },
    {
      'semester': 6,
      'totalCredits': 28,
      'earnedCredits': 28,
      'gpa': 8.7,
      'subjects': [
        {'name': 'Labour Law II', 'credits': 4, 'grade': 'A+', 'score': 91},
        {'name': 'Taxation Law', 'credits': 4, 'grade': 'A', 'score': 87},
        {'name': 'Banking Law', 'credits': 3, 'grade': 'A', 'score': 85},
        {'name': 'Insurance Law', 'credits': 3, 'grade': 'A+', 'score': 93},
        {'name': 'Consumer Protection Law', 'credits': 3, 'grade': 'A', 'score': 88},
        {'name': 'Cyber Law', 'credits': 3, 'grade': 'A+', 'score': 95},
        {'name': 'Professional Ethics', 'credits': 2, 'grade': 'A', 'score': 86},
        {'name': 'Internship I', 'credits': 6, 'grade': 'A', 'score': 89},
      ],
    },
    {
      'semester': 7,
      'totalCredits': 30,
      'earnedCredits': 28,
      'gpa': 8.3,
      'subjects': [
        {'name': 'International Law', 'credits': 4, 'grade': 'A', 'score': 86},
        {'name': 'Arbitration & Conciliation', 'credits': 3, 'grade': 'A+', 'score': 92},
        {'name': 'Corporate Governance', 'credits': 3, 'grade': 'A', 'score': 84},
        {'name': 'Securities Law', 'credits': 3, 'grade': 'B+', 'score': 79},
        {'name': 'Competition Law', 'credits': 3, 'grade': 'A', 'score': 87},
        {'name': 'Media Law', 'credits': 3, 'grade': 'A+', 'score': 94},
        {'name': 'Clinical Legal Education', 'credits': 4, 'grade': 'A', 'score': 88},
        {'name': 'Dissertation I', 'credits': 7, 'grade': 'A', 'score': 85},
      ],
    },
    {
      'semester': 8,
      'totalCredits': 30,
      'earnedCredits': 30,
      'gpa': 8.9,
      'subjects': [
        {'name': 'Comparative Law', 'credits': 3, 'grade': 'A+', 'score': 93},
        {'name': 'Legal Research Methodology', 'credits': 3, 'grade': 'A', 'score': 87},
        {'name': 'Alternative Dispute Resolution', 'credits': 3, 'grade': 'A+', 'score': 91},
        {'name': 'Space Law', 'credits': 3, 'grade': 'A', 'score': 85},
        {'name': 'Maritime Law', 'credits': 3, 'grade': 'A', 'score': 88},
        {'name': 'Sports Law', 'credits': 3, 'grade': 'A+', 'score': 95},
        {'name': 'Internship II', 'credits': 6, 'grade': 'A+', 'score': 92},
        {'name': 'Dissertation II', 'credits': 6, 'grade': 'A', 'score': 89},
      ],
    },
  ];

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
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  double get _totalCredits {
    return _semesterData.fold(0.0, (sum, sem) => sum + sem['earnedCredits']);
  }

  double get _overallGPA {
    double totalGPA = _semesterData.fold(0.0, (sum, sem) => sum + sem['gpa']);
    return totalGPA / _semesterData.length;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    const double baseWidth = 375.0;
    final double scaleFactor = screenWidth / baseWidth;

    // KEY CHANGE: Define the original gradient locally to ensure it's always used.
    const originalHeaderGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF6A1B9A), // The original darker purple
        Color(0xFF00ACC1), // The original aqua
      ],
    );


    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        // The AppBar is solid blue to match the HomePage
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        title: Text(
          'Credits',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22 * scaleFactor.clamp(0.9, 1.2),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // This container now uses the locally defined "original" gradient
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20 * scaleFactor),
            decoration: const BoxDecoration(
              gradient: originalHeaderGradient, // Using the restored gradient
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.school,
                  size: 50 * scaleFactor,
                  color: Colors.white,
                ).animate().scale(delay: 200.ms, curve: Curves.elasticOut),
                SizedBox(height: 15 * scaleFactor),
                Text(
                  'Academic Credits',
                  style: TextStyle(
                    fontSize: (28 * scaleFactor).clamp(24.0, 32.0),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate().slideY(delay: 400.ms, begin: -0.3, end: 0),
                SizedBox(height: 8 * scaleFactor),
                Text(
                  'Track your semester-wise progress',
                  style: TextStyle(
                    fontSize: (16 * scaleFactor).clamp(14.0, 18.0),
                    color: Colors.white.withOpacity(0.9),
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),
          // Main Credits Circle Layout
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20 * scaleFactor),
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildCreditsCircleLayout(),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildDetailsSection(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsCircleLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final centerRadius = size * 0.15;
        final smallRadius = size * 0.08;
        final orbitRadius = size * 0.3;

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
                    final angle = (index * 2 * math.pi / 8) + (_rotationController.value * 2 * math.pi * 0.1);
                    final x = orbitRadius * math.cos(angle);
                    final y = orbitRadius * math.sin(angle);

                    return Transform.translate(
                      offset: Offset(x, y),
                      child: _buildSemesterCircle(index + 1, smallRadius),
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
                      fontSize: radius * 0.3,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: radius * 0.05),
                  Text(
                    'CGPA: ${_overallGPA.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: radius * 0.3,
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
    final semesterData = _semesterData[semester - 1];
    final isSelected = _selectedSemester == semester;
    final colors = [
      Colors.red, Colors.orange, Colors.yellow.shade700, Colors.green,
      Colors.blue, Colors.indigo, Colors.purple, Colors.pink,
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
          : _buildSemesterDetails(_selectedSemester),
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
                child: _buildStatCard('Total Credits', '${_totalCredits.toInt()}', AppTheme.successGreen),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: _buildStatCard('Overall CGPA', _overallGPA.toStringAsFixed(2), AppTheme.accentAqua),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: _buildStatCard('Semesters', '${_semesterData.length}', AppTheme.primaryPurple),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterDetails(int semester) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final semesterData = _semesterData[semester - 1];
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
                child: _buildStatCard('Credits', '${semesterData['earnedCredits']}/${semesterData['totalCredits']}', AppTheme.successGreen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard('GPA', '${semesterData['gpa']}', AppTheme.accentAqua),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard('Subjects', '${subjects.length}', AppTheme.primaryPurple),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getGradeColor(subject['grade']).withOpacity(0.1),
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
                      const SizedBox(width: 8),
                      Text(
                        '${subject['score']}%',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeight.bold,
                          color: _getGradeColor(subject['grade']),
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
    switch (grade) {
      case 'A+':
        return AppTheme.successGreen;
      case 'A':
        return AppTheme.primaryBlue;
      case 'B+':
        return AppTheme.warningOrange;
      case 'B':
        return Colors.orange;
      default:
        return AppTheme.errorRed;
    }
  }
}