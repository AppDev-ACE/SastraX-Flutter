import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:sastra_x/Pages/loginpage.dart';

void main() {
  runApp(
   // DevicePreview(
     // enabled: !bool.fromEnvironment('dart.vm.product'),
      //builder: (context) => const MyApp(),
    //),
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: DevicePreview.appBuilder,
      locale: DevicePreview.locale(context),
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: LoginPage(),
    );
  }
}
