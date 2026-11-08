
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'widgets/menu-perfil.dart';

const azulPrincipal = Color(0xFF2563EB);
const azulEscuro = Color(0xFF1E3A8A);
const fundo = Color(0xFFF8FAFC);
const textoPrincipal = Color(0xFF1E293B);
const textoSecundario = Color(0xFF64748B);
const borda = Color(0xFFE2E8F0);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _mostrarTodosAlertas = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
            child: CircularProgressIndicator(),
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('entradasEstoque')
              .snapshots(),
          builder: (context, entradasSnapshot) {
            if (entradasSnapshot.hasError) {
              return const Center(
                child: Text('Erro ao carregar estoque.'),
              );
            }

            if (!entradasSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('desperdicios')
                  .snapshots(),
              builder: (context, desperdiciosSnapshot) {
                if (desperdiciosSnapshot.hasError) {
                  return const Center(
                    child: Text('Erro ao carregar desperdícios.'),
                  );
                }

                if (!desperdiciosSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return _montarHome(
                  context,
                  produtosSnapshot.data!.docs,
                  entradasSnapshot.data!.docs,
                  desperdiciosSnapshot.data!.docs,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _montarHome(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> produtosDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> entradasDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> desperdiciosDocs,
  ) {
    // PRODUTOS ATIVOS.
    final produtosAtivos = produtosDocs.where((doc) {
      return doc.data()['ativo'] != false;
    }).toList();

    // DADOS DOS PRODUTOS.
    final Map<String, Map<String, dynamic>> dadosProdutos = {
      for (final doc in produtosDocs) doc.id: doc.data(),
    };

    // ESTOQUE DISPONÍVEL POR PRODUTO.
    final Map<String, double> estoquePorProduto = {};

    for (final entrada in entradasDocs) {
      final dados = entrada.data();
      final produtoId = dados['produtoId']?.toString();

      if (produtoId == null || produtoId.isEmpty) continue;

      final quantidade =
          (dados['quantidadeDisponivel'] as num?)?.toDouble() ?? 0.0;

      estoquePorProduto[produtoId] =
          (estoquePorProduto[produtoId] ?? 0.0) + quantidade;
    }

    // FORMATAÇÃO DE QUANTIDADES.
    String formatarQuantidade(double quantidade) {
      return quantidade
          .toStringAsFixed(2)
          .replaceAll('.', ',')
          .replaceFirst(RegExp(r',?0+$'), '');
    }

    String formatarUnidade(String unidade) {
      switch (unidade.toLowerCase()) {
        case 'unidade':
        case 'unidades':
        case 'un':
        case 'un.':
        case 'und':
          return 'un.';
        case 'l':
        case 'litro':
        case 'litros':
          return 'L';
        case 'ml':
        case 'mililitro':
        case 'mililitros':
          return 'mL';
        default:
          return unidade;
      }
    }

    // INDICADORES DE ESTOQUE.
    int itensEmFalta = 0;
    int estoqueBaixo = 0;

    for (final produto in produtosAtivos) {
      final dados = produto.data();
      final quantidade = estoquePorProduto[produto.id] ?? 0.0;

      final minimo =
          (dados['estoqueMinimo'] as num?)?.toDouble() ?? 0.0;

      if (quantidade <= 0) {
        itensEmFalta++;
      } else if (quantidade < minimo) {
        estoqueBaixo++;
      }
    }

    // DESPERDÍCIO REGISTRADO HOJE.
    final agora = DateTime.now();

    final inicioHoje = DateTime(
      agora.year,
      agora.month,
      agora.day,
    );

    final inicioAmanha = inicioHoje.add(
      const Duration(days: 1),
    );

    final Map<String, double> desperdicioDiarioPorUnidade = {};

    for (final desperdicio in desperdiciosDocs) {
      final dados = desperdicio.data();
      final dataRegistro = dados['dataDesperdicio'];

      DateTime? data;

      if (dataRegistro is Timestamp) {
        data = dataRegistro.toDate();
      } else if (dataRegistro is DateTime) {
        data = dataRegistro;
      }

      if (data == null ||
          data.isBefore(inicioHoje) ||
          !data.isBefore(inicioAmanha)) {
        continue;
      }

      double quantidade =
    (dados['quantidade'] as num?)?.toDouble() ?? 0.0;

    final produtoId = dados['produtoId']?.toString();

    final unidade = (
      dados['unidade'] ??
      dadosProdutos[produtoId]?['unidade'] ??
      'unidade'
    ).toString().trim().toLowerCase();

    String unidadeNormalizada;

    switch (unidade) {
      case 'kg':
      case 'quilo':
      case 'quilos':
      case 'quilograma':
      case 'quilogramas':
        unidadeNormalizada = 'kg';
        break;

      case 'g':
      case 'grama':
      case 'gramas':
        unidadeNormalizada = 'kg';
        quantidade /= 1000;
        break;

      case 'l':
      case 'litro':
      case 'litros':
        unidadeNormalizada = 'l';
        break;

      case 'ml':
      case 'mililitro':
      case 'mililitros':
        unidadeNormalizada = 'l';
        quantidade /= 1000;
        break;

      case 'un':
      case 'un.':
      case 'und':
      case 'unidades':
      case 'unidade':
        unidadeNormalizada = 'unidade';
        break;

      default:
        unidadeNormalizada = unidade;
    }
      desperdicioDiarioPorUnidade[unidadeNormalizada] =
          (desperdicioDiarioPorUnidade[unidadeNormalizada] ?? 0.0) +
              quantidade;

    }

    final desperdicioOrdenado =
      desperdicioDiarioPorUnidade.entries.toList();

    const ordemUnidades = ['kg', 'l', 'unidade'];

    desperdicioOrdenado.sort((a, b) {
      final ordemA = ordemUnidades.indexOf(a.key);
      final ordemB = ordemUnidades.indexOf(b.key);

      return (ordemA == -1 ? 999 : ordemA)
          .compareTo(ordemB == -1 ? 999 : ordemB);
    });

    // ============================================================
    // MONTAGEM DOS ALERTAS
    // ============================================================

    final List<Widget> alertasWidgets = [];

    void adicionarAlerta({
      required IconData icone,
      required Color cor,
      required String titulo,
      required String descricao,
      required String tempo,
    }) {
      alertasWidgets.add(
        _alerta(
          icone: icone,
          cor: cor,
          titulo: titulo,
          descricao: descricao,
          tempo: tempo,
        ),
      );
    }

    // 1. PRODUTOS EM FALTA.
    for (final produto in produtosAtivos) {
      final quantidade = estoquePorProduto[produto.id] ?? 0.0;

      if (quantidade <= 0) {
        final nome =
            produto.data()['nome']?.toString() ?? 'Produto sem nome';

        adicionarAlerta(
          icone: Icons.error_outline,
          cor: const Color(0xFFDC2626),
          titulo: 'Produto em falta',
          descricao: '$nome está sem estoque disponível.',
          tempo: 'É necessário repor o estoque',
        );
      }
    }

    // 2. ESTOQUE ABAIXO DO MÍNIMO.
    for (final produto in produtosAtivos) {
      final dados = produto.data();
      final quantidade = estoquePorProduto[produto.id] ?? 0.0;

      final minimo =
          (dados['estoqueMinimo'] as num?)?.toDouble() ?? 0.0;

      if (quantidade > 0 && quantidade < minimo) {
        final nome = dados['nome']?.toString() ?? 'Produto sem nome';
        final unidade = dados['unidade']?.toString() ?? 'unidade';

        adicionarAlerta(
          icone: Icons.warning_amber_rounded,
          cor: const Color(0xFFD97706),
          titulo: 'Estoque baixo',
          descricao:
              '$nome possui ${formatarQuantidade(quantidade)} '
              '$unidade. O mínimo definido é '
              '${formatarQuantidade(minimo)} $unidade.',
          tempo: 'Abaixo do estoque mínimo',
        );
      }
    }

    // 3. LOTES VENCIDOS OU PRÓXIMOS DO VENCIMENTO.
    final hoje = DateTime.now();

    final hojeSemHorario = DateTime(
      hoje.year,
      hoje.month,
      hoje.day,
    );

    final limiteValidade = hojeSemHorario.add(
      const Duration(days: 7),
    );

    final List<Map<String, dynamic>> lotesComAlerta = [];

    for (final entrada in entradasDocs) {
      final dados = entrada.data();
      final produtoId = dados['produtoId']?.toString();

      if (produtoId == null || produtoId.isEmpty) continue;

      final produto = dadosProdutos[produtoId];

      if (produto == null || produto['ativo'] == false) continue;

      final quantidade =
          (dados['quantidadeDisponivel'] as num?)?.toDouble() ?? 0.0;

      if (quantidade <= 0) continue;

      final validadeRegistro = dados['validade'];

      DateTime? validade;

      if (validadeRegistro is Timestamp) {
        validade = validadeRegistro.toDate();
      } else if (validadeRegistro is DateTime) {
        validade = validadeRegistro;
      }

      if (validade == null) continue;

      final validadeSemHorario = DateTime(
        validade.year,
        validade.month,
        validade.day,
      );

      if (validadeSemHorario.isAfter(limiteValidade)) continue;

      lotesComAlerta.add({
        'nome': dados['nomeProduto'] ?? produto['nome'] ?? 'Produto',
        'lote': dados['lote'] ?? 'Não informado',
        'validade': validadeSemHorario,
        'quantidade': quantidade,
        'unidade': dados['unidade'] ?? produto['unidade'] ?? 'unidade',
      });
    }

    lotesComAlerta.sort((a, b) {
      return (a['validade'] as DateTime)
          .compareTo(b['validade'] as DateTime);
    });

    for (final lote in lotesComAlerta) {
      final validade = lote['validade'] as DateTime;
      final diferenca = validade.difference(hojeSemHorario).inDays;

      final vencido = diferenca < 0;
      final venceHoje = diferenca == 0;

      String descricaoValidade;

      if (vencido) {
        descricaoValidade =
            'Vencido há ${diferenca.abs()} dia(s).';
      } else if (venceHoje) {
        descricaoValidade = 'Este lote vence hoje.';
      } else {
        descricaoValidade = 'Vence em $diferenca dia(s).';
      }

      final dataFormatada =
          '${validade.day.toString().padLeft(2, '0')}/'
          '${validade.month.toString().padLeft(2, '0')}/'
          '${validade.year}';

      final quantidade = (lote['quantidade'] as num).toDouble();

      adicionarAlerta(
        icone: Icons.event_busy_outlined,
        cor: vencido
            ? const Color(0xFFDC2626)
            : const Color(0xFFD97706),
        titulo: vencido
            ? 'Produto vencido'
            : 'Produto próximo do vencimento',
        descricao:
            '${lote['nome']} — Lote ${lote['lote']}. '
            '$descricaoValidade Validade: $dataFormatada.',
        tempo:
            'Saldo: ${formatarQuantidade(quantidade)} ${lote['unidade']}',
      );
    }

    // 4. DESPERDÍCIOS MAIS RECENTES.
    final desperdiciosRecentes = desperdiciosDocs.where((documento) {
      final data = documento.data()['dataDesperdicio'];

      return data is Timestamp || data is DateTime;
    }).toList();

    DateTime obterDataDesperdicio(Map<String, dynamic> dados) {
      final valor = dados['dataDesperdicio'];

      if (valor is Timestamp) return valor.toDate();
      if (valor is DateTime) return valor;

      return DateTime(2000);
    }

    desperdiciosRecentes.sort((a, b) {
      return obterDataDesperdicio(b.data())
          .compareTo(obterDataDesperdicio(a.data()));
    });

    String tempoDecorrido(DateTime data) {
      final diferenca = DateTime.now().difference(data);

      if (diferenca.isNegative || diferenca.inMinutes < 1) {
        return 'Agora mesmo';
      }

      if (diferenca.inMinutes < 60) {
        return 'Há ${diferenca.inMinutes} min';
      }

      if (diferenca.inHours < 24) {
        return 'Há ${diferenca.inHours} hora(s)';
      }

      if (diferenca.inDays < 30) {
        return 'Há ${diferenca.inDays} dia(s)';
      }

      return 'Em ${data.day.toString().padLeft(2, '0')}/'
          '${data.month.toString().padLeft(2, '0')}/'
          '${data.year}';
    }

    for (final desperdicio in desperdiciosRecentes) {
      final dados = desperdicio.data();
      final produtoId = dados['produtoId']?.toString();

      final nome = dados['nomeProduto'] ??
          dadosProdutos[produtoId]?['nome'] ??
          'Produto';

      final quantidade =
          (dados['quantidade'] as num?)?.toDouble() ?? 0.0;

      final unidade = dados['unidade'] ??
          dadosProdutos[produtoId]?['unidade'] ??
          'unidade';

      final data = obterDataDesperdicio(dados);

      adicionarAlerta(
        icone: Icons.delete_outline,
        cor: azulPrincipal,
        titulo: 'Desperdício registrado',
        descricao:
            '$nome: ${formatarQuantidade(quantidade)} $unidade. '
            'Motivo: ${dados['motivo'] ?? 'Não informado'}.',
        tempo: tempoDecorrido(data),
      );
    }

    // ============================================================
    // TELA PRINCIPAL
    // ============================================================

    final quantidadeAlertas = alertasWidgets.length;

    final quantidadeVisivel = _mostrarTodosAlertas
        ? quantidadeAlertas
        : (quantidadeAlertas < 3 ? quantidadeAlertas : 3);

    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _cabecalho(context),

                  const SizedBox(height: 28),

                  const Text(
                    'Visão geral',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textoPrincipal,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Acompanhe seu restaurante hoje.',
                    style: TextStyle(
                      fontSize: 14,
                      color: textoSecundario,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // INDICADORES PRINCIPAIS.
                  Row(
                    children: [
                      Expanded(
                        child: _kpi(
                          titulo: 'Produtos',
                          valor: '${produtosAtivos.length}',
                          descricao: 'Cadastrados',
                          icone: Icons.inventory_2_outlined,
                          cor: azulPrincipal,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _kpi(
                          titulo: 'Itens em falta',
                          valor: '$itensEmFalta',
                          descricao: 'Sem estoque disponível',
                          icone: Icons.warning_amber_rounded,
                          cor: const Color(0xFFDC2626),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _kpi(
                          titulo: 'Estoque baixo',
                          valor: '$estoqueBaixo',
                          descricao: 'Abaixo do mínimo',
                          icone: Icons.trending_down,
                          cor: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // DESPERDÍCIO DO DIA.
                  _cardDesperdicio(
                    dados: desperdicioOrdenado,
                    formatarQuantidade: formatarQuantidade,
                    formatarUnidade: formatarUnidade,
                  ),

                  const SizedBox(height: 28),

                  _tituloSecao(
                    'Alertas recentes',
                    'Ocorrências que precisam de atenção',
                  ),

                  const SizedBox(height: 14),

                  // ALERTAS.
                  if (alertasWidgets.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borda),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF16A34A),
                            size: 35,
                          ),

                          SizedBox(height: 10),

                          Text(
                            'Tudo em ordem!',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textoPrincipal,
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'Não existem alertas para mostrar no momento.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    ...alertasWidgets.take(quantidadeVisivel).expand(
                      (alerta) => [
                        alerta,
                        const SizedBox(height: 10),
                      ],
                    ),

                    // BOTÃO VER MAIS / VER MENOS.
                    if (quantidadeAlertas > 3)
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _mostrarTodosAlertas =
                                  !_mostrarTodosAlertas;
                            });
                          },
                          icon: Icon(
                            _mostrarTodosAlertas
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                          ),
                          label: Text(
                            _mostrarTodosAlertas
                                ? 'Ver menos'
                                : 'Ver mais (${quantidadeAlertas - 3})',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: azulPrincipal,
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CABEÇALHO.
  Widget _cabecalho(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Row(
        children: [
          Expanded(
            child: Text(
              'Olá!',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: azulEscuro,
              ),
            ),
          ),
          MenuPerfil(),
        ],
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final nomeCompleto =
            snapshot.data?.data()?['nomeCompleto']?.toString() ??
                usuario.displayName ??
                '';

        final primeiroNome = nomeCompleto.trim().isEmpty
            ? 'usuário'
            : nomeCompleto.trim().split(RegExp(r'\s+')).first;

        return Row(
          children: [
            Expanded(
              child: Text(
                'Olá, $primeiroNome!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: azulEscuro,
                ),
              ),
            ),
            const MenuPerfil(),
          ],
        );
      },
    );
  }

  // CARDS DE INDICADORES.
  Widget _kpi({
    required String titulo,
    required String valor,
    required String descricao,
    required IconData icone,
    required Color cor,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 145),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, color: cor, size: 21),
          ),

          const SizedBox(height: 12),

          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              color: textoSecundario,
            ),
          ),

          const SizedBox(height: 5),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: textoPrincipal,
              ),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            descricao,
            style: const TextStyle(
              fontSize: 11,
              color: textoSecundario,
            ),
          ),
        ],
      ),
    );
  }

  
  // CARD ESTENDIDO DE DESPERDÍCIO.
  Widget _cardDesperdicio({
    required List<MapEntry<String, double>> dados,
    required String Function(double) formatarQuantidade,
    required String Function(String) formatarUnidade,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFEA580C),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Desperdício hoje',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textoPrincipal,
                  ),
                ),
              ),
            
            ],
          ),

          const SizedBox(height: 20),

          if (dados.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Nenhum desperdício registrado hoje.',
                  style: TextStyle(
                    fontSize: 13,
                    color: textoSecundario,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                for (int i = 0; i < dados.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 1,
                      height: 48,
                      color: borda,
                    ),

                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          formatarQuantidade(dados[i].value),
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: textoPrincipal,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          formatarUnidade(dados[i].key),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }


  // TÍTULOS DAS SEÇÕES.
  Widget _tituloSecao(String titulo, String subtitulo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textoPrincipal,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          subtitulo,
          style: const TextStyle(
            fontSize: 13,
            color: textoSecundario,
          ),
        ),
      ],
    );
  }

  // CARD DE ALERTA.
  Widget _alerta({
    required IconData icone,
    required Color cor,
    required String titulo,
    required String descricao,
    required String tempo,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borda),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, color: cor, size: 22),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textoPrincipal,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  descricao,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: textoSecundario,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  tempo,
                  style: TextStyle(
                    fontSize: 11,
                    color: cor,
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
}
