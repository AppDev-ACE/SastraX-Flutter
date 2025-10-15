import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student_profile.dart';
import 'ApiEndpoints.dart';

class ApiService {
  final ApiEndpoints api;

  ApiService(this.api);

  /// Fetches student profile from backend or Firestore.
  Future<StudentProfile> fetchStudentProfile(
      String token, {
        bool refresh = false,
      }) async {
    final response = await http.post(
      Uri.parse(api.profile),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        'token': token,
        'refresh': refresh,
      }),
    );

    if (response.statusCode == 200) {
      try {
        final jsonData = json.decode(response.body);

        // backend might send { profile: {...} } or { profileData: {...} }
        final profile = jsonData['profile'] ?? jsonData['profileData'];
        if (profile == null) {
          throw Exception("Profile data missing from response");
        }

        return StudentProfile.fromJson(profile);
      } catch (e) {
        throw Exception('Parsing error: $e');
      }
    } else {
      throw Exception(
        'Failed to load profile: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Fetches profile picture URL from backend or Firestore.
  Future<String?> fetchProfilePicUrl(
      String token, {
        bool refresh = false,
      }) async {
    final response = await http.post(
      Uri.parse(api.profilePic),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        'token': token,
        'refresh': refresh,
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);

      if (jsonBody['success'] == true) {
        // Backend returns either { profilePic: ... } or { imageUrl: ... }
        final url = jsonBody['profilePic'] ?? jsonBody['imageUrl'];
        return url;
      } else {
        // Throw an exception with the message from the backend if success is false
        throw Exception(jsonBody['message'] ?? 'Failed to retrieve profile picture URL');
      }
    } else {
      // Handle server or network errors
      throw Exception(
        'Failed to load profile picture: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
