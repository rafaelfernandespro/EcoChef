import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _carregando = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> enviarCodigo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _carregando = true;
    });

    final email = emailController.text.trim();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se houver uma conta associada a esse e-mail, você receberá um link de recuperação.',
          ),
          backgroundColor: Color(0xFF2563EB),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String mensagem;

      switch (e.code) {
        case 'invalid-email':
          mensagem = 'O e-mail informado é inválido.';
          break;

        case 'too-many-requests':
          mensagem =
              'Muitas tentativas. Tente novamente mais tarde.';
          break;

        case 'network-request-failed':
          mensagem = 'Verifique sua conexão com a internet.';
          break;

        default:
          mensagem =
              'Não foi possível enviar o link. Tente novamente.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
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
      backgroundColor: const Color(0xFFF8FAFC),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),

                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                  ),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      // CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),

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

                        child: Form(
                          key: _formKey,

                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              // TÍTULO
                              const Text(
                                'Recuperar senha',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),

                              const SizedBox(height: 6),

                              const Text(
                                'Informe seu e-mail para receber um link de recuperação de senha.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 28),

                              // LABEL
                              const Text(
                                'E-mail profissional',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // EMAIL
                              TextFormField(
                                controller: emailController,
                                keyboardType:
                                    TextInputType.emailAddress,

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

                              const SizedBox(height: 24),

                              // BOTÃO
                              SizedBox(
                                width: double.infinity,
                                height: 48,

                                child: ElevatedButton(
                                  onPressed: _carregando
                                      ? null
                                      : enviarCodigo,

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
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
                                          'Enviar link de recuperação',
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

                      const SizedBox(height: 28),

                      // VOLTAR
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },

                        icon: const Icon(
                          Icons.arrow_back,
                          size: 18,
                        ),

                        label: const Text(
                          'Voltar para login',
                        ),

                        style: TextButton.styleFrom(
                          foregroundColor:
                              const Color(0xFF2563EB),

                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // RODAPÉ
                      const Text(
                        'Exclusivo para restaurantes parceiros.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}