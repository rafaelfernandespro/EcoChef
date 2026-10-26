
import 'package:flutter/material.dart';

import 'home-page.dart';
import 'usuarios/gerenciar-usuario.dart';
import 'estoque-page.dart';

class HomeNavigationPage extends StatefulWidget {
  const HomeNavigationPage({super.key});

  @override
  State<HomeNavigationPage> createState() =>
      _HomeNavigationPageState();
}

class _HomeNavigationPageState
    extends State<HomeNavigationPage> {
  int paginaSelecionada = 0;

  late final List<Widget> paginas = [
    const HomePage(),

    const EstoquePage(),

    const _PaginaPlaceholder(
      titulo: 'Desperdício',
      icone: Icons.recycling_outlined,
      descricao: 'Registre e acompanhe as perdas de alimentos.',
    ),

    const _PaginaPlaceholder(
      titulo: 'Relatórios',
      icone: Icons.bar_chart_outlined,
      descricao: 'Acompanhe os indicadores e as estatísticas.',
    ),

    const ListaFuncionariosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: IndexedStack(
        index: paginaSelecionada,
        children: paginas,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: paginaSelecionada,

        onDestinationSelected: (int index) {
          setState(() {
            paginaSelecionada = index;
          });
        },

        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDBEAFE),
        elevation: 3,

        labelBehavior:
            NavigationDestinationLabelBehavior.alwaysShow,

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Produtos',
          ),
          NavigationDestination(
            icon: Icon(Icons.recycling_outlined),
            selectedIcon: Icon(Icons.recycling),
            label: 'Desperdício',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Relatórios',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Usuários',
          ),
        ],
      ),
    );
  }
}

class _PaginaPlaceholder extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final String descricao;

  const _PaginaPlaceholder({
    required this.titulo,
    required this.icone,
    required this.descricao,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icone,
                size: 64,
                color: const Color(0xFF2563EB),
              ),

              const SizedBox(height: 16),

              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                descricao,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Esta funcionalidade será implementada.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
