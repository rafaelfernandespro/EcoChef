import 'package:flutter/material.dart';
import 'Views/auth/login-page.dart';
import 'Views/auth/esqueceu-senha/enviar-codigo.dart';

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

      initialRoute: '/',
      
      routes: {
        '/': (context) => const LoginScreen(),
        '/esqueci-senha': (context) => ForgotPasswordPage(),
      },

    );
  }
}