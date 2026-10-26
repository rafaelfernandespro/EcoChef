import 'package:flutter/material.dart';

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
  static const int totalProdutos = 32;
  static const int itensEmFalta = 3;
  static const double desperdicioDiario = 12.5;
  static const double custoDesperdicio = 86.40;

  static const List<double> desperdicioSemanal = [
    8, 12, 6, 15, 10, 18, 12.5
  ];

  static const List<String> diasSemana = [
    'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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

                  // KPIs
                  Row(
                    children: [
                      Expanded(
                        child: _kpi(
                          titulo: 'Produtos',
                          valor: '$totalProdutos',
                          descricao: 'Cadastrados',
                          icone: Icons.inventory_2_outlined,
                          cor: azulPrincipal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _kpi(
                          titulo: 'Desperdício hoje',
                          valor: '${desperdicioDiario.toStringAsFixed(1)} kg',
                          descricao:
                              'R\$ ${custoDesperdicio.toStringAsFixed(2)}',
                          icone: Icons.delete_outline,
                          cor: const Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _kpi(
                          titulo: 'Itens em falta',
                          valor: '$itensEmFalta',
                          descricao: 'Precisam de atenção',
                          icone: Icons.warning_amber_rounded,
                          cor: const Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _kpi(
                          titulo: 'Estoque baixo',
                          valor: '5',
                          descricao: 'Abaixo do mínimo',
                          icone: Icons.trending_down,
                          cor: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  _tituloSecao(
                    'Desperdício semanal',
                    'Quantidade descartada por dia',
                  ),
                  const SizedBox(height: 14),
                  _graficoSemanal(),

                  const SizedBox(height: 28),

                  _tituloSecao(
                    'Alertas recentes',
                    'Ocorrências que precisam de atenção',
                  ),
                  const SizedBox(height: 14),

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
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: azulPrincipal,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.restaurant_menu,
            color: Colors.white,
            size: 27,
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
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: azulEscuro,
                ),
              ),
              Text(
                'Gestão inteligente',
                style: TextStyle(
                  fontSize: 12,
                  color: textoSecundario,
                ),
              ),
            ],
          ),
        ),

        // Ícone de perfil no canto superior direito
        IconButton(
          tooltip: 'Perfil',
          onPressed: () {
            // TODO: Navegar para a tela de perfil.
          },
          icon: const Icon(
            Icons.account_circle_outlined,
            size: 31,
            color: azulEscuro,
          ),
        ),
      ],
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

  Widget _graficoSemanal() {
    final maiorValor = desperdicioSemanal.reduce(
      (a, b) => a > b ? a : b,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alimentos desperdiçados',
            style: TextStyle(
              fontSize: 13,
              color: textoSecundario,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'kg / dia',
            style: TextStyle(
              fontSize: 12,
              color: textoSecundario,
            ),
          ),
          const SizedBox(height: 22),

          SizedBox(
            height: 145,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(desperdicioSemanal.length, (index) {
                final valor = desperdicioSemanal[index];
                final altura = maiorValor == 0
                    ? 0.0
                    : (valor / maiorValor) * 100;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          valor.toStringAsFixed(
                            valor == valor.roundToDouble() ? 0 : 1,
                          ),
                          style: const TextStyle(
                            fontSize: 10,
                            color: textoSecundario,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: altura,
                          decoration: BoxDecoration(
                            color: index == desperdicioSemanal.length - 1
                                ? azulEscuro
                                : azulPrincipal.withOpacity(0.65),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          diasSemana[index],
                          style: const TextStyle(
                            fontSize: 10,
                            color: textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
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