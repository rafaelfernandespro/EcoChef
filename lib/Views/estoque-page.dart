
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'cadastrar-produto.dart';
import 'registrar-entrada-estoque.dart';
import 'registrar-saida-estoque.dart';
import 'widgets/menu-perfil.dart';

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
  final String id;
  final String nome;
  final double quantidade;
  final String tipo;
  final String unidade;
  final double estoqueMinimo;
  final DateTime? validade;
  final String status;

  const ProdutoEstoque({
    required this.id,
    required this.nome,
    required this.quantidade,
    required this.tipo,
    required this.unidade,
    required this.estoqueMinimo,
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

  final List<ProdutoEstoque> produtos = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _produtosSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _entradasSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _saidasSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _desperdiciosSubscription;

  final Map<String, double> _quantidadesPorProduto = {};
  final Map<String, double> _saidasPorProduto = {};
  final Map<String, double> _desperdiciosPorProduto = {};

  final Map<String, DateTime> _validadePorProduto = {};

  bool carregando = true;
  String? erroCarregamento;

  final List<String> categorias = [
    'Grãos',
    'Hortifruti',
    'Laticínios',
    'Carnes',
    'Bebidas',
    'Congelados',
    'Outros',
  ];

  final List<String> unidades = [
    'kg',
    'g',
    'L',
    'mL',
    'unidade',
  ];

  @override
  void initState() {
    super.initState();

    _ouvirProdutos();
    _ouvirEntradas();
    _ouvirSaidas();
    _ouvirDesperdicios();
  }

  // Normaliza nomes para comparação.
  String _normalizarNome(String nome) {
    return nome
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  // Verifica se outro produto ativo já possui o mesmo nome.
  Future<bool> _nomeJaExiste(
    String nome,
    String produtoId,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('produtos')
        .get();

    final nomeNormalizado = _normalizarNome(nome);

    for (final documento in snapshot.docs) {
      if (documento.id == produtoId) continue;

      final dados = documento.data();

      if (dados['ativo'] == false) continue;

      final nomeExistente = _normalizarNome(
        (dados['nomeNormalizado'] ?? dados['nome'] ?? '')
            .toString(),
      );

      if (nomeExistente == nomeNormalizado) {
        return true;
      }
    }

    return false;
  }

  // Busca os produtos cadastrados em tempo real.
  void _ouvirProdutos() {
    _produtosSubscription?.cancel();

    _produtosSubscription = FirebaseFirestore.instance
        .collection('produtos')
        .snapshots()
        .listen(
      (snapshot) {
        _atualizarListaProdutos(snapshot.docs);
      },
      onError: (Object erro) {
        if (!mounted) return;

        setState(() {
          carregando = false;
          erroCarregamento = erro.toString();
        });
      },
    );
  }

  // Escuta as entradas de estoque em tempo real.
  
  void _ouvirEntradas() {
    _entradasSubscription?.cancel();

    _entradasSubscription = FirebaseFirestore.instance
        .collection('entradasEstoque')
        .snapshots()
        .listen(
      (snapshot) {
        final quantidades = <String, double>{};
        final validades = <String, DateTime>{};

        for (final documento in snapshot.docs) {
          final dados = documento.data();

          final produtoId = dados['produtoId']?.toString();

          if (produtoId == null || produtoId.isEmpty) {
            continue;
          }

          // Utilizar somente a quantidade ainda disponível no lote.
          final quantidade =
              (dados['quantidadeDisponivel'] as num?)?.toDouble() ?? 0.0;

          quantidades[produtoId] =
              (quantidades[produtoId] ?? 0.0) + quantidade;

          // Lotes zerados não devem influenciar o próximo vencimento.
          if (quantidade <= 0) continue;

          final validadeTimestamp = dados['validade'];

          DateTime? validade;

          if (validadeTimestamp is Timestamp) {
            validade = validadeTimestamp.toDate();
          } else if (validadeTimestamp is DateTime) {
            validade = validadeTimestamp;
          }

          if (validade != null) {
            final validadeAtual = validades[produtoId];

            if (validadeAtual == null ||
                validade.isBefore(validadeAtual)) {
              validades[produtoId] = validade;
            }
          }
        }

        if (!mounted) return;

        setState(() {
          _quantidadesPorProduto
            ..clear()
            ..addAll(quantidades);

          _validadePorProduto
            ..clear()
            ..addAll(validades);

          _recalcularProdutos();
        });
      },
      onError: (Object erro) {
        if (!mounted) return;

        setState(() {
          carregando = false;
          erroCarregamento = erro.toString();
        });
      },
    );
  }


  // Escuta as saídas normais de estoque em tempo real.
  void _ouvirSaidas() {
    _saidasSubscription?.cancel();

    _saidasSubscription = FirebaseFirestore.instance
        .collection('saidasEstoque')
        .snapshots()
        .listen(
      (snapshot) {
        final quantidades = <String, double>{};

        for (final documento in snapshot.docs) {
          final dados = documento.data();

          final produtoId = dados['produtoId']?.toString();

          if (produtoId == null || produtoId.isEmpty) {
            continue;
          }

          final quantidade =
              (dados['quantidade'] as num?)?.toDouble() ?? 0.0;

          quantidades[produtoId] =
              (quantidades[produtoId] ?? 0.0) + quantidade;
        }

        if (!mounted) return;

        setState(() {
          _saidasPorProduto
            ..clear()
            ..addAll(quantidades);

          _recalcularProdutos();
        });
      },
      onError: (Object erro) {
        if (!mounted) return;

        setState(() {
          carregando = false;
          erroCarregamento = erro.toString();
        });
      },
    );
  }

  // Escuta os desperdícios em tempo real.
  void _ouvirDesperdicios() {
    _desperdiciosSubscription?.cancel();

    _desperdiciosSubscription = FirebaseFirestore.instance
        .collection('desperdicios')
        .snapshots()
        .listen(
      (snapshot) {
        final quantidades = <String, double>{};

        for (final documento in snapshot.docs) {
          final dados = documento.data();

          // Considera somente desperdícios que geram baixa.
          // Documentos antigos, sem afetaEstoque, continuam contando.
          if (dados.containsKey('afetaEstoque') &&
              dados['afetaEstoque'] != true) {
            continue;
          }

          final produtoId = dados['produtoId']?.toString();
          if (produtoId == null || produtoId.isEmpty) {
            continue;
          }

          final quantidade =
              (dados['quantidade'] as num?)?.toDouble() ?? 0.0;

          quantidades[produtoId] =
              (quantidades[produtoId] ?? 0.0) + quantidade;
        }

        if (!mounted) return;

        setState(() {
          _desperdiciosPorProduto
            ..clear()
            ..addAll(quantidades);

          _recalcularProdutos();
        });
      },
      onError: (Object erro) {
        if (!mounted) return;

        setState(() {
          carregando = false;
          erroCarregamento = erro.toString();
        });
      },
    );
  }

  // Converte os documentos do Firestore em produtos.
  void _atualizarListaProdutos(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documentos,
  ) {
    final produtosRecebidos = documentos
        .where((documento) => documento.data()['ativo'] != false)
        .map((documento) {
      final dados = documento.data();

      return ProdutoEstoque(
        id: documento.id,
        nome: (dados['nome'] ?? '').toString(),
        quantidade: 0,
        tipo: (dados['categoria'] ?? 'Outros').toString(),
        unidade: (dados['unidade'] ?? 'unidade').toString(),
        estoqueMinimo:
            (dados['estoqueMinimo'] as num?)?.toDouble() ?? 0.0,
        validade: null,
        status: 'Em falta',
      );
    }).toList();

    if (!mounted) return;

    setState(() {
      produtos
        ..clear()
        ..addAll(produtosRecebidos);

      _recalcularProdutos();

      carregando = false;
      erroCarregamento = null;
    });
  }

  // Calcula o estoque disponível de cada produto.
  
  void _recalcularProdutos() {
    for (int i = 0; i < produtos.length; i++) {
      final produto = produtos[i];

      // O saldo já considera entradas, saídas e desperdícios,
      // pois cada movimentação atualiza quantidadeDisponivel.
      final quantidade =
          _quantidadesPorProduto[produto.id] ?? 0.0;

      final validade = _validadePorProduto[produto.id];

      final status = quantidade <= 0
          ? 'Em falta'
          : quantidade < produto.estoqueMinimo
              ? 'Abaixo do mínimo'
              : 'Disponível';

      produtos[i] = ProdutoEstoque(
        id: produto.id,
        nome: produto.nome,
        quantidade: quantidade,
        tipo: produto.tipo,
        unidade: produto.unidade,
        estoqueMinimo: produto.estoqueMinimo,
        validade: validade,
        status: status,
      );
    }

    produtos.sort(
      (a, b) => a.nome
          .toLowerCase()
          .compareTo(b.nome.toLowerCase()),
    );
  }


  @override
  void dispose() {
    _produtosSubscription?.cancel();
    _entradasSubscription?.cancel();
    _saidasSubscription?.cancel();
    _desperdiciosSubscription?.cancel();

    pesquisaController.dispose();

    super.dispose();
  }

  List<String> get tiposDisponiveis {
    final tipos = produtos.map((p) => p.tipo).toSet().toList();

    tipos.sort();

    return ['Todos', ...tipos];
  }

  List<ProdutoEstoque> get produtosFiltrados {
    final pesquisa =
        pesquisaController.text.toLowerCase().trim();

    return produtos.where((produto) {
      final correspondeNome =
          produto.nome.toLowerCase().contains(pesquisa);

      final correspondeStatus =
          filtroStatus == 'Todos' ||
              produto.status == filtroStatus;

      final correspondeTipo =
          filtroTipo == 'Todos' ||
              produto.tipo == filtroTipo;

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

  // Abre o cadastro de produto.
  Future<void> _abrirCadastroProduto() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CadastrarProdutoPage(),
      ),
    );

    if (!mounted || resultado != true) return;

    setState(() {
      filtroStatus = 'Todos';
      filtroTipo = 'Todos';
      pesquisaController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Produto cadastrado com sucesso!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Abre a tela de entrada de estoque.
  Future<void> _abrirEntradaEstoque() async {
    if (produtos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cadastre um produto antes de registrar uma entrada.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const RegistrarEntradaEstoquePage(),
      ),
    );

    if (!mounted || resultado != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entrada registrada com sucesso!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Abre a tela de saída de estoque.
  Future<void> _abrirSaidaEstoque() async {
    if (produtos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cadastre um produto antes de registrar uma saída.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const RegistrarSaidaEstoquePage(),
      ),
    );
  }

  // Abre as opções de gerenciamento ao clicar no produto.
  void _abrirOpcoesProduto(ProdutoEstoque produto) {
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
                Text(
                  produto.nome,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: textoPrincipal,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'O que deseja fazer com este produto?',
                  style: TextStyle(
                    fontSize: 14,
                    color: textoSecundario,
                  ),
                ),
                const SizedBox(height: 16),
                _opcaoEstoque(
                  icone: Icons.edit_outlined,
                  titulo: 'Editar produto',
                  descricao: 'Alterar as informações cadastradas',
                  cor: azulPrincipal,
                  aoTocar: () {
                    Navigator.pop(context);
                    _editarProduto(produto);
                  },
                ),
                _opcaoEstoque(
                  icone: Icons.inventory_2_outlined,
                  titulo: 'Inativar produto',
                  descricao: 'Retirar o produto da listagem do estoque',
                  cor: vermelhoStatus,
                  aoTocar: () {
                    Navigator.pop(context);
                    _confirmarInativacao(produto);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Formulário para editar produto.
  Future<void> _editarProduto(ProdutoEstoque produto) async {
    final nomeController =
        TextEditingController(text: produto.nome);

    final minimoController = TextEditingController(
      text: produto.estoqueMinimo.toString().replaceAll('.', ','),
    );

    String categoriaSelecionada =
        categorias.contains(produto.tipo) ? produto.tipo : 'Outros';

    String unidadeSelecionada =
        unidades.contains(produto.unidade)
            ? produto.unidade
            : 'unidade';
    
    final nomeOriginal = nomeController.text.trim();
    final minimoOriginal = minimoController.text.trim();
    final categoriaOriginal = categoriaSelecionada;
    final unidadeOriginal = unidadeSelecionada;

    final formKey = GlobalKey<FormState>();

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, atualizarDialog) {

            final houveAlteracao =
            nomeController.text.trim() != nomeOriginal ||
            minimoController.text.trim() != minimoOriginal ||
            categoriaSelecionada != categoriaOriginal ||
            unidadeSelecionada != unidadeOriginal;

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Editar produto',
                style: TextStyle(
                  color: textoPrincipal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nome do produto',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextFormField(
                        onChanged: (valor) {
                          atualizarDialog(() {});
                        },
                        controller: nomeController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _decoracaoCampo(
                          'Digite o nome do produto',
                        ),
                        validator: (valor) {
                          if (valor == null || valor.trim().isEmpty) {
                            return 'Informe o nome do produto.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Categoria',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 7),
                      DropdownButtonFormField<String>(
                        initialValue: categoriaSelecionada,
                        isExpanded: true,
                        decoration: _decoracaoCampo('Categoria'),
                        items: categorias.map((categoria) {
                          return DropdownMenuItem(
                            value: categoria,
                            child: Text(categoria),
                          );
                        }).toList(),
                        onChanged: (valor) {
                          if (valor != null) {
                            atualizarDialog(() {
                              categoriaSelecionada = valor;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Unidade de medida',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 7),
                      DropdownButtonFormField<String>(
                        initialValue: unidadeSelecionada,
                        isExpanded: true,
                        decoration: _decoracaoCampo('Unidade'),
                        items: unidades.map((unidade) {
                          return DropdownMenuItem(
                            value: unidade,
                            child: Text(unidade),
                          );
                        }).toList(),
                        onChanged: (valor) {
                          if (valor != null) {
                            atualizarDialog(() {
                              unidadeSelecionada = valor;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Estoque mínimo',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextFormField(
                        onChanged: (valor) {
                          atualizarDialog(() {});
                        },
                        controller: minimoController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _decoracaoCampo(
                          'Ex.: 10',
                        ),
                        validator: (valor) {
                          final numero = double.tryParse(
                            (valor ?? '').replaceAll(',', '.'),
                          );

                          if (numero == null || numero < 0) {
                            return 'Informe um valor válido.';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: textoSecundario),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azulPrincipal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: houveAlteracao ? () async {
                    if (!formKey.currentState!.validate()) return;

                    final nome = nomeController.text.trim();

                    try {
                      final existe = await _nomeJaExiste(
                        nome,
                        produto.id,
                      );

                      if (existe) {
                        if (!dialogContext.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Já existe um produto ativo com esse nome.',
                            ),
                          ),
                        );
                        return;
                      }

                      final estoqueMinimo = double.parse(
                        minimoController.text.replaceAll(',', '.'),
                      );

                      await FirebaseFirestore.instance
                          .collection('produtos')
                          .doc(produto.id)
                          .update({
                        'nome': nome,
                        'nomeNormalizado': _normalizarNome(nome),
                        'categoria': categoriaSelecionada,
                        'unidade': unidadeSelecionada,
                        'estoqueMinimo': estoqueMinimo,
                        'atualizadoEm': FieldValue.serverTimestamp(),
                      });

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext, true);
                    } catch (erro) {
                      if (!dialogContext.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Não foi possível editar o produto: $erro',
                          ),
                        ),
                      );
                    }
                  } : null,
                  child: const Text('Salvar alterações'),
                ),
              ],
            );
          },
        );
      },
    );

    nomeController.dispose();
    minimoController.dispose();

    if (!mounted || resultado != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Produto atualizado com sucesso!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _decoracaoCampo(String dica) {
    return InputDecoration(
      hintText: dica,
      filled: true,
      fillColor: fundo,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
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
        borderSide: const BorderSide(color: azulPrincipal),
      ),
    );
  }

  // Confirma a inativação do produto.
  Future<void> _confirmarInativacao(
    ProdutoEstoque produto,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Inativar produto?',
            style: TextStyle(
              color: textoPrincipal,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Deseja realmente inativar "${produto.nome}"?\n\n'
            'Ele deixará de aparecer na listagem, mas seu histórico '
            'de entradas e desperdícios será preservado.',
            style: const TextStyle(
              color: textoSecundario,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: textoSecundario),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: vermelhoStatus,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Inativar'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmar != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('produtos')
          .doc(produto.id)
          .update({
        'ativo': false,
        'inativadoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto inativado com sucesso!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível inativar o produto: $erro'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                    _cabecalho(),
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
            if (carregando)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (erroCarregamento != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 42,
                          color: vermelhoStatus,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Não foi possível carregar os dados do estoque.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textoPrincipal,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              carregando = true;
                              erroCarregamento = null;
                            });

                            _ouvirProdutos();
                            _ouvirEntradas();
                            _ouvirSaidas();
                            _ouvirDesperdicios();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (lista.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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
                    _abrirEntradaEstoque();
                  },
                ),
                _opcaoEstoque(
                  icone: Icons.north_east,
                  titulo: 'Registrar saída / dar baixa',
                  descricao: 'Retirar quantidade e informar o motivo',
                  cor: vermelhoStatus,
                  aoTocar: () {
                    Navigator.pop(context);
                    _abrirSaidaEstoque();
                  },
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _cabecalho() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estoque',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textoPrincipal,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Consulte os produtos e acompanhe suas quantidades.',
                style: TextStyle(
                  fontSize: 14,
                  color: textoSecundario,
                ),
              ),
            ],
          ),
        ),
        const MenuPerfil(),
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
                  setState(() {
                    filtroStatus = valor ?? 'Todos';
                  });
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
                  setState(() {
                    filtroTipo = valor ?? 'Todos';
                  });
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
      initialValue: valor,
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

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _abrirOpcoesProduto(produto),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
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
                    '${produto.quantidade.toStringAsFixed(1).replaceAll('.', ',')} ${produto.unidade}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: azulEscuro,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.more_horiz,
                    color: textoSecundario,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
