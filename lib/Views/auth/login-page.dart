import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoChef'),
      ),
       body: Padding(
        padding: const EdgeInsets.all(24.0),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

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
                  // Futuramente vamos colocar a recuperação de senha aqui
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
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Futuramente vamos fazer o login aqui
                },
                child: const Text('Entrar'),
              ),
            ),

            const SizedBox(height: 16),

            // Botão Cadastrar
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Futuramente vamos abrir a tela de cadastro
                },
                child: const Text('Cadastrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}