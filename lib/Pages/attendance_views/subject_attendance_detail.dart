import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../models/theme_model.dart';
import 'dart:math';

class SubjectAttendanceDetail extends StatelessWidget {
  final String subjectName;
  final double attendancePercentage;

  const SubjectAttendanceDetail({
    Key? key,
    required this.subjectName,
    required this.attendancePercentage,
  }) : super(key: key);

  static const Color primaryBlue = Color(0xFF1e3a8a);

  bool _isDarkMode(BuildContext context) => Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
  Color _getBackgroundColor(BuildContext context) => _isDarkMode(context) ? const Color(0xFF121212) : Colors.white;
  Color _getCardColor(BuildContext context) => _isDarkMode(context) ? const Color(0xFF1E1E1E) : Colors.white;
  Color _getTextColor(BuildContext context) => _isDarkMode(context) ? Colors.white : Colors.black;
  Color _getSecondaryTextColor(BuildContext context) => _isDarkMode(context) ? Colors.white70 : Colors.grey[600]!;
  Color _getAppBarColor(BuildContext context) => _isDarkMode(context) ? Colors.black12 : primaryBlue;
  Color _getGridColor(BuildContext context) => _isDarkMode(context) ? const Color(0xFF2C2C2C) : Colors.grey.withOpacity(0.3);

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }

  Color _getSubjectColor(String subject) {
    final hash = subject.hashCode;
    return Color((hash & 0xFFFFFF) | 0xFF000000).withOpacity(1.0);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present': return Colors.green;
      case 'absent': return Colors.red;
      case 'OD': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  String _generateRandomStatus() {
    final random = Random();
    final statuses = ['present', 'present', 'present', 'OD', 'absent'];
    return statuses[random.nextInt(statuses.length)];
  }

  Widget monthTitles(double value, TitleMeta meta, BuildContext context) {
    final style = TextStyle(color: _getTextColor(context), fontWeight: FontWeight.bold, fontSize: 10);
    String text;
    final months = ['Jun', 'Jul', 'Aug', 'Sep', 'Oct'];
    if (value.toInt() >= 0 && value.toInt() < months.length) {
      text = months[value.toInt()];
    } else {
      text = '';
    }
    return SideTitleWidget(axisSide: meta.axisSide, space: 8, child: Text(text, style: style));
  }

  Widget leftTitles(double value, TitleMeta meta, BuildContext context) {
    final style = TextStyle(color: _getTextColor(context), fontWeight: FontWeight.bold, fontSize: 10);
    String text;
    switch (value.toInt()) {
      case 0: text = '0%'; break;
      case 20: text = '20%'; break;
      case 40: text = '40%'; break;
      case 60: text = '60%'; break;
      case 80: text = '80%'; break;
      case 100: text = '100%'; break;
      default: return Container();
    }
    return SideTitleWidget(axisSide: meta.axisSide, space: 8, child: Text(text, style: style));
  }

  Widget _buildRecommendationItem(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> monthlyData = [
      {'month': 'Jun', 'percentage': 75},
      {'month': 'Jul', 'percentage': 78},
      {'month': 'Aug', 'percentage': 82},
      {'month': 'Sep', 'percentage': 79},
      {'month': 'Oct', 'percentage': attendancePercentage.toInt()},
    ];

    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      appBar: AppBar(
        title: Text(subjectName, style: const TextStyle(color: Colors.white)),
        backgroundColor: _getAppBarColor(context),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getAttendanceColor(attendancePercentage).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('Current Attendance', style: TextStyle(fontSize: 16, color: _getSecondaryTextColor(context))),
                  const SizedBox(height: 8),
                  Text(
                    '${attendancePercentage.toInt()}%',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _getAttendanceColor(attendancePercentage)),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: attendancePercentage / 100,
                    backgroundColor: _getGridColor(context),
                    valueColor: AlwaysStoppedAnimation<Color>(_getAttendanceColor(attendancePercentage)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Monthly Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getTextColor(context))),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 20, getDrawingHorizontalLine: (v) => FlLine(color: _getGridColor(context), strokeWidth: 1)),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1, getTitlesWidget: (v, m) => monthTitles(v, m, context))),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 42, interval: 20, getTitlesWidget: (v, m) => leftTitles(v, m, context))),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: _getGridColor(context))),
                  minX: 0,
                  maxX: monthlyData.length - 1.0,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: monthlyData.asMap().entries.map((entry) {
                        final percentage = (entry.value['percentage'] as num).toDouble();
                        return FlSpot(entry.key.toDouble(), percentage);
                      }).toList(),
                      isCurved: true,
                      color: _getSubjectColor(subjectName),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: _getSubjectColor(subjectName).withOpacity(0.2)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Recent Attendance Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getTextColor(context))),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 10,
              itemBuilder: (context, index) {
                final date = DateTime.now().subtract(Duration(days: index));
                final status = _generateRandomStatus();
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: _getCardColor(context),
                  shadowColor: _isDarkMode(context) ? Colors.black54 : Colors.grey.withOpacity(0.2),
                  child: ListTile(
                    leading: Text('${date.day}/${date.month}', style: TextStyle(fontWeight: FontWeight.bold, color: _getTextColor(context))),
                    title: Text(_getDayName(date.weekday), style: TextStyle(color: _getTextColor(context))),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text('Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getTextColor(context))),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildRecommendationItem('Attendance Goal', 'Try to maintain at least 85% attendance', Icons.flag, primaryBlue),
                  const SizedBox(height: 12),
                  _buildRecommendationItem('Study Time', 'Allocate extra time for ${subjectName.toLowerCase()}', Icons.schedule, Colors.green),
                  const SizedBox(height: 12),
                  _buildRecommendationItem(
                    'Performance',
                    attendancePercentage < 75 ? 'Your attendance is below average. Focus on improving.' : 'Good attendance! Keep it up.',
                    attendancePercentage < 75 ? Icons.warning : Icons.thumb_up,
                    attendancePercentage < 75 ? Colors.orange : Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}