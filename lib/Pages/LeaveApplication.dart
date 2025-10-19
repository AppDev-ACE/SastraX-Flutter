import 'package:flutter/material.dart';

// --- Data Model ---
// All parameters are optional in the constructor.
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
}

// --- UI Screen Widget ---
class LeaveApplicationScreen extends StatefulWidget {
  const LeaveApplicationScreen({super.key});

  @override
  State<LeaveApplicationScreen> createState() => _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState extends State<LeaveApplicationScreen> {
  // Mock data for dropdown
  final List<String> _leaveTypes = ['Casual Leave', 'Sick Leave', 'Special Leave', 'Exam Leave' , 'Weekday\\Weekend' , 'NSS\\NCC\\Moot Court'];
  String? _selectedLeaveType;

  // Mock data for previous applications
  final List<LeaveApplication> _previousApplications = [
    LeaveApplication(
      id: 1,
      leaveType: 'Open Holiday',
      from: DateTime(2025, 8, 6, 14, 0),
      to: DateTime(2025, 8, 11, 8, 0),
      numberOfDays: 4.0,
      reason: 'Open Holiday',
      status: 'Approved',
    ),
    LeaveApplication(
      id: 2,
      leaveType: 'Weekday/Weekend',
      from: DateTime(2025, 10, 17, 15, 0),
      to: DateTime(2025, 10, 23, 10, 0),
      numberOfDays: 7.0,
      reason: 'Diwali Holidays',
      status: 'Pending',
    ),
    LeaveApplication(
      id: 3,
      leaveType: 'Casual Leave',
      from: DateTime(2025, 10, 1, 9, 0),
      to: DateTime(2025, 10, 1, 18, 0),
      numberOfDays: 1.0,
      reason: 'Doctor\'s appointment',
      status: 'Rejected',
    ),
  ];

  // Form field controllers
  final TextEditingController _fromDateController = TextEditingController(text: '16-10-2025    10:00');
  final TextEditingController _toDateController = TextEditingController(text: '23-10-2025    18:00');
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _daysController = TextEditingController(text: '7');

  // Internal date values - Initialized to match the controllers' text
  DateTime? _fromDateTime = DateTime(2025, 10, 16, 10, 0);
  DateTime? _toDateTime = DateTime(2025, 10, 23, 18, 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateDays());
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    _reasonController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  void _calculateDays() {
    if (_fromDateTime == null || _toDateTime == null) {
      _daysController.text = '0';
      return;
    }

    if (!_toDateTime!.isAfter(_fromDateTime!)) {
      _daysController.text = '1';
      return;
    }

    final double days = _toDateTime!.difference(_fromDateTime!).inHours / 24;
    final int integerDays = days.floor();
    final String finalDays = integerDays <= 0 ? '1' : integerDays.toString();
    _daysController.text = finalDays;
  }

  Future<void> _selectDateTime(BuildContext context, TextEditingController controller, bool isFrom) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = isFrom ? (_fromDateTime ?? now) : (_toDateTime ?? now);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    final TimeOfDay initialTime = TimeOfDay.fromDateTime(initialDate);

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime == null) return;

    final DateTime combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    controller.text =
    '${combined.day.toString().padLeft(2, '0')}-${combined.month.toString().padLeft(2, '0')}-${combined.year}   ${combined.hour.toString().padLeft(2, '0')}:${combined.minute.toString().padLeft(2, '0')}';

    setState(() {
      if (isFrom) {
        _fromDateTime = combined;
      } else {
        _toDateTime = combined;
      }
      _calculateDays();
    });
  }

  void _submitApplication() {
    if (_selectedLeaveType == null || _reasonController.text.isEmpty || _daysController.text == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a leave type, provide a reason, and ensure valid dates.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Leave submitted for: $_selectedLeaveType (${_daysController.text} days)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _refreshScreen() {
    setState(() {
      _selectedLeaveType = null;
      _fromDateTime = null;
      _toDateTime = null;
      _fromDateController.text = '';
      _toDateController.text = '';
      _reasonController.text = '';
      _daysController.text = '0';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form cleared and data refreshed.')),
      );
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green.shade700;
      case 'Pending':
        return Colors.orange.shade700;
      case 'Rejected':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color appColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Leave Portal'),
        backgroundColor: appColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
              child: Text(
                'STUDENT LEAVE APPLICATION FORM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Text(
              'New Leave Application',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: appColor),
            ),
            const Divider(height: 20, thickness: 2),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Leave Type*',
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                        prefixIcon: Icon(Icons.list_alt, size: 20, color: appColor),
                      ),
                      value: _selectedLeaveType,
                      items: _leaveTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedLeaveType = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDateTimeField(context, 'From Date (HH:MM)', _fromDateController, true)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildDateTimeField(context, 'To Date (HH:MM)', _toDateController, false)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'No. of Days',
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                        prefixIcon: Icon(Icons.timer_sharp, size: 20, color: appColor),
                      ),
                      controller: _daysController,
                      readOnly: true,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Reason*',
                        hintText: 'Enter reason for leave...',
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                        prefixIcon: Icon(Icons.note_alt, size: 20, color: appColor),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _submitApplication,
                          icon: const Icon(Icons.send_rounded),
                          label: const Text('SUBMIT'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appColor,
                            foregroundColor: Colors.white,
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
            const SizedBox(height: 32),
            Text(
              'Previous Leave History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: appColor),
            ),
            const Divider(height: 20, thickness: 2),
            Column(
              children: _previousApplications.map((app) => _buildHistoryCard(app, context)).toList(),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(LeaveApplication app, BuildContext context) {
    String formattedFrom = app.from == null ? 'N/A' :
    '${app.from!.day.toString().padLeft(2, '0')}-${app.from!.month.toString().padLeft(2, '0')}-${app.from!.year} ${app.from!.hour.toString().padLeft(2, '0')}:${app.from!.minute.toString().padLeft(2, '0')}';
    String formattedTo = app.to == null ? 'N/A' :
    '${app.to!.day.toString().padLeft(2, '0')}-${app.to!.month.toString().padLeft(2, '0')}-${app.to!.year} ${app.to!.hour.toString().padLeft(2, '0')}:${app.to!.minute.toString().padLeft(2, '0')}';
    Color statusColor = _getStatusColor(app.status ?? 'Unknown');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    app.status ?? 'N/A',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Reason: ${app.reason ?? 'N/A'}', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)))),
                Text('${(app.numberOfDays ?? 0).toInt()} days', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From:', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                    Text(formattedFrom, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('To:', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                    Text(formattedTo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeField(BuildContext context, String label, TextEditingController controller, bool isFrom) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectDateTime(context, controller, isFrom),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        contentPadding: const EdgeInsets.fromLTRB(12, 16, 0, 16),
        suffixIcon: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, maxWidth: 40),
          icon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
          onPressed: () => _selectDateTime(context, controller, isFrom),
        ),
      ),
    );
  }
}