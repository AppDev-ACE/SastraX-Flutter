import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/ApiEndpoints.dart';

class FeeDueScreen extends StatefulWidget {
  final String url;
  final String token;

  const FeeDueScreen({
    super.key,
    required this.url,
    required this.token,
  });

  @override
  State<FeeDueScreen> createState() => _FeeDueScreenState();
}

class _FeeDueScreenState extends State<FeeDueScreen> {
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _sastraItems = [];
  List<Map<String, dynamic>> _hostelItems = [];
  String _sastraTotal = '0.00';
  String _hostelTotal = '0.00';
  late ApiEndpoints api;

  @override
  void initState() {
    super.initState();
    api = ApiEndpoints(widget.url);
    _fetchDues();
  }

  Future<void> _fetchDues() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _sastraItems = [];
      _hostelItems = [];
      _sastraTotal = '0.00';
      _hostelTotal = '0.00';
    });
    try {
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({'token': widget.token});

      // --- University dues ---
      final uniResp = await http.post(
        Uri.parse(api.sastraDue),
        headers: headers,
        body: body,
      );
      if (uniResp.statusCode == 200) {
        final data = jsonDecode(uniResp.body);
        _sastraItems = (data['sastraDue'] as List?)?.map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e)
        ).where((e) =>
        ((e['sem'] ?? '') as String).trim().isNotEmpty ||
            ((e['feeDetails'] ?? '') as String).trim().isNotEmpty ||
            ((e['dueDate'] ?? '') as String).trim().isNotEmpty ||
            ((e['dueAmount'] ?? '') as String).trim().isNotEmpty
        ).toList() ?? [];
        _sastraTotal = data['totalDue']?.toString() ?? '0.00';
      } else {
        throw Exception('University response not OK: ${uniResp.statusCode}');
      }

      // --- Hostel dues ---
      final hostelResp = await http.post(
        Uri.parse(api.hostelDue),
        headers: headers,
        body: body,
      );
      if (hostelResp.statusCode == 200) {
        final data = jsonDecode(hostelResp.body);
        _hostelItems = (data['hostelDue'] as List?)?.map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e)
        ).where((e) =>
        ((e['sem'] ?? '') as String).trim().isNotEmpty ||
            ((e['feeDetails'] ?? '') as String).trim().isNotEmpty ||
            ((e['dueDate'] ?? '') as String).trim().isNotEmpty ||
            ((e['dueAmount'] ?? '') as String).trim().isNotEmpty
        ).toList() ?? [];
        _hostelTotal = data['totalDue']?.toString() ?? '0.00';
      } else {
        throw Exception('Hostel response not OK: ${hostelResp.statusCode}');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e, st) {
      print('Error: $e\n$st');
      setState(() {
        _error = "Error fetching dues: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6d2bef),
        title: const Text("Fee Due Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildTotalDueCard("University Fee Due", _sastraTotal, const LinearGradient(colors: [Color(0xFF9443e3), Color(0xFF6d2bef)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          _buildTableHeader(),
          ..._renderTableRows(_sastraItems, accent: const Color(0xFF6d2bef)),
          _buildTotalDueCard("Hostel Fee Due", _hostelTotal, const LinearGradient(colors: [Color(0xFFf55951), Color(0xFFff7e67)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          _buildTableHeader(),
          ..._renderTableRows(_hostelItems, accent: Colors.deepOrange),
        ],
      ),
    );
  }

  Widget _buildTotalDueCard(String title, String amount, Gradient gradient) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 26),
      decoration: BoxDecoration(
        gradient: gradient, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 19)),
          const SizedBox(height: 12),
          Text("Rs. $amount", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      margin: const EdgeInsets.only(left: 21, right: 21, bottom: 6, top: 10),
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!, width: 1.1),
      ),
      child: Row(
        children: const [
          Expanded(flex: 2, child: Text('Sem.', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 4, child: Text('Fee Details', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text('Due Amount', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  List<Widget> _renderTableRows(List<Map<String, dynamic>> items, {required Color accent}) {
    if (items.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Text('No dues found.', style: TextStyle(color: accent, fontSize: 15)),
        )
      ];
    }

    return items.map((item) {
      String sem = item["sem"] ?? "";
      String feeDetails = item["feeDetails"] ?? "";
      String dueDate = item["dueDate"] ?? "";
      String amount = item["dueAmount"] ?? "";

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(sem, style: TextStyle(fontWeight: FontWeight.bold, color: accent))),
            Expanded(flex: 4, child: Text(feeDetails, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
            Expanded(flex: 3, child: Text(dueDate, style: TextStyle(color: accent, fontSize: 14))),
            Expanded(flex: 3, child: Text("Rs. $amount", style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      );
    }).toList();
  }
}