import 'package:flutter/material.dart';
import 'views/auth/login-page.dart';

void main() {
  runApp(const EcoChefApp());
}

class EcoChefApp extends StatelessWidget {
  const EcoChefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoChef',
      home: const LoginScreen(),
    );
  }
}