import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'esqueceu-senha/enviar-codigo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController senhaController =
      TextEditingController();

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  bool _carregando = false;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  // Encerra a sessão caso o perfil não seja autorizado.
  Future<void> encerrarSessao() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Evita que uma falha ao encerrar a sessão
      // interrompa o tratamento do erro original.
    }
  }

  // Realizar login pelo Firebase.
  Future<void> fazerLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = emailController.text.trim();
    final senha = senhaController.text;

    setState(() {
      _carregando = true;
    });

    try {
      // 1. Autenticar pelo Firebase Authentication.
      final credencial =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final usuario = credencial.user;

      if (usuario == null) {
        throw Exception('Usuário não identificado.');
      }

      // 2. Consultar o perfil no Firestore.
      final documento = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();

      final dados = documento.data();

      // 3. Verificar se o perfil existe.
      if (!documento.exists || dados == null) {
        await encerrarSessao();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Perfil de usuário não encontrado.',
            ),
          ),
        );

        return;
      }

      // 4. Verificar se a conta está ativa.
      if (dados['ativo'] != true) {
        await encerrarSessao();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Esta conta está inativa.',
            ),
          ),
        );

        return;
      }

      // 5. Verificar o tipo de usuário.
      final tipo = (dados['tipoUsuario'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      final ehAdmin = tipo == 'admin';

      final ehFuncionario =
          tipo == 'funcionario' ||
          tipo == 'funcionário';

      if (!ehAdmin && !ehFuncionario) {
        await encerrarSessao();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Perfil de usuário inválido.',
            ),
          ),
        );

        return;
      }

      // 6. Login autorizado.
      // Administradores e funcionários ativos podem entrar.
      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/home',
      );

    } on FirebaseAuthException catch (e) {
      String mensagem;

      switch (e.code) {
        case 'invalid-email':
          mensagem = 'O e-mail informado é inválido.';
          break;

        case 'invalid-credential':
        case 'invalid-login-credentials':
        case 'user-not-found':
        case 'wrong-password':
          mensagem = 'E-mail ou senha incorretos.';
          break;

        case 'user-disabled':
          mensagem = 'Esta conta está desativada.';
          break;

        case 'too-many-requests':
          mensagem =
              'Muitas tentativas. Tente novamente mais tarde.';
          break;

        case 'network-request-failed':
          mensagem =
              'Verifique sua conexão com a internet.';
          break;

        default:
          mensagem =
              'Não foi possível realizar o login.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
        ),
      );

    } on FirebaseException catch (e) {
      await encerrarSessao();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'permission-denied'
                ? 'Sem permissão para consultar o perfil. Verifique as regras do Firestore.'
                : 'Erro ao consultar os dados do usuário.',
          ),
        ),
      );

    } catch (_) {
      await encerrarSessao();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ocorreu um erro inesperado.',
          ),
        ),
      );

    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final alturaDisponivel = constraints.maxHeight;
            final compacto = alturaDisponivel < 700;

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // LOGO
                  Image.asset(
                    'assets/images/logo.png',
                    width: compacto ? 100 : 150,
                  ),

                  // NOME
                  const Text(
                    'EcoChef',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: compacto ? 12 : 30),

                  // CARD
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(compacto ? 16 : 24),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),

                    // FORMULÁRIO
                    child: Form(
                      key: _formKey,

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          // TÍTULO
                          const Text(
                            'Acesse sua Conta',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // CAMPO DE E-MAIL
                          TextFormField(
                            controller: emailController,
                            keyboardType:
                                TextInputType.emailAddress,
                            autocorrect: false,

                            decoration: InputDecoration(
                              hintText: 'seu@email.com',

                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: Color(0xFF64748B),
                              ),

                              filled: true,
                              fillColor: Colors.white,

                              contentPadding:
                                  const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),

                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),

                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),

                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2563EB),
                                  width: 1.5,
                                ),
                              ),

                              errorBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                ),
                              ),

                              focusedErrorBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                ),
                              ),
                            ),

                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Informe seu e-mail';
                              }

                              final emailRegex = RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              );

                              if (!emailRegex.hasMatch(
                                value.trim(),
                              )) {
                                return 'Informe um e-mail válido';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // CAMPO DE SENHA
                          TextFormField(
                            controller: senhaController,
                            obscureText: true,
                            enableSuggestions: false,
                            autocorrect: false,

                            decoration: InputDecoration(
                              hintText: 'Senha',

                              prefixIcon: const Icon(
                                Icons.key,
                                color: Color(0xFF64748B),
                              ),

                              filled: true,
                              fillColor: Colors.white,

                              contentPadding:
                                  const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),

                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),

                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),

                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2563EB),
                                  width: 1.5,
                                ),
                              ),

                              errorBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                ),
                              ),

                              focusedErrorBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                ),
                              ),
                            ),

                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty) {
                                return 'Informe sua senha';
                              }

                              return null;
                            },

                            onFieldSubmitted: (_) {
                              if (!_carregando) {
                                fazerLogin();
                              }
                            },
                          ),

                          const SizedBox(height: 10),

                          // ESQUECI MINHA SENHA
                          Align(
                            alignment: Alignment.centerRight,

                            child: TextButton(
                              onPressed: _carregando
                                  ? null
                                  : () {
                                      Navigator.pushNamed(
                                        context,
                                        '/esqueci-senha',
                                      );
                                    },

                              style: TextButton.styleFrom(
                                foregroundColor:
                                    const Color(0xFF2563EB),

                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              child: const Text(
                                'Esqueci minha senha',
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // BOTÃO ENTRAR
                          SizedBox(
                            width: double.infinity,
                            height: 48,

                            child: ElevatedButton(
                              onPressed: _carregando
                                  ? null
                                  : fazerLogin,

                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF2563EB),

                                foregroundColor: Colors.white,

                                disabledBackgroundColor:
                                    const Color(0xFF93B4F5),

                                elevation: 0,

                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                              ),

                              child: _carregando
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,

                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )

                                  : const Text(
                                      'Entrar',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}