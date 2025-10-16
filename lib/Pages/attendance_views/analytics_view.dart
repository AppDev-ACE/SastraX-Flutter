import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../models/theme_model.dart';

class AnalyticsView extends StatelessWidget {
  final Map<String, Map<String, dynamic>> subjectAttendance;

  const AnalyticsView({Key? key, required this.subjectAttendance}) : super(key: key);

  static const Color primaryBlue = Color(0xFF1e3a8a);

  Color _getTextColor(BuildContext context) => Provider.of<ThemeProvider>(context).isDarkMode ? Colors.white : Colors.black;
  Color _getGridColor(BuildContext context) => Provider.of<ThemeProvider>(context).isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.withOpacity(0.3);

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }

  Widget getTitles(double value, TitleMeta meta, BuildContext context) {
    final style = TextStyle(color: _getTextColor(context), fontWeight: FontWeight.bold, fontSize: 10);
    String text;
    final subjects = subjectAttendance.keys.toList();
    if (value.toInt() >= 0 && value.toInt() < subjects.length) {
      text = subjects[value.toInt()].substring(0, 3).toUpperCase();
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

  Widget monthTitles(double value, TitleMeta meta, BuildContext context) {
    final style = TextStyle(color: _getTextColor(context), fontWeight: FontWeight.bold, fontSize: 10);
    String text;
    switch (value.toInt()) {
      case 0: text = 'Jun'; break;
      case 1: text = 'Jul'; break;
      case 2: text = 'Aug'; break;
      case 3: text = 'Sep'; break;
      case 4: text = 'Oct'; break;
      case 5: text = 'Nov'; break;
      default: return Container();
    }
    return SideTitleWidget(axisSide: meta.axisSide, space: 8, child: Text(text, style: style));
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), // Adjusted padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox( // Ensures text shrinks if needed
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(height: 4),
          FittedBox( // Ensures text shrinks if needed
            fit: BoxFit.scaleDown,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int total = 0;
    int attended = 0;
    int missed = 0;
    subjectAttendance.forEach((key, value) {
      total += (value['totalClasses'] as int? ?? 0);
      attended += (value['present'] as int? ?? 0);
      missed += (value['absent'] as int? ?? 0);
    });

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overall Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getTextColor(context))),
          const SizedBox(height: 16),
          Row(
            children: [
              // ✅ FIX: Wrap each card in an Expanded widget
              Expanded(
                child: _buildStatCard('Total Classes', total.toString(), primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Attended', attended.toString(), Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Missed', missed.toString(), Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Subject-wise Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getTextColor(context))),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final subject = subjectAttendance.keys.elementAt(group.x.toInt());
                      return BarTooltipItem('$subject\n${rod.toY.round()}%', const TextStyle(color: Colors.white));
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => getTitles(v, m, context), reservedSize: 38)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => leftTitles(v, m, context))),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: subjectAttendance.entries.map((entry) {
                  return BarChartGroupData(
                    x: subjectAttendance.keys.toList().indexOf(entry.key),
                    barRods: [
                      BarChartRodData(
                        toY: entry.value['percentage'] as double,
                        color: _getAttendanceColor(entry.value['percentage'] as double),
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: _getGridColor(context), strokeWidth: 1),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
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
                maxX: 5,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 75), FlSpot(1, 78), FlSpot(2, 82),
                      FlSpot(3, 79), FlSpot(4, 85), FlSpot(5, 78),
                    ],
                    isCurved: true,
                    color: primaryBlue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: primaryBlue.withOpacity(0.2)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}