// subject_detail_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// You must import your actual theme model:
import '../models/theme_model.dart'; // <--- UPDATE THIS PATH AS NEEDED

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
  // Controllers for internals predictor
  final TextEditingController targetController = TextEditingController();

  // Controllers for end-sem predictor
  final TextEditingController expectedInternalsController =
  TextEditingController();
  String selectedGrade = "A";
  String endSemResult = "";

  String internalsPredictorResult = "";

  // --- ### CORRECTED TABLE ### ---
  // This map now correctly matches the image provided.
  static const Map<int, Map<String, int?>> gradeLookupTable = {
    0: {"S": null, "A+": null, "A": null, "B": null, "C": null, "D": 100},
    1: {"S": null, "A+": null, "A": null, "B": null, "C": null, "D": 98},
    2: {"S": null, "A+": null, "A": null, "B": null, "C": null, "D": 96},
    3: {"S": null, "A+": null, "A": null, "B": null, "C": null, "D": 94},
    4: {"S": null, "A+": null, "A": null, "B": null, "C": null, "D": 92},
    5: {"S": null, "A+": null, "A": null, "B": null, "C": 100, "D": 90},
    6: {"S": null, "A+": null, "A": null, "B": null, "C": 98, "D": 88},
    7: {"S": null, "A+": null, "A": null, "B": null, "C": 96, "D": 86},
    8: {"S": null, "A+": null, "A": null, "B": null, "C": 94, "D": 84},
    9: {"S": null, "A+": null, "A": null, "B": null, "C": 92, "D": 82},
    10: {"S": null, "A+": null, "A": null, "B": null, "C": 90, "D": 80},
    11: {"S": null, "A+": null, "A": null, "B": null, "C": 88, "D": 78},
    12: {"S": null, "A+": null, "A": null, "B": null, "C": 86, "D": 76},
    13: {"S": null, "A+": null, "A": null, "B": null, "C": 84, "D": 74},
    14: {"S": null, "A+": null, "A": null, "B": null, "C": 82, "D": 72},
    15: {"S": null, "A+": null, "A": null, "B": null, "C": 80, "D": 70},
    16: {"S": null, "A+": null, "A": null, "B": 100, "C": 78, "D": 68},
    17: {"S": null, "A+": null, "A": null, "B": 98, "C": 76, "D": 66},
    18: {"S": null, "A+": null, "A": null, "B": 96, "C": 74, "D": 64},
    19: {"S": null, "A+": null, "A": null, "B": 94, "C": 72, "D": 62},
    20: {"S": null, "A+": null, "A": null, "B": 92, "C": 70, "D": 60},
    21: {"S": null, "A+": null, "A": null, "B": 90, "C": 68, "D": 58},
    22: {"S": null, "A+": null, "A": null, "B": 88, "C": 66, "D": 56},
    23: {"S": null, "A+": null, "A": null, "B": 86, "C": 64, "D": 54},
    24: {"S": null, "A+": null, "A": null, "B": 84, "C": 62, "D": 52},
    25: {"S": null, "A+": null, "A": 100, "B": 82, "C": 60, "D": 50},
    26: {"S": null, "A+": null, "A": 98, "B": 80, "C": 58, "D": 48},
    27: {"S": null, "A+": null, "A": 96, "B": 78, "C": 56, "D": 46},
    28: {"S": null, "A+": null, "A": 94, "B": 76, "C": 54, "D": 44},
    29: {"S": null, "A+": null, "A": 92, "B": 74, "C": 52, "D": 42},
    30: {"S": null, "A+": null, "A": 90, "B": 72, "C": 50, "D": 40},
    31: {"S": null, "A+": null, "A": 88, "B": 70, "C": 48, "D": 38},
    32: {"S": null, "A+": null, "A": 86, "B": 68, "C": 46, "D": 36},
    33: {"S": null, "A+": null, "A": 84, "B": 66, "C": 44, "D": 34},
    34: {"S": null, "A+": null, "A": 82, "B": 64, "C": 42, "D": 32},
    35: {"S": null, "A+": null, "A": 80, "B": 62, "C": 40, "D": 30},
    36: {"S": null, "A+": 100, "A": 78, "B": 58, "C": 38, "D": 28},
    37: {"S": null, "A+": 98, "A": 76, "B": 56, "C": 36, "D": 26},
    38: {"S": null, "A+": 96, "A": 74, "B": 54, "C": 34, "D": 24},
    39: {"S": null, "A+": 94, "A": 72, "B": 52, "C": 32, "D": 22},
    40: {"S": null, "A+": 92, "A": 70, "B": 52, "C": 30, "D": 20},
    41: {"S": 100, "A+": 90, "A": 68, "B": 50, "C": 28, "D": 18},
    42: {"S": 98, "A+": 88, "A": 66, "B": 48, "C": 26, "D": 16},
    43: {"S": 96, "A+": 86, "A": 64, "B": 46, "C": 24, "D": 14},
    44: {"S": 94, "A+": 84, "A": 62, "B": 44, "C": 22, "D": 12},
    45: {"S": 92, "A+": 82, "A": 60, "B": 42, "C": 20, "D": 10},
    46: {"S": 90, "A+": 80, "A": 58, "B": 40, "C": 18, "D": 8},
    47: {"S": 88, "A+": 78, "A": 56, "B": 38, "C": 16, "D": 6},
    48: {"S": 86, "A+": 76, "A": 54, "B": 36, "C": 14, "D": 4},
    49: {"S": 84, "A+": 74, "A": 52, "B": 34, "C": 12, "D": 2},
    50: {"S": 82, "A+": 72, "A": 50, "B": 32, "C": 10, "D": 0},
  };

  final List<String> gradeKeys = ["S", "A+", "A", "B", "C", "D"];

  double _to20(int markOutOf50) => markOutOf50 * 0.4;

  double computeBestTwoOutOf40(int? cia1, int? cia2, int? cia3) {
    final List<double> list = [];
    if (cia1 != null) list.add(_to20(cia1));
    if (cia2 != null) list.add(_to20(cia2));
    if (cia3 != null) list.add(_to20(cia3));
    if (list.isEmpty) return 0.0;
    list.sort();
    if (list.length == 1) return list[0];
    return list.sublist(max(0, list.length - 2)).reduce((a, b) => a + b);
  }

  double currentInternalsOutOf50() {
    final bestTwo =
    computeBestTwoOutOf40(widget.cia1, widget.cia2, widget.cia3);
    return bestTwo + 10.0;
  }

  @override
  void initState() {
    super.initState();
    targetController.text = "40";
    expectedInternalsController.text =
        currentInternalsOutOf50().toStringAsFixed(1);
  }

  @override
  void dispose() {
    targetController.dispose();
    expectedInternalsController.dispose();
    super.dispose();
  }

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
      width: 92,
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

  void calculateInternalsPrediction() {
    final targetText = targetController.text.trim();
    final int? targetInternal = int.tryParse(targetText);
    if (targetInternal == null) {
      setState(() {
        internalsPredictorResult = "Enter a valid number";
      });
      return;
    }

    final current = currentInternalsOutOf50();
    final diff = targetInternal - current;

    setState(() {
      if (diff <= 0) {
        internalsPredictorResult =
        "You already have ${current.toStringAsFixed(1)} /50. No extra marks needed!";
      } else {
        final diffOutOf50 = (diff / 0.4).round();
        internalsPredictorResult =
        "You need $diffOutOf50 more marks (out of 50) to reach $targetInternal /50.";
      }
    });
  }

  // This function uses the gradeLookupTable
  void calculateEndSemNeeded() {
    final enteredInternalsText = expectedInternalsController.text.trim();
    final enteredInternals = double.tryParse(enteredInternalsText);

    if (enteredInternals == null) {
      setState(() {
        endSemResult = "Enter valid internals (out of 50).";
      });
      return;
    }


    final int internalKey = enteredInternals.round().clamp(0, 50);

    // Check if the internal mark exists in our table
    if (!gradeLookupTable.containsKey(internalKey)) {
      setState(() {
        endSemResult = "Cannot calculate for internal mark $internalKey.";
      });
      return;
    }

    // Get the row (map) for the specified internal mark
    final gradeRow = gradeLookupTable[internalKey]!;

    // Get the required end sem mark for the selected grade
    final int? requiredEndSem = gradeRow[selectedGrade];

    if (requiredEndSem == null) {
      // This means the table had a '-' (null)
      setState(() {
        endSemResult =
        "⚠ Not possible to achieve $selectedGrade grade with $internalKey internals.";
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
          "You need at least $requiredEndSem marks in End Sem to achieve $selectedGrade grade.";
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
    final bestTwoOutOf40 =
    computeBestTwoOutOf40(widget.cia1, widget.cia2, widget.cia3);
    final internalOutOf50 = bestTwoOutOf40 + 10;

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
                            Text(
                              "${internalOutOf50.toStringAsFixed(1)}/50",
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
                                value: (bestTwoOutOf40 / 40).clamp(0.0, 1.0),
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
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // CIA boxes row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ciaBox("CIA 1", widget.cia1, theme),
                    _ciaBox("CIA 2", widget.cia2, theme),
                    _ciaBox("CIA 3", widget.cia3, theme),
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
                        _buildThemedTextField(
                          theme: theme,
                          controller: targetController,
                          labelText: "Target internal (out of 50)",
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
                        _buildThemedTextField(
                          theme: theme,
                          controller: expectedInternalsController,
                          labelText: "Expected Internals (out of 50)",
                          hintText:
                          "Current: ${currentInternalsOutOf50().toStringAsFixed(1)}",
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
                              // Use the new gradeKeys list
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