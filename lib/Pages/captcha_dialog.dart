// lib/captcha_dialog.dart
import 'dart:convert';
import 'dart:typed_data'; // Required for Uint8List
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'; // Import Provider
import '../services/ApiEndpoints.dart'; // Adjust path if needed
import '../models/theme_model.dart';    // Import ThemeModel

class CaptchaDialog extends StatefulWidget {
  final String token; // The expired token
  final String apiUrl; // Base URL

  const CaptchaDialog({
    Key? key,
    required this.token,
    required this.apiUrl,
  }) : super(key: key);

  @override
  _CaptchaDialogState createState() => _CaptchaDialogState();
}

class _CaptchaDialogState extends State<CaptchaDialog> {
  final TextEditingController _captchaController = TextEditingController();
  Uint8List? _captchaImageData;
  bool _isLoadingCaptcha = true;
  bool _isSubmitting = false;
  String? _errorText;
  late final ApiEndpoints api;

  @override
  void initState() {
    super.initState();
    api = ApiEndpoints(widget.apiUrl);
    _fetchCaptcha();
  }

  Future<void> _fetchCaptcha() async {
    // Show loading state, clear previous image/error
    setState(() {
      _isLoadingCaptcha = true;
      _captchaImageData = null;
      _errorText = null;
    });
    try {
      final response = await http.post(
        Uri.parse(api.reloginCaptcha),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': widget.token}),
      );

      if (!mounted) return; // Check if widget is still in the tree

      if (response.statusCode == 200) {
        setState(() {
          _captchaImageData = response.bodyBytes;
          _isLoadingCaptcha = false;
        });
      } else {
        // Handle API errors
        var message = "Failed to load CAPTCHA (${response.statusCode})";
        try {
          final body = jsonDecode(response.body);
          message = body['message'] ?? message;
        } catch (_) {}

        // If session truly expired and cannot be recovered by server, close dialog
        if (response.statusCode == 400 && message.contains("Session expired")) {
          Navigator.of(context).pop(null); // Close dialog, return null (failure)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        } else {
          // Show error fetching captcha, but keep dialog open for retry
          setState(() {
            _errorText = message;
            _isLoadingCaptcha = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = "Network error fetching CAPTCHA: $e";
        _isLoadingCaptcha = false;
      });
    }
  }

  Future<void> _submitCaptcha() async {
    if (_captchaController.text.isEmpty) {
      setState(() { _errorText = "Please enter the CAPTCHA text."; });
      return;
    }
    if (_isSubmitting) return;

    setState(() { _isSubmitting = true; _errorText = null; });

    try {
      final response = await http.post(
        Uri.parse(api.relogin),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': widget.token,
          'captcha': _captchaController.text,
        }),
      ).timeout(const Duration(seconds: 20)); // Add timeout

      if (!mounted) return; // Check mount status after async gap

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        // SUCCESS! Return the new token
        final String? newToken = body['newtToken'];
        if (newToken != null && newToken.isNotEmpty) {
          Navigator.of(context).pop(newToken);
        } else {
          // Handle case where success is true but token is missing
          setState(() {
            _errorText = "Re-login succeeded but token was missing.";
            _isSubmitting = false;
            // --- REMOVED _fetchCaptcha() ---
          });
        }
      } else {
        // FAILED (e.g., wrong captcha, other server error)
        setState(() {
          _errorText = body['message'] ?? "Login failed (${response.statusCode})";
          _captchaController.clear(); // Clear input
          _isSubmitting = false;
          // --- REMOVED _fetchCaptcha() ---
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = "Network error during re-login: ${e.toString()}";
        _isSubmitting = false;
        // --- REMOVED _fetchCaptcha() ---
      });
    }
    // No finally needed as setState is called within try/catch for _isSubmitting
  }

  @override
  Widget build(BuildContext context) {
    // Get theme information
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    // Define colors based on theme
    final dialogBackgroundColor = isDarkMode ? AppTheme.darkSurface : Colors.white; // Use surface or white
    final primaryBlue = isDarkMode ? AppTheme.neonBlue : AppTheme.primaryBlue;
    final textColor = themeProvider.textColor;
    final secondaryTextColor = themeProvider.textSecondaryColor;
    final errorColor = Colors.redAccent;

    return AlertDialog(
      backgroundColor: dialogBackgroundColor, // Use theme background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(20), // Apply padding here
      content: SingleChildScrollView( // Ensure content scrolls if keyboard appears
        child: ListBody(
          children: <Widget>[
            Text(
              'Please enter the captcha below',
              style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            // Captcha Image or Loader
            SizedBox(
              height: 60, // Fixed height for consistency
              child: _isLoadingCaptcha
                  ? Center(child: CircularProgressIndicator(color: primaryBlue))
                  : _captchaImageData != null
                  ? Image.memory(
                _captchaImageData!,
                height: 60,
                gaplessPlayback: true, // Prevents flicker on refresh
                fit: BoxFit.contain, // Ensure image fits
              )
                  : Center(child: Text("Error loading image", style: TextStyle(color: errorColor))),
            ),
            // Refresh Button
            if (!_isLoadingCaptcha) // Show refresh only when not initially loading
              TextButton.icon(
                icon: Icon(Icons.refresh, color: primaryBlue),
                label: Text('Refresh CAPTCHA', style: TextStyle(color: primaryBlue)),
                onPressed: _isSubmitting ? null : _fetchCaptcha,
              ),
            const SizedBox(height: 10),
            // Input Field
            TextField(
              controller: _captchaController,
              decoration: InputDecoration(
                hintText: 'Enter captcha here',
                hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.7)),
                errorText: _errorText,
                filled: true,
                fillColor: isDarkMode ? Colors.grey[700] : Colors.grey[100], // Background for text field
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none, // Remove border for filled style
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryBlue, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: errorColor, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: errorColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              ),
              style: TextStyle(color: textColor), // Ensure input text is visible
              keyboardType: TextInputType.text,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              onSubmitted: (_) => _isSubmitting || _isLoadingCaptcha || _captchaImageData == null ? null : _submitCaptcha(), // Submit on Enter
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      actions: <Widget>[
        TextButton(
          child: Text('Cancel', style: TextStyle(color: secondaryTextColor)),
          onPressed: _isSubmitting ? null : () {
            Navigator.of(context).pop(null); // Indicate cancellation/failure
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white, // Text color on button
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
          ),
          onPressed: _isSubmitting || _isLoadingCaptcha || _captchaImageData == null ? null : _submitCaptcha,
          child: _isSubmitting
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Submit'),
        ),
      ],
    );
  }
}