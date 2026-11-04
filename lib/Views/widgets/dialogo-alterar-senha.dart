
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DialogoAlterarSenha extends StatefulWidget {
  const DialogoAlterarSenha({super.key});

  @override
  State<DialogoAlterarSenha> createState() =>
      _DialogoAlterarSenhaState();
}

class _DialogoAlterarSenhaState extends State<DialogoAlterarSenha> {
  final _formKey = GlobalKey<FormState>();

  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _carregando = false;
  bool _mostrarSenhas = false;

  @override
  void dispose() {
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _alterarSenha() async {
    if (!_formKey.currentState!.validate()) return;

    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null || usuario.email == null) {
      return;
    }

    setState(() => _carregando = true);

    try {
      // Confirma a senha atual do usuário.
      final credencial = EmailAuthProvider.credential(
        email: usuario.email!,
        password: _senhaAtualController.text,
      );

      await usuario.reauthenticateWithCredential(credencial);

      // Atualiza a senha no Firebase Authentication.
      await usuario.updatePassword(_novaSenhaController.text);

      if (!mounted) return;

      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      String mensagem;

      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          mensagem = 'A senha atual está incorreta.';
          break;
        case 'weak-password':
          mensagem = 'A nova senha é muito fraca.';
          break;
        case 'requires-recent-login':
          mensagem = 'Faça login novamente antes de alterar a senha.';
          break;
        case 'network-request-failed':
          mensagem = 'Verifique sua conexão com a internet.';
          break;
        default:
          mensagem = 'Não foi possível alterar a senha. Tente novamente.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagem)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocorreu um erro ao alterar a senha.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Widget _campoSenha({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !_mostrarSenhas,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() => _mostrarSenhas = !_mostrarSenhas);
          },
          icon: Icon(
            _mostrarSenhas
                ? Icons.visibility_off
                : Icons.visibility,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF2563EB),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Alterar senha',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _carregando
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: Colors.grey,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                const Text(
                  'Informe sua senha atual e escolha uma nova senha.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 24),

                _campoSenha(
                  label: 'Senha atual',
                  controller: _senhaAtualController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe sua senha atual.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                _campoSenha(
                  label: 'Nova senha',
                  controller: _novaSenhaController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe a nova senha.';
                    }

                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres.';
                    }

                    if (value == _senhaAtualController.text) {
                      return 'A nova senha deve ser diferente da atual.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                _campoSenha(
                  label: 'Confirmar nova senha',
                  controller: _confirmarSenhaController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirme sua nova senha.';
                    }

                    if (value != _novaSenhaController.text) {
                      return 'As senhas não coincidem.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _carregando ? null : _alterarSenha,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _carregando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Salvar nova senha'),
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
