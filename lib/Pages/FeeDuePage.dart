import 'package:flutter/material.dart';

void main() => runApp(const FeeDueApp());

class FeeDueApp extends StatelessWidget {
  const FeeDueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fee Dues',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const FeeDuePage(),
    );
  }
}

class FeeDuePage extends StatelessWidget {
  const FeeDuePage({super.key});

  final List<Map<String, dynamic>> feeDetails = const [
    {"type": "Tuition Fee", "amount": 25000},
    {"type": "Breakage Fee", "amount": 2000},
    {"type": "Examination Fee", "amount": 1500},
    {"type": "Fine", "amount": 500},
    {"type": "Sports & Games", "amount": 1000},
  ];

  @override
  Widget build(BuildContext context) {
    final total = feeDetails.fold(0, (sum, item) => sum + item["amount"] as int);
    final scheme = Theme.of(context).colorScheme;

    Widget buildCard(String title, int amount, {bool highlight = false}) {
      return Card(
        color: highlight ? scheme.primaryContainer : null,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          title: Text(
            title,
            style: TextStyle(fontWeight: highlight ? FontWeight.bold : FontWeight.w600),
          ),
          trailing: Text(
            "₹ $amount",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: scheme.primary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Fee Dues")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...feeDetails.map((fee) => buildCard(fee["type"], fee["amount"])),
          buildCard("Total Pending Fees", total, highlight: true),
        ],
      ),
    );
  }
}
