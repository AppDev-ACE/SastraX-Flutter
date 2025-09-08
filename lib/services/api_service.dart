import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student_profile.dart';
import 'ApiEndpoints.dart';

class ApiService {
  final ApiEndpoints api;
  ApiService(this.api);

  Future<StudentProfile> fetchStudentProfile(String token) async {
    final response = await http.post(
      Uri.parse(api.profile),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode == 200) {
      try {
        final jsonData = json.decode(response.body);
        return StudentProfile.fromJson(jsonData);
      } catch (e) {
        throw Exception('Parsing error: $e');
      }
    } else {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }
  }

  Future<String?> fetchProfilePicUrl(String token) async {
    final response = await http.post(
      Uri.parse(api.profilePic), // Use the profilePic endpoint
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'token': token}),
    );
    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return jsonBody['profilePic'] ?? jsonBody['imageUrl'];
    }
    return null;
  }
}