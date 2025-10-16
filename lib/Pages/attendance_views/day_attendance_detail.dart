import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/theme_model.dart';
import '../../components/theme_toggle_button.dart';

class DayAttendanceDetail extends StatefulWidget {
  final DateTime selectedDate;
  final Map<String, String> attendanceData;

  const DayAttendanceDetail({
    Key? key,
    required this.selectedDate,
    required this.attendanceData,
  }) : super(key: key);

  @override
  State<DayAttendanceDetail> createState() => _DayAttendanceDetailState();
}

class _DayAttendanceDetailState extends State<DayAttendanceDetail> {
  final Map<String, bool> _checkboxStates = {};
  static const Color primaryBlue = Color(0xFF1e3a8a);

  @override
  void initState() {
    super.initState();
    widget.attendanceData.forEach((subject, status) {
      if (status.toLowerCase() == 'absent') {
        _checkboxStates[subject] = false;
      }
    });
  }

  Color _getTextColor(BuildContext context) =>
      Provider.of<ThemeProvider>(context).isDarkMode
          ? Colors.white
          : Colors.black;
  Color _getSecondaryTextColor(BuildContext context) =>
      Provider.of<ThemeProvider>(context).isDarkMode
          ? Colors.white70
          : Colors.grey[600]!;
  Color _getCardColor(BuildContext context) =>
      Provider.of<ThemeProvider>(context).isDarkMode
          ? const Color(0xFF1E1E1E)
          : Colors.white;
  Color _getAppBarColor(BuildContext context) =>
      Provider.of<ThemeProvider>(context).isDarkMode
          ? Colors.black12
          : primaryBlue;

  Color _getOverallStatusColor() {
    if (widget.attendanceData.values.any((s) => s == 'absent'))
      return Colors.red;
    if (widget.attendanceData.values.any((s) => s == 'OD'))
      return Colors.orange;
    return Colors.green;
  }

  IconData _getOverallStatusIcon() {
    if (widget.attendanceData.values.any((s) => s == 'absent'))
      return Icons.cancel;
    if (widget.attendanceData.values.any((s) => s == 'OD'))
      return Icons.access_time;
    return Icons.check_circle;
  }

  String _getOverallStatusText() {
    if (widget.attendanceData.values.any((s) => s == 'absent'))
      return 'PARTIAL';
    if (widget.attendanceData.values.any((s) => s == 'OD')) return 'OD';
    return 'PRESENT';
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
    final hash = subject.hashCode;
    return Color((hash & 0xFFFFFF) | 0xFF000000).withOpacity(1.0);
  }

  String _getInsightMessage() {
    int absentCount =
        widget.attendanceData.values.where((s) => s == 'absent').length;
    int odCount = widget.attendanceData.values.where((s) => s == 'OD').length;
    if (absentCount > 0)
      return 'You missed $absentCount class(es) today. Make sure to catch up on the material you missed.';
    if (odCount > 0)
      return 'You were on OD for $odCount class(es) today. Make sure to complete any pending work.';
    return 'Great job! You attended all your classes today. Keep up the good work!';
  }

  String _getSubjectTime(String subject) {
    // This is a placeholder. For real data, you'd need to pass the timetable.
    switch (subject) {
      case 'Data Structure':
        return '9:00 AM - 10:00 AM';
      case 'Computer Networks':
        return '10:00 AM - 11:00 AM';
      case 'Operating System':
        return '11:00 AM - 12:00 PM';
      case 'Natural Language Processing':
        return '1:00 PM - 2:00 PM';
      case 'Soft Skills':
        return '2:00 PM - 3:00 PM';
      default:
        return 'Time not available';
    }
  }

  bool _isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    String formattedDate =
    DateFormat('dd MMMM, yyyy').format(widget.selectedDate);
    final odreasoncontroller = TextEditingController();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text(formattedDate, style: const TextStyle(color: Colors.white)),
        backgroundColor: _getAppBarColor(context),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ThemeToggleButton(
                isDarkMode: isDark, onToggle: themeProvider.toggleTheme),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildOverallStatusCard(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Subject-wise Attendance',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getTextColor(context)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.attendanceData.length,
              itemBuilder: (context, index) {
                final subject = widget.attendanceData.keys.elementAt(index);
                final status = widget.attendanceData[subject]!;
                final isChecked = _checkboxStates[subject] ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  color: _getCardColor(context),
                  shadowColor:
                  isDark ? Colors.black54 : Colors.grey.withOpacity(0.2),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getSubjectColor(subject),
                      child: Text(subject.substring(0, 1),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(subject,
                        style: TextStyle(color: _getTextColor(context))),
                    subtitle: Text(_getSubjectTime(subject),
                        style:
                        TextStyle(color: _getSecondaryTextColor(context))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ),
                        if (status.toLowerCase() == 'absent')
                          Checkbox(
                            value: isChecked,
                            onChanged: (bool? newValue) {
                              setState(() {
                                _checkboxStates[subject] = newValue ?? false;
                              });
                            },
                            activeColor:
                            isDark ? Colors.cyanAccent : primaryBlue,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_checkboxStates.values.any((value) => value))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isDarkMode(context)
                    ? primaryBlue.withOpacity(0.2)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                controller: odreasoncontroller,
                decoration: InputDecoration(
                    label: const Text("Reason for OD"),
                    suffixIcon: IconButton(
                        onPressed: () {
                          //integrate with firebase
                          null;
                        },
                        icon: const Icon(Icons.send_rounded))),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Error";
                  }
                  return null;
                },
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? primaryBlue.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Insights',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(context)),
                ),
                const SizedBox(height: 8),
                Text(_getInsightMessage(),
                    style:
                    TextStyle(fontSize: 14, color: _getTextColor(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStatusCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getOverallStatusColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('Overall Status',
              style: TextStyle(
                  fontSize: 16, color: _getSecondaryTextColor(context))),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getOverallStatusIcon(),
                  color: _getOverallStatusColor(), size: 32),
              const SizedBox(width: 8),
              Text(
                _getOverallStatusText(),
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getOverallStatusColor()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
