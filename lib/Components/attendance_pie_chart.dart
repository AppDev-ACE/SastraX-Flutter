import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/theme_model.dart';

class AttendancePieChart extends StatelessWidget {
  final double attendancePercentage;
  final int attendedClasses;
  final int totalClasses;
  final int bunkingDaysLeft;

  const AttendancePieChart({
    super.key,
    required this.attendancePercentage,
    required this.attendedClasses,
    required this.totalClasses,
    required int bunkingDaysLeft,
  }) : bunkingDaysLeft = bunkingDaysLeft < 0 ? 0 : bunkingDaysLeft;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark
                ? [
              BoxShadow(
                color: AppTheme.neonBlue.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ]
                : [
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Attendance',
                style: TextStyle(
                  fontSize: 18, // Slightly increased from 16
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.neonBlue : AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Left Column: Pie Chart
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(enabled: false),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 0,
                        centerSpaceRadius: 35,
                        sections: [
                          PieChartSectionData(
                            color: attendancePercentage < 80
                                ? Colors.red
                                : (isDark ? AppTheme.neonBlue : Colors.green),
                            value: attendancePercentage,
                            title: '${attendancePercentage.toInt()}%',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                            value: 100 - attendancePercentage,
                            title: '',
                            radius: 45,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right Column: Attended, Total, Can Skip stats
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStat(
                        'Attended',
                        '$attendedClasses',
                        isDark ? AppTheme.neonBlue : AppTheme.primaryBlue,
                        isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildStat(
                        'Total',
                        '$totalClasses',
                        isDark ? Colors.white : Colors.black,
                        isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildStat(
                        'Can Skip',
                        '$bunkingDaysLeft',
                        isDark ? AppTheme.electricBlue : Colors.orange,
                        isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildStat(String label, String value, Color valueColor, bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: dark ? Colors.white70 : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}