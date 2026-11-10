
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/menu-perfil.dart';

class ListaFuncionariosScreen extends StatefulWidget {
  final int animationKey;

  const ListaFuncionariosScreen({
    super.key,
    this.animationKey = 0,
  });

  @override
  State<ListaFuncionariosScreen> createState() =>
      _ListaFuncionariosScreenState();
}

class _ListaFuncionariosScreenState
    extends State<ListaFuncionariosScreen>
    with TickerProviderStateMixin {
  final TextEditingController buscaController =
      TextEditingController();

  final FocusNode buscaFocusNode = FocusNode();

  // Atualiza somente a listagem, sem reconstruir a tela inteira.
  final ValueNotifier<int> atualizacaoResultados =
      ValueNotifier<int>(0);

  late final AnimationController _animacaoController;
  late final AnimationController _resultadosController;

  String filtroStatus = 'Todos';
  String filtroTipo = 'Todos';

  final CollectionReference<Map<String, dynamic>> usuariosRef =
      FirebaseFirestore.instance.collection('usuarios');

  @override
  void initState() {
    super.initState();

    _animacaoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _resultadosController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _animacaoController.forward();
    _resultadosController.forward();
  }

  @override
  void didUpdateWidget(
    covariant ListaFuncionariosScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animationKey != widget.animationKey) {
      _animacaoController.forward(from: 0);
      _resultadosController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    buscaController.dispose();
    buscaFocusNode.dispose();
    atualizacaoResultados.dispose();
    _animacaoController.dispose();
    _resultadosController.dispose();

    super.dispose();
  }

  // Animação geral de entrada da tela.
  Widget animarEntrada(Widget child) {
    return AnimatedBuilder(
      animation: _animacaoController,
      child: child,
      builder: (context, child) {
        final progresso = Curves.easeOutCubic.transform(
          (_animacaoController.value / 0.55).clamp(0.0, 1.0),
        );

        return Opacity(
          opacity: progresso,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - progresso)),
            child: child,
          ),
        );
      },
    );
  }

  // Reinicia somente a animação dos resultados.
  void reiniciarAnimacaoResultados() {
    _resultadosController.forward(from: 0);
  }

  // Atualiza a listagem sem reconstruir o campo de pesquisa.
  void atualizarResultados() {
    atualizacaoResultados.value++;
    reiniciarAnimacaoResultados();
  }

  Future<void> abrirCadastroUsuario() async {
    await Navigator.pushNamed(
      context,
      '/cadastro-usuarios',
    );

    if (!mounted) return;

    // Reinicia a animação geral da tela.
    _animacaoController.forward(from: 0);

    // Reinicia a animação dos cards.
    _resultadosController.forward(from: 0);
  }

  // Anima os cards em sequência.
  Widget animarCard(int indice, Widget child) {
    final inicio = (0.08 + indice * 0.07).clamp(0.0, 0.65);
    final fim = (inicio + 0.35).clamp(0.0, 1.0);

    final animacao = CurvedAnimation(
      parent: _resultadosController,
      curve: Interval(
        inicio.toDouble(),
        fim.toDouble(),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animacao,
      child: child,
      builder: (context, child) {
        return Opacity(
          opacity: animacao.value,
          child: Transform.translate(
            offset: Offset(
              0,
              22 * (1 - animacao.value),
            ),
            child: child,
          ),
        );
      },
    );
  }

  // Normaliza os tipos de usuários.
  String normalizarTipo(String? tipo) {
    final valor = (tipo ?? '').trim().toLowerCase();

    if (valor == 'admin' || valor == 'administrador') {
      return 'admin';
    }

    if (valor == 'funcionário' || valor == 'funcionario') {
      return 'funcionario';
    }

    return valor;
  }

  String nomeTipo(String? tipo) {
    switch (normalizarTipo(tipo)) {
      case 'admin':
        return 'Admin';
      case 'funcionario':
        return 'Funcionário';
      default:
        return tipo ?? 'Não informado';
    }
  }

  // Filtra e ordena os usuários.
  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      filtrarUsuarios(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documentos,
  ) {
    final busca = buscaController.text.trim().toLowerCase();

    final buscaSemPontuacao =
        busca.replaceAll(RegExp(r'\D'), '');

    final resultado = documentos.where((documento) {
      final dados = documento.data();

      final nome =
          (dados['nomeCompleto'] ?? '').toString().toLowerCase();

      final email =
          (dados['email'] ?? '').toString().toLowerCase();

      final cpf = (dados['cpf'] ?? '').toString();
      final cpfNumeros = cpf.replaceAll(RegExp(r'\D'), '');

      final tipo = normalizarTipo(
        dados['tipoUsuario']?.toString(),
      );

      final ativo = dados['ativo'] == true;

      final correspondeBusca =
          busca.isEmpty ||
          nome.contains(busca) ||
          email.contains(busca) ||
          cpf.contains(busca) ||
          (buscaSemPontuacao.isNotEmpty &&
              cpfNumeros.contains(buscaSemPontuacao));

      final correspondeStatus =
          filtroStatus == 'Todos' ||
          (filtroStatus == 'Ativos' && ativo) ||
          (filtroStatus == 'Inativos' && !ativo);

      final correspondeTipo =
          filtroTipo == 'Todos' ||
          (filtroTipo == 'Admin' && tipo == 'admin') ||
          (filtroTipo == 'Funcionário' &&
              tipo == 'funcionario');

      return correspondeBusca &&
          correspondeStatus &&
          correspondeTipo;
    }).toList();

    resultado.sort((a, b) {
      final dadosA = a.data();
      final dadosB = b.data();

      final ativoA = dadosA['ativo'] == true;
      final ativoB = dadosB['ativo'] == true;

      // Ativos primeiro.
      if (ativoA != ativoB) {
        return ativoA ? -1 : 1;
      }

      // Ordem alfabética.
      final nomeA =
          (dadosA['nomeCompleto'] ?? '').toString().toLowerCase();

      final nomeB =
          (dadosB['nomeCompleto'] ?? '').toString().toLowerCase();

      return nomeA.compareTo(nomeB);
    });

    return resultado;
  }

  // Exibe mensagens para o usuário.
  void mostrarMensagem(
    String mensagem, {
    bool erro = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: erro
              ? Colors.red
              : const Color(0xFF2563EB),
        ),
      );
  }

  // Cadastro disponível somente para administradores ativos.
  Widget botaoCadastrarUsuario() {
    final usuarioLogado = FirebaseAuth.instance.currentUser;

    if (usuarioLogado == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: usuariosRef.doc(usuarioLogado.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final dados = snapshot.data!.data();

        final tipo = normalizarTipo(
          dados?['tipoUsuario']?.toString(),
        );

        final ativo = dados?['ativo'] == true;

        final ehAdmin = tipo == 'admin' && ativo;

        if (!ehAdmin) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: abrirCadastroUsuario,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Cadastrar usuário'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }

  // Altera o status no Firestore.
  Future<void> alterarStatus(
    QueryDocumentSnapshot<Map<String, dynamic>> documento,
  ) async {
    final dados = documento.data();
    final ativoAtual = dados['ativo'] == true;

    final usuarioLogado = FirebaseAuth.instance.currentUser;

    if (usuarioLogado?.uid == documento.id) {
      mostrarMensagem(
        'Você não pode alterar o status da própria conta.',
        erro: true,
      );
      return;
    }

    try {
      await usuariosRef.doc(documento.id).update({
        'ativo': !ativoAtual,
      });

      mostrarMensagem(
        ativoAtual
            ? 'Usuário inativado com sucesso.'
            : 'Usuário reativado com sucesso.',
      );
    } on FirebaseException catch (e) {
      mostrarMensagem(
        e.code == 'permission-denied'
            ? 'Você não tem permissão para alterar este usuário.'
            : 'Não foi possível alterar o status do usuário.',
        erro: true,
      );
    } catch (_) {
      mostrarMensagem(
        'Ocorreu um erro ao alterar o status.',
        erro: true,
      );
    }
  }

  // Edita os dados do usuário.
  Future<void> editarFuncionario(
    QueryDocumentSnapshot<Map<String, dynamic>> documento,
  ) async {
    final usuarioLogado = FirebaseAuth.instance.currentUser;

    if (usuarioLogado?.uid == documento.id) {
      mostrarMensagem(
        'Você não pode editar sua própria conta.',
        erro: true,
      );
      return;
    }

    final dados = documento.data();

    final nomeController = TextEditingController(
      text: (dados['nomeCompleto'] ?? '').toString(),
    );

    final emailController = TextEditingController(
      text: (dados['email'] ?? '').toString(),
    );

    final cpfController = TextEditingController(
      text: (dados['cpf'] ?? '').toString(),
    );

    String tipoSelecionado =
        normalizarTipo(dados['tipoUsuario']?.toString());

    final nomeOriginal = nomeController.text.trim();
    final tipoOriginal = tipoSelecionado;

    final formKey = GlobalKey<FormState>();

    try {
      final salvar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (contexto, atualizarDialogo) {
              final houveAlteracao =
                  nomeController.text.trim() != nomeOriginal ||
                  tipoSelecionado != tipoOriginal;

              return AlertDialog(
                title: const Text('Editar usuário'),
                content: SizedBox(
                  width: 400,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: nomeController,
                            onChanged: (valor) {
                              atualizarDialogo(() {});
                            },
                            decoration: const InputDecoration(
                              labelText: 'Nome completo',
                              prefixIcon: Icon(
                                Icons.person_outline,
                              ),
                            ),
                            validator: (valor) {
                              if (valor == null ||
                                  valor.trim().isEmpty) {
                                return 'Informe o nome.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: emailController,
                            readOnly: true,
                            keyboardType:
                                TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                              ),
                              helperText:
                                  'O e-mail é gerenciado pelo Firebase Authentication.',
                            ),
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: cpfController,
                            readOnly: true,
                            enableInteractiveSelection: false,
                            showCursor: false,
                            decoration: const InputDecoration(
                              labelText: 'CPF',
                              prefixIcon: Icon(
                                Icons.badge_outlined,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            initialValue: tipoSelecionado.isEmpty
                                ? null
                                : tipoSelecionado,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de usuário',
                              prefixIcon: Icon(
                                Icons.manage_accounts_outlined,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'funcionario',
                                child: Text('Funcionário'),
                              ),
                              DropdownMenuItem(
                                value: 'admin',
                                child: Text('Administrador'),
                              ),
                            ],
                            onChanged: (valor) {
                              if (valor != null) {
                                atualizarDialogo(() {
                                  tipoSelecionado = valor;
                                });
                              }
                            },
                            validator: (valor) {
                              if (valor == null) {
                                return 'Selecione o tipo.';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                    },
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: houveAlteracao
                        ? () {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(dialogContext, true);
                            }
                          }
                        : null,
                    child: const Text('Salvar alterações'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (salvar != true || !mounted) {
        return;
      }

      await usuariosRef.doc(documento.id).update({
        'nomeCompleto': nomeController.text.trim(),
        'tipoUsuario': tipoSelecionado,
      });

      mostrarMensagem('Usuário atualizado com sucesso!');
    } on FirebaseException catch (e) {
      mostrarMensagem(
        e.code == 'permission-denied'
            ? 'Você não tem permissão para editar este usuário.'
            : 'Não foi possível atualizar os dados.',
        erro: true,
      );
    } catch (_) {
      mostrarMensagem(
        'Ocorreu um erro ao editar o usuário.',
        erro: true,
      );
    } finally {
      nomeController.dispose();
      emailController.dispose();
      cpfController.dispose();
    }
  }

  // Estilo dos filtros.
  InputDecoration estiloFiltro({
    required String titulo,
    required IconData icone,
  }) {
    return InputDecoration(
      labelText: titulo,
      prefixIcon: Icon(
        icone,
        color: const Color(0xFF64748B),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // Constrói a listagem separadamente da tela principal.
  Widget construirListaUsuarios(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documentos,
  ) {
    return ValueListenableBuilder<int>(
      valueListenable: atualizacaoResultados,
      builder: (context, _, child) {
        final lista = filtrarUsuarios(documentos);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Lista de usuários',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Text(
                  '${lista.length} encontrados',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (lista.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.person_search_outlined,
                      size: 42,
                      color: Color(0xFF94A3B8),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Nenhum usuário encontrado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...lista.asMap().entries.map((entrada) {
                final indice = entrada.key;
                final documento = entrada.value;
                final dados = documento.data();

                final ehUsuarioLogado =
                    FirebaseAuth.instance.currentUser?.uid ==
                        documento.id;

                final nome =
                    (dados['nomeCompleto'] ?? '').toString();

                final email =
                    (dados['email'] ?? '').toString();

                final cpf =
                    (dados['cpf'] ?? '').toString();

                final tipo = nomeTipo(
                  dados['tipoUsuario']?.toString(),
                );

                final ativo = dados['ativo'] == true;

                final iniciais = nome
                    .split(' ')
                    .where((parte) => parte.isNotEmpty)
                    .take(2)
                    .map((parte) => parte[0])
                    .join()
                    .toUpperCase();

                return animarCard(
                  indice,
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  const Color(0xFFDBEAFE),
                              child: Text(
                                iniciais.isEmpty ? '?' : iniciais,
                                style: const TextStyle(
                                  color: Color(0xFF1D4ED8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nome,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    email,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  Text(
                                    'Tipo: $tipo',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),

                                  const SizedBox(height: 3),

                                  Text(
                                    'CPF: $cpf',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: ativo
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFF1F5F9),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                ativo ? 'Ativo' : 'Inativo',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: ativo
                                      ? const Color(0xFF166534)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (!ehUsuarioLogado) ...[
                          const SizedBox(height: 12),

                          const Divider(
                            color: Color(0xFFE2E8F0),
                          ),

                          const SizedBox(height: 4),

                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () =>
                                      editarFuncionario(documento),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Editar'),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        const Color(0xFF2563EB),
                                  ),
                                ),
                              ),

                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () =>
                                      alterarStatus(documento),
                                  icon: Icon(
                                    ativo
                                        ? Icons.person_off_outlined
                                        : Icons.person_outline,
                                    size: 18,
                                  ),
                                  label: Text(
                                    ativo ? 'Inativar' : 'Reativar',
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: ativo
                                        ? const Color(0xFFB45309)
                                        : const Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: usuariosRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2563EB),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 45,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Não foi possível carregar os usuários.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final documentos = snapshot.data?.docs ?? [];

            final totalAtivos = documentos.where((doc) {
              return doc.data()['ativo'] == true;
            }).length;

            return animarEntrada(
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CABEÇALHO
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Usuários',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const MenuPerfil(),
                      ],
                    ),

                    const SizedBox(height: 4),

                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text(
                        'Gerencie os usuários do EcoChef.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // RESUMO DE USUÁRIOS ATIVOS
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
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
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.groups_outlined,
                              color: Color(0xFF2563EB),
                              size: 28,
                            ),
                          ),

                          const SizedBox(width: 14),

                          const Expanded(
                            child: Text(
                              'Usuários ativos',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),

                          Text(
                            '$totalAtivos',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // CADASTRAR USUÁRIO
                    botaoCadastrarUsuario(),

                    const SizedBox(height: 24),

                    // PESQUISA
                    const Text(
                      'Pesquisar usuários',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      key: const ValueKey('pesquisa-usuarios'),
                      controller: buscaController,
                      focusNode: buscaFocusNode,
                      onChanged: (_) {
                        atualizarResultados();
                      },
                      decoration: InputDecoration(
                        hintText: 'Nome, e-mail ou CPF',
                        prefixIcon: const Icon(
                          Icons.search,
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
                      ),
                    ),

                    const SizedBox(height: 16),

                    // FILTRO DE STATUS
                    DropdownButtonFormField<String>(
                      initialValue: filtroStatus,
                      decoration: estiloFiltro(
                        titulo: 'Filtrar por status',
                        icone: Icons.toggle_on_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Todos',
                          child: Text('Todos os status'),
                        ),
                        DropdownMenuItem(
                          value: 'Ativos',
                          child: Text('Ativos'),
                        ),
                        DropdownMenuItem(
                          value: 'Inativos',
                          child: Text('Inativos'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null && filtroStatus != value) {
                          filtroStatus = value;
                          atualizarResultados();
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // FILTRO DE TIPO
                    DropdownButtonFormField<String>(
                      initialValue: filtroTipo,
                      decoration: estiloFiltro(
                        titulo: 'Filtrar por tipo',
                        icone: Icons.manage_accounts_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Todos',
                          child: Text('Todos os tipos'),
                        ),
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
                        if (value != null && filtroTipo != value) {
                          filtroTipo = value;
                          atualizarResultados();
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // LISTAGEM INDEPENDENTE DA PESQUISA
                    construirListaUsuarios(documentos),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
