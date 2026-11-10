import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const azulPrincipal = Color(0xFF2563EB);
const azulEscuro = Color(0xFF1E3A8A);
const fundo = Color(0xFFF8FAFC);
const textoPrincipal = Color(0xFF1E293B);
const textoSecundario = Color(0xFF64748B);
const borda = Color(0xFFE2E8F0);

class HistoricoDesperdicioPage extends StatefulWidget {
  const HistoricoDesperdicioPage({super.key});

  @override
  State<HistoricoDesperdicioPage> createState() =>
      _HistoricoDesperdicioPageState();
}

class _HistoricoDesperdicioPageState extends State<HistoricoDesperdicioPage>
    with TickerProviderStateMixin {
  final pesquisaController = TextEditingController();
  final atualizacaoResultados = ValueNotifier<int>(0);

  late final AnimationController _entradaController;
  late final AnimationController _resultadosController;

  String pesquisa = '';
  DateTime? dataInicial;
  DateTime? dataFinal;
  String? motivoSelecionado;

  @override
  void initState() {
    super.initState();

    _entradaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _resultadosController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _entradaController.forward();
    _resultadosController.forward();
  }

  @override
  void dispose() {
    pesquisaController.dispose();
    atualizacaoResultados.dispose();
    _entradaController.dispose();
    _resultadosController.dispose();
    super.dispose();
  }

  void atualizarResultados() {
    atualizacaoResultados.value++;
    _resultadosController.forward(from: 0);
  }

  String formatarData(dynamic valor) {
    if (valor is! Timestamp) return 'Data indisponível';

    final data = valor.toDate();

    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  Future<void> selecionarData(bool inicial) async {
    final agora = DateTime.now();
    final dataAtual = inicial ? dataInicial : dataFinal;

    final selecionada = await showDatePicker(
      context: context,
      initialDate: dataAtual ?? (inicial ? dataFinal : dataInicial) ?? agora,
      firstDate: DateTime(2000),
      lastDate: agora,
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: azulPrincipal,
              onPrimary: Colors.white,
              onSurface: textoPrincipal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || selecionada == null) return;

    if (inicial) {
      dataInicial = selecionada;

      if (dataFinal != null && dataFinal!.isBefore(selecionada)) {
        dataFinal = selecionada;
      }
    } else {
      dataFinal = selecionada;

      if (dataInicial != null && dataInicial!.isAfter(selecionada)) {
        dataInicial = selecionada;
      }
    }

    atualizarResultados();
  }

  String formatarQuantidade(dynamic valor) {
    final quantidade = (valor as num?)?.toDouble() ?? 0;

    return quantidade.toStringAsFixed(2).replaceAll('.', ',');
  }

  Widget animarEntrada(Widget child) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entradaController,
        curve: Curves.easeOut,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _entradaController,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget animarCard({
    required Widget child,
    required int index,
    required int total,
  }) {
    final inicio = (index * 0.08).clamp(0.0, 0.70);
    final fim = (inicio + 0.35).clamp(0.0, 1.0);

    final curva = CurvedAnimation(
      parent: _resultadosController,
      curve: Interval(
        inicio,
        fim,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: curva,
      child: child,
      builder: (context, child) {
        return Opacity(
          opacity: curva.value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - curva.value)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textoPrincipal),
        title: const Text(
          'Histórico de desperdícios',
          style: TextStyle(
            color: textoPrincipal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: animarEntrada(
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: TextField(
                controller: pesquisaController,
                onChanged: (valor) {
                  pesquisa = valor.toLowerCase().trim();
                  atualizarResultados();
                },
                decoration: InputDecoration(
                  hintText: 'Pesquisar produto',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: textoSecundario,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: borda),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: borda),
                  ),
                ),
              ),
            ),

            // FILTRO POR PERÍODO
            ValueListenableBuilder<int>(
              valueListenable: atualizacaoResultados,
              builder: (context, _, __) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => selecionarData(true),
                          icon: const Icon(
                            Icons.calendar_month_outlined,
                            color: azulPrincipal,
                          ),
                          label: Text(
                            dataInicial == null
                                ? 'Data inicial'
                                : 'Início: ${formatarData(Timestamp.fromDate(dataInicial!))}',
                            style: const TextStyle(
                              color: azulPrincipal,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: borda),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => selecionarData(false),
                          icon: const Icon(
                            Icons.calendar_month_outlined,
                            color: azulPrincipal,
                          ),
                          label: Text(
                            dataFinal == null
                                ? 'Data final'
                                : 'Fim: ${formatarData(Timestamp.fromDate(dataFinal!))}',
                            style: const TextStyle(
                              color: azulPrincipal,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: borda),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (dataInicial != null || dataFinal != null)
                        IconButton(
                          tooltip: 'Limpar período',
                          onPressed: () {
                            dataInicial = null;
                            dataFinal = null;
                            atualizarResultados();
                          },
                          icon: const Icon(
                            Icons.close,
                            color: textoSecundario,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('produtos')
                    .snapshots(),
                builder: (context, produtosSnapshot) {
                  if (produtosSnapshot.hasError) {
                    return const Center(
                      child: Text('Erro ao carregar produtos.'),
                    );
                  }

                  if (!produtosSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: azulPrincipal,
                      ),
                    );
                  }

                  final nomesProdutos = <String, Map<String, dynamic>>{};

                  for (final doc in produtosSnapshot.data!.docs) {
                    nomesProdutos[doc.id] = doc.data();
                  }

                  return StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('desperdicios')
                        .orderBy(
                          'dataDesperdicio',
                          descending: true,
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Erro ao carregar histórico.'),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: azulPrincipal,
                          ),
                        );
                      }

                      final documentos = snapshot.data!.docs;

                      final motivos = documentos
                          .map((doc) =>
                              doc.data()['motivo']?.toString().trim() ?? '')
                          .where((motivo) => motivo.isNotEmpty)
                          .toSet()
                          .toList()
                        ..sort(
                          (a, b) =>
                              a.toLowerCase().compareTo(b.toLowerCase()),
                        );

                      return ValueListenableBuilder<int>(
                        valueListenable: atualizacaoResultados,
                        builder: (context, _, __) {
                          final motivoAtual =
                              motivos.contains(motivoSelecionado)
                                  ? motivoSelecionado
                                  : null;

                          final filtrados = documentos.where((doc) {
                            final dados = doc.data();

                            final produtoId =
                                dados['produtoId']?.toString() ?? '';

                            final nomeProduto =
                                nomesProdutos[produtoId]?['nome']
                                        ?.toString() ??
                                    'Produto não encontrado';

                            final motivo =
                                dados['motivo']?.toString() ?? '';

                            final correspondePesquisa = nomeProduto
                                .toLowerCase()
                                .contains(pesquisa);

                            final correspondeMotivo = motivoAtual == null ||
                                motivo == motivoAtual;

                            final valorData = dados['dataDesperdicio'];

                            final dataRegistro = valorData is Timestamp
                                ? valorData.toDate()
                                : null;

                            final inicio = dataInicial == null
                                ? null
                                : DateTime(
                                    dataInicial!.year,
                                    dataInicial!.month,
                                    dataInicial!.day,
                                  );

                            final fimExclusivo = dataFinal == null
                                ? null
                                : DateTime(
                                    dataFinal!.year,
                                    dataFinal!.month,
                                    dataFinal!.day + 1,
                                  );

                            final correspondeData =
                                (inicio == null ||
                                    (dataRegistro != null &&
                                        !dataRegistro.isBefore(inicio))) &&
                                (fimExclusivo == null ||
                                    (dataRegistro != null &&
                                        dataRegistro
                                            .isBefore(fimExclusivo)));

                            return correspondePesquisa &&
                                correspondeMotivo &&
                                correspondeData;
                          }).toList();

                          final semFiltros = pesquisa.isEmpty &&
                              dataInicial == null &&
                              dataFinal == null &&
                              motivoAtual == null;

                          return Column(
                            children: [
                              // SELETOR DE MOTIVOS
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 12),
                                child: DropdownButtonFormField<String>(
                                  value: motivoAtual ?? '',
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Filtrar por motivo',
                                    prefixIcon: const Icon(
                                      Icons.filter_list,
                                      color: textoSecundario,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 13,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: borda),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: borda),
                                    ),
                                  ),
                                  hint: const Text('Todos os motivos'),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: '',
                                      child: Text('Todos os motivos'),
                                    ),
                                    ...motivos.map(
                                      (motivo) => DropdownMenuItem<String>(
                                        value: motivo,
                                        child: Text(
                                          motivo,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (valor) {
                                    final novoMotivo =
                                        valor == null || valor.isEmpty
                                            ? null
                                            : valor;

                                    if (motivoSelecionado != novoMotivo) {
                                      motivoSelecionado = novoMotivo;
                                      atualizarResultados();
                                    }
                                  },
                                ),
                              ),

                              // LISTA DE DESPERDÍCIOS
                              Expanded(
                                child: filtrados.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                semFiltros
                                                    ? Icons.history
                                                    : Icons.search_off,
                                                size: 48,
                                                color: textoSecundario
                                                    .withValues(alpha: 0.6),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                semFiltros
                                                    ? 'Nenhum desperdício registrado.'
                                                    : 'Nenhum resultado encontrado para os filtros selecionados.',
                                                style: const TextStyle(
                                                  color: textoSecundario,
                                                  fontSize: 14,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          8,
                                          20,
                                          24,
                                        ),
                                        itemCount: filtrados.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          final doc = filtrados[index];
                                          final dados = doc.data();

                                          final produtoId =
                                              dados['produtoId']?.toString() ??
                                                  '';

                                          final produto =
                                              nomesProdutos[produtoId];

                                          final nomeProduto =
                                              produto?['nome']?.toString() ??
                                                  'Produto não encontrado';

                                          final unidade =
                                              produto?['unidade']?.toString() ??
                                                  'unidade';

                                          final motivo =
                                              dados['motivo']?.toString() ??
                                                  'Sem motivo';

                                          final quantidade =
                                              formatarQuantidade(
                                            dados['quantidade'],
                                          );

                                          final data = formatarData(
                                            dados['dataDesperdicio'],
                                          );

                                          // DOCUMENTOS ANTIGOS SEM O CAMPO
                                          // CONTINUAM SENDO CONSIDERADOS COMO
                                          // BAIXA DE ESTOQUE.
                                          final afetaEstoque =
                                              dados['afetaEstoque'] != false;

                                          return animarCard(
                                            index: index,
                                            total: filtrados.length,
                                            child: _cardDesperdicio(
                                              nomeProduto: nomeProduto,
                                              motivo: motivo,
                                              quantidade: quantidade,
                                              unidade: unidade,
                                              data: data,
                                              afetaEstoque: afetaEstoque,
                                              aoTocar: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        DetalhesDesperdicioPage(
                                                      desperdicioId: doc.id,
                                                      dados: dados,
                                                      nomeProduto: nomeProduto,
                                                      unidade: unidade,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardDesperdicio({
    required String nomeProduto,
    required String motivo,
    required String quantidade,
    required String unidade,
    required String data,
    required bool afetaEstoque,
    required VoidCallback aoTocar,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borda),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: azulPrincipal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: azulPrincipal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nomeProduto,
                          style: const TextStyle(
                            color: textoPrincipal,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          motivo,
                          style: const TextStyle(
                            color: textoSecundario,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: textoSecundario,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: borda, height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.scale_outlined,
                    size: 17,
                    color: textoSecundario,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$quantidade $unidade',
                    style: const TextStyle(
                      color: textoPrincipal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: textoSecundario,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    data,
                    style: const TextStyle(
                      color: textoSecundario,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _indicadorEstoque(afetaEstoque),
            ],
          ),
        ),
      ),
    );
  }

  Widget _indicadorEstoque(bool afetaEstoque) {
    final cor = afetaEstoque
        ? const Color(0xFFEA580C)
        : const Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            afetaEstoque ? Icons.remove_circle_outline : Icons.link,
            size: 15,
            color: cor,
          ),
          const SizedBox(width: 6),
          Text(
            afetaEstoque
                ? 'Descontado do estoque'
                : 'Vinculado a uma saída',
            style: TextStyle(
              color: cor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TELA DE DETALHES
// ============================================================

class DetalhesDesperdicioPage extends StatelessWidget {
  final String desperdicioId;
  final Map<String, dynamic> dados;
  final String nomeProduto;
  final String unidade;

  const DetalhesDesperdicioPage({
    super.key,
    required this.desperdicioId,
    required this.dados,
    required this.nomeProduto,
    required this.unidade,
  });

  String formatarData(dynamic valor) {
    if (valor is! Timestamp) return 'Data indisponível';

    final data = valor.toDate();

    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  String formatarQuantidade(dynamic valor) {
    final quantidade = (valor as num?)?.toDouble() ?? 0;

    return quantidade.toStringAsFixed(2).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final afetaEstoque = dados['afetaEstoque'] != false;
    final saidaId = dados['saidaId']?.toString();

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textoPrincipal),
        title: const Text(
          'Detalhes do desperdício',
          style: TextStyle(
            color: textoPrincipal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borda),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.delete_outline,
                    size: 42,
                    color: azulPrincipal,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nomeProduto,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: textoPrincipal,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${formatarQuantidade(dados['quantidade'])} $unidade',
                    style: const TextStyle(
                      color: azulPrincipal,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _statusEstoque(afetaEstoque),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Informações do registro',
              style: TextStyle(
                color: textoPrincipal,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _informacao(
              'Motivo',
              dados['motivo']?.toString() ?? 'Não informado',
              Icons.report_problem_outlined,
            ),
            _informacao(
              'Data do desperdício',
              formatarData(dados['dataDesperdicio']),
              Icons.calendar_today_outlined,
            ),
            _informacao(
              'Observação',
              dados['observacao']?.toString().trim().isNotEmpty == true
                  ? dados['observacao'].toString()
                  : 'Nenhuma observação informada.',
              Icons.notes_outlined,
            ),
            const SizedBox(height: 24),
            const Text(
              'Impacto no estoque',
              style: TextStyle(
                color: textoPrincipal,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _informacao(
              'Situação',
              afetaEstoque
                  ? 'Baixa realizada diretamente pelo desperdício.'
                  : 'Não houve nova baixa. O produto já havia sido retirado.',
              Icons.inventory_outlined,
            ),
            if (saidaId != null && saidaId.isNotEmpty) ...[
              const SizedBox(height: 8),
              _detalhesSaida(saidaId),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusEstoque(bool afetaEstoque) {
    final cor = afetaEstoque ? const Color(0xFFEA580C) : azulPrincipal;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        afetaEstoque
            ? 'Descontado do estoque'
            : 'Vinculado a uma saída',
        style: TextStyle(
          color: cor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _informacao(
    String titulo,
    String valor,
    IconData icone,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borda),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: textoSecundario, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: textoSecundario,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  valor,
                  style: const TextStyle(
                    color: textoPrincipal,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detalhesSaida(String saidaId) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('saidasEstoque')
          .doc(saidaId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: CircularProgressIndicator(
                color: azulPrincipal,
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _informacao(
            'Saída relacionada',
            'Registro de saída não encontrado.',
            Icons.receipt_long_outlined,
          );
        }

        final saida = snapshot.data!.data()!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _informacao(
              'Motivo da saída',
              saida['motivo']?.toString() ?? 'Não informado',
              Icons.receipt_long_outlined,
            ),
            _informacao(
              'Quantidade retirada',
              '${formatarQuantidade(saida['quantidade'])} $unidade',
              Icons.scale_outlined,
            ),
            _informacao(
              'Data da saída',
              formatarData(saida['dataSaida']),
              Icons.calendar_today_outlined,
            ),
          ],
        );
      },
    );
  }
}