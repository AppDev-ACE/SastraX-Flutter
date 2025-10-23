import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Pages/home_page.dart';
import 'pages/loginpage.dart';
import 'firebase_options.dart';
import 'models/theme_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'SASTRAX Student App',
            theme: themeProvider.currentTheme,
            home: const AuthHandler(url: 'https://sastrax-backend.onrender.com'),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
class AuthHandler extends StatefulWidget {
  final String url;
  const AuthHandler({super.key, required this.url});

  @override
  State<AuthHandler> createState() => _AuthHandlerState();
}

class _AuthHandlerState extends State<AuthHandler> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final regNo = prefs.getString('regNo');

      // Debug logs
      debugPrint("🟩 Checking saved session...");
      debugPrint("Stored token: $token");
      debugPrint("Stored regNo: $regNo");

      if (token == null || regNo == null || token.isEmpty) {
        _goToLogin();
        return;
      }
      final doc =
      await FirebaseFirestore.instance.collection("activeSessions").doc(token).get();

      if (doc.exists) {
        debugPrint("✅ Session valid. Staying logged in.");
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(
                token: token,
                regNo: regNo,
                url: widget.url,
              ),
            ),
          );
        }
      } else {
        debugPrint("🔴 Session invalid or expired. Clearing local data.");
        await prefs.clear();
        _goToLogin();
      }
    } catch (e) {
      debugPrint("⚠️ Session check failed: $e");
      _goToLogin();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage(url: widget.url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}