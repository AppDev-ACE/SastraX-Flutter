import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sastra_x/Components/TextUserPassField.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sastra_x/Pages/home_page.dart';
import 'package:sastra_x/UI/LoginUI.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/theme_model.dart';
import '../services/ApiEndpoints.dart';

class LoginPage extends StatefulWidget {
  final String url;
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

  late String captchaUrl;
  late final ApiEndpoints api; // Add a field for the API class

  @override
  void initState() {
    super.initState();
    api = ApiEndpoints(widget.url); // Initialize the API class
    _refreshCaptcha();

    userController.addListener(() {
      if (userController.text.isNotEmpty) {
        setState(() => userErrorMessage = null);
      }
    });

    passwordController.addListener(() {
      if (passwordController.text.isNotEmpty) {
        setState(() => passwordErrorMessage = null);
      }
    });

    captchaController.addListener(() {
      if (captchaController.text.isNotEmpty) {
        setState(() => captchaErrorMessage = null);
      }
    });
  }

  // Refresh captcha and include regno param when available
  void _refreshCaptcha() {
    final regNo = userController.text.trim();
    setState(() {
      if (regNo.isEmpty) {
        captchaUrl = '${api.captcha}?ts=${DateTime.now().millisecondsSinceEpoch}';
      } else {
        captchaUrl = '${api.captcha}?regno=$regNo&ts=${DateTime.now().millisecondsSinceEpoch}';
      }
    });
  }

  Future<void> _validateCaptcha() async {
    FocusScope.of(context).unfocus();
    if (captchaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter CAPTCHA'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        // Use the API endpoint property
        Uri.parse(api.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'regno': userController.text.trim(),
          'pwd': passwordController.text.trim(),
          'captcha': captchaController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context); // Close dialog
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HomePage(regNo: userController.text, url: widget.url)),
        );
      } else {
        final result = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Captcha verification failed'),
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

  void _showCaptchaDialog() {
    // Refresh captcha using current register number (if any)
    _refreshCaptcha();
    captchaController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Center(
              child: Material(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 330),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 60,
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Center(
                              child: SizedBox(
                                width: 180,
                                height: 50,
                                child: CachedNetworkImage(
                                  key: ValueKey(captchaUrl),
                                  imageUrl: captchaUrl,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => const Center(
                                    child: SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.red,
                                    child: const Center(
                                      child: Text(
                                        "Error",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new),
                                onPressed: () {
                                  captchaController.clear();
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                            Positioned(
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: () {
                                  captchaController.clear();
                                  setDialogState(() {
                                    final regNo = userController.text.trim();
                                    if (regNo.isEmpty) {
                                      captchaUrl = '${api.captcha}?ts=${DateTime.now().millisecondsSinceEpoch}';
                                    } else {
                                      captchaUrl = '${api.captcha}?regno=$regNo&ts=${DateTime.now().millisecondsSinceEpoch}';
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: captchaController,
                        decoration: InputDecoration(
                          hintText: "Enter CAPTCHA",
                          hintStyle: const TextStyle(fontSize: 12),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FloatingActionButton.extended(
                        onPressed: _validateCaptcha,
                        label: const Text(
                          "S U B M I T",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        backgroundColor: Colors.blue.shade400,
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
            // The following Padding and Text are wrapped in a Row with Flexible
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Enter your Login Credentials',
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(
                          fontSize: 12, // You might need to adjust this size
                          fontWeight: FontWeight.w900,
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis, // Prevents overflow
                      softWrap: true, // Allows wrapping to next line
                    ),
                  ),
                ],
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
              child: FloatingActionButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
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
                backgroundColor: Colors.blue,
                splashColor: Colors.blue,
                child: Text(
                  "L O G I N ",
                  style: GoogleFonts.lato(fontWeight: FontWeight.w900, fontSize: 10),
                ),
              ),
            ),
            Center(
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => HomePage(regNo: userController.text, url: widget.url)));
                },
                mini: true,
                child: const Icon(Icons.arrow_forward),
              ),
            ),
          ],
        ),
      ),
    );
  }
}