
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

class RegistrarSaidaEstoquePage extends StatefulWidget {
  const RegistrarSaidaEstoquePage({super.key});

  @override
  State<RegistrarSaidaEstoquePage> createState() =>
      _RegistrarSaidaEstoquePageState();
}

class _RegistrarSaidaEstoquePageState
    extends State<RegistrarSaidaEstoquePage> {
  final _formKey = GlobalKey<FormState>();

  final quantidadeController = TextEditingController();
  final observacaoController = TextEditingController();

  String? produtoSelecionado;
  String? motivoSelecionado;

  double? estoqueDisponivel;
  String unidadeProduto = 'unidade';

  bool carregando = false;
  bool consultandoEstoque = false;

  final List<String> motivos = [
    'Consumo na cozinha',
    'Preparo de receitas',
    'Transferência',
    'Outro',
  ];

  @override
  void dispose() {
    quantidadeController.dispose();
    observacaoController.dispose();
    super.dispose();
  }

  // Soma as quantidades de uma coleção para determinado produto.
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
      final quantidade = doc.data()['quantidade'];

      if (quantidade is num) {
        total += quantidade.toDouble();
      } else if (quantidade != null) {
        total +=
            double.tryParse(quantidade.toString().replaceAll(',', '.')) ??
                0;
      }
    }

    return total;
  }

  // Calcula o estoque real: entradas - saídas - desperdícios.
  Future<double> _calcularEstoque(String produtoId) async {
    final resultados = await Future.wait([
      _somarColecao('entradasEstoque', produtoId),
      _somarColecao('saidasEstoque', produtoId),
      _somarColecao('desperdicios', produtoId),
    ]);

    final entradas = resultados[0];
    final saidas = resultados[1];
    final desperdicios = resultados[2];

    return entradas - saidas - desperdicios;
  }

  Future<void> _atualizarEstoqueDisponivel(String produtoId) async {
    setState(() {
      consultandoEstoque = true;
      estoqueDisponivel = null;
    });

    try {
      final resultado = await _calcularEstoque(produtoId);

      if (!mounted || produtoSelecionado != produtoId) return;

      setState(() {
        estoqueDisponivel = resultado;
      });
    } catch (e) {
      if (!mounted || produtoSelecionado != produtoId) return;

      _mensagem('Não foi possível consultar o estoque.');
    } finally {
      if (mounted && produtoSelecionado == produtoId) {
        setState(() {
          consultandoEstoque = false;
        });
      }
    }
  }

  String _formatarQuantidade(double quantidade) {
    if (quantidade == quantidade.truncateToDouble()) {
      return quantidade.toStringAsFixed(0);
    }

    return quantidade.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  Future<void> _registrarSaida() async {
    if (carregando) return;

    if (!_formKey.currentState!.validate()) return;

    if (produtoSelecionado == null) {
      _mensagem('Selecione um produto.');
      return;
    }

    if (motivoSelecionado == null) {
      _mensagem('Selecione o motivo da saída.');
      return;
    }

    final quantidade = double.tryParse(
      quantidadeController.text.trim().replaceAll(',', '.'),
    );

    if (quantidade == null || quantidade <= 0) {
      _mensagem('Informe uma quantidade válida.');
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      final produto = await FirebaseFirestore.instance
          .collection('produtos')
          .doc(produtoSelecionado)
          .get();

      if (!produto.exists || produto.data()?['ativo'] == false) {
        _mensagem('O produto selecionado não está disponível.');
        return;
      }

      final dadosProduto = produto.data()!;

      // Consulta novamente antes de registrar para evitar
      // utilizar um valor de estoque desatualizado.
      final disponivel = await _calcularEstoque(produto.id);

      if (quantidade > disponivel) {
        _mensagem(
          'Estoque insuficiente. Disponível: '
          '${_formatarQuantidade(disponivel)} $unidadeProduto.',
        );

        if (mounted) {
          setState(() {
            estoqueDisponivel = disponivel;
          });
        }
        return;
      }

      await FirebaseFirestore.instance
          .collection('saidasEstoque')
          .add({
        'produtoId': produto.id,
        'nomeProduto': dadosProduto['nome'] ?? '',
        'categoria': dadosProduto['categoria'] ?? 'Outros',
        'unidade': dadosProduto['unidade'] ?? 'unidade',
        'quantidade': quantidade,
        'motivo': motivoSelecionado,
        'observacao': observacaoController.text.trim(),
        'dataSaida': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saída registrada com sucesso!'),
          backgroundColor: verdeStatus,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      _mensagem(
        'Erro ao salvar no Firebase: ${e.message ?? e.code}',
      );
    } catch (e) {
      _mensagem('Não foi possível registrar a saída.');
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  void _mensagem(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _decoracao({
    required String titulo,
    required IconData icone,
    String? dica,
  }) {
    return InputDecoration(
      labelText: titulo,
      hintText: dica,
      prefixIcon: Icon(
        icone,
        color: textoSecundario,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: fundo,
        foregroundColor: azulEscuro,
        elevation: 0,
        title: const Text(
          'Registrar saída',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textoPrincipal,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saída de estoque',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: textoPrincipal,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Informe os dados do produto retirado do estoque.',
                  style: TextStyle(
                    fontSize: 14,
                    color: textoSecundario,
                  ),
                ),
                const SizedBox(height: 26),

                // PRODUTO
                const Text(
                  'Produto',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textoPrincipal,
                  ),
                ),
                const SizedBox(height: 9),

                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('produtos')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text(
                        'Erro ao carregar os produtos.',
                        style: TextStyle(color: Colors.red),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final produtos = snapshot.data!.docs
                        .where(
                          (doc) => doc.data()['ativo'] != false,
                        )
                        .toList();

                    if (produtos.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borda),
                        ),
                        child: const Text(
                          'Nenhum produto cadastrado.',
                          style: TextStyle(
                            color: textoSecundario,
                          ),
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: produtoSelecionado,
                      isExpanded: true,
                      decoration: _decoracao(
                        titulo: 'Selecione o produto',
                        icone: Icons.inventory_2_outlined,
                      ),
                      items: produtos.map((doc) {
                        final nome =
                            doc.data()['nome']?.toString() ?? '';

                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(
                            nome,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: carregando
                          ? null
                          : (valor) {
                              if (valor == null) return;

                              final selecionado = produtos.firstWhere(
                                (doc) => doc.id == valor,
                              );

                              setState(() {
                                produtoSelecionado = valor;
                                unidadeProduto = selecionado
                                        .data()['unidade']
                                        ?.toString() ??
                                    'unidade';
                              });

                              _atualizarEstoqueDisponivel(valor);
                            },
                      validator: (valor) {
                        if (valor == null) {
                          return 'Selecione um produto';
                        }
                        return null;
                      },
                    );
                  },
                ),

                const SizedBox(height: 14),

                // ESTOQUE DISPONÍVEL
                if (produtoSelecionado != null)
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
                          Icons.inventory_2_outlined,
                          color: azulPrincipal,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estoque disponível',
                                style: TextStyle(
                                  color: textoSecundario,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (consultandoEstoque)
                                const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                Text(
                                  estoqueDisponivel == null
                                      ? 'Não foi possível consultar'
                                      : '${_formatarQuantidade(estoqueDisponivel!)} '
                                          '$unidadeProduto',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: textoPrincipal,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 22),

                // QUANTIDADE
                TextFormField(
                  controller: quantidadeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*([,.]\d*)?$'),
                    ),
                  ],
                  decoration: _decoracao(
                    titulo: 'Quantidade da saída',
                    icone: Icons.scale_outlined,
                    dica: 'Ex.: 5 ou 2,5',
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Informe a quantidade';
                    }

                    final quantidade = double.tryParse(
                      valor.replaceAll(',', '.'),
                    );

                    if (quantidade == null || quantidade <= 0) {
                      return 'Informe uma quantidade maior que zero';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 22),

                // MOTIVO
                DropdownButtonFormField<String>(
                  initialValue: motivoSelecionado,
                  isExpanded: true,
                  decoration: _decoracao(
                    titulo: 'Motivo da saída',
                    icone: Icons.assignment_outlined,
                  ),
                  items: motivos.map((motivo) {
                    return DropdownMenuItem<String>(
                      value: motivo,
                      child: Text(motivo),
                    );
                  }).toList(),
                  onChanged: carregando
                      ? null
                      : (valor) {
                          setState(() {
                            motivoSelecionado = valor;
                          });
                        },
                  validator: (valor) {
                    if (valor == null) {
                      return 'Selecione o motivo da saída';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 22),

                // OBSERVAÇÃO
                TextFormField(
                  controller: observacaoController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decoracao(
                    titulo: 'Observação (opcional)',
                    icone: Icons.notes_outlined,
                    dica: 'Adicione algum detalhe, se necessário.',
                  ),
                ),

                const SizedBox(height: 30),

                // BOTÃO SALVAR
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed:
                        carregando ? null : _registrarSaida,
                    icon: carregando
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      carregando
                          ? 'Salvando...'
                          : 'Registrar saída',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azulPrincipal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFF93B4F5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
