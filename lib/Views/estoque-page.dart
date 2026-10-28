
import 'package:flutter/material.dart';
import 'cadastrar-produto.dart';


const azulPrincipal = Color(0xFF2563EB);
const azulEscuro = Color(0xFF1E3A8A);
const fundo = Color(0xFFF8FAFC);
const textoPrincipal = Color(0xFF1E293B);
const textoSecundario = Color(0xFF64748B);
const borda = Color(0xFFE2E8F0);

const verdeStatus = Color(0xFF16A34A);
const vermelhoStatus = Color(0xFFDC2626);
const amareloStatus = Color(0xFFD97706);

class ProdutoEstoque {
  final String nome;
  final double quantidade;
  final String tipo;
  final DateTime? validade;
  final String status;

  const ProdutoEstoque({
    required this.nome,
    required this.quantidade,
    required this.tipo,
    required this.validade,
    required this.status,
  });
}

class EstoquePage extends StatefulWidget {
  const EstoquePage({super.key});

  @override
  State<EstoquePage> createState() => _EstoquePageState();
}

class _EstoquePageState extends State<EstoquePage> {
  final TextEditingController pesquisaController =
      TextEditingController();

  String filtroStatus = 'Todos';
  String filtroTipo = 'Todos';

  // Dados fictícios para demonstrar a tela.
  final List<ProdutoEstoque> produtos = [
    ProdutoEstoque(
      nome: 'Arroz',
      quantidade: 24.5,
      tipo: 'Grãos',
      validade: DateTime(2026, 11, 15),
      status: 'Disponível',
    ),
    ProdutoEstoque(
      nome: 'Tomate',
      quantidade: 3.2,
      tipo: 'Hortifruti',
      validade: DateTime(2026, 10, 28),
      status: 'Abaixo do mínimo',
    ),
    ProdutoEstoque(
      nome: 'Leite',
      quantidade: 0,
      tipo: 'Laticínios',
      validade: null,
      status: 'Em falta',
    ),
    ProdutoEstoque(
      nome: 'Feijão',
      quantidade: 18.0,
      tipo: 'Grãos',
      validade: DateTime(2026, 12, 10),
      status: 'Disponível',
    ),
    ProdutoEstoque(
      nome: 'Queijo',
      quantidade: 2.5,
      tipo: 'Laticínios',
      validade: DateTime(2026, 10, 30),
      status: 'Abaixo do mínimo',
    ),
    ProdutoEstoque(
      nome: 'Batata',
      quantidade: 15.0,
      tipo: 'Hortifruti',
      validade: DateTime(2026, 11, 5),
      status: 'Disponível',
    ),
  ];

  @override
  void dispose() {
    pesquisaController.dispose();
    super.dispose();
  }

  List<String> get tiposDisponiveis {
    final tipos = produtos.map((p) => p.tipo).toSet().toList();
    tipos.sort();
    return ['Todos', ...tipos];
  }

  List<ProdutoEstoque> get produtosFiltrados {
    final pesquisa = pesquisaController.text.toLowerCase().trim();

    return produtos.where((produto) {
      final correspondeNome =
          produto.nome.toLowerCase().contains(pesquisa);

      final correspondeStatus = filtroStatus == 'Todos' ||
          produto.status == filtroStatus;

      final correspondeTipo =
          filtroTipo == 'Todos' || produto.tipo == filtroTipo;

      return correspondeNome &&
          correspondeStatus &&
          correspondeTipo;
    }).toList();
  }

  Color corStatus(String status) {
    switch (status) {
      case 'Disponível':
        return verdeStatus;
      case 'Em falta':
        return vermelhoStatus;
      case 'Abaixo do mínimo':
        return amareloStatus;
      default:
        return textoSecundario;
    }
  }

  String formatarData(DateTime? data) {
    if (data == null) return 'Sem lote disponível';

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  // Abre a tela de cadastro e recebe o produto cadastrado.
  Future<void> _abrirCadastroProduto() async {
    final resultado = await Navigator.push<ProdutoEstoque>(
      context,
      MaterialPageRoute(
        builder: (context) => CadastrarProdutoPage(),
      ),
    );

    if (!mounted || resultado == null) return;

    setState(() {
      produtos.add(resultado);

      // Atualiza os filtros para mostrar o novo produto.
      filtroStatus = 'Todos';
      filtroTipo = 'Todos';
      pesquisaController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${resultado.nome} cadastrado com sucesso!',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = produtosFiltrados;

    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cabecalho(context),
                    const SizedBox(height: 28),
                    const Text(
                      'Estoque',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Consulte os produtos e acompanhe suas quantidades.',
                      style: TextStyle(
                        fontSize: 14,
                        color: textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _campoPesquisa(),
                    const SizedBox(height: 12),
                    _filtros(),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Text(
                          'Produtos cadastrados',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textoPrincipal,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${lista.length} ${lista.length == 1 ? 'produto' : 'produtos'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: textoSecundario,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (lista.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 44,
                          color: textoSecundario,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Nenhum produto encontrado.',
                          style: TextStyle(
                            color: textoSecundario,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _cardProduto(lista[index]),
                      );
                    },
                    childCount: lista.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarOpcoesEstoque,
        backgroundColor: azulPrincipal,
        foregroundColor: Colors.white,
        tooltip: 'Opções de estoque',
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  // Menu de operações do estoque.
  void _mostrarOpcoesEstoque() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: borda,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Gerenciar estoque',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textoPrincipal,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Escolha uma operação',
                  style: TextStyle(
                    color: textoSecundario,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),

                _opcaoEstoque(
                  icone: Icons.add_box_outlined,
                  titulo: 'Cadastrar produto',
                  descricao: 'Adicionar um novo produto ao catálogo',
                  cor: azulPrincipal,
                  aoTocar: () {
                    Navigator.pop(context);
                    _abrirCadastroProduto();
                  },
                ),

                _opcaoEstoque(
                  icone: Icons.south_west,
                  titulo: 'Registrar entrada',
                  descricao: 'Adicionar quantidade ao estoque',
                  cor: verdeStatus,
                  aoTocar: () {
                    Navigator.pop(context);
                    _mostrarAvisoOpcaoEmDesenvolvimento(
                      'Registro de entrada',
                    );
                  },
                ),

                _opcaoEstoque(
                  icone: Icons.north_east,
                  titulo: 'Registrar saída / dar baixa',
                  descricao: 'Retirar quantidade e informar o motivo',
                  cor: vermelhoStatus,
                  aoTocar: () {
                    Navigator.pop(context);
                    _mostrarAvisoOpcaoEmDesenvolvimento(
                      'Registro de saída',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarAvisoOpcaoEmDesenvolvimento(String opcao) {
    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Text('$opcao: tela ainda não conectada.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _opcaoEstoque({
    required IconData icone,
    required String titulo,
    required String descricao,
    required Color cor,
    required VoidCallback aoTocar,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        vertical: 5,
        horizontal: 4,
      ),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icone, color: cor, size: 25),
      ),
      title: Text(
        titulo,
        style: const TextStyle(
          color: textoPrincipal,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        descricao,
        style: const TextStyle(
          color: textoSecundario,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: textoSecundario,
      ),
      onTap: aoTocar,
    );
  }

  Widget _cabecalho(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: azulPrincipal,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.restaurant_menu,
            color: Colors.white,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EcoChef',
                style: TextStyle(
                  color: azulEscuro,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Gestão inteligente',
                style: TextStyle(
                  color: textoSecundario,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            // TODO: abrir perfil do usuário.
          },
          icon: const Icon(
            Icons.account_circle_outlined,
            color: azulEscuro,
            size: 30,
          ),
        ),
      ],
    );
  }

  Widget _campoPesquisa() {
    return TextField(
      controller: pesquisaController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Pesquisar produto...',
        hintStyle: const TextStyle(color: textoSecundario),
        prefixIcon: const Icon(
          Icons.search,
          color: textoSecundario,
        ),
        suffixIcon: pesquisaController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  pesquisaController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borda),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borda),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: azulPrincipal),
        ),
      ),
    );
  }

  Widget _filtros() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.filter_list,
              size: 19,
              color: textoSecundario,
            ),
            SizedBox(width: 6),
            Text(
              'Filtrar listagem',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textoSecundario,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _dropdownFiltro(
                valor: filtroStatus,
                itens: const [
                  'Todos',
                  'Disponível',
                  'Em falta',
                  'Abaixo do mínimo',
                ],
                dica: 'Status',
                aoMudar: (valor) {
                  setState(() => filtroStatus = valor!);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dropdownFiltro(
                valor: filtroTipo,
                itens: tiposDisponiveis,
                dica: 'Tipo',
                aoMudar: (valor) {
                  setState(() => filtroTipo = valor!);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dropdownFiltro({
    required String valor,
    required List<String> itens,
    required String dica,
    required ValueChanged<String?> aoMudar,
  }) {
    return DropdownButtonFormField<String>(
      value: valor,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: dica,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borda),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borda),
        ),
      ),
      items: itens.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
      onChanged: aoMudar,
    );
  }

  Widget _cardProduto(ProdutoEstoque produto) {
    final cor = corStatus(produto.status);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borda),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: cor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produto.nome,
                  style: const TextStyle(
                    color: textoPrincipal,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    produto.tipo,
                    style: const TextStyle(
                      color: azulEscuro,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: textoSecundario,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Próximo vencimento: ${formatarData(produto.validade)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: textoSecundario,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    produto.status,
                    style: TextStyle(
                      color: cor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Quantidade',
                style: TextStyle(
                  fontSize: 11,
                  color: textoSecundario,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${produto.quantidade.toStringAsFixed(1).replaceAll('.', ',')} kg',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: azulEscuro,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
