import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sastra_x/services/notification_service.dart';
import 'Pages/loginpage.dart';
import 'models/theme_model.dart';
import 'pages/home_page.dart';
import 'services/ApiEndpoints.dart';

const String kBaseUrl = 'https://computing-sticky-rolling-mild.trycloudflare.com';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final ApiEndpoints apiEndpoints = ApiEndpoints(kBaseUrl);

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<ApiEndpoints>(
      create: (_) => apiEndpoints,
      child: ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              title: 'SASTRAX Student App',
              theme: themeProvider.currentTheme,
              home: LoginPage(url: kBaseUrl), // No more URL parameter here
              debugShowCheckedModeBanner: false,
            );
          },
        ),
      ),
    );
  }
}