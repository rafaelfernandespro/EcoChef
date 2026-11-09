
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

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

  bool ocultarSenha = true;
  bool _carregando = false;

  static const String _nomeAppSecundario = 'ecoChefCadastro';

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();
    cpfController.dispose();
    super.dispose();
  }

  // Cria ou recupera uma segunda aplicação Firebase.
  // Ela permite cadastrar usuários sem encerrar
  // a sessão do administrador na aplicação principal.
  Future<FirebaseApp> _obterAppSecundario() async {
    for (final app in Firebase.apps) {
      if (app.name == _nomeAppSecundario) {
        return app;
      }
    }

    return Firebase.initializeApp(
      name: _nomeAppSecundario,
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Valida o CPF, incluindo os dígitos verificadores.
  bool _cpfValido(String cpf) {
    final numeros = cpf.replaceAll(RegExp(r'\D'), '');

    if (numeros.length != 11) return false;

    // Impede CPFs com todos os números iguais.
    if (RegExp(r'^(\d)\1{10}$').hasMatch(numeros)) {
      return false;
    }

    final digitos = numeros.split('').map(int.parse).toList();

    // Primeiro dígito verificador.
    int soma = 0;

    for (int i = 0; i < 9; i++) {
      soma += digitos[i] * (10 - i);
    }

    int resto = (soma * 10) % 11;
    if (resto == 10) resto = 0;

    if (resto != digitos[9]) return false;

    // Segundo dígito verificador.
    soma = 0;

    for (int i = 0; i < 10; i++) {
      soma += digitos[i] * (11 - i);
    }

    resto = (soma * 10) % 11;
    if (resto == 10) resto = 0;

    return resto == digitos[10];
  }

  // Exibe mensagens na tela.
  void _mostrarMensagem(
    String mensagem, {
    Color cor = const Color(0xFF2563EB),
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: cor,
        ),
      );
  }

  // Remove a conta do Authentication caso não seja
  // possível salvar seu documento no Firestore.
  Future<bool> _reverterCadastro(
    User? usuario,
    FirebaseAuth? authSecundario,
  ) async {
    bool conseguiuExcluir = true;

    if (usuario != null) {
      try {
        await usuario.delete();
      } catch (_) {
        conseguiuExcluir = false;
      }
    }

    try {
      await authSecundario?.signOut();
    } catch (_) {}

    return conseguiuExcluir;
  }

  // Estilo padrão dos campos.
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
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
    );
  }

  // Campo de texto com título.
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
          autocorrect: false,
          enableSuggestions: !senha,

          // Limita o CPF a 11 números.
          inputFormatters: titulo == 'CPF'
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ]
              : null,

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

  // Cadastrar usuário no Authentication e no Firestore.
  Future<void> cadastrarUsuario() async {
    if (_carregando) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (tipoUsuario == null) {
      return;
    }

    setState(() {
      _carregando = true;
    });

    FirebaseAuth? authSecundario;
    User? usuarioCriado;

    bool documentoSalvo = false;

    try {
      // 1. Verifica se existe uma sessão autenticada.
      final administrador = FirebaseAuth.instance.currentUser;

      if (administrador == null) {
        _mostrarMensagem(
          'Você precisa estar autenticado para cadastrar usuários.',
          cor: Colors.red,
        );
        return;
      }

      // 2. Confirma se o usuário atual é administrador.
      final documentoAdmin = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(administrador.uid)
          .get();

      final dadosAdmin = documentoAdmin.data();

      if (!documentoAdmin.exists ||
          dadosAdmin?['tipoUsuario'] != 'admin' ||
          dadosAdmin?['ativo'] != true) {
        _mostrarMensagem(
          'Somente administradores ativos podem cadastrar usuários.',
          cor: Colors.red,
        );
        return;
      }

      // 3. Prepara os dados.
      final nome = nomeController.text.trim();
      final email = emailController.text.trim();
      final senha = senhaController.text;

      final cpf = cpfController.text.replaceAll(
        RegExp(r'\D'),
        '',
      );

      // 4. Verifica se o CPF já está cadastrado.
      final cpfExistente = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('cpf', isEqualTo: cpf)
          .limit(1)
          .get();

      if (cpfExistente.docs.isNotEmpty) {
        _mostrarMensagem(
          'Este CPF já está cadastrado.',
          cor: Colors.red,
        );
        return;
      }

      // 5. Obtém a aplicação Firebase secundária.
      final appSecundario = await _obterAppSecundario();

      authSecundario = FirebaseAuth.instanceFor(
        app: appSecundario,
      );

      // 6. Cria a conta no Firebase Authentication.
      final credencial =
          await authSecundario!.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      usuarioCriado = credencial.user;

      if (usuarioCriado == null) {
        throw Exception(
          'Não foi possível criar a conta do usuário.',
        );
      }

      // 7. Salva os dados na coleção usuarios.
      // O UID do Authentication será o ID do documento.
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuarioCriado!.uid)
          .set({
        'nomeCompleto': nome,
        'email': email,
        'cpf': cpf,
        'tipoUsuario': tipoUsuario,
        'ativo': true,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      documentoSalvo = true;

      // 8. Encerra somente a sessão da aplicação secundária.
      // A sessão do administrador permanece aberta.
      try {
        await authSecundario!.signOut();
      } catch (_) {}

      // 9. Limpa o formulário.
      _formKey.currentState?.reset();

      nomeController.clear();
      emailController.clear();
      senhaController.clear();
      cpfController.clear();

      setState(() {
        tipoUsuario = null;
        ocultarSenha = true;
      });

      _mostrarMensagem(
        'Usuário cadastrado com sucesso!',
        cor: const Color(0xFF16A34A),
      );
      Navigator.pop(context, true);
      
    } on FirebaseAuthException catch (e) {
      bool contaRemovida = true;

      if (!documentoSalvo && usuarioCriado != null) {
        contaRemovida = await _reverterCadastro(
          usuarioCriado,
          authSecundario,
        );
      }

      String mensagem;

      switch (e.code) {
        case 'email-already-in-use':
          mensagem = 'Este e-mail já está cadastrado.';
          break;

        case 'invalid-email':
          mensagem = 'O e-mail informado é inválido.';
          break;

        case 'weak-password':
          mensagem = 'A senha é muito fraca.';
          break;

        case 'operation-not-allowed':
          mensagem =
              'O cadastro por e-mail e senha não está habilitado.';
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
              'Não foi possível criar a conta: ${e.message ?? e.code}';
      }

      if (!contaRemovida) {
        mensagem +=
            ' Verifique o Authentication: a conta pode ter sido criada sem o perfil no Firestore.';
      }

      _mostrarMensagem(
        mensagem,
        cor: Colors.red,
      );
    } on FirebaseException catch (e) {
      bool contaRemovida = true;

      if (!documentoSalvo && usuarioCriado != null) {
        contaRemovida = await _reverterCadastro(
          usuarioCriado,
          authSecundario,
        );
      }

      String mensagem;

      if (e.code == 'permission-denied') {
        mensagem =
            'Sem permissão para consultar ou salvar os dados. Verifique as regras do Firestore.';
      } else {
        mensagem =
            'Erro no Firebase: ${e.message ?? e.code}';
      }

      if (!contaRemovida) {
        mensagem +=
            ' A conta pode ter permanecido no Authentication. Confira antes de tentar novamente.';
      }

      _mostrarMensagem(
        mensagem,
        cor: Colors.red,
      );
    } catch (e) {
      bool contaRemovida = true;

      if (!documentoSalvo && usuarioCriado != null) {
        contaRemovida = await _reverterCadastro(
          usuarioCriado,
          authSecundario,
        );
      }

      String mensagem =
          'Ocorreu um erro ao cadastrar o usuário.';

      if (!contaRemovida) {
        mensagem +=
            ' A conta pode ter sido criada no Authentication sem o documento no Firestore.';
      }

      _mostrarMensagem(
        mensagem,
        cor: Colors.red,
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
                          hint: 'Digite o seu CPF',
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

                            if (!_cpfValido(cpf)) {
                              return 'Informe um CPF válido';
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
                          initialValue: tipoUsuario,
                          decoration: estiloCampo(
                            hint: 'Selecione o tipo',
                            icone: Icons.manage_accounts_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin'),
                            ),
                            DropdownMenuItem(
                              value: 'funcionario',
                              child: Text('Funcionário'),
                            ),
                          ],
                          onChanged: _carregando
                              ? null
                              : (value) {
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

                        const SizedBox(height: 28),

                        // BOTÃO CADASTRAR
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _carregando
                                ? null
                                : cadastrarUsuario,
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
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
                            onPressed: _carregando
                                ? null
                                : () {
                                    _formKey.currentState?.reset();

                                    nomeController.clear();
                                    emailController.clear();
                                    senhaController.clear();
                                    cpfController.clear();

                                    setState(() {
                                      tipoUsuario = null;
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
