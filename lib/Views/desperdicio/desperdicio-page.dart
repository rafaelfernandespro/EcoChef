
import 'package:flutter/material.dart';

import 'registrar-desperdicio.dart';
import 'historico-desperdicio.dart';
import '../widgets/menu-perfil.dart';

const azulPrincipal = Color(0xFF2563EB);
const azulEscuro = Color(0xFF1E3A8A);
const fundo = Color(0xFFF8FAFC);
const textoPrincipal = Color(0xFF1E293B);
const textoSecundario = Color(0xFF64748B);
const borda = Color(0xFFE2E8F0);

class DesperdicioPage extends StatefulWidget {
  final int animationKey;

  const DesperdicioPage({
    super.key,
    this.animationKey = 0,
  });

  @override
  State<DesperdicioPage> createState() =>
      _DesperdicioPageState();
}

class _DesperdicioPageState extends State<DesperdicioPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animacaoController;

  @override
  void initState() {
    super.initState();

    _animacaoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void didUpdateWidget(covariant DesperdicioPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animationKey != widget.animationKey) {
      _animacaoController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animacaoController.dispose();
    super.dispose();
  }

  Widget _animarEntrada({
    required Widget child,
    required double inicio,
    required double fim,
  }) {
    return AnimatedBuilder(
      animation: _animacaoController,
      child: child,
      builder: (context, child) {
        final animacao = CurvedAnimation(
          parent: _animacaoController,
          curve: Interval(
            inicio,
            fim,
            curve: Curves.easeOutCubic,
          ),
        );

        return Opacity(
          opacity: animacao.value,
          child: Transform.translate(
            offset: Offset(
              0,
              22 * (1 - animacao.value),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _animarEntrada(
                inicio: 0,
                fim: 0.45,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Desperdício',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: textoPrincipal,
                            ),
                          ),
                        ),
                        const MenuPerfil(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Registre e acompanhe as perdas de alimentos.',
                      style: TextStyle(
                        fontSize: 14,
                        color: textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              _animarEntrada(
                inicio: 0.15,
                fim: 0.65,
                child: _botaoOpcao(
                  contexto: context,
                  icone: Icons.add_circle_outline,
                  titulo: 'Registrar desperdício',
                  descricao:
                      'Informe os alimentos descartados e o motivo.',
                  cor: azulPrincipal,
                  aoTocar: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegistrarDesperdicioPage(),
                      ),
                    );

                    if (!mounted) return;

                    _animacaoController.forward(from: 0);
                  },
                ),
              ),

              const SizedBox(height: 16),

              _animarEntrada(
                inicio: 0.30,
                fim: 0.80,
                child: _botaoOpcao(
                  contexto: context,
                  icone: Icons.history,
                  titulo: 'Visualizar histórico',
                  descricao:
                      'Consulte os desperdícios registrados.',
                  cor: azulEscuro,
                  aoTocar: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HistoricoDesperdicioPage(),
                      ),
                    );

                    if (!mounted) return;

                    _animacaoController.forward(from: 0);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botaoOpcao({
    required BuildContext contexto,
    required IconData icone,
    required String titulo,
    required String descricao,
    required Color cor,
    required VoidCallback aoTocar,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borda),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icone,
                  color: cor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      descricao,
                      style: const TextStyle(
                        fontSize: 12,
                        color: textoSecundario,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: textoSecundario,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
