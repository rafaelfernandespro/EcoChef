import 'package:flutter/material.dart';
import 'esqueceu-senha/enviar-codigo.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF4F7FA),

    body: Padding(
      padding: const EdgeInsets.all(24.0),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Image.asset(
                'assets/images/logo.png',
            width: 150,
        ),
            Text('Ecochef'),

            const SizedBox(height: 30),

            // Campo de e-mail
            TextField(
              decoration: InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Campo de senha
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // Esqueci minha senha
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/esqueci-senha');
                },
                child: const Text(
                  'Esqueci minha senha',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Botão Entrar
            SizedBox(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Entrar'),
              ),
            ),

          ],
        ),
      ),
    );
  }
}