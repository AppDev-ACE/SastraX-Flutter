import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student_profile.dart';
import 'ApiEndpoints.dart';

class ApiService {
  final ApiEndpoints api;

  ApiService(this.api);

  Future<StudentProfile> fetchStudentProfile(String token, {bool refresh = false}) async {
    final response = await http.post(
      Uri.parse(api.profile),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // ✅ Send token in header
      },
      body: jsonEncode({
        'refresh': refresh, // optional refresh flag
      }),
    );

    if (response.statusCode == 200) {
      try {
        final jsonData = json.decode(response.body);
        final profile = jsonData['profile'] ?? jsonData['profileData'];
        if (profile == null) {
          throw Exception("Profile data missing from response");
        }
        return StudentProfile.fromJson(profile);
      } catch (e) {
        throw Exception('Parsing error: $e');
      }
    } else {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }
  }

  Future<String?> fetchProfilePicUrl(String token, {bool refresh = false}) async {
    final response = await http.post(
      Uri.parse(api.profilePic),
      headers: {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $token", // ✅ Same here
      },
      body: jsonEncode({
        'refresh': refresh,
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return jsonBody['profilePic'] ?? jsonBody['imageUrl'];
    }

    return null;
  }
}
