import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../models/theme_model.dart'; // ✅ Import your Theme Model

// --- Data Model (LeaveApplication) ---
// (Keep the LeaveApplication class exactly as it was)
class LeaveApplication {
  final int? id;
  final String? leaveType;
  final DateTime? from;
  final DateTime? to;
  final double? numberOfDays;
  final String? reason;
  final String? status;
  final String? attachment;

  LeaveApplication({
    this.id,
    this.leaveType,
    this.from,
    this.to,
    this.numberOfDays,
    this.reason,
    this.status,
    this.attachment,
  });

  factory LeaveApplication.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(String? dateString) {
      if (dateString == null || dateString.isEmpty) return null;
      try {
        List<String> parts = dateString.split(RegExp(r'[ \/:-]'));
        if (parts.length >= 5) {
          return DateTime( int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]), int.parse(parts[3]), int.parse(parts[4]), );
        }
      } catch (e) { debugPrint('Error parsing date: $dateString, Error: $e'); }
      return null;
    }

    return LeaveApplication(
      id: int.tryParse(json['sno'] ?? '0'),
      leaveType: json['leaveType'],
      from: parseDateTime(json['fromDate']),
      to: parseDateTime(json['toDate']),
      numberOfDays: double.tryParse(json['noOfDays'] ?? '0'),
      reason: json['reason'],
      status: json['status'],
    );
  }
}
// --- End Data Model ---

// ----------------------------------------------------
// --- UI Screen Widget ---
// ----------------------------------------------------
class LeaveApplicationScreen extends StatefulWidget {
  final String token;
  final String regNo;
  final String apiUrl;

  const LeaveApplicationScreen({
    super.key,
    required this.token,
    required this.regNo,
    required this.apiUrl,
  });

  @override
  State<LeaveApplicationScreen> createState() => _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState extends State<LeaveApplicationScreen> {
  // Mock data for dropdown
  final List<String> _leaveTypes = ['Casual Leave', 'Sick Leave', 'Special Leave', 'Exam Leave', 'Weekday\\Weekend', 'NSS\\NCC\\Moot Court'];
  String? _selectedLeaveType;

  // --- Leave History Data Storage ---
  List<LeaveApplication> _previousApplications = [];
  bool _isLoading = true;
  String? _errorMessage;
  // --- End History Data ---

  // --- Form Field Controllers & State ---
  final TextEditingController _fromDateController = TextEditingController(text: '16-10-2025    10:00');
  final TextEditingController _toDateController = TextEditingController(text: '23-10-2025    18:00');
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _daysController = TextEditingController(text: '7');
  DateTime? _fromDateTime = DateTime(2025, 10, 16, 10, 0);
  DateTime? _toDateTime = DateTime(2025, 10, 23, 18, 0);
  // --- End Form State ---

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateDays();
      _fetchLeaveHistory();
    });
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    _reasonController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  // --- Data Fetching Logic (_fetchLeaveHistory) ---
  // (Keep _fetchLeaveHistory exactly as it was)
  Future<void> _fetchLeaveHistory({bool refresh = false}) async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final url = Uri.parse('${widget.apiUrl}/leaveHistory');
      final response = await http.post( url, headers: {'Content-Type': 'application/json'}, body: json.encode({ 'token': widget.token, 'regNo': widget.regNo, 'refresh': refresh, }), );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> historyJson = data['leaveHistory'] ?? [];
          _previousApplications = historyJson .map<LeaveApplication>((json) => LeaveApplication.fromJson(json as Map<String, dynamic>)) .toList();
          if (refresh && mounted) { ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Leave history refreshed successfully!')), ); }
        } else { _errorMessage = data['message'] ?? 'Failed to fetch leave history.'; }
      } else { _errorMessage = 'API failed with status: ${response.statusCode}'; }
    } catch (e) { _errorMessage = 'An unexpected error occurred: $e'; }
    finally { if (mounted) { setState(() { _isLoading = false; }); } }
  }
  // --- End Data Fetching ---

  // --- Helper Functions (_calculateDays, _selectDateTime, _submitApplication, _getStatusColor) ---
  // (Keep these exactly as they were, except _getStatusColor might use theme later if needed)
  void _calculateDays() {
    if (_fromDateTime == null || _toDateTime == null) { _daysController.text = '0'; return; }
    if (!_toDateTime!.isAfter(_fromDateTime!)) { _daysController.text = '1'; return; }
    final double days = _toDateTime!.difference(_fromDateTime!).inHours / 24;
    final int integerDays = days.ceil(); // Use ceil to count partial days as full days
    final String finalDays = integerDays <= 0 ? '1' : integerDays.toString();
    _daysController.text = finalDays;
  }

  Future<void> _selectDateTime(BuildContext context, TextEditingController controller, bool isFrom) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = isFrom ? (_fromDateTime ?? now) : (_toDateTime ?? now);
    final DateTime? pickedDate = await showDatePicker( context: context, initialDate: initialDate, firstDate: DateTime(2000), lastDate: DateTime(2100), );
    if (pickedDate == null || !mounted) return;
    final TimeOfDay initialTime = TimeOfDay.fromDateTime(initialDate);
    final TimeOfDay? pickedTime = await showTimePicker( context: context, initialTime: initialTime, );
    if (pickedTime == null) return;
    final DateTime combined = DateTime( pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute, );
    controller.text = '${combined.day.toString().padLeft(2, '0')}-${combined.month.toString().padLeft(2, '0')}-${combined.year}   ${combined.hour.toString().padLeft(2, '0')}:${combined.minute.toString().padLeft(2, '0')}';
    setState(() { if (isFrom) { _fromDateTime = combined; } else { _toDateTime = combined; } _calculateDays(); });
  }

  void _submitApplication() {
    if (_selectedLeaveType == null || _reasonController.text.isEmpty || _daysController.text == '0') {
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Please select a leave type, provide a reason, and ensure valid dates.')), );
      return;
    }
    // TODO: Implement actual API call to submit leave
    print('Submitting Leave: Type=$_selectedLeaveType, From=$_fromDateTime, To=$_toDateTime, Days=${_daysController.text}, Reason=${_reasonController.text}');
    ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text('Leave submitted for: $_selectedLeaveType (${_daysController.text} days)'), backgroundColor: Colors.green, ), );
    // Optionally clear form or refresh history after submission
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) { // Use lowercase for robust matching
      case 'approved' || 'verified': return Colors.green.shade700;
      case 'pending': return Colors.orange.shade700;
      case 'rejected': return Colors.red.shade700;
      default: return Colors.grey.shade600;
    }
  }
  // --- End Helper Functions ---

  @override
  Widget build(BuildContext context) {
    // ✅ Get ThemeProvider and the specific blue color
    final themeProvider = Provider.of<ThemeProvider>(context);
    final Color appBlueColor = themeProvider.isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue;
    final Color cardBgColor = themeProvider.isDarkMode ? AppTheme.darkSurface : Colors.white;
    final Color textColor = themeProvider.isDarkMode ? Colors.white : Colors.black87;
    final Color subtleTextColor = themeProvider.isDarkMode ? Colors.white70 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? AppTheme.darkBackground : Colors.grey[100], // Themed background
      appBar: AppBar(
        title: const Text('Student Leave Portal'),
        // ✅ Use the specific blue color
        backgroundColor: appBlueColor,
        foregroundColor: Colors.white, // Keep text/icons white on blue
        elevation: themeProvider.isDarkMode ? 0 : 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- New Application Form Section ---
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
              child: Text(
                'STUDENT LEAVE APPLICATION FORM',
                style: TextStyle( fontSize: 12, fontWeight: FontWeight.w600, color: subtleTextColor.withOpacity(0.8), letterSpacing: 1.5, ),
              ),
            ),
            Text(
              'New Leave Application',
              // ✅ Use the specific blue color
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: appBlueColor),
            ),
            const Divider(height: 20, thickness: 1.5), // Slightly thicker divider
            Card(
              elevation: themeProvider.isDarkMode ? 1 : 4, // Adjust elevation based on theme
              color: cardBgColor, // Use themed card background
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: themeProvider.isDarkMode ? BorderSide(color: appBlueColor.withOpacity(0.3)) : BorderSide.none // Add border in dark mode
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Leave Type*',
                        labelStyle: TextStyle(color: subtleTextColor), // Themed label
                        enabledBorder: OutlineInputBorder( borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: subtleTextColor.withOpacity(0.5))),
                        focusedBorder: OutlineInputBorder( borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: appBlueColor, width: 2)),
                        // ✅ Use the specific blue color for icon
                        prefixIcon: Icon(Icons.list_alt, size: 20, color: appBlueColor),
                      ),
                      dropdownColor: cardBgColor, // Match dropdown background
                      style: TextStyle(color: textColor), // Themed text style
                      value: _selectedLeaveType,
                      items: _leaveTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() { _selectedLeaveType = newValue; });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ Pass appBlueColor to the helper
                        Expanded(child: _buildDateTimeField(context, 'From Date (HH:MM)', _fromDateController, true, appBlueColor, subtleTextColor)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildDateTimeField(context, 'To Date (HH:MM)', _toDateController, false, appBlueColor, subtleTextColor)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'No. of Days',
                        labelStyle: TextStyle(color: subtleTextColor),
                        enabledBorder: OutlineInputBorder( borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: subtleTextColor.withOpacity(0.5))),
                        focusedBorder: OutlineInputBorder( borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: appBlueColor, width: 2)),
                        // ✅ Use the specific blue color for icon
                        prefixIcon: Icon(Icons.timer_sharp, size: 20, color: appBlueColor),
                      ),
                      controller: _daysController,
                      readOnly: true, // Keep read-only
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor), // Themed text
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 4,
                      style: TextStyle(color: textColor), // Themed text
                      decoration: InputDecoration(
                        labelText: 'Reason*',
                        labelStyle: TextStyle(color: subtleTextColor),
                        hintText: 'Enter reason for leave...',
                        hintStyle: TextStyle(color: subtleTextColor.withOpacity(0.7)),
                        enabledBorder: OutlineInputBorder( borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: subtleTextColor.withOpacity(0.5))),
                        focusedBorder: OutlineInputBorder( borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: appBlueColor, width: 2)),
                        // ✅ Use the specific blue color for icon
                        prefixIcon: Padding( // Add padding to align icon better
                          padding: const EdgeInsets.only(top: 12.0, left: 12.0, right: 12.0),
                          child: Icon(Icons.note_alt_outlined, size: 20, color: appBlueColor),
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _submitApplication,
                          icon: const Icon(Icons.send_rounded),
                          label: const Text('SUBMIT'),
                          style: ElevatedButton.styleFrom(
                            // ✅ Use the specific blue color
                            backgroundColor: appBlueColor,
                            foregroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white, // Adjust contrast
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // --- End New Application Form Section ---

            const SizedBox(height: 32),

            // --- Previous History Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Previous Leave History',
                  // ✅ Use the specific blue color
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: appBlueColor),
                ),
                IconButton(
                  // ✅ Use the specific blue color
                  icon: Icon(Icons.refresh, color: appBlueColor),
                  onPressed: () => _fetchLeaveHistory(refresh: true),
                  tooltip: 'Refresh History',
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1.5),

            // Displaying History (uses state variables _isLoading, _errorMessage, _previousApplications)
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column( // Added column for retry button
                    children: [
                      Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => _fetchLeaveHistory(refresh: true),
                        child: Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appBlueColor,
                          foregroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
                        ),
                      )
                    ],
                  ),
                ),
              )
            else if (_previousApplications.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('No previous leave applications found.', style: TextStyle(color: subtleTextColor)),
                  ),
                )
              else
                Column(
                  // ✅ Pass colors to the history card builder
                  children: _previousApplications.map((app) => _buildHistoryCard(app, context, appBlueColor, cardBgColor, textColor, subtleTextColor)).toList(),
                ),
            // --- End Previous History Section ---

            const SizedBox(height: 50), // Bottom padding
          ],
        ),
      ),
    );
  }

  // ✅ Modified History Card builder to accept themed colors
  Widget _buildHistoryCard(LeaveApplication app, BuildContext context, Color primaryColor, Color cardBg, Color textClr, Color subtleTextClr) {
    String formattedFrom = app.from == null ? 'N/A' : DateFormat('dd-MM-yyyy HH:mm').format(app.from!);
    String formattedTo = app.to == null ? 'N/A' : DateFormat('dd-MM-yyyy HH:mm').format(app.to!);
    Color statusColor = _getStatusColor(app.status ?? 'Unknown');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? 0.5 : 2,
      color: cardBg, // Use themed background
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? BorderSide(color: primaryColor.withOpacity(0.2)) : BorderSide.none
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  app.leaveType ?? 'N/A',
                  // ✅ Use the specific blue color
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration( color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor, width: 1), ),
                  child: Text( app.status ?? 'N/A', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13), ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Reason: ${app.reason ?? 'N/A'}', style: TextStyle(fontSize: 14, color: textClr.withOpacity(0.9)))), // Slightly less opacity than main text
                Text('${(app.numberOfDays ?? 0).toInt()} days', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textClr)),
              ],
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: subtleTextClr.withOpacity(0.3)), // Themed divider
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From:', style: TextStyle(color: subtleTextClr, fontSize: 12)),
                    Text(formattedFrom, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textClr)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end, // Align 'To' date text to the right
                  children: [
                    Text('To:', style: TextStyle(color: subtleTextClr, fontSize: 12)),
                    Text(formattedTo, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textClr)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Modified DateTime field builder to accept themed colors
  Widget _buildDateTimeField(BuildContext context, String label, TextEditingController controller, bool isFrom, Color primaryColor, Color subtleTxtColor) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectDateTime(context, controller, isFrom),
      style: TextStyle(color: Provider.of<ThemeProvider>(context, listen: false).textColor), // Use main text color
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subtleTxtColor), // Themed label
        enabledBorder: OutlineInputBorder( borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: subtleTxtColor.withOpacity(0.5))),
        focusedBorder: OutlineInputBorder( borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: primaryColor, width: 2)),
        contentPadding: const EdgeInsets.fromLTRB(12, 16, 0, 16),
        suffixIcon: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, maxWidth: 40),
          // ✅ Use the specific blue color
          icon: Icon(Icons.calendar_today, color: primaryColor),
          onPressed: () => _selectDateTime(context, controller, isFrom),
        ),
      ),
    );
  }
}