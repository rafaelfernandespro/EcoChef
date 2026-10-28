import 'package:flutter/material.dart';
import 'estoque-page.dart';

class CadastrarProdutoPage extends StatefulWidget {
  const CadastrarProdutoPage({super.key});

  @override
  State<CadastrarProdutoPage> createState() =>
      _CadastrarProdutoPageState();
}

class _CadastrarProdutoPageState
    extends State<CadastrarProdutoPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _estoqueMinimoController = TextEditingController();

  String? _categoria;
  String _unidade = 'kg';

  final List<String> _categorias = [
    'Grãos',
    'Hortifruti',
    'Laticínios',
    'Carnes',
    'Bebidas',
    'Congelados',
    'Outros',
  ];

  final List<String> _unidades = [
    'kg',
    'g',
    'L',
    'mL',
    'unidade',
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _estoqueMinimoController.dispose();
    super.dispose();
  }

  void _cadastrarProduto() {
    if (!_formKey.currentState!.validate()) return;

    final nome = _nomeController.text.trim();

    final estoqueMinimo = double.parse(
      _estoqueMinimoController.text
          .trim()
          .replaceAll(',', '.'),
    );

    final novoProduto = ProdutoEstoque(
      nome: nome,
      quantidade: 0,
      tipo: _categoria!,
      validade: null,
      status: estoqueMinimo > 0
          ? 'Abaixo do mínimo'
          : 'Disponível',
    );

    Navigator.pop(context, novoProduto);
  }

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF2563EB);
    const azulEscuro = Color(0xFF1E3A8A);
    const fundo = Color(0xFFF8FAFC);
    const texto = Color(0xFF1E293B);
    const secundario = Color(0xFF64748B);
    const borda = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: fundo,
        foregroundColor: azulEscuro,
        elevation: 0,
        title: const Text(
          'Cadastrar produto',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borda),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: azul,
                      size: 26,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Cadastre os dados do alimento. '
                        'A quantidade será informada '
                        'ao registrar uma entrada.',
                        style: TextStyle(
                          color: secundario,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Nome do produto *',
                style: TextStyle(
                  color: texto,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nomeController,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: _decoracao(
                  'Ex.: Arroz, Tomate, Leite...',
                  borda,
                ),
                validator: (valor) {
                  if (valor == null ||
                      valor.trim().isEmpty) {
                    return 'Informe o nome do produto.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text(
                'Categoria *',
                style: TextStyle(
                  color: texto,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _categoria,
                isExpanded: true,
                decoration: _decoracao(
                  'Selecione uma categoria',
                  borda,
                ),
                items: _categorias.map((categoria) {
                  return DropdownMenuItem<String>(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                onChanged: (valor) {
                  setState(() => _categoria = valor);
                },
                validator: (valor) {
                  if (valor == null) {
                    return 'Selecione uma categoria.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text(
                'Unidade de medida *',
                style: TextStyle(
                  color: texto,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _unidade,
                isExpanded: true,
                decoration: _decoracao(
                  'Selecione a unidade',
                  borda,
                ),
                items: _unidades.map((unidade) {
                  return DropdownMenuItem<String>(
                    value: unidade,
                    child: Text(unidade),
                  );
                }).toList(),
                onChanged: (valor) {
                  if (valor != null) {
                    setState(() => _unidade = valor);
                  }
                },
              ),
              const SizedBox(height: 20),

              const Text(
                'Estoque mínimo *',
                style: TextStyle(
                  color: texto,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _estoqueMinimoController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _decoracao(
                  'Ex.: 5',
                  borda,
                ).copyWith(
                  helperText:
                      'Quantidade mínima desejada em $_unidade.',
                ),
                validator: (valor) {
                  if (valor == null ||
                      valor.trim().isEmpty) {
                    return 'Informe o estoque mínimo.';
                  }

                  final numero = double.tryParse(
                    valor.trim().replaceAll(',', '.'),
                  );

                  if (numero == null ||
                      !numero.isFinite ||
                      numero < 0) {
                    return 'Informe um número válido, maior ou igual a zero.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _cadastrarProduto,
                  icon: const Icon(Icons.check),
                  label: const Text(
                    'Cadastrar produto',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azul,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: azulEscuro,
                    side: const BorderSide(color: borda),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracao(
    String dica,
    Color borda,
  ) {
    return InputDecoration(
      hintText: dica,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borda),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF2563EB),
          width: 1.5,
        ),
      ),
    );
  }
}