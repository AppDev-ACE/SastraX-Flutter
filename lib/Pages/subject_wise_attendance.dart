import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class SubjectWiseAttendancePage extends StatefulWidget {
  const SubjectWiseAttendancePage({Key? key}) : super(key: key);

  @override
  State<SubjectWiseAttendancePage> createState() => _SubjectWiseAttendancePageState();
}

class _SubjectWiseAttendancePageState extends State<SubjectWiseAttendancePage>
    with TickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Add listener to update the UI when tab changes
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Sample attendance data
  final Map<DateTime, Map<String, String>> _attendanceData = {
    DateTime(2023, 10, 2): {
      'Data Structure': 'present',
      'Computer Networks': 'present',
      'Operating System': 'present',
      'Natural Language Processing': 'present',
      'Soft Skills': 'present'
    },
    DateTime(2023, 10, 3): {
      'Data Structure': 'present',
      'Computer Networks': 'present',
      'Operating System': 'absent',
      'Natural Language Processing': 'present',
      'Soft Skills': 'present'
    },
    DateTime(2023, 10, 4): {
      'Data Structure': 'present',
      'Computer Networks': 'present',
      'Operating System': 'present',
      'Natural Language Processing': 'absent',
      'Soft Skills': 'OD'
    },
    DateTime(2023, 10, 5): {
      'Data Structure': 'present',
      'Computer Networks': 'absent',
      'Operating System': 'present',
      'Natural Language Processing': 'present',
      'Soft Skills': 'present'
    },
    DateTime(2023, 10, 6): {
      'Data Structure': 'OD',
      'Computer Networks': 'present',
      'Operating System': 'present',
      'Natural Language Processing': 'present',
      'Soft Skills': 'present'
    },
  };

  // Subject-wise attendance data with counts
  final Map<String, Map<String, dynamic>> _subjectAttendance = {
    'Data Structure': {
      'percentage': 85.0,
      'totalClasses': 20,
      'present': 17,
      'absent': 2,
      'od': 1,
    },
    'Computer Networks': {
      'percentage': 85.0,
      'totalClasses': 20,
      'present': 17,
      'absent': 2,
      'od': 1,
    },
    'Operating System': {
      'percentage': 85.0,
      'totalClasses': 20,
      'present': 17,
      'absent': 2,
      'od': 1,
    },
    'Natural Language Processing': {
      'percentage': 63.0,
      'totalClasses': 19,
      'present': 12,
      'absent': 5,
      'od': 2,
    },
    'Soft Skills': {
      'percentage': 75.0,
      'totalClasses': 16,
      'present': 12,
      'absent': 3,
      'od': 1,
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject-wise Attendance'),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.transparent, // Hide default indicator
          tabs: [
            Tab(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _tabController.index == 0
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Monthly View',
                  style: TextStyle(
                    color: _tabController.index == 0 ? Colors.white : Colors.white70,
                    fontSize: _tabController.index == 0 ? 16 : 14,
                    fontWeight: _tabController.index == 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
            Tab(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _tabController.index == 1
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Subject View',
                  style: TextStyle(
                    color: _tabController.index == 1 ? Colors.white : Colors.white70,
                    fontSize: _tabController.index == 1 ? 16 : 14,
                    fontWeight: _tabController.index == 1
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
            Tab(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _tabController.index == 2
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Analytics',
                  style: TextStyle(
                    color: _tabController.index == 2 ? Colors.white : Colors.white70,
                    fontSize: _tabController.index == 2 ? 16 : 14,
                    fontWeight: _tabController.index == 2
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMonthlyView(),
          _buildSubjectView(),
          _buildAnalyticsView(),
        ],
      ),
    );
  }

  Widget _buildMonthlyView() {
    return Column(
      children: [
        // Month selector and stats
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.withOpacity(0.1),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_focusedDay),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      _buildLegend('Present', Colors.green),
                      const SizedBox(width: 16),
                      _buildLegend('Absent', Colors.red),
                      const SizedBox(width: 16),
                      _buildLegend('OD', Colors.orange),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMonthStat('Present', '18', Colors.green),
                  _buildMonthStat('Absent', '3', Colors.red),
                  _buildMonthStat('OD', '2', Colors.orange),
                  _buildMonthStat('Percentage', '78%', Colors.blue),
                ],
              ),
            ],
          ),
        ),

        // Calendar
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TableCalendar<String>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: (day) {
                // Convert day to DateTime without time to match keys
                final dayKey = DateTime(day.year, day.month, day.day);
                return _attendanceData.containsKey(dayKey)
                    ? ['has data']
                    : [];
              },
              calendarStyle: CalendarStyle(
                markersMaxCount: 1,
                markerDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF1565C0),
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: _buildAttendanceMarker(day),
                    );
                  }
                  return null;
                },
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });

                // Navigate to day detail view
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DayAttendanceDetail(
                      selectedDate: selectedDay,
                      attendanceData: _attendanceData[DateTime(selectedDay.year, selectedDay.month, selectedDay.day)] ?? {},
                    ),
                  ),
                );
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),
        ),

        // Achievement section
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.withOpacity(0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attendance Achievements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAchievement('Week Streak', '2', Icons.local_fire_department, Colors.orange),
                  _buildAchievement('Best Month', 'Sept', Icons.emoji_events, Colors.amber),
                  _buildAchievement('Improvement', '+5%', Icons.trending_up, Colors.green),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subject-wise Attendance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Subject cards
          ..._subjectAttendance.entries.map((entry) {
            final subjectData = entry.value;
            final bunkableClasses = _calculateBunkableClasses(subjectData);
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubjectAttendanceDetail(
                      subjectName: entry.key,
                      attendancePercentage: subjectData['percentage'],
                    ),
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _getSubjectColor(entry.key),
                            child: Text(
                              entry.key.substring(0, 1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: (subjectData['percentage'] as double) / 100,
                                  backgroundColor: Colors.grey.withOpacity(0.3),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getAttendanceColor(subjectData['percentage'] as double),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${(subjectData['percentage'] as double).toInt()}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getAttendanceColor(subjectData['percentage'] as double),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Attendance details row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildAttendanceDetail('Total', subjectData['totalClasses'], Colors.blue),
                          _buildAttendanceDetail('Present', subjectData['present'], Colors.green),
                          _buildAttendanceDetail('Absent', subjectData['absent'], Colors.red),
                          _buildAttendanceDetail('OD', subjectData['od'], Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Bunkable classes info
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.purple,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'You can bunk $bunkableClasses more classes',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.purple,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 20),
          const Text(
            'Subject-wise Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInsightItem(
                  'Best Performance',
                  'Data Structures, Computer Networks, Operating System',
                  Icons.star,
                  Colors.amber,
                ),
                const SizedBox(height: 12),
                _buildInsightItem(
                  'Needs Improvement',
                  'Natural Language Processing',
                  Icons.trending_down,
                  Colors.red,
                ),
                const SizedBox(height: 12),
                _buildInsightItem(
                  'Recommendation',
                  'Focus on Natural Language Processing and Soft Skill',
                  Icons.lightbulb,
                  Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall stats
          const Text(
            'Overall Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Total Classes', '182', Colors.blue),
              _buildStatCard('Attended', '142', Colors.green),
              _buildStatCard('Missed', '40', Colors.red),
            ],
          ),
          const SizedBox(height: 24),

          // Subject-wise attendance chart
          const Text(
            'Subject-wise Attendance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final subject = _subjectAttendance.keys.elementAt(group.x.toInt());
                      return BarTooltipItem(
                        '$subject\n${rod.toY.round()}%',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: getTitles,
                      reservedSize: 38,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: leftTitles,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: _subjectAttendance.entries.map((entry) {
                  return BarChartGroupData(
                    x: _subjectAttendance.keys.toList().indexOf(entry.key),
                    barRods: [
                      BarChartRodData(
                        toY: entry.value['percentage'] as double,
                        color: _getAttendanceColor(entry.value['percentage'] as double),
                        width: 20,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Monthly trend
          const Text(
            'Monthly Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 20,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: monthTitles,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: 20,
                      getTitlesWidget: leftTitles,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                minX: 0,
                maxX: 5,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 75),
                      FlSpot(1, 78),
                      FlSpot(2, 82),
                      FlSpot(3, 79),
                      FlSpot(4, 85),
                      FlSpot(5, 78),
                    ],
                    isCurved: true,
                    color: const Color(0xFF1565C0),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF1565C0),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF1565C0).withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Widget _buildMonthStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceMarker(DateTime day) {
    final dayKey = DateTime(day.year, day.month, day.day);
    if (!_attendanceData.containsKey(dayKey)) return const SizedBox();

    final dayAttendance = _attendanceData[dayKey]!;
    int presentCount = 0;
    int absentCount = 0;
    int odCount = 0;

    dayAttendance.forEach((subject, status) {
      switch (status) {
        case 'present':
          presentCount++;
          break;
        case 'absent':
          absentCount++;
          break;
        case 'OD':
          odCount++;
          break;
      }
    });

    // Determine the dominant status for the day
    String dominantStatus;
    Color color;

    if (absentCount > 0) {
      dominantStatus = 'absent';
      color = Colors.red;
    } else if (odCount > 0) {
      dominantStatus = 'OD';
      color = Colors.orange;
    } else {
      dominantStatus = 'present';
      color = Colors.green;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildAchievement(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceDetail(String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  int _calculateBunkableClasses(Map<String, dynamic> subjectData) {
    final totalClasses = subjectData['totalClasses'] as int;
    final present = subjectData['present'] as int;
    final absent = subjectData['absent'] as int;
    final od = subjectData['od'] as int;

    // Assuming 75% is the minimum required attendance
    const minRequiredPercentage = 75.0;
    final minRequiredClasses = (totalClasses * minRequiredPercentage / 100).ceil();
    final currentEffectiveClasses = present + od;

    if (currentEffectiveClasses >= minRequiredClasses) {
      return 0;
    }

    final remainingClasses = totalClasses - present - absent - od;
    final neededClasses = minRequiredClasses - currentEffectiveClasses;

    return (remainingClasses - neededClasses).clamp(0, remainingClasses);
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Data Structure':
        return Colors.blue;
      case 'Computer Networks':
        return Colors.purple;
      case 'Operating System':
        return Colors.green;
      case 'Natural Language Processing':
        return Colors.teal;
      case 'Soft Skills':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  Color _getAttendanceColor(double percentage) {
    if (percentage >= 85) {
      return Colors.green;
    } else if (percentage >= 75) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    String text;
    final subjects = _subjectAttendance.keys.toList();
    if (value.toInt() >= 0 && value.toInt() < subjects.length) {
      text = subjects[value.toInt()].substring(0, 3);
    } else {
      text = '';
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Text(text, style: style),
    );
  }

  Widget leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    String text;
    switch (value.toInt()) {
      case 0:
        text = '0%';
        break;
      case 20:
        text = '20%';
        break;
      case 40:
        text = '40%';
        break;
      case 60:
        text = '60%';
        break;
      case 80:
        text = '80%';
        break;
      case 100:
        text = '100%';
        break;
      default:
        text = '';
        break;
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Text(text, style: style),
    );
  }

  Widget monthTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    String text;
    switch (value.toInt()) {
      case 0:
        text = 'Jun';
        break;
      case 1:
        text = 'Jul';
        break;
      case 2:
        text = 'Aug';
        break;
      case 3:
        text = 'Sep';
        break;
      case 4:
        text = 'Oct';
        break;
      case 5:
        text = 'Nov';
        break;
      default:
        text = '';
        break;
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Text(text, style: style),
    );
  }
}

// Day Attendance Detail View
class DayAttendanceDetail extends StatelessWidget {
  final DateTime selectedDate;
  final Map<String, String> attendanceData;

  const DayAttendanceDetail({
    Key? key,
    required this.selectedDate,
    required this.attendanceData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance - ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Overall status card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getOverallStatusColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Overall Status',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getOverallStatusIcon(),
                      color: _getOverallStatusColor(),
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getOverallStatusText(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getOverallStatusColor(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Subject-wise attendance
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Subject-wise Attendance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: attendanceData.length,
              itemBuilder: (context, index) {
                final subject = attendanceData.keys.elementAt(index);
                final status = attendanceData[subject]!;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getSubjectColor(subject),
                      child: Text(
                        subject.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(subject),
                    subtitle: Text(_getSubjectTime(subject)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Attendance insights
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getInsightMessage(),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getOverallStatusColor() {
    int presentCount = 0;
    int absentCount = 0;
    int odCount = 0;

    attendanceData.forEach((subject, status) {
      switch (status) {
        case 'present':
          presentCount++;
          break;
        case 'absent':
          absentCount++;
          break;
        case 'OD':
          odCount++;
          break;
      }
    });

    if (absentCount > 0) {
      return Colors.red;
    } else if (odCount > 0) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  IconData _getOverallStatusIcon() {
    int presentCount = 0;
    int absentCount = 0;
    int odCount = 0;

    attendanceData.forEach((subject, status) {
      switch (status) {
        case 'present':
          presentCount++;
          break;
        case 'absent':
          absentCount++;
          break;
        case 'OD':
          odCount++;
          break;
      }
    });

    if (absentCount > 0) {
      return Icons.cancel;
    } else if (odCount > 0) {
      return Icons.access_time;
    } else {
      return Icons.check_circle;
    }
  }

  String _getOverallStatusText() {
    int presentCount = 0;
    int absentCount = 0;
    int odCount = 0;

    attendanceData.forEach((subject, status) {
      switch (status) {
        case 'present':
          presentCount++;
          break;
        case 'absent':
          absentCount++;
          break;
        case 'OD':
          odCount++;
          break;
      }
    });

    if (absentCount > 0) {
      return 'PARTIAL';
    } else if (odCount > 0) {
      return 'OD';
    } else {
      return 'PRESENT';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'OD':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Mathematics':
        return Colors.blue;
      case 'Physics':
        return Colors.purple;
      case 'Chemistry':
        return Colors.green;
      case 'Biology':
        return Colors.teal;
      case 'Computer':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getSubjectTime(String subject) {
    switch (subject) {
      case 'Mathematics':
        return '9:00 AM - 10:00 AM';
      case 'Physics':
        return '10:00 AM - 11:00 AM';
      case 'Chemistry':
        return '11:00 AM - 12:00 PM';
      case 'Biology':
        return '1:00 PM - 2:00 PM';
      case 'Computer':
        return '2:00 PM - 3:00 PM';
      default:
        return 'Time not available';
    }
  }

  String _getInsightMessage() {
    int presentCount = 0;
    int absentCount = 0;
    int odCount = 0;

    attendanceData.forEach((subject, status) {
      switch (status) {
        case 'present':
          presentCount++;
          break;
        case 'absent':
          absentCount++;
          break;
        case 'OD':
          odCount++;
          break;
      }
    });

    if (absentCount > 0) {
      return 'You missed $absentCount class(es) today. Make sure to catch up on the material you missed.';
    } else if (odCount > 0) {
      return 'You were on OD for $odCount class(es) today. Make sure to complete any pending work.';
    } else {
      return 'Great job! You attended all your classes today. Keep up the good work!';
    }
  }
}

// Subject Attendance Detail View
class SubjectAttendanceDetail extends StatelessWidget {
  final String subjectName;
  final double attendancePercentage;

  const SubjectAttendanceDetail({
    Key? key,
    required this.subjectName,
    required this.attendancePercentage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample monthly attendance data for the subject
    final List<Map<String, dynamic>> monthlyData = [
      {'month': 'Jun', 'percentage': 75},
      {'month': 'Jul', 'percentage': 78},
      {'month': 'Aug', 'percentage': 82},
      {'month': 'Sep', 'percentage': 79},
      {'month': 'Oct', 'percentage': attendancePercentage.toInt()},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('$subjectName Attendance'),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getAttendanceColor(attendancePercentage).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Current Attendance',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${attendancePercentage.toInt()}%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: _getAttendanceColor(attendancePercentage),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: attendancePercentage / 100,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getAttendanceColor(attendancePercentage),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Monthly trend
            const Text(
              'Monthly Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 20,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.white.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.white.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: monthTitles,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: 20,
                        getTitlesWidget: leftTitles,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.black.withOpacity(0.3)),
                  ),
                  minX: 0,
                  maxX: monthlyData.length - 1.0,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: monthlyData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value['percentage'].toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: _getSubjectColor(subjectName),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: _getSubjectColor(subjectName),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: _getSubjectColor(subjectName).withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Detailed attendance records
            const Text(
              'Recent Attendance Records',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                  child: ListTile(
                    leading: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    title: Text(_getDayName(date.weekday)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Recommendations
            const SizedBox(height: 20),
            const Text(
              'Recommendations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRecommendationItem(
                    'Attendance Goal',
                    'Try to maintain at least 85% attendance',
                    Icons.flag,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildRecommendationItem(
                    'Study Time',
                    'Allocate extra time for ${subjectName.toLowerCase()}',
                    Icons.schedule,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildRecommendationItem(
                    'Performance',
                    attendancePercentage < 75
                        ? 'Your attendance is below average. Focus on improving.'
                        : 'Good attendance! Keep it up.',
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

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 85) {
      return Colors.green;
    } else if (percentage >= 75) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Mathematics':
        return Colors.blue;
      case 'Physics':
        return Colors.purple;
      case 'Chemistry':
        return Colors.green;
      case 'Biology':
        return Colors.teal;
      case 'Computer':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'OD':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  String _generateRandomStatus() {
    final random = Random();
    final statuses = ['present', 'present', 'present', 'OD', 'absent'];
    return statuses[random.nextInt(statuses.length)];
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget monthTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    String text;
    final months = ['Jun', 'Jul', 'Aug', 'Sep', 'Oct'];
    if (value.toInt() >= 0 && value.toInt() < months.length) {
      text = months[value.toInt()];
    } else {
      text = '';
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Text(text, style: style),
    );
  }

  Widget leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    String text;
    switch (value.toInt()) {
      case 0:
        text = '0%';
        break;
      case 20:
        text = '20%';
        break;
      case 40:
        text = '40%';
        break;
      case 60:
        text = '60%';
        break;
      case 80:
        text = '80%';
        break;
      case 100:
        text = '100%';
        break;
      default:
        text = '';
        break;
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Text(text, style: style),
    );
  }
}