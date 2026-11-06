
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const azulPrincipal = Color(0xFF2563EB);
const azulEscuro = Color(0xFF1E3A8A);
const fundo = Color(0xFFF8FAFC);
const textoPrincipal = Color(0xFF1E293B);
const textoSecundario = Color(0xFF64748B);
const borda = Color(0xFFE2E8F0);
const verdeStatus = Color(0xFF16A34A);

class RegistrarDesperdicioPage extends StatefulWidget {
  const RegistrarDesperdicioPage({super.key});

  @override
  State<RegistrarDesperdicioPage> createState() =>
      _RegistrarDesperdicioPageState();
}

class _RegistrarDesperdicioPageState
    extends State<RegistrarDesperdicioPage> {
  final _formKey = GlobalKey<FormState>();
  final quantidadeController = TextEditingController();
  final observacaoController = TextEditingController();

  String? produtoSelecionado;
  String unidadeProduto = 'unidade';
  String? loteSelecionado;
  String? motivoSelecionado;
  _SaidaDisponivel? saidaSelecionada;

  double? estoqueDisponivel;
  bool carregando = false;
  bool consultando = false;

  // Será utilizado somente quando o motivo for "Outro".
  bool? outroPossuiSaida;

  final List<String> motivosDesperdicio = [
    'Vencimento no estoque',
    'Deterioração no estoque',
    'Contaminação no estoque',
    'Armazenamento inadequado',
    'Preparo incorreto',
    'Alimento queimado durante preparo',
    'Sobra descartada após preparo',
    'Contaminação durante preparo',
    'Outro',
  ];

  final List<String> motivosComSaida = [
    'Preparo incorreto',
    'Alimento queimado durante preparo',
    'Sobra descartada após preparo',
    'Contaminação durante preparo',
  ];

  final List<String> motivosComBaixaDireta = [
    'Vencimento no estoque',
    'Deterioração no estoque',
    'Contaminação no estoque',
    'Armazenamento inadequado',
  ];

  List<_SaidaDisponivel> saidasDisponiveis = [];
  List<_LoteDisponivel> lotesDisponiveis = [];
  _LoteDisponivel? loteAtualSelecionado;

  bool get precisaSaidaAnterior {
    if (motivosComSaida.contains(motivoSelecionado)) {
      return true;
    }

    if (motivosComBaixaDireta.contains(motivoSelecionado)) {
      return false;
    }

    if (motivoSelecionado == 'Outro') {
      return outroPossuiSaida == true;
    }

    return false;
  }

  bool get afetaEstoque {
    return !precisaSaidaAnterior;
  }

  @override
  void dispose() {
    quantidadeController.dispose();
    observacaoController.dispose();
    super.dispose();
  }

  // ============================================================
  // SELEÇÃO DE PRODUTOS
  // ============================================================

  Future<void> _abrirSeletorProdutos(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> produtos,
  ) async {
    final pesquisaController = TextEditingController();

    final resultado =
        await showModalBottomSheet<
            QueryDocumentSnapshot<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, atualizarModal) {
            final pesquisa =
                pesquisaController.text.toLowerCase().trim();

            final filtrados = produtos.where((doc) {
              final nome =
                  doc.data()['nome']?.toString().toLowerCase() ?? '';

              return nome.contains(pesquisa);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selecionar produto',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: pesquisaController,
                        onChanged: (_) => atualizarModal(() {}),
                        decoration: InputDecoration(
                          hintText: 'Pesquisar produto...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: fundo,
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
                      const SizedBox(height: 16),
                      Expanded(
                        child: filtrados.isEmpty
                            ? const Center(
                                child: Text('Nenhum produto encontrado.'),
                              )
                            : ListView.separated(
                                itemCount: filtrados.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(color: borda),
                                itemBuilder: (context, index) {
                                  final produto = filtrados[index];
                                  final nome = produto.data()['nome']
                                          ?.toString() ??
                                      '';

                                  final selecionado =
                                      produto.id == produtoSelecionado;

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      nome,
                                      style: const TextStyle(
                                        color: textoPrincipal,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    trailing: Icon(
                                      selecionado
                                          ? Icons.check_circle
                                          : Icons.chevron_right,
                                      color: selecionado
                                          ? azulPrincipal
                                          : textoSecundario,
                                    ),
                                    onTap: () {
                                      Navigator.pop(context, produto);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    pesquisaController.dispose();

    if (resultado == null || !mounted) return;

    setState(() {
      produtoSelecionado = resultado.id;
      unidadeProduto =
        resultado.data()['unidade']?.toString() ?? 'unidade';
      estoqueDisponivel = null;
      saidaSelecionada = null;
      saidasDisponiveis = [];
      consultando = true;
      loteAtualSelecionado = null;
      lotesDisponiveis = [];
    });

    await _carregarInformacoesProduto(resultado.id);
  }

  // ============================================================
  // CÁLCULO DO ESTOQUE
  // ============================================================

  Future<double> _somarColecao(
    String colecao,
    String produtoId,
  ) async {
    final consulta = await FirebaseFirestore.instance
        .collection(colecao)
        .where('produtoId', isEqualTo: produtoId)
        .get();

    double total = 0;

    for (final doc in consulta.docs) {
      final dados = doc.data();

      if (colecao == 'desperdicios' &&
          dados.containsKey('afetaEstoque') &&
          dados['afetaEstoque'] != true) {
        continue;
      }

      total +=
          (dados['quantidade'] as num?)?.toDouble() ?? 0.0;
    }

    return total;
  }

  Future<double> _calcularEstoque(String produtoId) async {
    final consulta = await FirebaseFirestore.instance
        .collection('entradasEstoque')
        .where('produtoId', isEqualTo: produtoId)
        .get();

    double total = 0;

    for (final doc in consulta.docs) {
      final dados = doc.data();

      total +=
          (dados['quantidadeDisponivel'] as num?)?.toDouble() ?? 0.0;
    }

    return total;
  }

  Future<void> _carregarInformacoesProduto(String produtoId) async {
    try {
      final estoque = await _calcularEstoque(produtoId);
      final saidas = await _carregarSaidas(produtoId);
      final lotes = await _carregarLotes(produtoId);

      if (!mounted) return;

      setState(() {
        estoqueDisponivel = estoque;
        saidasDisponiveis = saidas;
        lotesDisponiveis = lotes;
        consultando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        consultando = false;
      });

      _mensagem('Erro ao consultar o produto: $e');
    }
  }

    Future<List<_LoteDisponivel>> _carregarLotes(
    String produtoId,
  ) async {
    final consulta = await FirebaseFirestore.instance
        .collection('entradasEstoque')
        .where('produtoId', isEqualTo: produtoId)
        .get();

    final lotes = consulta.docs.map((doc) {
      final dados = doc.data();

      final validade = dados['validade'];

      return _LoteDisponivel(
        id: doc.id,
        lote: dados['lote']?.toString() ?? 'Sem identificação',
        quantidadeDisponivel:
            (dados['quantidadeDisponivel'] as num?)?.toDouble() ?? 0,
        validade: validade is Timestamp
            ? validade.toDate()
            : null,
      );
    }).where((lote) {
      return lote.quantidadeDisponivel > 0;
    }).toList();

    lotes.sort((a, b) {
      if (a.validade == null && b.validade == null) return 0;
      if (a.validade == null) return 1;
      if (b.validade == null) return -1;

      return a.validade!.compareTo(b.validade!);
    });

    return lotes;
  }

  // ============================================================
  // SAÍDAS RELACIONADAS
  // ============================================================

  Future<List<_SaidaDisponivel>> _carregarSaidas(
    String produtoId,
  ) async {
    final consultaSaidas = await FirebaseFirestore.instance
        .collection('saidasEstoque')
        .where('produtoId', isEqualTo: produtoId)
        .get();

    final consultaDesperdicios = await FirebaseFirestore.instance
        .collection('desperdicios')
        .where('produtoId', isEqualTo: produtoId)
        .get();

    final desperdicioPorSaida = <String, double>{};

    for (final doc in consultaDesperdicios.docs) {
      final dados = doc.data();
      final saidaId = dados['saidaId']?.toString();

      if (saidaId == null || saidaId.isEmpty) continue;

      final quantidade =
          (dados['quantidade'] as num?)?.toDouble() ?? 0.0;

      desperdicioPorSaida[saidaId] =
          (desperdicioPorSaida[saidaId] ?? 0.0) + quantidade;
    }

    final resultado = <_SaidaDisponivel>[];

    for (final doc in consultaSaidas.docs) {
      final dados = doc.data();

      final quantidadeOriginal =
          (dados['quantidade'] as num?)?.toDouble() ?? 0.0;

      final quantidadeVinculada =
          desperdicioPorSaida[doc.id] ?? 0.0;

      final restante = quantidadeOriginal - quantidadeVinculada;

      if (restante > 0.000001) {
        resultado.add(
          _SaidaDisponivel(
            id: doc.id,
            quantidadeOriginal: quantidadeOriginal,
            quantidadeRestante: restante,
            motivo: dados['motivo']?.toString() ?? 'Saída',
            data: dados['dataSaida'] is Timestamp
                ? (dados['dataSaida'] as Timestamp).toDate()
                : null,
          ),
        );
      }
    }

    return resultado;
  }

  Future<void> _abrirSeletorSaidas() async {
    if (saidasDisponiveis.isEmpty) {
      _mensagem(
        'Não existem saídas disponíveis para este produto.',
      );
      return;
    }

    final resultado = await showModalBottomSheet<_SaidaDisponivel>(
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
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecionar saída relacionada',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Escolha a retirada na qual ocorreu o desperdício.',
                    style: TextStyle(color: textoSecundario),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: saidasDisponiveis.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: borda),
                      itemBuilder: (context, index) {
                        final saida = saidasDisponiveis[index];

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            saida.motivo,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: textoPrincipal,
                            ),
                          ),
                          subtitle: Text(
                            'Retirada: ${_formatarQuantidade(saida.quantidadeOriginal)}'
                            ' | Restante: ${_formatarQuantidade(saida.quantidadeRestante)}',
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: azulPrincipal,
                          ),
                          onTap: () => Navigator.pop(context, saida),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (resultado == null || !mounted) return;

    setState(() {
      saidaSelecionada = resultado;
    });
  }

  Future<void> _abrirSeletorLotes() async {
    if (lotesDisponiveis.isEmpty) {
      _mensagem('Não existem lotes com saldo disponível para este produto.');
      return;
    }

    final resultado = await showModalBottomSheet<_LoteDisponivel>(
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
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 420,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecionar lote',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Escolha o lote de onde o produto será descartado.',
                    style: TextStyle(color: textoSecundario),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: lotesDisponiveis.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: borda),
                      itemBuilder: (context, index) {
                        final lote = lotesDisponiveis[index];

                        final vencido = lote.validade != null &&
                            DateTime(
                              lote.validade!.year,
                              lote.validade!.month,
                              lote.validade!.day,
                            ).isBefore(
                              DateTime(
                                DateTime.now().year,
                                DateTime.now().month,
                                DateTime.now().day,
                              ),
                            );

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Lote: ${lote.lote}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: textoPrincipal,
                            ),
                          ),
                          subtitle: Text(
                            'Disponível: ${_formatarQuantidade(lote.quantidadeDisponivel)} $unidadeProduto'
                            '\nValidade: ${lote.validade == null ? 'Não informada' : _formatarData(lote.validade!)}'
                            '${vencido ? '\nVENCIDO' : ''}',
                            style: TextStyle(
                              color: vencido
                                  ? Colors.red
                                  : textoSecundario,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: azulPrincipal,
                          ),
                          onTap: () => Navigator.pop(context, lote),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (resultado == null || !mounted) return;

    setState(() {
      loteAtualSelecionado = resultado;
      loteSelecionado = resultado.id;
    });
  }

  // ============================================================
  // REGISTRO DO DESPERDÍCIO
  // ============================================================

  Future<void> _registrarDesperdicio() async {
    if (carregando) return;

    if (!_formKey.currentState!.validate()) return;

    if (motivoSelecionado == 'Outro' &&
        observacaoController.text.trim().isEmpty) {
      _mensagem('Informe uma observação para o motivo selecionado.');
      return;
    }

    if (produtoSelecionado == null || motivoSelecionado == null) {
      _mensagem('Preencha todos os campos obrigatórios.');
      return;
    }

    if (motivoSelecionado == 'Outro' && outroPossuiSaida == null) {
      _mensagem('Informe se o produto já havia saído do estoque.');
      return;
    }

    final geraBaixa = afetaEstoque;

    if (geraBaixa && loteAtualSelecionado == null) {
      _mensagem('Selecione o lote do produto.');
      return;
    }

    if (!geraBaixa && saidaSelecionada == null) {
      _mensagem('Selecione a saída relacionada.');
      return;
    }

    final quantidade = double.tryParse(
      quantidadeController.text.trim().replaceAll(',', '.'),
    );

    if (quantidade == null || quantidade <= 0) {
      _mensagem('Informe uma quantidade válida.');
      return;
    }

    final unidadeNormalizada = unidadeProduto.toLowerCase().trim();

    final unidadeContavel = [
      'unidade',
      'un',
      'unidades',
    ].contains(unidadeNormalizada);

    if (unidadeContavel && quantidade % 1 != 0) {
      _mensagem(
        'Para produtos cadastrados por unidade, informe um número inteiro.',
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      final produtoId = produtoSelecionado!;
      final produtoRef = firestore.collection('produtos').doc(produtoId);

      final desperdicioRef = firestore
          .collection('desperdicios')
          .doc();

      final observacao = motivoSelecionado == 'Outro'
          ? observacaoController.text.trim()
          : null;

      final saidaId = geraBaixa ? null : saidaSelecionada!.id;

      // Referências utilizadas na transação.
      final loteRef = geraBaixa
          ? firestore
              .collection('entradasEstoque')
              .doc(loteAtualSelecionado!.id)
          : null;

      final saidaRef = !geraBaixa
          ? firestore
              .collection('saidasEstoque')
              .doc(saidaSelecionada!.id)
          : null;

      // Validação adicional da saída relacionada.
      if (!geraBaixa) {
        final saidasAtualizadas = await _carregarSaidas(produtoId);

        final saidaAtualizada = saidasAtualizadas
            .where((item) => item.id == saidaId)
            .toList();

        if (saidaAtualizada.isEmpty ||
            quantidade >
                saidaAtualizada.first.quantidadeRestante + 0.000001) {
          throw Exception(
            'A quantidade ultrapassa o restante disponível da saída selecionada.',
          );
        }
      }

      await firestore.runTransaction((transaction) async {
        // Primeiro fazemos todas as leituras.
        final produtoDoc = await transaction.get(produtoRef);

        if (!produtoDoc.exists ||
            produtoDoc.data()?['ativo'] != true) {
          throw Exception('O produto não está mais ativo.');
        }

        DocumentSnapshot<Map<String, dynamic>>? loteDoc;
        DocumentSnapshot<Map<String, dynamic>>? saidaDoc;

        if (geraBaixa) {
          loteDoc = await transaction.get(loteRef!);

          if (!loteDoc.exists ||
              loteDoc.data()?['produtoId'] != produtoId) {
            throw Exception('O lote selecionado não é mais válido.');
          }

          final saldoLote =
              (loteDoc.data()?['quantidadeDisponivel'] as num?)
                  ?.toDouble() ?? 0.0;

          if (saldoLote <= 0) {
            throw Exception('Este lote não possui saldo disponível.');
          }

          if (quantidade > saldoLote + 0.000001) {
            throw Exception(
              'A quantidade informada ultrapassa o saldo do lote '
              '(${_formatarQuantidade(saldoLote)} disponíveis).',
            );
          }
        } else {
          saidaDoc = await transaction.get(saidaRef!);

          if (!saidaDoc.exists ||
              saidaDoc.data()?['produtoId'] != produtoId) {
            throw Exception('A saída selecionada não é mais válida.');
          }
        }

        final unidadeRegistro = (
          saidaDoc?.data()?['unidade'] ??
          produtoDoc.data()?['unidade'] ??
          unidadeProduto
        ).toString();

        // Todas as leituras foram feitas.
        // Agora podemos gravar as alterações.

        if (geraBaixa) {
          final saldoAtual =
              (loteDoc!.data()?['quantidadeDisponivel'] as num)
                  .toDouble();

          transaction.update(loteRef!, {
            'quantidadeDisponivel': saldoAtual - quantidade,
          });
        }

        transaction.set(desperdicioRef, {
          'produtoId': produtoId,
          'quantidade': quantidade,
          'motivo': motivoSelecionado,
          'dataDesperdicio': FieldValue.serverTimestamp(),
          'saidaId': saidaId,
          'entradaId': geraBaixa ? loteAtualSelecionado!.id : null,
          'afetaEstoque': geraBaixa,
          'observacao': observacao,
          'unidade': unidadeRegistro,
        });
      });

      if (!mounted) return;

      _mensagem('Desperdício registrado com sucesso!');
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      _mensagem(
        'Erro ao salvar no Firebase: ${e.message ?? e.code}',
      );
    } catch (e) {
      _mensagem(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  // ============================================================
  // AUXILIARES
  // ============================================================

  String _formatarQuantidade(double valor) {
    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  InputDecoration _decoracao({
    required String titulo,
    required IconData icone,
  }) {
    return InputDecoration(
      labelText: titulo,
      prefixIcon: Icon(icone, color: textoSecundario),
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: azulPrincipal,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // INTERFACE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textoPrincipal),
        title: const Text(
          'Registrar desperdício',
          style: TextStyle(
            color: textoPrincipal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('produtos')
            .where('ativo', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Erro ao carregar produtos.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: azulPrincipal,
              ),
            );
          }

          final produtos = snapshot.data!.docs;

          final produtoAtual = produtos
              .where((doc) => doc.id == produtoSelecionado)
              .toList();

          final nomeProduto = produtoAtual.isEmpty
              ? null
              : produtoAtual.first.data()['nome']?.toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informações do desperdício',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Informe os dados do alimento descartado.',
                    style: TextStyle(
                      color: textoSecundario,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // PRODUTO
                  const Text(
                    'Produto *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: carregando || consultando
                        ? null
                        : () => _abrirSeletorProdutos(produtos),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: _decoracao(
                        titulo: 'Selecione o produto',
                        icone: Icons.inventory_2_outlined,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              nomeProduto ??
                                  'Pesquisar e selecionar produto',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: nomeProduto == null
                                    ? textoSecundario
                                    : textoPrincipal,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.search,
                            color: azulPrincipal,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ESTOQUE DISPONÍVEL
                  if (produtoSelecionado != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borda),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.inventory_outlined,
                            color: azulPrincipal,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              consultando
                                  ? 'Consultando estoque...'
                                  : 'Estoque disponível',
                              style: const TextStyle(
                                color: textoSecundario,
                              ),
                            ),
                          ),
                          if (consultando)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: azulPrincipal,
                              ),
                            )
                          else
                            Text(
                              '${_formatarQuantidade(estoqueDisponivel ?? 0)} $unidadeProduto',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textoPrincipal,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // LOTE PARA BAIXA DIRETA
                  if (afetaEstoque && produtoSelecionado != null) ...[
                    const Text(
                      'Lote do produto *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: carregando || consultando
                          ? null
                          : _abrirSeletorLotes,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: _decoracao(
                          titulo: 'Selecione o lote',
                          icone: Icons.inventory_2_outlined,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                loteAtualSelecionado == null
                                    ? 'Selecionar lote para descarte'
                                    : 'Lote: ${loteAtualSelecionado!.lote} '
                                        '(${_formatarQuantidade(loteAtualSelecionado!.quantidadeDisponivel)} disponíveis)',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: loteAtualSelecionado == null
                                      ? textoSecundario
                                      : textoPrincipal,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.search,
                              color: azulPrincipal,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // QUANTIDADE
                  const Text(
                    'Quantidade desperdiçada *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: quantidadeController,
                    enabled: !carregando,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9,.]'),
                      ),
                    ],
                    decoration: _decoracao(
                      titulo: 'Ex.: 1,5',
                      icone: Icons.scale_outlined,
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'Informe a quantidade.';
                      }

                      final quantidade = double.tryParse(
                        valor.trim().replaceAll(',', '.'),
                      );

                      if (quantidade == null || quantidade <= 0) {
                        return 'Informe uma quantidade válida.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // MOTIVO
                  const Text(
                    'Motivo do desperdício *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: motivoSelecionado,
                    isExpanded: true,
                    decoration: _decoracao(
                      titulo: 'Selecione o motivo',
                      icone: Icons.report_problem_outlined,
                    ),
                    items: motivosDesperdicio.map((motivo) {
                      return DropdownMenuItem<String>(
                        value: motivo,
                        child: Text(
                          motivo,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: carregando
                        ? null
                        : (valor) {
                            setState(() {
                              motivoSelecionado = valor;
                              saidaSelecionada = null;
                              outroPossuiSaida = null;
                            });
                          },
                    validator: (valor) {
                      if (valor == null) {
                        return 'Selecione o motivo.';
                      }
                      return null;
                    },
                  ),

                  // OBSERVAÇÃO PARA OUTRO
                  if (motivoSelecionado == 'Outro') ...[
                    const SizedBox(height: 20),

                    const Text(
                      'Observação *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textoPrincipal,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: observacaoController,
                      enabled: !carregando,
                      maxLines: 3,
                      maxLength: 300,
                      decoration: _decoracao(
                        titulo: 'Descreva o motivo do desperdício',
                        icone: Icons.edit_note_outlined,
                      ),
                    ),
                  ],      

                  // OPÇÃO OUTRO
                  if (motivoSelecionado == 'Outro') ...[
                    const SizedBox(height: 20),
                    const Text(
                      'O produto já havia sido retirado do estoque?',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: carregando
                                ? null
                                : () {
                                    setState(() {
                                      outroPossuiSaida = true;
                                      saidaSelecionada = null;
                                    });
                                  },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: outroPossuiSaida == true
                                  ? azulPrincipal.withValues(alpha: 0.08)
                                  : Colors.white,
                              side: BorderSide(
                                color: outroPossuiSaida == true
                                    ? azulPrincipal
                                    : borda,
                              ),
                            ),
                            child: const Text('Sim'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: carregando
                                ? null
                                : () {
                                    setState(() {
                                      outroPossuiSaida = false;
                                      saidaSelecionada = null;
                                    });
                                  },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: outroPossuiSaida == false
                                  ? azulPrincipal.withValues(alpha: 0.08)
                                  : Colors.white,
                              side: BorderSide(
                                color: outroPossuiSaida == false
                                    ? azulPrincipal
                                    : borda,
                              ),
                            ),
                            child: const Text('Não'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // SAÍDA RELACIONADA
                  if (precisaSaidaAnterior) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Saída relacionada *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: carregando
                          ? null
                          : _abrirSeletorSaidas,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: _decoracao(
                          titulo: 'Selecione a saída',
                          icone: Icons.receipt_long_outlined,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                saidaSelecionada == null
                                    ? 'Selecionar retirada anterior'
                                    : '${saidaSelecionada!.motivo} '
                                        '(${_formatarQuantidade(saidaSelecionada!.quantidadeRestante)} restantes)',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: saidaSelecionada == null
                                      ? textoSecundario
                                      : textoPrincipal,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.search,
                              color: azulPrincipal,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // DATA
                  const Text(
                    'Data do desperdício',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: _decoracao(
                      titulo: 'Data do registro',
                      icone: Icons.calendar_today_outlined,
                    ),
                    child: Text(
                      _formatarData(DateTime.now()),
                      style: const TextStyle(color: textoPrincipal),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // INFORMAÇÃO SOBRE O ESTOQUE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: afetaEstoque
                          ? const Color(0xFFFFF7ED)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: afetaEstoque
                            ? const Color(0xFFFED7AA)
                            : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          afetaEstoque
                              ? Icons.remove_circle_outline
                              : Icons.info_outline,
                          color: afetaEstoque
                              ? const Color(0xFFEA580C)
                              : azulPrincipal,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            afetaEstoque
                                ? 'Este desperdício será descontado diretamente do estoque.'
                                : 'Este desperdício será vinculado a uma saída anterior e não gerará uma segunda baixa.',
                            style: TextStyle(
                              color: afetaEstoque
                                  ? const Color(0xFF9A3412)
                                  : azulEscuro,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // BOTÃO SALVAR
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: carregando || consultando
                          ? null
                          : _registrarDesperdicio,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azulPrincipal,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            azulPrincipal.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: carregando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Registrar desperdício',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SaidaDisponivel {
  final String id;
  final double quantidadeOriginal;
  final double quantidadeRestante;
  final String motivo;
  final DateTime? data;

  _SaidaDisponivel({
    required this.id,
    required this.quantidadeOriginal,
    required this.quantidadeRestante,
    required this.motivo,
    required this.data,
  });
}

class _LoteDisponivel {
  final String id;
  final String lote;
  final double quantidadeDisponivel;
  final DateTime? validade;

  _LoteDisponivel({
    required this.id,
    required this.lote,
    required this.quantidadeDisponivel,
    required this.validade,
  });
}
