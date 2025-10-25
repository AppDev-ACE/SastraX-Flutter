// subject_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// You must import your actual theme model:
import '../models/theme_model.dart'; // <--- UPDATE THIS PATH AS NEEDED

class SubjectDetailPage extends StatefulWidget {
  final String subjectName;
  final String subjectCode;
  final int maxInternals; // This will still be 50, but we'll ignore it
  final int maxEndSem;

  // Parameters are still accepted, but 'assignment' will be ignored
  final int? cia1;
  final int? cia1Max;
  final int? cia2;
  final int? cia2Max;
  final int? cia3;
  final int? cia3Max;
  final int? assignment;
  final int? assignmentMax;

  const SubjectDetailPage({
    super.key,
    required this.subjectName,
    required this.subjectCode,
    required this.maxInternals,
    required this.maxEndSem,
    this.cia1,
    this.cia1Max,
    this.cia2,
    this.cia2Max,
    this.cia3,
    this.cia3Max,
    this.assignment,
    this.assignmentMax,
  });

  @override
  State<SubjectDetailPage> createState() => _SubjectDetailPageState();
}

class _SubjectDetailPageState extends State<SubjectDetailPage> {
  // Controllers for internals predictor
  final TextEditingController targetController = TextEditingController();

  // Controllers for end-sem predictor
  final TextEditingController expectedInternalsController =
  TextEditingController();
  String selectedGrade = "A";
  String endSemResult = "";

  String internalsPredictorResult = "";

  // ... (gradeLookupTable remains the same, we will scale to use it) ...
  static const Map<int, Map<String, int?>> gradeLookupTable = {
    // (Table data is large and unchanged, so it's omitted for brevity)
    0: {"S": null, "A+": null, "A": null, "B": null, "C": null, "D": 100},
    // ... (rest of the table)
    50: {"S": 82, "A+": 72, "A": 50, "B": 32, "C": 10, "D": 0},
  };


  final List<String> gradeKeys = ["S", "A+", "A", "B", "C", "D"];

  // Scaling logic remains the same
  double _scaleMark(int? mark, int? maxMark, double targetMax) {
    if (mark == null || maxMark == null || maxMark == 0) return 0.0;
    double scaled = (mark.toDouble() / maxMark.toDouble()) * targetMax;
    return scaled.clamp(0.0, targetMax); // Ensure it doesn't exceed target
  }

  // CHANGE 1: Renamed and simplified function. No assignment, total out of 40.
  /// Calculates total internals out of 40 (Best 2 CIAs).
  Map<String, double> calculateInternalsOutOf40({
    int? cia1, int? cia1Max,
    int? cia2, int? cia2Max,
    int? cia3, int? cia3Max,
    // Assignment parameters are no longer needed
  }) {
    // Scale all CIAs to 20
    final List<double> ciaScoresOutOf20 = [];
    if (cia1 != null) ciaScoresOutOf20.add(_scaleMark(cia1, cia1Max ?? 20, 20.0));
    if (cia2 != null) ciaScoresOutOf20.add(_scaleMark(cia2, cia2Max ?? 20, 20.0));
    if (cia3 != null) ciaScoresOutOf20.add(_scaleMark(cia3, cia3Max ?? 20, 20.0));

    // Sort CIAs descending to find best two
    ciaScoresOutOf20.sort((a, b) => b.compareTo(a));

    double bestTwoCIAsOutOf40 = 0.0;
    if (ciaScoresOutOf20.isNotEmpty) bestTwoCIAsOutOf40 += ciaScoresOutOf20[0]; // Add best
    if (ciaScoresOutOf20.length > 1) bestTwoCIAsOutOf40 += ciaScoresOutOf20[1]; // Add second best

    // REMOVED: Assignment scaling
    // REMOVED: Total calculation including assignment

    return {
      'total': bestTwoCIAsOutOf40.clamp(0.0, 40.0), // Ensure total doesn't exceed 40
    };
  }


  // CHANGE 2: Renamed function to reflect new total
  double currentInternalsOutOf40() {
    final internals = calculateInternalsOutOf40(
      cia1: widget.cia1, cia1Max: widget.cia1Max,
      cia2: widget.cia2, cia2Max: widget.cia2Max,
      cia3: widget.cia3, cia3Max: widget.cia3Max,
    );
    return internals['total']!;
  }

  @override
  void initState() {
    super.initState();
    // CHANGE 3: Default target is now 35 out of 40
    targetController.text = "35";
    // This call is now correct and gets the total out of 40
    expectedInternalsController.text =
        currentInternalsOutOf40().toStringAsFixed(1);
  }

  @override
  void dispose() {
    targetController.dispose();
    expectedInternalsController.dispose();
    super.dispose();
  }

  // CHANGE 4: Box width increased to 96 to fill space
  Widget _ciaBox(String label, int? value, ThemeProvider theme) {
    final isDark = theme.isDarkMode;
    final bool hasValue = value != null;

    Color getBackgroundColor() {
      if (isDark) {
        return hasValue
            ? AppTheme.darkSurface
            : AppTheme.darkBackground.withOpacity(0.7);
      } else {
        return hasValue ? Colors.white : Colors.blue.shade50;
      }
    }
    Color getBorderColor() {
      if (isDark) {
        return hasValue
            ? AppTheme.neonBlue
            : AppTheme.neonBlue.withOpacity(0.2);
      } else {
        return Colors.blue.shade200;
      }
    }
    Color getTextColor() {
      if (isDark) {
        return hasValue ? Colors.white : Colors.white54;
      } else {
        return hasValue ? Colors.black87 : Colors.blueGrey;
      }
    }

    return Container(
      width: 96, // Increased width
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: getBackgroundColor(),
        border: Border.all(color: getBorderColor()),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value?.toString() ?? label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: getTextColor(),
        ),
      ),
    );
  }

  /// ---------------------------
  /// CHANGE 5: Updated internals predictor logic for 40 marks
  /// ---------------------------
  void calculateInternalsPrediction() {
    // Target expected total internal (out of 40)
    final targetText = targetController.text.trim();
    final double? target = double.tryParse(targetText);
    if (target == null) {
      setState(() {
        internalsPredictorResult = "Enter a valid target number (out of 40).";
      });
      return;
    }

    // Clamp sensible target bounds (Max internals is 40)
    if (target < 0 || target > 40) { // Hardcoded to 40
      setState(() {
        internalsPredictorResult =
        "Target must be between 0 and 40.";
      });
      return;
    }

    // REMOVED: Assumed assignment marks

    // Get all existing *scaled* CIA marks
    final List<double> scaledCias = [];
    if (widget.cia1 != null) scaledCias.add(_scaleMark(widget.cia1, widget.cia1Max, 20.0));
    if (widget.cia2 != null) scaledCias.add(_scaleMark(widget.cia2, widget.cia2Max, 20.0));
    if (widget.cia3 != null) scaledCias.add(_scaleMark(widget.cia3, widget.cia3Max, 20.0));

    // Current best-two contribution (using available *scaled* CIAs)
    scaledCias.sort((a, b) => b.compareTo(a)); // Sort descending
    double currentBestTwoScaled = 0.0;
    if (scaledCias.isNotEmpty) currentBestTwoScaled += scaledCias[0];
    if (scaledCias.length > 1) currentBestTwoScaled += scaledCias[1];


    // Current total *is* just the best two
    final double currentTotal = currentBestTwoScaled;

    // If all three CIAs are present -> you can't improve via CIAs
    final int filledCount = scaledCias.length;

    if (filledCount == 3) {
      // All CIAs done: check if target already met or impossible
      if (currentTotal >= target) {
        setState(() {
          internalsPredictorResult =
          "You already have ${currentTotal.toStringAsFixed(1)}/40 — target achieved.";
        });
      } else {
        setState(() {
          internalsPredictorResult =
          "All CIAs are done. Max internals is ${currentTotal.toStringAsFixed(1)}/40. Target ${target.toStringAsFixed(1)} is not achievable.";
        });
      }
      return;
    }

    // ---
    // Find mark 'x' (out of 20) needed in the *next* CIA
    // ---

    // Helper function to compute total (out of 40) given a candidate x (out of 20)
    double totalWithX(double x) {
      // We assume the next CIA is out of 20
      final double scaledX = _scaleMark(x.round(), 20, 20.0);

      final List<double> picks = List.from(scaledCias);
      picks.add(scaledX);

      picks.sort((a, b) => b.compareTo(a)); // descending

      double sumTopTwoScaled = 0.0;
      if (picks.isNotEmpty) sumTopTwoScaled += picks[0];
      if (picks.length > 1) sumTopTwoScaled += picks[1];

      return sumTopTwoScaled; // Total is just the sum
    }

    // Quick check: if even with perfect next CIA (20/20) we can't reach target
    final double bestPossibleWithPerfectNext = totalWithX(20.0);
    if (bestPossibleWithPerfectNext < target) {
      setState(() {
        internalsPredictorResult =
        "Even with 20/20 in the next CIA, max possible internals = ${bestPossibleWithPerfectNext.toStringAsFixed(1)}/40. Target ${target.toStringAsFixed(1)} is not achievable.";
      });
      return;
    }

    // If current total already meets target
    if (currentTotal >= target) {
      setState(() {
        internalsPredictorResult =
        "You already have ${currentTotal.toStringAsFixed(1)}/40 — target achieved. No extra marks needed in the next CIA.";
      });
      return;
    }

    // Binary search for the minimal x in [0, 20]
    double lo = 0.0;
    double hi = 20.0; // We are solving for a mark out of 20
    double mid = hi;
    for (int i = 0; i < 40; i++) {
      mid = (lo + hi) / 2;
      if (totalWithX(mid) >= target) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    final double required = hi;

    setState(() {
      final requiredRounded = required <= 0 ? 0 : required;
      internalsPredictorResult =
      "You need at least ${requiredRounded.toStringAsFixed(1)}/20 in the next CIA to reach ${target.toStringAsFixed(1)}/40 internal.";
    });
  }

  // CHANGE 6: Updated End Sem logic to scale from 40 to 50 for lookup
  void calculateEndSemNeeded() {
    final enteredInternalsText = expectedInternalsController.text.trim();
    final enteredInternals = double.tryParse(enteredInternalsText);

    if (enteredInternals == null) {
      setState(() {
        endSemResult = "Enter valid internals (out of 40).";
      });
      return;
    }

    // Add bounds check for 40
    if (enteredInternals < 0 || enteredInternals > 40) {
      setState(() {
        endSemResult = "Internals must be between 0 and 40.";
      });
      return;
    }

    // --- NEW SCALING STEP ---
    // Scale the 0-40 mark to 0-50 to use the lookup table
    final double scaledTo50 = (enteredInternals / 40.0) * 50.0;
    // The key is the scaled mark, rounded and clamped
    final int internalKey = scaledTo50.round().clamp(0, 50);
    // --- END SCALING STEP ---


    // Check if the *scaled* internal mark exists in our table
    if (!gradeLookupTable.containsKey(internalKey)) {
      setState(() {
        endSemResult = "Cannot calculate for internal mark $enteredInternalsText (scaled to $internalKey).";
      });
      return;
    }

    // Get the row (map) for the specified *scaled* internal mark
    final gradeRow = gradeLookupTable[internalKey]!;

    // Get the required end sem mark for the selected grade
    final int? requiredEndSem = gradeRow[selectedGrade];

    if (requiredEndSem == null) {
      // This means the table had a '-' (null)
      setState(() {
        endSemResult =
        "⚠ Not possible to achieve $selectedGrade grade with $enteredInternalsText/40 internals (scaled to $internalKey/50).";
      });
    } else {
      // Check if the required mark is over the max
      if (requiredEndSem > widget.maxEndSem) {
        setState(() {
          endSemResult =
          "⚠ Not possible to achieve $selectedGrade grade. (Needs $requiredEndSem)";
        });
      } else {
        setState(() {
          endSemResult =
          "You need at least $requiredEndSem marks in End Sem to achieve $selectedGrade grade (with $enteredInternalsText/40 internals).";
        });
      }
    }
  }

  Widget _buildThemedTextField({
    required ThemeProvider theme,
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType keyboardType = TextInputType.number,
  }) {
    final isDark = theme.isDarkMode;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        isDense: true,
        labelStyle:
        TextStyle(color: isDark ? Colors.white70 : Colors.grey[700]),
        hintStyle:
        TextStyle(color: isDark ? Colors.white54 : Colors.grey[500]),
        enabledBorder: OutlineInputBorder(
          borderSide:
          BorderSide(color: isDark ? Colors.white54 : Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? AppTheme.neonBlue : AppTheme.primaryBlue,
            width: 2,
          ),
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildThemedButton({
    required ThemeProvider theme,
    required VoidCallback onPressed,
    required String text,
  }) {
    final isDark = theme.isDarkMode;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? AppTheme.neonBlue : AppTheme.primaryBlue,
        foregroundColor: isDark ? Colors.black : Colors.white,
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }

  Widget _buildResultBox(String text, ThemeProvider theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.isDarkMode
            ? AppTheme.darkBackground.withOpacity(0.7)
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // CHANGE 7: Call renamed function
    final internalMarks = calculateInternalsOutOf40(
      cia1: widget.cia1, cia1Max: widget.cia1Max,
      cia2: widget.cia2, cia2Max: widget.cia2Max,
      cia3: widget.cia3, cia3Max: widget.cia3Max,
    );
    // Total is out of 40
    final totalOutOf40 = internalMarks['total']!;

    // REMOVED: assignmentScaled and bestTwoCIAs variables


    return Consumer<ThemeProvider>(
      builder: (_, theme, __) {
        final isDark = theme.isDarkMode;

        return Scaffold(
          backgroundColor:
          isDark ? AppTheme.darkBackground : Colors.grey[100],
          appBar: AppBar(
            title: Text(widget.subjectName),
            backgroundColor:
            isDark ? AppTheme.darkBackground : AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject header card
                Card(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  elevation: isDark ? 0 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isDark
                        ? BorderSide(
                      color: AppTheme.neonBlue.withOpacity(0.5),
                      width: 1,
                    )
                        : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.subjectName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppTheme.neonBlue
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Code: ${widget.subjectCode}",
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // CHANGE 8: Display total out of 40
                            Text(
                              "${totalOutOf40.toStringAsFixed(1)}/40",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 140,
                              child: LinearProgressIndicator(
                                // CHANGE 9: Progress bar value scaled to 40
                                value: (totalOutOf40 / 40.0).clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: isDark
                                    ? AppTheme.darkBackground.withOpacity(0.7)
                                    : Colors.blue.shade50,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark
                                      ? AppTheme.neonBlue
                                      : AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // CHANGE 10: Simplified breakdown text
                            Text(
                              "Best 2 CIAs: ${totalOutOf40.toStringAsFixed(1)}/40",
                              style: TextStyle( color: isDark ? Colors.white70 : Colors.grey[700], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // CHANGE 11: CIA boxes row (Assign box removed)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ciaBox("CIA 1", widget.cia1, theme),
                    _ciaBox("CIA 2", widget.cia2, theme),
                    _ciaBox("CIA 3", widget.cia3, theme),
                    // REMOVED: _ciaBox("Assign", widget.assignment, theme),
                  ],
                ),
                const SizedBox(height: 20),

                // Internals Predictor Card
                Card(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  elevation: isDark ? 0 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isDark
                        ? BorderSide(
                      color: AppTheme.neonBlue.withOpacity(0.5),
                      width: 1,
                    )
                        : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "CIA Internals Predictor",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                            isDark ? AppTheme.neonBlue : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // CHANGE 12: Corrected label
                        _buildThemedTextField(
                          theme: theme,
                          controller: targetController,
                          labelText: "Target internal (out of 40)",
                        ),
                        const SizedBox(height: 12),
                        _buildThemedButton(
                          theme: theme,
                          onPressed: calculateInternalsPrediction,
                          text: "Calculate",
                        ),
                        if (internalsPredictorResult.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildResultBox(internalsPredictorResult, theme),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // End Sem Marks Predictor Card
                Card(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  elevation: isDark ? 0 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isDark
                        ? BorderSide(
                      color: AppTheme.neonBlue.withOpacity(0.5),
                      width: 1,
                    )
                        : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "End Sem Marks Predictor",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                            isDark ? AppTheme.neonBlue : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // CHANGE 13: Corrected label and hint
                        _buildThemedTextField(
                          theme: theme,
                          controller: expectedInternalsController,
                          labelText: "Expected Internals (out of 40)",
                          hintText:
                          "Current: ${currentInternalsOutOf40().toStringAsFixed(1)}",
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              "Desired Grade: ",
                              style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black),
                            ),
                            const SizedBox(width: 10),
                            DropdownButton<String>(
                              value: selectedGrade,
                              style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black),
                              dropdownColor:
                              isDark ? AppTheme.darkSurface : Colors.white,
                              iconEnabledColor:
                              isDark ? Colors.white70 : Colors.grey[700],
                              items: gradeKeys
                                  .map((g) => DropdownMenuItem<String>(
                                value: g,
                                child: Text(g,
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black)),
                              ))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedGrade = val!;
                                });
                              },
                            ),
                            const Spacer(),
                            _buildThemedButton(
                              theme: theme,
                              onPressed: calculateEndSemNeeded,
                              text: "Calculate",
                            ),
                          ],
                        ),
                        if (endSemResult.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildResultBox(endSemResult, theme),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}