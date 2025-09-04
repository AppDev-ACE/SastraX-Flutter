import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../models/theme_model.dart';
import '../models/student_profile.dart';
import '../services/ApiEndpoints.dart';
import '../services/api_service.dart';
import 'loginpage.dart';

class ProfilePage extends StatefulWidget {
  final String regNo;
  final String url; // Add url as a parameter
  const ProfilePage({super.key, required this.regNo, required this.url});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<StudentProfile> profileFuture;
  late Future<String?> picUrlFuture;
  late final ApiService _apiService; // Create a variable for the service

  @override
  void initState() {
    super.initState();
    // Initialize the API service with the URL from the widget
    _apiService = ApiService(ApiEndpoints(widget.url));
    profileFuture = _apiService.fetchStudentProfile(widget.regNo);
    picUrlFuture = _apiService.fetchProfilePicUrl(widget.regNo);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(1.0, 1.1),
          ),
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
              title: const Text("Profile"),
            ),
            backgroundColor: themeProvider.backgroundColor,
            body: FutureBuilder<StudentProfile>(
              future: profileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final student = snapshot.data!;
                return SingleChildScrollView(
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
                            FutureBuilder<String?>(
                              future: picUrlFuture,
                              builder: (context, snap) {
                                if (snap.connectionState == ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                }
                                if (!snap.hasData || snap.data == null) {
                                  return Icon(Icons.person, size: 80, color: themeProvider.isDarkMode ? Colors.black : const Color(0xFF1e3a8a));
                                }
                                return ClipOval(
                                  child: Image.network(
                                    snap.data!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.person,
                                      size: 80,
                                      color: themeProvider.isDarkMode ? Colors.black : const Color(0xFF1e3a8a),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 15),
                            Text(
                              student.name ?? "Name Not Available",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: themeProvider.isDarkMode ? themeProvider.primaryColor : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              student.regNo ?? "",
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
                            _buildProfileCard('Department', student.department ?? "", Icons.school, themeProvider.primaryColor, themeProvider),
                            const SizedBox(height: 15),
                            _buildProfileCard('Semester', student.semester ?? "", Icons.calendar_today, Colors.green, themeProvider),
                            const SizedBox(height: 15),
                            _buildProfileCard('Batch', _getBatch(student.regNo ?? "", student.department ?? ""), Icons.group, Colors.orange, themeProvider),
                            const SizedBox(height: 15),
                            _buildProfileCard('Email', _getEmail(student.regNo ?? ""), Icons.email, themeProvider.primaryColor, themeProvider),
                            const SizedBox(height: 30),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushReplacement(
                                    context, MaterialPageRoute(builder: (context) => LoginPage(url: widget.url)));
                              },
                              icon: const Icon(Icons.logout, color: Colors.white),
                              label: const Text('Log Out', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeProvider.primaryColor,
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
                );
              },
            ),
          ),
        );
      },
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
        final offset = department.toLowerCase().contains("m.tech") ? 5 : 4;
        final startYear = gradYear - offset;
        return "$startYear - $gradYear";
      }
    } catch (e) {}
    return "Unknown";
  }

  Widget _buildProfileCard(String title, String value, IconData icon, Color color, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: themeProvider.isDarkMode ? Border.all(color: color.withOpacity(0.3)) : null,
        boxShadow: themeProvider.isDarkMode ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)] : [const BoxShadow(color: Colors.black12, blurRadius: 10)],
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