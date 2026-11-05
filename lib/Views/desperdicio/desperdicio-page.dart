
import 'package:flutter/material.dart';

import 'registrar-desperdicio.dart';
import 'historico-desperdicio.dart';

const azulPrincipal = Color(0xFF2563EB);
const azulEscuro = Color(0xFF1E3A8A);
const fundo = Color(0xFFF8FAFC);
const textoPrincipal = Color(0xFF1E293B);
const textoSecundario = Color(0xFF64748B);
const borda = Color(0xFFE2E8F0);

class DesperdicioPage extends StatelessWidget {
  const DesperdicioPage({super.key});

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
              const Text(
                'Desperdício',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textoPrincipal,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Registre e acompanhe as perdas de alimentos.',
                style: TextStyle(
                  fontSize: 14,
                  color: textoSecundario,
                ),
              ),

              const SizedBox(height: 32),

              _botaoOpcao(
                contexto: context,
                icone: Icons.add_circle_outline,
                titulo: 'Registrar desperdício',
                descricao:
                    'Informe os alimentos descartados e o motivo.',
                cor: azulPrincipal,
                aoTocar: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const RegistrarDesperdicioPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              _botaoOpcao(
                contexto: context,
                icone: Icons.history,
                titulo: 'Visualizar histórico',
                descricao:
                    'Consulte os desperdícios registrados.',
                cor: azulEscuro,
                aoTocar: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HistoricoDesperdicioPage(),
                    ),
                  );
                },
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