
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

class RegistrarEntradaEstoquePage extends StatefulWidget {
  const RegistrarEntradaEstoquePage({super.key});

  @override
  State<RegistrarEntradaEstoquePage> createState() =>
      _RegistrarEntradaEstoquePageState();
}

class _RegistrarEntradaEstoquePageState
    extends State<RegistrarEntradaEstoquePage> {
  final _formKey = GlobalKey<FormState>();

  final quantidadeController = TextEditingController();
  final loteController = TextEditingController();

  String? produtoSelecionado;
  String? nomeProdutoSelecionado;
  DateTime? validadeSelecionada;

  bool carregando = false;

  @override
  void dispose() {
    quantidadeController.dispose();
    loteController.dispose();
    super.dispose();
  }

  
  Future<void> _abrirSeletorProdutos(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> produtos,
  ) async {
    final pesquisaController = TextEditingController();

    final resultado = await showModalBottomSheet<
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
            final termo = pesquisaController.text
                .trim()
                .toLowerCase();

            final filtrados = produtos.where((produto) {
              final nome =
                  produto.data()['nome']?.toString().toLowerCase() ?? '';

              return nome.contains(termo);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: Column(
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
                          prefixIcon: const Icon(
                            Icons.search,
                            color: textoSecundario,
                          ),
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
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: azulPrincipal,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        '${filtrados.length} produtos encontrados',
                        style: const TextStyle(
                          fontSize: 12,
                          color: textoSecundario,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Expanded(
                        child: filtrados.isEmpty
                            ? const Center(
                                child: Text(
                                  'Nenhum produto encontrado.',
                                  style: TextStyle(
                                    color: textoSecundario,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtrados.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(
                                  height: 1,
                                  color: borda,
                                ),
                                itemBuilder: (context, index) {
                                  final produto = filtrados[index];
                                  final nome = produto.data()['nome']
                                          ?.toString() ??
                                      'Produto sem nome';

                                  final selecionado =
                                      produto.id == produtoSelecionado;

                                  return ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: selecionado
                                            ? const Color(0xFFDBEAFE)
                                            : fundo,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.inventory_2_outlined,
                                        color: selecionado
                                            ? azulPrincipal
                                            : textoSecundario,
                                      ),
                                    ),
                                    title: Text(
                                      nome,
                                      style: TextStyle(
                                        fontWeight: selecionado
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: textoPrincipal,
                                      ),
                                    ),
                                    trailing: selecionado
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: azulPrincipal,
                                          )
                                        : const Icon(
                                            Icons.chevron_right,
                                            color: textoSecundario,
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

    if (resultado != null && mounted) {
      setState(() {
        produtoSelecionado = resultado.id;
        nomeProdutoSelecionado =
            resultado.data()['nome']?.toString() ?? '';
      });
    }
  }


  Future<void> _selecionarValidade() async {
    final hoje = DateTime.now();

    final data = await showDatePicker(
      context: context,
      initialDate: validadeSelecionada ?? hoje,
      firstDate: hoje,
      lastDate: DateTime(hoje.year + 20),
      helpText: 'Selecione a validade',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: azulPrincipal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textoPrincipal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (data != null) {
      setState(() {
        validadeSelecionada = data;
      });
    }
  }

  String _formatarData(DateTime? data) {
    if (data == null) return 'Selecionar data';

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  Future<void> _registrarEntrada() async {
    if (carregando) return;

    if (!_formKey.currentState!.validate()) return;

    if (produtoSelecionado == null) {
      _mensagem('Selecione um produto.');
      return;
    }

    if (validadeSelecionada == null) {
      _mensagem('Informe a data de validade.');
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
      // Busca o produto selecionado para guardar
      // também algumas informações de referência.
      final produto = await FirebaseFirestore.instance
          .collection('produtos')
          .doc(produtoSelecionado)
          .get();

      if (!produto.exists || produto.data()?['ativo'] == false) {
        _mensagem('O produto selecionado não está disponível.');
        return;
      }

      final dadosProduto = produto.data()!;

      // Cada recebimento gera um documento próprio.
      await FirebaseFirestore.instance
          .collection('entradasEstoque')
          .add({
        'produtoId': produto.id,
        'nomeProduto': dadosProduto['nome'] ?? '',
        'categoria': dadosProduto['categoria'] ?? 'Outros',
        'unidade': dadosProduto['unidade'] ?? 'unidade',
        'quantidade': quantidade,
        'lote': loteController.text.trim(),
        'validade': Timestamp.fromDate(
          validadeSelecionada!,
        ),
        'dataEntrada': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrada registrada com sucesso!'),
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
      _mensagem('Não foi possível registrar a entrada.');
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
          'Registrar entrada',
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
                  'Entrada de estoque',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: textoPrincipal,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Informe os dados do produto recebido.',
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
                          'Nenhum produto cadastrado. Cadastre um produto primeiro.',
                          style: TextStyle(
                            color: textoSecundario,
                          ),
                        ),
                      );
                    }

                    return InkWell(
                      onTap: carregando
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
                                nomeProdutoSelecionado ?? 'Pesquisar e selecionar produto',
                                style: TextStyle(
                                  color: nomeProdutoSelecionado == null
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
                    );
                  },
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
                    titulo: 'Quantidade recebida',
                    icone: Icons.scale_outlined,
                    dica: 'Ex.: 25 ou 2,5',
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

                // LOTE
                TextFormField(
                  controller: loteController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _decoracao(
                    titulo: 'Número do lote',
                    icone: Icons.qr_code_2,
                    dica: 'Ex.: LT2026A01',
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Informe o número do lote';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 22),

                // VALIDADE
                const Text(
                  'Data de validade',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textoPrincipal,
                  ),
                ),
                const SizedBox(height: 9),

                InkWell(
                  onTap: carregando ? null : _selecionarValidade,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: _decoracao(
                      titulo: 'Validade',
                      icone: Icons.calendar_today_outlined,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatarData(validadeSelecionada),
                            style: TextStyle(
                              color: validadeSelecionada == null
                                  ? textoSecundario
                                  : textoPrincipal,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.date_range,
                          color: azulPrincipal,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // BOTÃO SALVAR
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed:
                        carregando ? null : _registrarEntrada,
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
                          : 'Registrar entrada',
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
