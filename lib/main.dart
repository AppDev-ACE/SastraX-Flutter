
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sastra_x/Pages/SplashScreen.dart';
import 'package:sastra_x/services/notification_service.dart';
import 'Pages/loginpage.dart';
import 'models/theme_model.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'SASTRAX Student App',
            theme: themeProvider.currentTheme,
            home: SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
