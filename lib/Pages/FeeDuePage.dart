import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/ApiEndpoints.dart';

class FeeDueScreen extends StatefulWidget {
  final String url;
  final String token;
  final String regNo;

  const FeeDueScreen({
    super.key,
    required this.url,
    required this.token,
    required this.regNo,
  });

  @override
  State<FeeDueScreen> createState() => _FeeDueScreenState();
}

class _FeeDueScreenState extends State<FeeDueScreen> {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _sastraDue;
  Map<String, dynamic>? _hostelDue;
  late final ApiEndpoints api;

  @override
  void initState() {
    super.initState();
    api = ApiEndpoints(widget.url);
    _fetchDues();
  }

  Future<Map<String, dynamic>> _fetchDueApi(String endpoint) async {
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'token': widget.token, 'regNo': widget.regNo});
    final response = await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: body,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      return {};
    } else {
      throw Exception('Failed to load FeeDue: ${response.statusCode}');
    }
  }

  Future<void> _fetchDues() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _sastraDue = null;
      _hostelDue = null;
    });
    try {
      final dues = await Future.wait([
        _fetchDueApi(api.sastraDue),
        _fetchDueApi(api.hostelDue),
      ]);
      setState(() {
        _sastraDue = dues[0];
        _hostelDue = dues[1];
        _isLoading = false;
      });
    } catch (e) {
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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: _fetchDues, child: const Text("Retry"))
              ],
            ),
          ),
        ),
      );
    }

    final sastraTotal = _parseDouble(_sastraDue?["totalSastraDue"]) ?? 0.0;
    final List sastraItems = _extractList(_sastraDue, "dueDetails");

    final hostelTotal = _parseDouble(_hostelDue?["totalDue"]) ?? 0.0;
    final List hostelItems = _extractList(_hostelDue, "hostelDue");

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
          // SASTRA Due Section
          _buildTotalDueCard(
            title: "University Fee Due",
            amount: sastraTotal,
            gradient: const LinearGradient(
              colors: [Color(0xFF9443e3), Color(0xFF6d2bef)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          ..._renderDueList(sastraItems, accent: const Color(0xFF6d2bef)),
          // Hostel Due Section
          _buildTotalDueCard(
            title: "Hostel Fee Due",
            amount: hostelTotal,
            gradient: const LinearGradient(
              colors: [Color(0xFFf55951), Color(0xFFff7e67)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          ..._renderDueList(hostelItems, accent: Colors.deepOrange),
        ],
      ),
    );
  }

  Widget _buildTotalDueCard({
    required String title,
    required double amount,
    required Gradient gradient,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 26),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.08),
            blurRadius: 18, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 19),
          ),
          const SizedBox(height: 12),
          Text(
            "Rs. ${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}",
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  List<Widget> _renderDueList(List items, {required Color accent}) {
    if (items.isEmpty) {
      return [

      ];
    }

    return items.map((item) {
      String name = item["name"] ?? item["title"] ?? "Due Item";
      String dueDate = item["dueDate"] ??
                 item["date"] ??
                 item["due_date"] ??
                 item["duedate"] ??
                 item["DueDate"] ??
                 "";

      String amount = item["amount"]?.toString() ?? item["due"]?.toString() ?? "";
      return Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accent.withOpacity(0.3), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 6, height: 38,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: accent,
                      )),
                    if (dueDate.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "Due: $dueDate",
                          style: TextStyle(fontSize: 12, color: accent.withOpacity(0.7)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Rs. $amount",
                style: TextStyle(
                  fontSize: 15, color: accent, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // Helper for safer numeric parsing
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '').replaceAll('Rs.', '').trim());
  }

  // Helper for list extraction
  List _extractList(Map<String, dynamic>? root, String key) {
    if (root == null) return [];
    final value = root[key];
    if (value is List) return value;
    return [];
  }
}