import 'package:flutter/material.dart';
import 'package:smokii/const/constant.dart';
import 'package:smokii/splashscreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMOCII',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: const Color(0xFFFCFDFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          surface: pirmaryColorElementBG,
        ),
      ),
      home: const Splashscreen(),
    );
  }
}
