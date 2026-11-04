
import 'package:flutter/material.dart';
import 'dialogo-perfil.dart';

class MenuPerfil extends StatelessWidget {
  const MenuPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        tooltip: 'Perfil',
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.account_circle_outlined,
          color: Color(0xFF1E3A8A),
          size: 31,
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const DialogoPerfil(),
          );
        },
      ),
    );
  }
}
