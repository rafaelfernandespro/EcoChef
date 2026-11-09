import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'widgets/menu-perfil.dart';

const Color azulPrincipal = Color(0xFF2563EB);
const Color azulEscuro = Color(0xFF1E3A8A);
const Color fundo = Color(0xFFF8FAFC);
const Color textoPrincipal = Color(0xFF1E293B);
const Color textoSecundario = Color(0xFF64748B);
const Color borda = Color(0xFFE2E8F0);

enum PeriodoRelatorio { semana, mes, trimestre }

class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  PeriodoRelatorio periodo = PeriodoRelatorio.semana;
  String unidadeSelecionada = 'kg';

  DateTime get dataInicial {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    switch (periodo) {
      case PeriodoRelatorio.semana:
        return hoje.subtract(const Duration(days: 6));
      case PeriodoRelatorio.mes:
        return hoje.subtract(const Duration(days: 29));
      case PeriodoRelatorio.trimestre:
        return hoje.subtract(const Duration(days: 89));
    }
  }

  String get nomePeriodo {
    switch (periodo) {
      case PeriodoRelatorio.semana:
        return 'Últimos 7 dias';
      case PeriodoRelatorio.mes:
        return 'Últimos 30 dias';
      case PeriodoRelatorio.trimestre:
        return 'Últimos 90 dias';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('desperdicios')
              .snapshots(),
          builder: (context, desperdiciosSnapshot) {
            if (desperdiciosSnapshot.hasError) {
              return _mensagemErro();
            }

            if (!desperdiciosSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: azulPrincipal),
              );
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('produtos')
                  .snapshots(),
              builder: (context, produtosSnapshot) {
                if (produtosSnapshot.hasError) {
                  return _mensagemErro();
                }

                if (!produtosSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: azulPrincipal,
                    ),
                  );
                }

                final produtos = <String, Map<String, dynamic>>{};

                for (final doc in produtosSnapshot.data!.docs) {
                  produtos[doc.id] = doc.data();
                }

                final agora = DateTime.now();
                final inicioPeriodo = dataInicial;

                final registros = desperdiciosSnapshot.data!.docs
                    .map((doc) => doc.data())
                    .where((item) {
                  final data = item['dataDesperdicio'];

                  if (data is! Timestamp) return false;

                  final dataRegistro = data.toDate();

                  return !dataRegistro.isBefore(inicioPeriodo) &&
                      !dataRegistro.isAfter(agora);
                }).toList();

                final dados = registros.map((item) {
                  final produtoId = item['produtoId']?.toString() ?? '';
                  final produto = produtos[produtoId] ?? {};

                  final nome = produto['nome']?.toString() ??
                      'Produto não identificado';

                  final unidade = _normalizarUnidade(
                    item['unidade']?.toString() ??
                        produto['unidade']?.toString() ??
                        '',
                  );

                  final quantidade = _numero(item['quantidade']);

                  return _RegistroDesperdicio(
                    nome: nome,
                    quantidade: _converterQuantidade(
                      quantidade,
                      unidade,
                    ),
                    unidade: unidade,
                    motivo: _motivo(item['motivo']?.toString()),
                    data: (item['dataDesperdicio'] as Timestamp).toDate(),
                  );
                }).toList();

                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _cabecalho(),
                          const SizedBox(height: 26),
                          _tituloSecao('Período'),
                          const SizedBox(height: 12),
                          _filtrosPeriodo(),
                          const SizedBox(height: 26),
                          _tituloSecao('Evolução do desperdício'),
                          const SizedBox(height: 5),
                          const Text(
                            'Acompanhe a quantidade descartada ao longo do tempo.',
                            style: TextStyle(
                              color: textoSecundario,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _seletorUnidade(),
                          const SizedBox(height: 14),
                          _graficoEvolucao(dados),
                          const SizedBox(height: 28),
                          _tituloSecao('Motivos do desperdício'),
                          const SizedBox(height: 5),
                          const Text(
                            'Quantidade de registros por motivo.',
                            style: TextStyle(
                              color: textoSecundario,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _graficoMotivos(dados),
                          const SizedBox(height: 28),
                          _tituloSecao('Produtos mais desperdiçados'),
                          const SizedBox(height: 5),
                          const Text(
                            'Ranking separado por unidade de medida.',
                            style: TextStyle(
                              color: textoSecundario,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _rankingProdutos(dados),
                          const SizedBox(height: 24),
                          Center(
                            child: Text(
                              nomePeriodo,
                              style: const TextStyle(
                                color: textoSecundario,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _cabecalho() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Relatórios',
                style: TextStyle(
                  color: textoPrincipal,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Acompanhe os dados do desperdício.',
                style: TextStyle(
                  color: textoSecundario,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const MenuPerfil(),
      ],
    );
  }

  Widget _tituloSecao(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        color: textoPrincipal,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _filtrosPeriodo() {
    return Row(
      children: [
        _botaoPeriodo('Semana', PeriodoRelatorio.semana),
        const SizedBox(width: 8),
        _botaoPeriodo('Mês', PeriodoRelatorio.mes),
        const SizedBox(width: 8),
        _botaoPeriodo('Trimestre', PeriodoRelatorio.trimestre),
      ],
    );
  }

  Widget _botaoPeriodo(String texto, PeriodoRelatorio valor) {
    final selecionado = periodo == valor;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => periodo = valor),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selecionado ? azulPrincipal : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selecionado ? azulPrincipal : borda,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            texto,
            style: TextStyle(
              color: selecionado ? Colors.white : textoSecundario,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _seletorUnidade() {
    return Row(
      children: [
        _botaoUnidade('kg'),
        const SizedBox(width: 8),
        _botaoUnidade('L'),
        const SizedBox(width: 8),
        _botaoUnidade('un.'),
      ],
    );
  }

  Widget _botaoUnidade(String unidade) {
    final selecionado = unidadeSelecionada == unidade;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => unidadeSelecionada = unidade),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selecionado
              ? const Color(0xFFDBEAFE)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado ? azulPrincipal : borda,
          ),
        ),
        child: Text(
          unidade,
          style: TextStyle(
            color: selecionado ? azulEscuro : textoSecundario,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  
  Widget _graficoEvolucao(List<_RegistroDesperdicio> dados) {
    final filtrados = dados
        .where((item) => item.unidade == unidadeSelecionada)
        .toList();

    final quantidadeBarras =
        periodo == PeriodoRelatorio.semana ? 7 : 10;

    final diasPeriodo = switch (periodo) {
      PeriodoRelatorio.semana => 7,
      PeriodoRelatorio.mes => 30,
      PeriodoRelatorio.trimestre => 90,
    };

    final inicio = dataInicial;

    final intervalos = <_Intervalo>[];

    for (int i = 0; i < quantidadeBarras; i++) {
      // Divide o período proporcionalmente entre as barras.
      // Assim, nenhum dia fica de fora.
      final diaInicial = (i * diasPeriodo) ~/ quantidadeBarras;
      final diaFinal = ((i + 1) * diasPeriodo) ~/ quantidadeBarras;

      final inicioIntervalo = inicio.add(
        Duration(days: diaInicial),
      );

      final fimIntervalo = inicio.add(
        Duration(days: diaFinal),
      );

      final valor = filtrados
          .where(
            (item) =>
                !item.data.isBefore(inicioIntervalo) &&
                item.data.isBefore(fimIntervalo),
          )
          .fold<double>(
            0,
            (total, item) => total + item.quantidade,
          );

      intervalos.add(
        _Intervalo(
          valor: valor,
          legenda: periodo == PeriodoRelatorio.semana
              ? _diaSemana(inicioIntervalo.weekday)
              : '${inicioIntervalo.day}/${inicioIntervalo.month}',
        ),
      );
    }

    final maiorValor = intervalos.fold<double>(
      0,
      (maior, item) => math.max(maior, item.valor).toDouble(),
    );

    return _cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Quantidade descartada',
                  style: TextStyle(
                    color: textoSecundario,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                unidadeSelecionada,
                style: const TextStyle(
                  color: azulEscuro,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          SizedBox(
            height: 175,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: intervalos.map((item) {
                final altura = maiorValor == 0
                    ? 4.0
                    : math.max(
                        4.0,
                        (item.valor / maiorValor) * 125,
                      ).toDouble();

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                    ),

                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // VALOR ACIMA DA BARRA
                        SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _formatar(item.valor),
                              maxLines: 1,
                              softWrap: false,
                              style: const TextStyle(
                                color: textoSecundario,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 5),

                        // BARRA
                        Container(
                          height: altura,
                          decoration: BoxDecoration(
                            color: azulPrincipal,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // DATA ABAIXO DA BARRA
                        SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.legenda,
                              maxLines: 1,
                              softWrap: false,
                              style: const TextStyle(
                                color: textoSecundario,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          if (filtrados.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Nenhum desperdício registrado nessa unidade no período.',
                style: TextStyle(
                  color: textoSecundario,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }


  
Widget _graficoMotivos(List<_RegistroDesperdicio> dados) {
  final contagem = <String, int>{};

  for (final item in dados) {
    contagem[item.motivo] = (contagem[item.motivo] ?? 0) + 1;
  }

  final ordenados = contagem.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  if (ordenados.isEmpty) {
    return _cartao(
      child: _mensagemVazia(
        'Nenhum registro encontrado no período.',
      ),
    );
  }

  final maior = ordenados.first.value;
  final menor = ordenados.last.value;

  Color corPorQuantidade(int quantidade) {
    if (maior == menor) {
      return azulPrincipal;
    }

    final proporcao =
        (quantidade - menor) / (maior - menor);

    if (proporcao >= 0.75) {
      return const Color(0xFFDC2626); // Vermelho
    }

    if (proporcao >= 0.50) {
      return const Color(0xFFF97316); // Laranja
    }

    if (proporcao >= 0.25) {
      return const Color(0xFFEAB308); // Amarelo
    }

    return azulPrincipal; // Azul
  }

  return _cartao(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...ordenados.map((item) {
          final percentual = item.value / maior;
          final cor = corPorQuantidade(item.value);

          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.key,
                        style: const TextStyle(
                          color: textoPrincipal,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${item.value} ${item.value == 1 ? 'registro' : 'registros'}',
                      style: TextStyle(
                        color: cor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentual,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFEFF4FA),
                    color: cor,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    ),
  );
}


  Widget _rankingProdutos(List<_RegistroDesperdicio> dados) {
    return Column(
      children: [
        _secaoRanking('Quilogramas (kg)', 'kg', dados),
        const SizedBox(height: 12),
        _secaoRanking('Litros (L)', 'L', dados),
        const SizedBox(height: 12),
        _secaoRanking('Unidades (un.)', 'un.', dados),
      ],
    );
  }

  Widget _secaoRanking(
    String titulo,
    String unidade,
    List<_RegistroDesperdicio> dados,
  ) {
    final totais = <String, double>{};

    for (final item in dados.where((item) => item.unidade == unidade)) {
      totais[item.nome] = (totais[item.nome] ?? 0) + item.quantidade;
    }

    final ordenados = totais.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maiores = ordenados.take(5).toList();

    return _cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: textoPrincipal,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          if (maiores.isEmpty)
            _mensagemVazia('Nenhum produto registrado.')
          else
            ...maiores.asMap().entries.map((entrada) {
              final posicao = entrada.key + 1;
              final item = entrada.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Row(
                  children: [
                    Container(
                      width: 27,
                      height: 27,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$posicao',
                        style: const TextStyle(
                          color: azulEscuro,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        item.key,
                        style: const TextStyle(
                          color: textoPrincipal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '${_formatar(item.value)} $unidade',
                      style: const TextStyle(
                        color: azulEscuro,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _cartao({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borda),
      ),
      child: child,
    );
  }

  Widget _mensagemVazia(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: textoSecundario,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _mensagemErro() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Não foi possível carregar os relatórios. Verifique sua conexão e tente novamente.',
          textAlign: TextAlign.center,
          style: TextStyle(color: textoSecundario),
        ),
      ),
    );
  }

  double _numero(dynamic valor) {
    if (valor is num) return valor.toDouble();

    return double.tryParse(
          valor?.toString().replaceAll(',', '.') ?? '',
        ) ??
        0;
  }

  String _normalizarUnidade(String unidade) {
    final valor = unidade.trim().toLowerCase();

    if (['kg', 'quilo', 'quilos', 'quilograma', 'quilogramas'].contains(valor)) {
      return 'kg';
    }

    if (['g', 'gr', 'grama', 'gramas'].contains(valor)) {
      return 'g';
    }

    if (['l', 'litro', 'litros'].contains(valor)) {
      return 'L';
    }

    if (['ml', 'mililitro', 'mililitros'].contains(valor)) {
      return 'ml';
    }

    if ([
      'un',
      'un.',
      'unidade',
      'unidades',
      'und',
      'ovo',
      'ovos'
    ].contains(valor)) {
      return 'un.';
    }

    return 'un.';
  }

  double _converterQuantidade(double quantidade, String unidade) {
    if (unidade == 'g') return quantidade / 1000;
    if (unidade == 'ml') return quantidade / 1000;

    return quantidade;
  }

  String _motivo(String? motivo) {
    if (motivo == null || motivo.trim().isEmpty) {
      return 'Não informado';
    }

    return motivo.trim();
  }

  String _formatar(double valor) {
    if (valor == valor.roundToDouble()) {
      return valor.toStringAsFixed(0);
    }

    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _diaSemana(int dia) {
    const dias = [
      'Seg',
      'Ter',
      'Qua',
      'Qui',
      'Sex',
      'Sáb',
      'Dom',
    ];

    return dias[dia - 1];
  }
}

class _RegistroDesperdicio {
  final String nome;
  final double quantidade;
  final String unidade;
  final String motivo;
  final DateTime data;

  const _RegistroDesperdicio({
    required this.nome,
    required this.quantidade,
    required this.unidade,
    required this.motivo,
    required this.data,
  });
}

class _Intervalo {
  final double valor;
  final String legenda;

  const _Intervalo({
    required this.valor,
    required this.legenda,
  });
}
