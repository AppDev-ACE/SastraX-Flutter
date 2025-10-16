import 'package:flutter/material.dart';

class SubjectDetailPage extends StatefulWidget {
  final String subjectName;
  final String subjectCode;
  final int maxInternals;
  final int maxEndSem;
  final int? cia1;
  final int? cia2;
  final int? cia3;

  const SubjectDetailPage({
    Key? key,
    required this.subjectName,
    required this.subjectCode,
    required this.maxInternals,
    required this.maxEndSem,
    this.cia1,
    this.cia2,
    this.cia3,
  }) : super(key: key);

  @override
  State<SubjectDetailPage> createState() => _SubjectDetailPageState();
}

class _SubjectDetailPageState extends State<SubjectDetailPage> {
  final TextEditingController targetController = TextEditingController();
  final TextEditingController assignmentController = TextEditingController();
  final TextEditingController gradeController = TextEditingController();

  String result = "";

  // Simple grade cutoffs
  final Map<String, int> gradeCutoffs = {
    "S": 90,
    "A+": 80,
    "A": 70,
    "B": 60,
    "C": 50,
    "D": 40,
  };

  int? calculateRequiredEndSem(int internals, String grade) {
    if (!gradeCutoffs.containsKey(grade)) return null;
    int totalMax = widget.maxInternals + widget.maxEndSem;
    int requiredTotal = (gradeCutoffs[grade]! * totalMax / 100).ceil();
    int requiredEndSem = requiredTotal - internals;
    if (requiredEndSem > widget.maxEndSem) return null;
    return requiredEndSem < 0 ? 0 : requiredEndSem;
  }

  void _showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subjectName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Code: ${widget.subjectCode}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            // Show CIA boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCiaBox("CIA 1", widget.cia1),
                _buildCiaBox("CIA 2", widget.cia2),
                _buildCiaBox("CIA 3", widget.cia3),
              ],
            ),

            const SizedBox(height: 30),

            // Buttons
            ElevatedButton(
              onPressed: () {
                // Internals predictor logic placeholder
                _showMessage("Internals Predictor",
                    "👉 Logic for CIA marks prediction goes here.");
              },
              child: const Text("CIA Internals Predictor"),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                // End sem predictor logic placeholder
                int internals =
                    (widget.cia1 ?? 0) + (widget.cia2 ?? 0) + (widget.cia3 ?? 0);
                String grade = "A"; // example
                int? needed = calculateRequiredEndSem(internals, grade);
                if (needed == null) {
                  _showMessage("End Sem Predictor",
                      "⚠ Not possible to achieve $grade grade.");
                } else {
                  _showMessage("End Sem Predictor",
                      "👉 You need at least $needed marks in End Sem for $grade grade.");
                }
              },
              child: const Text("End Sem Marks Predictor"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCiaBox(String label, dynamic value) {
    return Container(
      width: 80,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value?.toString() ?? label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}