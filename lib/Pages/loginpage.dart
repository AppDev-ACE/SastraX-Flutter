import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:sastra_x/Components/TextUserPassField.dart'; // Ensure correct path
import 'package:google_fonts/google_fonts.dart';
import 'package:sastra_x/Pages/home_page.dart';        // Ensure correct path
import 'package:sastra_x/UI/LoginUI.dart';              // Ensure correct path
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme_model.dart';                   // Ensure correct path
import '../services/ApiEndpoints.dart';                 // Ensure correct path

class LoginPage extends StatefulWidget {
  final String url; // Base backend URL
  const LoginPage({super.key, required this.url});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userController = TextEditingController();
  final passwordController = TextEditingController();
  final captchaController = TextEditingController();

  String? userErrorMessage;
  String? passwordErrorMessage;
  // Captcha error message is handled within the dialog state now

  Uint8List? captchaBytes;
  late final ApiEndpoints api;
  bool _isLoggingIn = false; // Add loading state

  @override
  void initState() {
    super.initState();
    api = ApiEndpoints(widget.url);
  }

  /// 🔹 Fetch Captcha Image (Returns bytes for dialog state update)
  Future<Uint8List?> _getCaptcha() async {
    final regNo = userController.text.trim();
    if (regNo.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter Register Number first'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return null; // Indicate failure
    }

    try {
      final response = await http.post(
        Uri.parse(api.captcha),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'regNo': regNo}),
      );

      if (response.statusCode == 200) {
        // Return bytes on success
        return response.bodyBytes;
      } else {
        // Try decoding the error message
        String message = 'Failed to fetch captcha (${response.statusCode})';
        try {
          final err = jsonDecode(response.body);
          message = err['message'] ?? message;
        } catch (_) { /* Ignore if body isn't JSON */ }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return null; // Indicate failure
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error fetching captcha: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return null; // Indicate failure
    }
  }


  /// 🔹 Store session in SharedPreferences
  Future<void> _storeSession(String token, String regNo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token); // Using 'authToken' key consistent with HomePage
    await prefs.setString('regNo', regNo);
    print("💾 Session stored successfully: token=$token, regNo=$regNo");
  }

  /// 🔹 Login API Call (Handles dialog state update via return value)
  Future<Uint8List?> _login() async { // Return potential new captcha bytes
    final regNo = userController.text.trim();
    final pwd = passwordController.text.trim();
    final captcha = captchaController.text.trim();

    // Basic validation
    if (regNo.isEmpty || pwd.isEmpty || captcha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.redAccent,
        ),
      );
      // Return current bytes if available, dialog state shouldn't change
      return captchaBytes;
    }
    if (_isLoggingIn) return captchaBytes; // Prevent multiple clicks

    // Update UI to show loading state
    // Use setState only if inside dialog; otherwise, main build handles it
    if (ModalRoute.of(context)?.isCurrent ?? false) { // Check if dialog is current route
      setState(() { _isLoggingIn = true; });
    }

    Uint8List? newCaptchaBytes; // Variable to hold refreshed captcha on error

    try {
      final response = await http.post(
        Uri.parse(api.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'regNo': regNo,
          'pwd': pwd,
          'captcha': captcha,
        }),
      ).timeout(const Duration(seconds: 20)); // Add timeout

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        // --- CRUCIAL TOKEN VALIDATION ---
        final dynamic tokenValue = result['token'];
        final String? token = (tokenValue is String && tokenValue.isNotEmpty) ? tokenValue : null;

        if (token == null) {
          print("❌ Error: Login response missing or invalid token. Response: $result");
          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login failed: Invalid session data received.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          newCaptchaBytes = await _getCaptcha(); // Refresh captcha
          // Return new bytes for dialog update
          // Need to ensure loading state is reset in finally block
          return newCaptchaBytes;
        }
        // --- END OF VALIDATION ---

        // If validation passed:
        print("✅ Received valid token: $token");
        await _storeSession(token, regNo);

        if(!mounted) return null; // Check mount status before navigation

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login Successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Pop dialog *before* navigating
        Navigator.pop(context);

        print("Navigating to HomePage with validated token: $token");
        // Ensure context used for navigation is still valid
        if(mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(token: token, url: widget.url, regNo: regNo),
            ),
          );
        }
        return null; // Success, no need to update captcha in dialog

      } else {
        // Login API failed (wrong credentials, wrong captcha etc.)
        String message = 'Login failed (${response.statusCode})';
        try { message = result['message'] ?? message; } catch(_) {}
        print("❌ Login API Failed: $message");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        newCaptchaBytes = await _getCaptcha(); // Refresh captcha after failure
        return newCaptchaBytes; // Return new bytes for dialog update
      }
    } catch (e) {
      // General network/parsing/timeout errors
      print("❌ Login Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred during login: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      newCaptchaBytes = await _getCaptcha(); // Refresh captcha on general errors too
      return newCaptchaBytes; // Return new bytes for dialog update
    } finally {
      // Reset loading state regardless of outcome
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  /// 🔹 Show Captcha Dialog Box
  void _showCaptchaDialog() async {
    captchaController.clear();
    // Show loading indicator on main page while fetching initial captcha
    setState(() { captchaBytes = null; _isLoggingIn = true; }); // Use _isLoggingIn for main button loader
    final initialCaptcha = await _getCaptcha();
    // Hide main page loader once captcha is fetched (or fails)
    if(mounted) {
      setState(() { _isLoggingIn = false; });
    }


    // If fetch failed, don't show the dialog, error was already shown
    if (initialCaptcha == null) return;

    // Use the fetched bytes directly for the dialog
    // No need for setState here as showDialog builds the UI

    showDialog(
      context: context,
      barrierDismissible: false, // Make sure user interacts
      builder: (BuildContext context) {
        // StatefulBuilder to manage dialog's internal state (captcha image, submitting state)
        Uint8List? currentCaptchaBytes = initialCaptcha; // Local state for dialog image
        bool isDialogSubmitting = false; // Local state for dialog submit button

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Center(
              child: Material(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 330),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    // Using your original dialog color
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton( // Close button
                            icon: const Icon(Icons.close),
                            // Disable close while submitting
                            onPressed: isDialogSubmitting ? null : () => Navigator.pop(context),
                          ),
                          IconButton( // Refresh button
                            icon: const Icon(Icons.refresh),
                            // Disable refresh while submitting or if captcha is currently loading
                            onPressed: isDialogSubmitting || currentCaptchaBytes == null ? null : () async {
                              // Show loading inside dialog
                              setDialogState(() { currentCaptchaBytes = null; });
                              final refreshedBytes = await _getCaptcha(); // Fetch new captcha
                              // Update dialog state
                              setDialogState(() { currentCaptchaBytes = refreshedBytes; });
                            },
                          ),
                        ],
                      ),
                      // Use the currentCaptchaBytes from the StatefulBuilder's state
                      currentCaptchaBytes != null
                          ? Image.memory(currentCaptchaBytes!, height: 60, fit: BoxFit.contain, gaplessPlayback: true,)
                          : const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())), // Show loader
                      const SizedBox(height: 15),
                      TextField(
                        controller: captchaController,
                        decoration: InputDecoration(
                          hintText: "Enter CAPTCHA",
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          filled: true,
                          fillColor: Colors.white, // Original fill color
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            // Make border visible if needed:
                            // borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          enabledBorder: OutlineInputBorder( // Consistent border appearance
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        // Submit on enter
                        onSubmitted: (_) {
                          if (!isDialogSubmitting && currentCaptchaBytes != null) {
                            setDialogState(() { isDialogSubmitting = true; }); // Show loader in button
                            _login().then((updatedBytes) {
                              // Update dialog state *after* login attempt finishes
                              if(mounted) { // Check if dialog context is still valid
                                setDialogState(() {
                                  if (updatedBytes != null) {
                                    currentCaptchaBytes = updatedBytes; // Update image on failure
                                    captchaController.clear(); // Clear input on failure
                                  }
                                  isDialogSubmitting = false; // Hide loader
                                });
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        // Disable button while submitting or if captcha isn't loaded
                        onPressed: isDialogSubmitting || currentCaptchaBytes == null ? null : () {
                          setDialogState(() { isDialogSubmitting = true; }); // Show loader in button
                          _login().then((updatedBytes) {
                            // Update dialog state *after* login attempt finishes
                            if(mounted) { // Check if dialog context is still valid
                              setDialogState(() {
                                if (updatedBytes != null) {
                                  currentCaptchaBytes = updatedBytes; // Update image on failure
                                  captchaController.clear(); // Clear input on failure
                                }
                                isDialogSubmitting = false; // Hide loader
                              });
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, // Original button color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(double.infinity, 45), // Make button fill width
                          padding: const EdgeInsets.symmetric(vertical: 12), // Adjust padding if needed
                        ),
                        child: isDialogSubmitting // Show loader or text based on dialog state
                            ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text(
                          "Submit",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), // Explicitly set text color
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 🔹 Main UI (Your Original Structure - Minimal Changes)
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LoginUI(), // Your custom UI
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Enter your Login Credentials',
                style: GoogleFonts.lato(
                  textStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
            TextUserPassField( // Your custom field
              controller: userController,
              hintText: "Register Number",
              passObscure: false,
              errorText: userErrorMessage,
              textColor: themeProvider.isDarkMode ? Colors.white : Colors.black,
              hintColor: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
            ),
            const SizedBox(height: 5),
            TextUserPassField( // Your custom field
              controller: passwordController,
              hintText: "Password",
              passObscure: true,
              errorText: passwordErrorMessage,
              textColor: themeProvider.isDarkMode ? Colors.white : Colors.black,
              hintColor: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isLoggingIn ? null : () { // Disable button when logging in (fetching captcha or submitting)
                      // Basic validation before showing dialog
                      final user = userController.text.trim();
                      final pass = passwordController.text.trim();
                      bool hasError = false;
                      // Use setState to show/clear error messages immediately
                      setState(() {
                        userErrorMessage = user.isEmpty ? "Register Number cannot be empty" : null;
                        passwordErrorMessage = pass.isEmpty ? "Password cannot be empty" : null;
                        hasError = userErrorMessage != null || passwordErrorMessage != null;
                      });

                      if (!hasError) {
                        _showCaptchaDialog();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Your original style
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    // Show loader or text based on _isLoggingIn (main page login state)
                    child: _isLoggingIn
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                      "LOGIN",
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _isLoggingIn ? null : () { // Disable button when logging in
                      print("Navigating as guest...");
                      const guestToken = "guest_token";
                      // Simple check for the constant
                      if (guestToken.isEmpty) {
                        print("Error: Guest token is empty!");
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error entering guest mode.'))
                        );
                        return;
                      }
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomePage(
                            token: guestToken,
                            url: widget.url,
                            regNo: "",
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Continue without Login',
                      style: TextStyle(
                        color: themeProvider.isDarkMode
                            ? Colors.blue.shade300
                            : Colors.blue.shade700, // Your original style
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30), // Added padding at the bottom
          ],
        ),
      ),
    );
  }
}