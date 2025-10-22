// internals_page.dart
import 'dart:convert'; // For jsonDecode
import 'dart:async'; // For Future and timeout
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http; // For making HTTP requests
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'subjectDetailPage.dart'; // Make sure this import is correct
import 'dart:math'; // For max() and sorting
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
    setState(() { _isLoading = true; _error = null; });

    try {
      // 1. Check Firestore
      print("InternalsPage: Checking Firestore for existing data...");
      final docRef = FirebaseFirestore.instance.collection('studentDetails').doc(widget.regNo);
      final docSnapshot = await docRef.get().timeout(const Duration(seconds: 5)); // Add timeout

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        // Check key exists AND is a non-empty list
        if (data != null && data.containsKey('ciaWiseInternalMarks') && data['ciaWiseInternalMarks'] is List && (data['ciaWiseInternalMarks'] as List).isNotEmpty) {
          print("InternalsPage: Found non-empty data in Firestore. Using it.");
          if (mounted) {
            setState(() {
              _ciaMarksData = data['ciaWiseInternalMarks'] as List<dynamic>?;
              _isLoading = false;
            });
          }
          return; // Done
        } else {
          print("InternalsPage: Data in Firestore is empty/missing key 'ciaWiseInternalMarks'. Will fetch from API.");
        }
      } else {
        print("InternalsPage: Firestore document doesn't exist. Will fetch from API.");
      }

      // 2. Fetch from API if Firestore check didn't return
      await _fetchFromApi();

    } catch (e, stackTrace) {
      print("InternalsPage: Error during initial data load: $e \n$stackTrace");
      if (mounted) {
        setState(() {
          _error = "Failed to load initial data.\nError: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }


  /// Fetches data specifically from the API. Handles Firestore update via server.
  Future<void> _fetchFromApi() async {
    // Removed the problematic check: 'if (_isLoading && mounted)'

    if (!mounted) return Future.value(); // Keep this check

    print("InternalsPage: Starting _fetchFromApi...");
    // Ensure loading state is set *if* called directly (e.g., by RefreshIndicator)
    // If called from _loadData, it's already true, but setting it again is harmless.
    setState(() { _isLoading = true; _error = null; });

    try {
      // Small delay might not be necessary, but keep if intended
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return Future.value();

      print("InternalsPage: Fetching internals from API with token: ${widget.token.substring(0,min(10, widget.token.length))}...");
      final response = await http
          .post(
        Uri.parse(api.ciaWiseInternalMarks),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': widget.token}),
      )
          .timeout(const Duration(seconds: 45)); // Keep timeout

      if (!mounted) return Future.value();

      print("InternalsPage: API Response Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        // Assuming your backend responds with JSON like:
        // { "success": true, "message": "...", "marksData": [...] }
        // OR on error: { "success": false, "message": "Error..." }
        final dynamic data = jsonDecode(response.body); // Use dynamic type first

        // Check if the response is a Map and has the 'success' key
        if (data is Map<String, dynamic> && data.containsKey('success')) {
          if (data['success'] == true) {
            print("InternalsPage: API fetch successful. Processing marksData.");
            // Safely access 'marksData' which should be a List
            final List<dynamic>? marksList = data['marksData'] as List<dynamic>?;

            setState(() {
              _ciaMarksData = marksList; // Update state with new data
              _isLoading = false;
              _error = null;
            });
            // NOTE: We assume the BACKEND is responsible for writing this
            // marksList to the 'ciaWiseInternalMarks' field in Firestore.
          } else {
            // API reported success=false
            final String errorMessage = data['message'] as String? ?? 'API failed to load marks (no message)';
            print("InternalsPage: API reported success=false. Message: $errorMessage");
            throw Exception(errorMessage);
          }
        } else {
          // Handle unexpected response format
          print("InternalsPage: Unexpected API response format: ${response.body}");
          throw Exception('Invalid response format from server');
        }
      } else {
        print("InternalsPage: HTTP error occurred. Status: ${response.statusCode}");
        throw Exception('Server error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e, stackTrace) {
      print("InternalsPage: Error caught in _fetchFromApi: $e\n$stackTrace");
      if (mounted) {
        setState(() {
          // Show error, differentiating between initial load failure and refresh failure
          _error = (_ciaMarksData == null || _ciaMarksData!.isEmpty)
              ? "Failed to fetch marks.\nPlease pull down to refresh.\nError: ${e.toString()}"
              : "Failed to refresh marks.\nError: ${e.toString()}";
          _isLoading = false; // Stop loading on error
        });
      }
    } finally {
      // Ensure isLoading is set to false if the fetch completes or errors out,
      // but only if it wasn't already handled (e.g., successful fetch)
      if (mounted && _isLoading) {
        setState(() { _isLoading = false; });
      }
    }
    // Return a completed future for RefreshIndicator compatibility
    return Future.value();
  }


  /// Helper to parse mark strings (handles decimals, rounds them). Returns int?.
  int? _parseMark(String? markStr) {
    if (markStr == null) return null;
    final double? markDouble = double.tryParse(markStr.trim().replaceAll(RegExp(r'[^\d.]'), '')); // Allow only digits and decimal
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

  /// ✅ MODIFIED: Transforms API data, now includes Assignment mark and its max value.
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
        "maxInternals": 50, // ✅ Max internals is now 50
        "maxEndSem": 100,
        "cia1": null, "cia1_max": null, // Store max marks if needed for scaling CIAs later
        "cia2": null, "cia2_max": null,
        "cia3": null, "cia3_max": null,
        "assignment": null, // ✅ Add assignment field
        "assignment_max": null, // ✅ Add assignment max field
      },
      );

      final String lowerComponent = component.toLowerCase();

      // Store CIA marks and their max values
      if (lowerComponent.contains("cia 3") || lowerComponent.contains("cia iii") || lowerComponent.contains("3rd mid-term")) {
        groupedSubjects[subjectCode]!["cia3"] = mark;
        groupedSubjects[subjectCode]!["cia3_max"] = maxMark;
      } else if (lowerComponent.contains("cia 2") || lowerComponent.contains("cia ii") || lowerComponent.contains("2nd mid-term")) {
        groupedSubjects[subjectCode]!["cia2"] = mark;
        groupedSubjects[subjectCode]!["cia2_max"] = maxMark;
      } else if (lowerComponent.contains("cia 1") || lowerComponent.contains("cia i") || lowerComponent.contains("1st mid-term")) {
        groupedSubjects[subjectCode]!["cia1"] = mark;
        groupedSubjects[subjectCode]!["cia1_max"] = maxMark;
      }
      // ✅ Store Assignment mark and its max value
      else if (lowerComponent.contains("assignment")) {
        groupedSubjects[subjectCode]!["assignment"] = mark;
        groupedSubjects[subjectCode]!["assignment_max"] = maxMark;
      }
    }
    return groupedSubjects.values.toList();
  }


  /// ✅ MODIFIED: Calculates total internals out of 50.
  /// Takes CIAs (assumed out of 20 from API) and Assignment (raw mark + max mark).
  Map<String, double> calculateInternalsOutOf50({
    int? cia1, int? cia1Max,
    int? cia2, int? cia2Max,
    int? cia3, int? cia3Max,
    int? assignment, int? assignmentMax
  }) {
    final List<double> ciaScoresOutOf20 = [];
    // Scale CIAs to 20 if needed (assuming API provides raw marks like 18/20)
    // If API provides marks out of 50, scale them: mark * (20.0 / maxMark)
    // For now, assume API gives marks directly out of 20 as per previous examples
    // Add null safety checks
    if (cia1 != null) ciaScoresOutOf20.add(cia1.toDouble());
    if (cia2 != null) ciaScoresOutOf20.add(cia2.toDouble());
    if (cia3 != null) ciaScoresOutOf20.add(cia3.toDouble());


    // Sort CIAs descending to find best two
    ciaScoresOutOf20.sort((a, b) => b.compareTo(a));

    double bestTwoCIAsOutOf40 = 0.0;
    if (ciaScoresOutOf20.isNotEmpty) bestTwoCIAsOutOf40 += ciaScoresOutOf20[0]; // Add best
    if (ciaScoresOutOf20.length > 1) bestTwoCIAsOutOf40 += ciaScoresOutOf20[1]; // Add second best

    // Scale assignment mark to be out of 10
    double assignmentOutOf10 = 0.0;
    if (assignment != null && assignmentMax != null && assignmentMax > 0) {
      assignmentOutOf10 = (assignment.toDouble() / assignmentMax.toDouble()) * 10.0;
      // Clamp between 0 and 10 in case of data errors
      assignmentOutOf10 = assignmentOutOf10.clamp(0.0, 10.0);
    } else if (assignment != null) {
      // Fallback: If max is missing, assume assignment mark is already out of 10
      // (Adjust this assumption if needed based on typical data)
      print("Warning: Assignment max mark missing for value $assignment. Assuming it's out of 10.");
      assignmentOutOf10 = assignment.toDouble().clamp(0.0, 10.0);
    }


    double totalOutOf50 = bestTwoCIAsOutOf40 + assignmentOutOf10;

    return {
      'total': totalOutOf50.clamp(0.0, 50.0), // Ensure total doesn't exceed 50
      'assignment_scaled': assignmentOutOf10,
      'best_two_cias': bestTwoCIAsOutOf40,
    };
  }


  @override
  Widget build(BuildContext context) {
    // Process data using the updated function
    final List<Map<String, dynamic>> subjects = _processMarksData(_ciaMarksData);

    return Consumer<ThemeProvider>(
      builder: (_, theme, __) {
        final isDark = theme.isDarkMode;
        final primaryColor = isDark ? AppTheme.neonBlue : AppTheme.primaryBlue;

        Widget bodyContent;
        // --- Loading / Error / Empty States ---
        if (_isLoading && _ciaMarksData == null) { // Show loading only on initial load
          bodyContent = Center( child: CircularProgressIndicator( color: primaryColor, ), );
        } else if (_error != null && subjects.isEmpty) { // Show error only if no data to display
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
        } else if (!_isLoading && subjects.isEmpty) { // Show empty state if not loading and no data
          bodyContent = Center( child: Text( "No internal marks found.", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54), ), );
        } else {
          // --- Data List ---
          bodyContent = ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(), // Ensure scrollable even during refresh
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            // Adjust count for potential error banner when showing cached data
            itemCount: subjects.length + (_error != null && subjects.isNotEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              // --- Error Banner Logic (if refresh fails but we have old data) ---
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
              // --- End Error Banner ---

              // Adjust index if error banner is shown
              final subjectIndex = _error != null && subjects.isNotEmpty ? index - 1 : index;
              // Boundary check after index adjustment
              if (subjectIndex < 0 || subjectIndex >= subjects.length) return const SizedBox.shrink();

              final subject = subjects[subjectIndex];
              // Extract marks needed for calculation
              final cia1 = subject["cia1"] as int?;
              final cia1Max = subject["cia1_max"] as int?;
              final cia2 = subject["cia2"] as int?;
              final cia2Max = subject["cia2_max"] as int?;
              final cia3 = subject["cia3"] as int?;
              final cia3Max = subject["cia3_max"] as int?;
              final assignment = subject["assignment"] as int?;
              final assignmentMax = subject["assignment_max"] as int?;

              // ✅ Call the new calculation function
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
                  onTap: () {
                    Navigator.push( context, MaterialPageRoute( builder: (_) => SubjectDetailPage(
                      subjectName: subject["name"],
                      subjectCode: subject["code"],
                      maxInternals: 50, // ✅ Pass 50 as maxInternals
                      maxEndSem: subject["maxEndSem"],
                      // Pass original CIA marks (let detail page handle scaling if needed)
                      cia1: cia1?.toDouble(),
                      cia2: cia2?.toDouble(),
                      cia3: cia3?.toDouble(),
                    ), ), );
                  },
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
                            // Display original marks in boxes (e.g., 18, not 18.0)
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
                            Text( // ✅ Show total out of 50
                              "${totalOutOf50.toStringAsFixed(1)}/50",
                              style: TextStyle( fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87, ), ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect( /* Progress Bar */
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            // ✅ Value based on total out of 50
                            value: (totalOutOf50 / 50.0).clamp(0.0, 1.0),
                            backgroundColor: isDark ? AppTheme.darkBackground.withOpacity(0.7) : AppTheme.primaryBlue.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // ✅ Updated Text: Show breakdown
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
            // Wrap bodyContent in a layout builder to ensure RefreshIndicator works even when content is small
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: bodyContent, // Display loading, error, empty, or list
                ),
              ),
            ),
          ),
        );
        // --- End Scaffold ---
      },
    ); // End Consumer
  } // End build

  // --- _buildCiaBox helper ---
  Widget _buildCiaBox(String label, dynamic value, ThemeProvider theme) {
    final isDark = theme.isDarkMode;
    final bool hasValue = value != null;

    // Use a more specific check for "AB" or similar non-numeric values if needed
    final String displayText = value?.toString() ?? label; // Default to label if value is null

    Color getBackgroundColor() {
      if (isDark) {
        return hasValue ? AppTheme.darkSurface : AppTheme.darkBackground.withOpacity(0.7);
      } else {
        return hasValue ? Colors.white : Colors.blue.shade50;
      }
    }
    Color getBorderColor() {
      if (isDark) {
        return hasValue ? AppTheme.neonBlue : AppTheme.neonBlue.withOpacity(0.2);
      } else {
        // Use a consistent border color, maybe slightly lighter if no value
        return hasValue ? Colors.blue.shade200 : Colors.blue.shade100;
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
      width: MediaQuery.of(context).size.width * 0.25, // Adjust width based on screen size
      padding: EdgeInsets.symmetric(vertical: 8), // Padding for text
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: getBackgroundColor(),
        border: Border.all(color: getBorderColor()),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: getTextColor(),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
// --- End _buildCiaBox ---

} // End _InternalsPageState