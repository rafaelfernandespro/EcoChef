
import 'package:flutter/material.dart';

class CadastroUsuariosScreen extends StatefulWidget {
  const CadastroUsuariosScreen({super.key});

  @override
  State<CadastroUsuariosScreen> createState() =>
      _CadastroUsuariosScreenState();
}

class _CadastroUsuariosScreenState
    extends State<CadastroUsuariosScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nomeController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController senhaController =
      TextEditingController();

  final TextEditingController cpfController =
      TextEditingController();

  String? tipoUsuario;
  String statusUsuario = 'Ativo';

  bool ocultarSenha = true;

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();
    cpfController.dispose();
    super.dispose();
  }

  // Estilo padrão dos campos
  InputDecoration estiloCampo({
    required String hint,
    required IconData icone,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icone,
        color: const Color(0xFF64748B),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFFCBD5E1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFFCBD5E1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFF2563EB),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  // Campo de texto com título
  Widget campoTexto({
    required String titulo,
    required String hint,
    required IconData icone,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType teclado = TextInputType.text,
    bool senha = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: teclado,
          obscureText: senha && ocultarSenha,
          validator: validator,
          decoration: estiloCampo(
            hint: hint,
            icone: icone,
          ).copyWith(
            suffixIcon: senha
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        ocultarSenha = !ocultarSenha;
                      });
                    },
                    icon: Icon(
                      ocultarSenha
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF64748B),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  // Validar e cadastrar usuário
  void cadastrarUsuario() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Formulário validado! Integre o cadastro ao banco de dados.',
        ),
        backgroundColor: Color(0xFF2563EB),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: Column(
              children: [
                // CABEÇALHO
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Cadastro de usuários',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // IDENTIDADE VISUAL
                Image.asset(
                  'assets/images/logo.png',
                  width: 90,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: Color(0xFF2563EB),
                    );
                  },
                ),

                const SizedBox(height: 8),

                const Text(
                  'EcoChef',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Gestão de usuários do sistema',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 28),

                // CARD DO FORMULÁRIO
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dados do usuário',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'Preencha os dados para cadastrar um usuário.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // NOME
                        campoTexto(
                          titulo: 'Nome completo',
                          hint: 'Digite o nome completo',
                          icone: Icons.person_outline,
                          controller: nomeController,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Informe o nome do usuário';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // E-MAIL
                        campoTexto(
                          titulo: 'E-mail',
                          hint: 'seu@email.com',
                          icone: Icons.email_outlined,
                          controller: emailController,
                          teclado: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Informe o e-mail';
                            }

                            final regex = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            );

                            if (!regex.hasMatch(value.trim())) {
                              return 'Informe um e-mail válido';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // CPF
                        campoTexto(
                          titulo: 'CPF',
                          hint: 'Digite o CPF',
                          icone: Icons.badge_outlined,
                          controller: cpfController,
                          teclado: TextInputType.number,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Informe o CPF';
                            }

                            final cpf = value.replaceAll(
                              RegExp(r'\D'),
                              '',
                            );

                            if (cpf.length != 11) {
                              return 'O CPF deve conter 11 números';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // SENHA
                        campoTexto(
                          titulo: 'Senha',
                          hint: 'Digite a senha',
                          icone: Icons.key_outlined,
                          controller: senhaController,
                          senha: true,
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty) {
                              return 'Informe a senha';
                            }

                            if (value.length < 6) {
                              return 'A senha deve ter pelo menos 6 caracteres';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // TIPO DE USUÁRIO
                        const Text(
                          'Tipo de usuário',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),

                        const SizedBox(height: 8),

                        DropdownButtonFormField<String>(
                          value: tipoUsuario,
                          decoration: estiloCampo(
                            hint: 'Selecione o tipo',
                            icone: Icons.manage_accounts_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Admin',
                              child: Text('Admin'),
                            ),
                            DropdownMenuItem(
                              value: 'Funcionário',
                              child: Text('Funcionário'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              tipoUsuario = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Selecione o tipo de usuário';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // STATUS

                        const SizedBox(height: 28),

                        // BOTÃO CADASTRAR
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: cadastrarUsuario,
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
                            child: const Text(
                              'Cadastrar usuário',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // BOTÃO LIMPAR
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              _formKey.currentState?.reset();

                              nomeController.clear();
                              emailController.clear();
                              senhaController.clear();
                              cpfController.clear();

                              setState(() {
                                tipoUsuario = null;
                                statusUsuario = 'Ativo';
                                ocultarSenha = true;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  const Color(0xFF2563EB),
                              side: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Limpar campos'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'EcoChef • Gestão Inteligente de Desperdício',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
