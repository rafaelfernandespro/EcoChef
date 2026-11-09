
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/menu-perfil.dart';

class ListaFuncionariosScreen extends StatefulWidget {
  const ListaFuncionariosScreen({super.key});

  @override
  State<ListaFuncionariosScreen> createState() =>
      _ListaFuncionariosScreenState();
}

class _ListaFuncionariosScreenState
    extends State<ListaFuncionariosScreen> {
  final TextEditingController buscaController =
      TextEditingController();

  String filtroStatus = 'Todos';
  String filtroTipo = 'Todos';

  final CollectionReference<Map<String, dynamic>> usuariosRef =
      FirebaseFirestore.instance.collection('usuarios');

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
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

  // Filtra os usuários recebidos do Firestore.
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
  void mostrarMensagem(String mensagem, {bool erro = false}) {
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

  // Verifica o perfil do usuário conectado.
  // Somente administradores ativos visualizam o botão.
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
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/cadastro-usuarios',
              );
            },
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

  // Altera o status diretamente no Firestore.
  Future<void> alterarStatus(
    QueryDocumentSnapshot<Map<String, dynamic>> documento,
  ) async {
    final dados = documento.data();
    final ativoAtual = dados['ativo'] == true;

    // Impede que o administrador desative a própria conta.
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

  // Edita os dados do usuário no Firestore.
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

              final houveAlteracao = nomeController.text.trim() != nomeOriginal || tipoSelecionado != tipoOriginal;
              
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
                          // NOME
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

                          // EMAIL
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

                          // CPF
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

                          // TIPO DE USUÁRIO
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

      // Impede remover o próprio perfil de administrador.
      final usuarioLogado = FirebaseAuth.instance.currentUser;

      if (usuarioLogado?.uid == documento.id &&
          tipoSelecionado != 'admin') {
        mostrarMensagem(
          'Você não pode remover seu próprio perfil de administrador.',
          erro: true,
        );
        return;
      }

      // Atualiza os dados no Firestore.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: usuariosRef.snapshots(),
          builder: (context, snapshot) {
            // CARREGAMENTO
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2563EB),
                ),
              );
            }

            // ERRO DE CONSULTA
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

            // TOTAL DE USUÁRIOS ATIVOS
            final totalAtivos = documentos.where((doc) {
              return doc.data()['ativo'] == true;
            }).length;

            // APLICA OS FILTROS
            final lista = filtrarUsuarios(documentos);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CABEÇALHO - SOMENTE O TÍTULO
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
                            borderRadius: BorderRadius.circular(12),
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

                  // BOTÃO CADASTRAR - SOMENTE ADMINISTRADOR
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
                    controller: buscaController,
                    onChanged: (_) => setState(() {}),
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
                      if (value != null) {
                        setState(() {
                          filtroStatus = value;
                        });
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
                      if (value != null) {
                        setState(() {
                          filtroTipo = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // TÍTULO DA LISTA
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

                  // LISTA DE USUÁRIOS
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
                    ...lista.map((documento) {
                      final dados = documento.data();
                      final ehUsuarioLogado =
                        FirebaseAuth.instance.currentUser?.uid == documento.id;

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

                      return Container(
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
                                    iniciais.isEmpty
                                        ? '?'
                                        : iniciais,
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

                              // AÇÕES
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () => editarFuncionario(documento),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Editar'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),

                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () => alterarStatus(documento),
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
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
