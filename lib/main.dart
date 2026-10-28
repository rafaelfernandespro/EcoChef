
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'Views/auth/login-page.dart';
import 'Views/auth/esqueceu-senha/enviar-codigo.dart';
import 'Views/usuarios/cadastrar-usuario.dart';
import 'Views/usuarios/gerenciar-usuario.dart';
import 'Views/home-page.dart';
import 'Views/nav-bar.dart';
import 'Views/estoque-page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const EcoChefApp());
}

class EcoChefApp extends StatelessWidget {
  const EcoChefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoChef',
      initialRoute: '/home',
      routes: {
        '/': (context) => const LoginScreen(),
        '/esqueci-senha': (context) => ForgotPasswordPage(),
        '/cadastro-usuarios': (context) =>
            const CadastroUsuariosScreen(),
        '/gerenciar-usuario': (context) =>
            const ListaFuncionariosScreen(),
        '/home': (context) => const HomeNavigationPage(),
        '/estoque-usuario': (context) =>
            const EstoquePage(),
      },
    );
  }
}
