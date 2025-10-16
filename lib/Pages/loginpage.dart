import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:sastra_x/Components/TextUserPassField.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sastra_x/Pages/home_page.dart';
import 'package:sastra_x/UI/LoginUI.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Added
import '../models/theme_model.dart';
import '../services/ApiEndpoints.dart';

class LoginPage extends StatefulWidget {
  final String url; // Base backend URL (e.g., http://your-server.com:3000)
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
  String? captchaErrorMessage;

  Uint8List? captchaBytes;
  late final ApiEndpoints api;

  @override
  void initState() {
    super.initState();
    api = ApiEndpoints(widget.url);
  }

  /// 🔹 Fetch Captcha Image
  Future<void> _getCaptcha() async {
    final regNo = userController.text.trim();
    if (regNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter Register Number first'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(api.captcha),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'regNo': regNo}),
      );

      if (response.statusCode == 200) {
        setState(() {
          captchaBytes = response.bodyBytes;
        });
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err['message'] ?? 'Failed to fetch captcha'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network or server error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// 🔹 Store session in SharedPreferences
  Future<void> _storeSession(String token, String regNo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_token', token);
    await prefs.setString('regNo', regNo);
    print("💾 Session stored successfully: token=$token, regNo=$regNo");
  }

  /// 🔹 Login API Call
  Future<void> _login() async {
    final regNo = userController.text.trim();
    final pwd = passwordController.text.trim();
    final captcha = captchaController.text.trim();

    if (regNo.isEmpty || pwd.isEmpty || captcha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(api.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'regNo': regNo,
          'pwd': pwd,
          'captcha': captcha,
        }),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        final token = result['token'];

        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login response missing token'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }

        print("✅ Received token: $token");

        // ✅ Save session locally
        await _storeSession(token, regNo);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login Successful!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context); // Close captcha dialog

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(token: token, url: widget.url, regNo: regNo),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Login failed'),
            backgroundColor: Colors.redAccent,
          ),
        );
        await _getCaptcha(); // Refresh captcha after failure
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// 🔹 Show Captcha Dialog Box
  void _showCaptchaDialog() async {
    captchaController.clear();
    await _getCaptcha();

    if (captchaBytes == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Center(
              child: Material(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 330),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () async {
                              await _getCaptcha();
                              setDialogState(() {});
                            },
                          ),
                        ],
                      ),
                      captchaBytes != null
                          ? Image.memory(captchaBytes!, height: 60, fit: BoxFit.contain)
                          : const CircularProgressIndicator(),
                      const SizedBox(height: 15),
                      TextField(
                        controller: captchaController,
                        decoration: InputDecoration(
                          hintText: "Enter CAPTCHA",
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Submit",
                          style: TextStyle(fontWeight: FontWeight.bold),
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

  /// 🔹 Main UI
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LoginUI(),
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
            TextUserPassField(
              controller: userController,
              hintText: "Register Number",
              passObscure: false,
              errorText: userErrorMessage,
              textColor: themeProvider.isDarkMode ? Colors.white : Colors.black,
              hintColor: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
            ),
            const SizedBox(height: 5),
            TextUserPassField(
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
                    onPressed: () {
                      if (userController.text.isEmpty || passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter Register Number and Password'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }
                      _showCaptchaDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
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
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomePage(
                            token: "guest_token",
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
                            : Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
