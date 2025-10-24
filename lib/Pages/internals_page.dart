// internals_page.dart
import 'dart:convert'; // For jsonDecode
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http; // For making HTTP requests
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Import Firestore
import 'subjectDetailPage.dart'; // Make sure this import is correct
import 'dart:math'; // For max()
import '../models/theme_model.dart'; // Make sure this import is correct
import '../services/ApiEndpoints.dart'; // Make sure this import is correct

class InternalsPage extends StatefulWidget {
  final String token;
  final String url;
  final String regNo;

  const InternalsPage({
    Key? key,
    required this.token,
    required this.url,
    required this.regNo,
  }) : super(key: key);

  @override
  State<InternalsPage> createState() => _InternalsPageState();
}

class _InternalsPageState extends State<InternalsPage> {
  // State variables
  bool _isLoading = true;
  String? _error;
  List<dynamic>? _ciaMarksData; // Holds raw data from API or Firestore
  late final ApiEndpoints api; // To get API URLs

  @override
  void initState() {
    super.initState();
    api = ApiEndpoints(widget.url); // Initialize API endpoint helper
    _loadData(); // Load data on init
  }

  /// Loads data, checking Firestore first, then API if needed.
  Future<void> _loadData() async {
    if (!mounted) return;
    print("InternalsPage: Starting _loadData...");
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Check Firestore first
      print("InternalsPage: Checking Firestore for existing data...");
      final docRef = FirebaseFirestore.instance.collection('studentDetails').doc(widget.regNo);
      final docSnapshot = await docRef.get().timeout(const Duration(seconds: 5));

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        // Check if the key exists and if the data is a non-empty list
        if (data != null && data.containsKey('ciaWiseInternalMarks') && data['ciaWiseInternalMarks'] is List && (data['ciaWiseInternalMarks'] as List).isNotEmpty) {
          print("InternalsPage: Found non-empty data in Firestore. Using it.");
          if (mounted) {
            setState(() {
              _ciaMarksData = data['ciaWiseInternalMarks'] as List<dynamic>?;
              _isLoading = false;
            });
          }
          return; // Stop here, data loaded from Firestore
        } else {
          print("InternalsPage: Data in Firestore is empty or missing key. Will fetch from API.");
        }
      } else {
        print("InternalsPage: Firestore document doesn't exist. Will fetch from API.");
      }

      // 2. If Firestore check didn't return, fetch from API
      await _fetchFromApi();

    } catch (e, stackTrace) {
      print("InternalsPage: Error during initial data load: $e\n$stackTrace");
      if (mounted) {
        setState(() {
          _error = "Failed to load initial data.\nError: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }


  /// Fetches data specifically from the API. Used for initial load failure or refresh.
  Future<void> _fetchFromApi() async {
    if (!mounted) return Future.value();

    // This was the fix from before: removing the block that prevented initial fetch.

    print("InternalsPage: Starting _fetchFromApi...");
    setState(() {
      _isLoading = true; // Show loading indicator for refresh
      _error = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      print("InternalsPage: Fetching internals from API with token: ${widget.token.substring(0, min(10, widget.token.length))}...");
      final response = await http
          .post(
        Uri.parse(api.ciaWiseInternalMarks),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': widget.token}),
      )
          .timeout(const Duration(seconds: 45));

      if (!mounted) return;

      print("InternalsPage: API Response Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print("InternalsPage: API fetch successful. Setting state.");
          setState(() {
            _ciaMarksData = data['marksData'] as List<dynamic>?;
            _isLoading = false;
            _error = null;
          });
        } else {
          print("InternalsPage: API reported success=false. Message: ${data['message']}");
          throw Exception(data['message'] ?? 'API failed to load marks');
        }
      } else {
        print("InternalsPage: HTTP error occurred. Status: ${response.statusCode}");
        throw Exception('Server error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e, stackTrace) {
      print("InternalsPage: Error caught in _fetchFromApi: $e\n$stackTrace");
      if (mounted) {
        setState(() {
          _error = _ciaMarksData == null || _ciaMarksData!.isEmpty
              ? "Failed to fetch marks.\nPlease pull down to refresh.\nError: ${e.toString()}"
              : "Failed to refresh marks.\nError: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  /// Helper to parse mark strings (handles decimals, rounds them). Returns int?.
  int? _parseMark(String? markStr) {
    if (markStr == null) return null;
    final double? markDouble = double.tryParse(markStr.trim().replaceAll(RegExp(r'[^\d.]'), ''));
    if (markDouble == null) { return null; } // Handle "AB", etc.
    return markDouble.round(); // Round 18.40 -> 18
  }

  /// Helper to parse max mark strings. Returns int?.
  int? _parseMaxMark(String? markStr) {
    if (markStr == null) return null;
    final double? markDouble = double.tryParse(markStr.trim().replaceAll(RegExp(r'[^\d.]'), ''));
    if (markDouble == null) { return null; }
    return markDouble.round(); // Usually whole numbers like 20 or 50
  }

  /// Transforms API data, now includes Assignment mark.
  List<Map<String, dynamic>> _processMarksData(List<dynamic>? rawMarks) {
    if (rawMarks == null || rawMarks.isEmpty) { return []; }

    final Map<String, Map<String, dynamic>> groupedSubjects = {};

    for (final item in rawMarks) {
      if (item is! Map) continue;

      final String? subjectCode = item['subjectCode'];
      final String? subjectName = item['subjectName'];
      final String? component = item['component'];
      final int? mark = _parseMark(item['marksObtained']);
      final int? maxMark = _parseMaxMark(item['maxMarks']); // Parse max marks

      if (subjectCode == null || subjectName == null || component == null) continue;

      // Initialize subject map if not present
      groupedSubjects.putIfAbsent( subjectCode, () => {
        "name": subjectName,
        "code": subjectCode,
        "maxInternals": 50,
        "maxEndSem": 100,
        "cia1": null, "cia1_max": 20, // Default to 20 if not provided
        "cia2": null, "cia2_max": 20,
        "cia3": null, "cia3_max": 20,
        "assignment": null,
        "assignment_max": 10, // Default to 10 if not provided
      },
      );

      final String lowerComponent = component.toLowerCase();

      if (lowerComponent.contains("cia 3") || lowerComponent.contains("cia iii") || lowerComponent.contains("3rd mid-term")) {
        groupedSubjects[subjectCode]!["cia3"] = mark;
        if (maxMark != null) groupedSubjects[subjectCode]!["cia3_max"] = maxMark;
      } else if (lowerComponent.contains("cia 2") || lowerComponent.contains("cia ii") || lowerComponent.contains("2nd mid-term")) {
        groupedSubjects[subjectCode]!["cia2"] = mark;
        if (maxMark != null) groupedSubjects[subjectCode]!["cia2_max"] = maxMark;
      } else if (lowerComponent.contains("cia 1") || lowerComponent.contains("cia i") || lowerComponent.contains("1st mid-term")) {
        groupedSubjects[subjectCode]!["cia1"] = mark;
        if (maxMark != null) groupedSubjects[subjectCode]!["cia1_max"] = maxMark;
      }
      else if (lowerComponent.contains("assignment")) {
        groupedSubjects[subjectCode]!["assignment"] = mark;
        if (maxMark != null) groupedSubjects[subjectCode]!["assignment_max"] = maxMark;
      }
    }
    return groupedSubjects.values.toList();
  }


  /// Scales a mark to a target max value.
  double _scaleMark(int? mark, int? maxMark, double targetMax) {
    if (mark == null || maxMark == null || maxMark == 0) return 0.0;
    double scaled = (mark.toDouble() / maxMark.toDouble()) * targetMax;
    return scaled.clamp(0.0, targetMax); // Ensure it doesn't exceed target
  }


  /// Calculates total internals out of 50.
  Map<String, double> calculateInternalsOutOf50({
    int? cia1, int? cia1Max,
    int? cia2, int? cia2Max,
    int? cia3, int? cia3Max,
    int? assignment, int? assignmentMax
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

    // Scale assignment mark to be out of 10
    double assignmentOutOf10 = _scaleMark(assignment, assignmentMax ?? 10, 10.0);

    double totalOutOf50 = bestTwoCIAsOutOf40 + assignmentOutOf10;

    return {
      'total': totalOutOf50.clamp(0.0, 50.0), // Ensure total doesn't exceed 50
      'assignment_scaled': assignmentOutOf10,
      'best_two_cias': bestTwoCIAsOutOf40,
    };
  }


  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> subjects = _processMarksData(_ciaMarksData);

    return Consumer<ThemeProvider>(
      builder: (_, theme, __) {
        final isDark = theme.isDarkMode;
        final primaryColor = isDark ? AppTheme.neonBlue : AppTheme.primaryBlue;

        Widget bodyContent;
        // --- Loading / Error / Empty States ---
        if (_isLoading && _ciaMarksData == null) {
          bodyContent = Center( child: CircularProgressIndicator( color: primaryColor, ), );
        } else if (_error != null && subjects.isEmpty) {
          bodyContent = Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: isDark ? Colors.red[300] : Colors.red[700], size: 40),
                  const SizedBox(height: 10),
                  Text( _error!, style: TextStyle(color: isDark ? Colors.red[300] : Colors.red[700]), textAlign: TextAlign.center, ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _fetchFromApi, // Retry triggers API fetch
                    child: const Text('Retry'),
                    style: ElevatedButton.styleFrom( backgroundColor: primaryColor, foregroundColor: isDark ? Colors.black : Colors.white ),
                  ),
                ],
              ),
            ),
          );
        } else if (!_isLoading && subjects.isEmpty) {
          bodyContent = Center( child: Text( "No internal marks found.", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54), ), );
        } else {
          // --- Data List ---
          bodyContent = ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            itemCount: subjects.length + (_error != null && subjects.isNotEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              // Error Banner
              if (_error != null && subjects.isNotEmpty && index == 0) {
                return Container(
                  color: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_error!, style: TextStyle(color: Colors.white, fontSize: 13))),
                      TextButton(
                        onPressed: () => setState(() => _error = null),
                        child: Text('DISMISS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                );
              }
              final subjectIndex = _error != null && subjects.isNotEmpty ? index - 1 : index;
              if (subjectIndex < 0 || subjectIndex >= subjects.length) return const SizedBox.shrink();

              final subject = subjects[subjectIndex];
              // Extract marks
              final cia1 = subject["cia1"] as int?;
              final cia1Max = subject["cia1_max"] as int?;
              final cia2 = subject["cia2"] as int?;
              final cia2Max = subject["cia2_max"] as int?;
              final cia3 = subject["cia3"] as int?;
              final cia3Max = subject["cia3_max"] as int?;
              final assignment = subject["assignment"] as int?;
              final assignmentMax = subject["assignment_max"] as int?;

              // Call the new calculation function
              final internalMarks = calculateInternalsOutOf50(
                  cia1: cia1, cia1Max: cia1Max,
                  cia2: cia2, cia2Max: cia2Max,
                  cia3: cia3, cia3Max: cia3Max,
                  assignment: assignment, assignmentMax: assignmentMax
              );
              final totalOutOf50 = internalMarks['total']!;
              final assignmentScaled = internalMarks['assignment_scaled']!;
              final bestTwoCIAs = internalMarks['best_two_cias']!;

              // --- Card UI ---
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: isDark ? AppTheme.darkSurface : Colors.white,
                elevation: isDark ? 0 : 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: isDark ? BorderSide( color: AppTheme.neonBlue.withOpacity(0.5), width: 1) : BorderSide.none,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  // ✅ --- THIS IS THE FIX from the previous step ---
                  onTap: () {
                    Navigator.push( context, MaterialPageRoute( builder: (_) => SubjectDetailPage(
                      subjectName: subject["name"],
                      subjectCode: subject["code"],
                      maxInternals: 50, // This is 50
                      maxEndSem: subject["maxEndSem"],

                      // Pass all the raw data
                      cia1: cia1,
                      cia1Max: cia1Max,
                      cia2: cia2,
                      cia2Max: cia2Max,
                      cia3: cia3,
                      cia3Max: cia3Max,
                      assignment: assignment,
                      assignmentMax: assignmentMax,

                    ), ), );
                  },
                  // ✅ --- END FIX ---
                  child: Padding(
                    padding: const EdgeInsets.symmetric( vertical: 16, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row( /* Subject Name/Code */
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible( child: Text( subject["name"], style: TextStyle( fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor, ), maxLines: 2, overflow: TextOverflow.ellipsis,), ),
                            Text( subject["code"], style: TextStyle( fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[700], ), ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row( /* CIA Boxes */
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildCiaBox("CIA 1", cia1, theme),
                            _buildCiaBox("CIA 2", cia2, theme),
                            _buildCiaBox("CIA 3", cia3, theme),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row( /* Status Label/Total */
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text( "Current Internals", style: TextStyle( fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87, ), ),
                            Text(
                              "${totalOutOf50.toStringAsFixed(1)}/50",
                              style: TextStyle( fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87, ), ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect( /* Progress Bar */
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: (totalOutOf50 / 50.0).clamp(0.0, 1.0),
                            backgroundColor: isDark ? AppTheme.darkBackground.withOpacity(0.7) : AppTheme.primaryBlue.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "CIAs: ${bestTwoCIAs.toStringAsFixed(1)}/40  •  Assignment: ${assignmentScaled.toStringAsFixed(1)}/10",
                          style: TextStyle( color: isDark ? Colors.white70 : Colors.grey[700], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              // --- End Card UI ---
            },
          );
        } // End else (data loaded)

        // --- Scaffold with RefreshIndicator ---
        return Scaffold(
          backgroundColor: isDark ? AppTheme.darkBackground : Colors.grey[100],
          body: RefreshIndicator(
            onRefresh: _fetchFromApi, // Pull-to-refresh calls API fetch
            color: primaryColor,
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            child: bodyContent, // Display loading, error, empty, or list
          ),
        );
        // --- End Scaffold ---
      },
    ); // End Consumer
  } // End build

  // --- _buildCiaBox helper (unchanged) ---
  Widget _buildCiaBox(String label, dynamic value, ThemeProvider theme) {
    final isDark = theme.isDarkMode;
    final bool hasValue = value != null;
    Color getBackgroundColor() { if (isDark) { return hasValue ? AppTheme.darkSurface : AppTheme.darkBackground.withOpacity(0.7); } else { return hasValue ? Colors.white : Colors.blue.shade50; } }
    Color getBorderColor() { if (isDark) { return hasValue ? AppTheme.neonBlue : AppTheme.neonBlue.withOpacity(0.2); } else { return Colors.blue.shade200; } }
    Color getTextColor() { if (isDark) { return hasValue ? Colors.white : Colors.white54; } else { return hasValue ? Colors.black87 : Colors.blueGrey; } }
    return Container( width: 96, height: 44, alignment: Alignment.center, decoration: BoxDecoration( color: getBackgroundColor(), border: Border.all(color: getBorderColor()), borderRadius: BorderRadius.circular(10), ), child: Text( value?.toString() ?? label, style: TextStyle( fontSize: 14, fontWeight: FontWeight.w600, color: getTextColor(), ), ), );
  }
// --- End _buildCiaBox ---

} // End _InternalsPageState