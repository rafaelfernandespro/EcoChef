import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home-page.dart';
import 'estoque-page.dart';
import 'desperdicio/desperdicio-page.dart';
import 'usuarios/gerenciar-usuario.dart';
import 'relatorios-page.dart';

class HomeNavigationPage extends StatefulWidget {
  const HomeNavigationPage({super.key});

  @override
  State<HomeNavigationPage> createState() =>
      _HomeNavigationPageState();
}

class _HomeNavigationPageState extends State<HomeNavigationPage> {
  int paginaSelecionada = 0;
  int _homeAnimationKey = 0;
  int _estoqueAnimationKey = 0;

  bool carregandoPerfil = true;
  bool ehAdmin = false;
  String? erroPerfil;

  @override
  void initState() {
    super.initState();
    carregarPerfil();
  }

  // Consulta o perfil do usuário conectado.
  Future<void> carregarPerfil() async {
    try {
      final usuario = FirebaseAuth.instance.currentUser;

      if (usuario == null) {
        throw Exception('Usuário não autenticado.');
      }

      final documento = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();

      final dados = documento.data();

      if (!documento.exists || dados == null) {
        throw Exception('Perfil de usuário não encontrado.');
      }

      if (dados['ativo'] != true) {
        throw Exception('Esta conta está inativa.');
      }

      final tipo = (dados['tipoUsuario'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      final administrador =
          tipo == 'admin' || tipo == 'administrador';

      final funcionario =
          tipo == 'funcionario' || tipo == 'funcionário';

      if (!administrador && !funcionario) {
        throw Exception('Tipo de usuário inválido.');
      }

      if (!mounted) return;

      setState(() {
        ehAdmin = administrador;
        carregandoPerfil = false;
        erroPerfil = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregandoPerfil = false;
        erroPerfil = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // Controla a seleção das páginas disponíveis.
  void selecionarPagina(int index) {
  setState(() {
    // Reinicia a Home sempre que o usuário voltar para ela.
    if (index == 0 && paginaSelecionada != 0) {
      _homeAnimationKey++;
    }

    paginaSelecionada = index;
  });
}

  @override
  Widget build(BuildContext context) {
    if (carregandoPerfil) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2563EB),
          ),
        ),
      );
    }

    if (erroPerfil != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(height: 16),
                Text(
                  erroPerfil!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();

                    if (!context.mounted) return;

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  },
                  child: const Text('Voltar ao login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Páginas disponíveis para cada perfil.
    final List<Widget> paginas = ehAdmin
        ? [
            HomePage(
              key: ValueKey('home-$_homeAnimationKey'),
            ),
            EstoquePage(
              animationKey: _estoqueAnimationKey,
            ),
            const DesperdicioPage(),
            const RelatoriosPage(),
            const ListaFuncionariosScreen(),
          ]
        : [
            HomePage(
              key: ValueKey('home-$_homeAnimationKey'),
            ),
            EstoquePage(
              animationKey: _estoqueAnimationKey,
            ),
            const DesperdicioPage(),
          ];

    // Itens correspondentes às páginas.
    final List<NavigationDestination> destinos = [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Início',
      ),
      const NavigationDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: 'Estoque',
      ),
      const NavigationDestination(
        icon: Icon(Icons.recycling_outlined),
        selectedIcon: Icon(Icons.recycling),
        label: 'Desperdício',
      ),
      if (ehAdmin) ...[
        const NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Relatórios',
        ),
        const NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Usuários',
        ),
      ],
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: IndexedStack(
        index: paginaSelecionada,
        children: paginas,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: paginaSelecionada,
        onDestinationSelected: selecionarPagina,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDBEAFE),
        elevation: 3,
        labelBehavior:
            NavigationDestinationLabelBehavior.alwaysShow,
        destinations: destinos,
      ),
    );
  }
}