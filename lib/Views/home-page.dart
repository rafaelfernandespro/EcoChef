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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // DADOS DE DEMONSTRAÇÃO.
  // Futuramente, substituir por dados vindos da API.

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
  // Produtos ativos.
  final produtosAtivos = produtosDocs.where((doc) {
    return doc.data()['ativo'] != false;
  }).toList();

  // Informações dos produtos para consultar unidade e estoque mínimo.
  final dadosProdutos = {
    for (final doc in produtosDocs)
      doc.id: doc.data(),
  };

  // Estoque disponível por produto.
  final estoquePorProduto = <String, double>{};

  for (final entrada in entradasDocs) {
    final dados = entrada.data();
    final produtoId = dados['produtoId']?.toString();

    if (produtoId == null || produtoId.isEmpty) continue;

    final quantidade =
        (dados['quantidadeDisponivel'] as num?)?.toDouble() ?? 0.0;

    estoquePorProduto[produtoId] =
        (estoquePorProduto[produtoId] ?? 0.0) + quantidade;
  }

  // Calcula produtos sem estoque e abaixo do mínimo.
  int itensEmFalta = 0;
  int estoqueBaixo = 0;

  for (final produto in produtosAtivos) {
    final dados = produto.data();

    final quantidade =
        estoquePorProduto[produto.id] ?? 0.0;

    final estoqueMinimo =
        (dados['estoqueMinimo'] as num?)?.toDouble() ?? 0.0;

    if (quantidade <= 0) {
      itensEmFalta++;
    } else if (quantidade < estoqueMinimo) {
      estoqueBaixo++;
    }
  }

  // Calcula o desperdício registrado hoje em kg.
  final agora = DateTime.now();

  final inicioHoje = DateTime(
    agora.year,
    agora.month,
    agora.day,
  );

  final inicioAmanha = inicioHoje.add(
    const Duration(days: 1),
  );

  final desperdicioDiarioPorUnidade = <String, double>{};

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

    final quantidade =
        (dados['quantidade'] as num?)?.toDouble() ?? 0.0;

    final produtoId = dados['produtoId']?.toString();

    final unidade = (
      dados['unidade'] ??
      dadosProdutos[produtoId]?['unidade'] ??
      'unidade'
    ).toString().trim().toLowerCase();

    String unidadeNormalizada;

    switch (unidade) {
      case 'un':
      case 'un.':
      case 'und':
      case 'unidades':
      case 'unidade':
        unidadeNormalizada = 'unidade';
        break;
      case 'l':
      case 'litro':
      case 'litros':
        unidadeNormalizada = 'l';
        break;
      case 'ml':
      case 'mililitro':
      case 'mililitros':
        unidadeNormalizada = 'ml';
        break;
      default:
        unidadeNormalizada = unidade;
    }

    desperdicioDiarioPorUnidade[unidadeNormalizada] =
        (desperdicioDiarioPorUnidade[unidadeNormalizada] ?? 0) +
            quantidade;
  }

String formatarQuantidade(double quantidade) {
  return quantidade
      .toStringAsFixed(2)
      .replaceAll('.', ',')
      .replaceFirst(RegExp(r',?0+$'), '');
}

String formatarUnidade(String unidade) {
  switch (unidade) {
    case 'unidade':
      return 'un.';
    case 'l':
      return 'L';
    case 'ml':
      return 'mL';
    default:
      return unidade;
  }
}

final desperdicioTexto =
    desperdicioDiarioPorUnidade.isEmpty
        ? '0 kg'
        : desperdicioDiarioPorUnidade.entries
            .map((entrada) =>
                '${formatarQuantidade(entrada.value)} '
                '${formatarUnidade(entrada.key)}')
            .join('\n');

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

                  // PRIMEIRA LINHA DE CARDS
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
                          titulo: 'Desperdício hoje',
                          valor: desperdicioTexto,
                          descricao: 'Registrado hoje',
                          icone: Icons.delete_outline,
                          cor: const Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // SEGUNDA LINHA DE CARDS
                  Row(
                    children: [
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

                  const SizedBox(height: 28),

                  _tituloSecao(
                    'Alertas recentes',
                    'Ocorrências que precisam de atenção',
                  ),
                  const SizedBox(height: 14),

                  // PLACEHOLDERS: MANTIDOS POR ENQUANTO
                  _alerta(
                    icone: Icons.error_outline,
                    cor: const Color(0xFFDC2626),
                    titulo: 'Produto em falta',
                    descricao: 'Frango está sem estoque disponível.',
                    tempo: 'Há 20 min',
                  ),
                  const SizedBox(height: 10),

                  _alerta(
                    icone: Icons.warning_amber_rounded,
                    cor: const Color(0xFFD97706),
                    titulo: 'Estoque baixo',
                    descricao: 'O estoque de arroz está abaixo do mínimo.',
                    tempo: 'Há 1 hora',
                  ),
                  const SizedBox(height: 10),

                  _alerta(
                    icone: Icons.delete_outline,
                    cor: azulPrincipal,
                    titulo: 'Desperdício registrado',
                    descricao: '2,5 kg de alimentos foram descartados.',
                    tempo: 'Há 3 horas',
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  
  }

  
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
              color: cor.withOpacity(0.10),
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
              color: cor.withOpacity(0.10),
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