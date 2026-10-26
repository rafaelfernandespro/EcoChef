
import 'package:flutter/material.dart';

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

  // Dados fictícios para testar a interface.
  final List<Map<String, dynamic>> funcionarios = [
    {
      'nome': 'Ana Souza',
      'email': 'ana@exemplo.com',
      'cpf': '123.456.789-00',
      'tipo': 'Funcionário',
      'status': true,
    },
    {
      'nome': 'Carlos Lima',
      'email': 'carlos@exemplo.com',
      'cpf': '987.654.321-00',
      'tipo': 'Admin',
      'status': true,
    },
    {
      'nome': 'Mariana Oliveira',
      'email': 'mariana@exemplo.com',
      'cpf': '111.222.333-44',
      'tipo': 'Funcionário',
      'status': false,
    },
  ];

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
  }

  // Filtrar por pesquisa, status e tipo.
  List<Map<String, dynamic>> get funcionariosFiltrados {
    final busca = buscaController.text.toLowerCase().trim();

    return funcionarios.where((funcionario) {
      final nome =
          funcionario['nome'].toString().toLowerCase();
      final email =
          funcionario['email'].toString().toLowerCase();
      final cpf = funcionario['cpf'].toString();
      final tipo = funcionario['tipo'] as String;
      final ativo = funcionario['status'] as bool;

      final correspondeBusca =
          nome.contains(busca) ||
          email.contains(busca) ||
          cpf.contains(busca);

      final correspondeStatus =
          filtroStatus == 'Todos' ||
          (filtroStatus == 'Ativos' && ativo) ||
          (filtroStatus == 'Inativos' && !ativo);

      final correspondeTipo =
          filtroTipo == 'Todos' || tipo == filtroTipo;

      return correspondeBusca &&
          correspondeStatus &&
          correspondeTipo;
    }).toList();
  }

  // Alterar status do funcionário.
  void alterarStatus(Map<String, dynamic> funcionario) {
    setState(() {
      funcionario['status'] =
          !(funcionario['status'] as bool);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          funcionario['status']
              ? 'Funcionário reativado.'
              : 'Funcionário inativado.',
        ),
        backgroundColor: const Color(0xFF2563EB),
      ),
    );
  }

  // Ação provisória para edição.
  
Future<void> editarFuncionario(
  Map<String, dynamic> funcionario,
) async {
  final nomeController = TextEditingController(
    text: funcionario['nome'] as String,
  );
  final emailController = TextEditingController(
    text: funcionario['email'] as String,
  );
  final cpfController = TextEditingController(
    text: funcionario['cpf'] as String,
  );

  String tipoSelecionado = funcionario['tipo'] as String;
  final formKey = GlobalKey<FormState>();

  try {
    final salvar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (contexto, atualizarDialogo) {
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
                          decoration: const InputDecoration(
                            labelText: 'Nome completo',
                            prefixIcon: Icon(Icons.person_outline),
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
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (valor) {
                            if (valor == null ||
                                !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                    .hasMatch(valor.trim())) {
                              return 'Informe um e-mail válido.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: cpfController,
                          decoration: const InputDecoration(
                            labelText: 'CPF',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (valor) {
                            if (valor == null ||
                                valor.trim().isEmpty) {
                              return 'Informe o CPF.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: tipoSelecionado,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de usuário',
                            prefixIcon: Icon(
                              Icons.manage_accounts_outlined,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Funcionário',
                              child: Text('Funcionário'),
                            ),
                            DropdownMenuItem(
                              value: 'Admin',
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
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                  child: const Text('Salvar alterações'),
                ),
              ],
            );
          },
        );
      },
    );

    if (salvar == true && mounted) {
      setState(() {
        funcionario['nome'] = nomeController.text.trim();
        funcionario['email'] = emailController.text.trim();
        funcionario['cpf'] = cpfController.text.trim();
        funcionario['tipo'] = tipoSelecionado;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário atualizado com sucesso!'),
          backgroundColor: Color(0xFF2563EB),
        ),
      );
    }
  } finally {
    nomeController.dispose();
    emailController.dispose();
    cpfController.dispose();
  }
}


  @override
  Widget build(BuildContext context) {
    final lista = funcionariosFiltrados;

    final totalAtivos = funcionarios
        .where((f) => f['status'] == true)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Usuários',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
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

              // RESUMO DE FUNCIONÁRIOS ATIVOS
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

              // BOTÃO CADASTRAR
              SizedBox(
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
              ),

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
                ),
              ),

              const SizedBox(height: 16),

              // FILTRO DE STATUS
              DropdownButtonFormField<String>(
                value: filtroStatus,
                decoration: InputDecoration(
                  labelText: 'Filtrar por status',
                  prefixIcon: const Icon(
                    Icons.toggle_on_outlined,
                    color: Color(0xFF64748B),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                value: filtroTipo,
                decoration: InputDecoration(
                  labelText: 'Filtrar por tipo',
                  prefixIcon: const Icon(
                    Icons.manage_accounts_outlined,
                    color: Color(0xFF64748B),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                ...lista.map((funcionario) {
                  final nome = funcionario['nome'] as String;
                  final email = funcionario['email'] as String;
                  final tipo = funcionario['tipo'] as String;
                  final ativo = funcionario['status'] as bool;

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
                                iniciais,
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
                                borderRadius: BorderRadius.circular(20),
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

                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 4),

                        // AÇÕES
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () =>
                                    editarFuncionario(funcionario),
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
                                    alterarStatus(funcionario),
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
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
