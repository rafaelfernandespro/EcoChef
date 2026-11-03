
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  bool _verificandoPermissao = false;
  bool _podeVerUsuarios = false;

  // Verifica se o usuário conectado é administrador ativo.
  Future<void> verificarAcessoUsuarios() async {
    if (_verificandoPermissao) return;

    setState(() {
      paginaSelecionada = 4;
      _verificandoPermissao = true;
      _podeVerUsuarios = false;
    });

    bool autorizado = false;

    try {
      final usuario = FirebaseAuth.instance.currentUser;

      if (usuario != null) {
        final documento = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(usuario.uid)
            .get();

        final dados = documento.data();

        if (documento.exists && dados != null) {
          final tipo = (dados['tipoUsuario'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

          final ativo = dados['ativo'] == true;

          autorizado =
              (tipo == 'admin' || tipo == 'administrador') &&
              ativo;
        }
      }
    } catch (_) {
      autorizado = false;
    }

    if (!mounted) return;

    setState(() {
      _podeVerUsuarios = autorizado;
      _verificandoPermissao = false;
    });
  }

  // Controla a seleção das páginas.
  void selecionarPagina(int index) {
    if (index == 4) {
      verificarAcessoUsuarios();
      return;
    }

    setState(() {
      paginaSelecionada = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: IndexedStack(
        index: paginaSelecionada,
        children: [
          // INÍCIO
          const HomePage(),

          // PRODUTOS
          const EstoquePage(),

          // DESPERDÍCIO
          const _PaginaPlaceholder(
            titulo: 'Desperdício',
            icone: Icons.recycling_outlined,
            descricao:
                'Registre e acompanhe as perdas de alimentos.',
          ),

          // RELATÓRIOS
          const _PaginaPlaceholder(
            titulo: 'Relatórios',
            icone: Icons.bar_chart_outlined,
            descricao:
                'Acompanhe os indicadores e as estatísticas.',
          ),

          // USUÁRIOS
          if (_verificandoPermissao)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2563EB),
              ),
            )
          else if (_podeVerUsuarios)
            const ListaFuncionariosScreen()
          else
            const _PaginaPlaceholder(
              titulo: 'Usuários',
              icone: Icons.recycling_outlined,
              tituloCentral: 'Acesso não permitido',
              descricao:
                  'Você não tem permissão para acessar esta funcionalidade.',
              mensagemFinal:
                  'Entre em contato com um administrador para solicitar acesso.',
            ),
        ],
      ),

      // BARRA DE NAVEGAÇÃO
      bottomNavigationBar: NavigationBar(
        selectedIndex: paginaSelecionada,

        onDestinationSelected: selecionarPagina,

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

// TELA PADRÃO DAS FUNCIONALIDADES
class _PaginaPlaceholder extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final String descricao;

  final String? tituloCentral;

  final String mensagemFinal;

  const _PaginaPlaceholder({
    required this.titulo,
    required this.icone,
    required this.descricao,
    this.tituloCentral,
    this.mensagemFinal =
        'Esta funcionalidade será implementada.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        automaticallyImplyLeading: false,
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
                tituloCentral ?? titulo,
                textAlign: TextAlign.center,
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

              Text(
                mensagemFinal,
                textAlign: TextAlign.center,
                style: const TextStyle(
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
