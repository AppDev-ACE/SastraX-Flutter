import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme_model.dart';
import '../services/ApiEndpoints.dart';
import 'credits_page.dart';
import 'home_page.dart';
import 'loginpage.dart';
// For CreditsScreen cache (adjust filename if needed)
import 'mess_menu_page.dart';    // For MessMenuPage cache
import 'calendar_page.dart';     // For CalendarPage cache
// No need to import profile_page.dart itself

class ProfilePage extends StatefulWidget {
  final String token;
  final String url;
  final String regNo;

  const ProfilePage({
    super.key,
    required this.token,
    required this.url,
    required this.regNo,
  });

  // Cache is correctly here
  static Future<DocumentSnapshot<Map<String, dynamic>>>? _profileFutureCache;

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  // ... (initState, _fetchAndRefreshProfile, _refreshProfile are the same) ...
  late Future<DocumentSnapshot<Map<String, dynamic>>> _profileFuture;
  late final ApiEndpoints _apiEndpoints;

  @override
  void initState() {
    super.initState();
    _apiEndpoints = ApiEndpoints(widget.url);
    _profileFuture = ProfilePage._profileFutureCache ??= _fetchAndRefreshProfile();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchAndRefreshProfile() async {
    final docRef = FirebaseFirestore.instance.collection('studentDetails').doc(widget.regNo);
    final doc = await docRef.get();

    if (doc.exists && (doc.data()?['profilePic'] == null || doc.data()!['profilePic'].isEmpty)) {
      debugPrint("Profile picture missing in Firestore. Fetching from API...");
      try {
        await http.post(
          Uri.parse(_apiEndpoints.profilePic),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'token': widget.token, 'refresh': true}),
        );
        return await docRef.get();
      } catch (e) {
        debugPrint("Failed to trigger profile pic refresh: $e");
        return doc;
      }
    }
    return doc;
  }

  Future<void> _refreshProfile() async {
    try {
      await Future.wait([
        http.post(
          Uri.parse(_apiEndpoints.profile),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'token': widget.token, 'refresh': true}),
        ),
        http.post(
          Uri.parse(_apiEndpoints.profilePic),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'token': widget.token, 'refresh': true}),
        ),
      ]);
    } catch (e) {
      debugPrint("Failed to trigger profile refresh: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Refresh failed: $e"), backgroundColor: Colors.red));
      }
    }

    final newFuture = FirebaseFirestore.instance
        .collection('studentDetails')
        .doc(widget.regNo)
        .get();

    ProfilePage._profileFutureCache = newFuture;
    setState(() {
      _profileFuture = newFuture;
    });
  }


  /// 🔹 Handles the complete logout process including cache clearing
  Future<void> _logout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await http.post(
        Uri.parse(_apiEndpoints.logout),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': widget.token}),
      );
    } catch (e) {
      debugPrint("Error calling logout endpoint, but logging out locally anyway: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_token');
    await prefs.remove('regNo');

    // ✅ CLEAR ALL STATIC CACHES USING THE CLASS NAME
    // Ensure the class names match your file/class definitions exactly.
    DashboardScreen.dashboardCache = null;
    CreditsScreen.creditsCache = null;
    MessMenuPage.menuCache = null;
    CalendarPage.firebaseEventsCache = null;
    ProfilePage._profileFutureCache = null; // Clear this page's own cache

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage(url: widget.url)),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (build method remains identical) ...
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            ),
            title: const Text("Profile"),
          ),
          backgroundColor: themeProvider.backgroundColor,
          body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: Text('Error: Could not load profile data.\n${snapshot.error ?? "Document does not exist."}'));
              }

              final data = snapshot.data!.data()!;
              final profileData = data['profile'] as Map<String, dynamic>? ?? {};
              final name = profileData['name'] ?? "Name Not Available";
              final regNo = profileData['regNo'] ?? "";
              final department = profileData['department'] ?? "";
              final semester = profileData['semester'] ?? "";
              final picUrl = data['profilePic'] as String?;

              return RefreshIndicator(
                onRefresh: _refreshProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(), // Ensure refresh works
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: themeProvider.isDarkMode
                              ? const LinearGradient(colors: [Colors.black, Color(0xFF1A1A1A)])
                              : const LinearGradient(colors: [Color(0xFF1e3a8a), Color(0xFF3b82f6)]),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            ClipOval(
                              child: (picUrl != null && picUrl.isNotEmpty)
                                  ? Image.network(
                                picUrl,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildDefaultAvatar(themeProvider),
                              )
                                  : _buildDefaultAvatar(themeProvider),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: themeProvider.isDarkMode ? themeProvider.primaryColor : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              regNo,
                              style: TextStyle(
                                fontSize: 16,
                                color: themeProvider.isDarkMode ? themeProvider.textSecondaryColor : Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildProfileCard('Department', department, Icons.school, themeProvider.primaryColor, themeProvider),
                            const SizedBox(height: 15),
                            _buildProfileCard('Semester', semester, Icons.calendar_today, Colors.green, themeProvider),
                            const SizedBox(height: 15),
                            _buildProfileCard('Batch', _getBatch(regNo, department), Icons.group, Colors.orange, themeProvider),
                            const SizedBox(height: 15),
                            _buildProfileCard('Email', _getEmail(regNo), Icons.email, themeProvider.primaryColor, themeProvider),
                            const SizedBox(height: 30),
                            ElevatedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout, color: Colors.white),
                              label: const Text('Log Out', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ... (All other build/helper methods remain identical)
  Widget _buildDefaultAvatar(ThemeProvider themeProvider) {
    return Icon(
      Icons.person,
      size: 120,
      color: themeProvider.isDarkMode ? Colors.white70 : Colors.white,
    );
  }

  String _getEmail(String regNo) {
    if (regNo.length >= 9) {
      return '${regNo.substring(regNo.length - 9)}@sastra.ac.in';
    }
    return '$regNo@sastra.ac.in';
  }

  String _getBatch(String regNo, String department) {
    try {
      final match = RegExp(r'(\d{2})\d{6}$').firstMatch(regNo);
      if (match != null) {
        final gradYear = 2000 + int.parse(match.group(1)!);
        final offset = department.toLowerCase().contains("m.tech") ? 2 : 4;
        final startYear = gradYear - offset;
        return "$startYear - $gradYear";
      }
    } catch (_) {}
    return "Unknown";
  }

  Widget _buildProfileCard(String title, String value, IconData icon, Color color, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: themeProvider.isDarkMode ? Border.all(color: color.withOpacity(0.3)) : null,
        boxShadow: themeProvider.isDarkMode
            ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)]
            : [const BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: themeProvider.isDarkMode ? Border.all(color: color.withOpacity(0.3)) : null,
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, color: themeProvider.textSecondaryColor, fontWeight: FontWeight.w500)),
                const SizedBox(height: 5),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: themeProvider.textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}