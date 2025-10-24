import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/ApiEndpoints.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String url;
  final String token;

  const PaymentHistoryScreen({
    super.key,
    required this.url,
    required this.token,
  });

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _paymentItems = [];
  double _totalCollected = 0.0;
  late ApiEndpoints api;

  @override
  void initState() {
    super.initState();
    api = ApiEndpoints(widget.url);
    _fetchPaymentHistory();
  }

  Future<void> _fetchPaymentHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _paymentItems = [];
      _totalCollected = 0.0;
    });
    try {
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({'token': widget.token});

      final resp = await http.post(
        Uri.parse('${widget.url}/feeCollections'),
        headers: headers,
        body: body,
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        _paymentItems = (data['feeCollections'] as List?)
            ?.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList() ?? [];

        double sumAmount(List<Map<String, dynamic>> items) {
          double sum = 0.0;
          for (var item in items) {
            final amountCollected = item["amountCollected"] ?? item["dueAmount"] ?? "";
            final parsed = double.tryParse(amountCollected.toString().replaceAll(',', '').trim()) ?? 0.0;
            sum += parsed;
          }
          return sum;
        }

        _totalCollected = sumAmount(_paymentItems);

        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('Response not OK: ${resp.statusCode}');
      }
    } catch (e, st) {
      print('Error: $e\n$st');
      setState(() {
        _error = "Error fetching payment history: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = Color(0xFF6d2bef);

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
              child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 18, fontWeight: FontWeight.w500)),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: accent,
        title: const Text("Payment History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 15),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: accent.withOpacity(0.06), blurRadius: 10, offset: Offset(0, 4))]
                      ),
                      child: Center(
                        child: FittedBox(
                          child: Text(
                            "Total Collected : Rs. ${_totalCollected.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _paymentItems.isEmpty
                          ? Center(child: Text('No payment history found.', style: TextStyle(color: accent, fontSize: 16, fontWeight: FontWeight.w600)))
                          : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: SingleChildScrollView(  // Add vertical scrolling here
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              columnSpacing: 20,
                              headingRowColor: MaterialStateColor.resolveWith((states) => accent.withOpacity(0.16)),
                              columns: const [
                                DataColumn(label: Text('Semester', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                DataColumn(label: Text('Institution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                DataColumn(label: Text('Particulars', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                DataColumn(label: Text('Collected Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                              ],
                              rows: _paymentItems.map((item) {
                                return DataRow(cells: [
                                  DataCell(Text(item["semester"] ?? "", style: TextStyle(fontSize: 16, color: accent, fontWeight: FontWeight.bold))),
                                  DataCell(Text(item["institution"] ?? "", style: TextStyle(fontSize: 15))),
                                  DataCell(Text(item["particulars"] ?? "", style: TextStyle(fontSize: 15))),
                                  DataCell(Text(item["collectedDate"] ?? "", style: TextStyle(fontSize: 15))),
                                  DataCell(Text("Rs. ${item["amountCollected"] ?? ""}", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade800, fontSize: 16))),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              );
            }
        ),
      ),
    );
  }
}