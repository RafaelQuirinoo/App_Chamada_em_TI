import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/dados_service.dart';
import '../utils/erros.dart';
import '../widgets/comuns.dart';

const String _tipoOutro = 'Outro';

class MaquinaFormScreen extends StatefulWidget {
  const MaquinaFormScreen({
    super.key,
    this.maquina,
    required this.secretarias,
  });

  final Maquina? maquina;
  final List<Secretaria> secretarias;

  @override
  State<MaquinaFormScreen> createState() => _MaquinaFormScreenState();
}

class _MaquinaFormScreenState extends State<MaquinaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _registroCtrl;
  late final TextEditingController _modeloCtrl;
  late final TextEditingController _outroTipoCtrl;

  String? _tipo;
  int? _secretariaId;
  bool _salvando = false;
  bool _tentouSalvar = false;

  bool get _editando => widget.maquina != null;

  @override
  void initState() {
    super.initState();
    final maquina = widget.maquina;
    _registroCtrl = TextEditingController(text: maquina?.numeroRegistro ?? '');
    _modeloCtrl = TextEditingController(text: maquina?.modelo ?? '');
    _outroTipoCtrl = TextEditingController();
    _secretariaId = maquina?.secretariaId;
    if (maquina != null) {
      if (kTiposMaquina.contains(maquina.tipoMaquina)) {
        _tipo = maquina.tipoMaquina;
      } else {
        _tipo = _tipoOutro;
        _outroTipoCtrl.text = maquina.tipoMaquina;
      }
    }
  }

  @override
  void dispose() {
    _registroCtrl.dispose();
    _modeloCtrl.dispose();
    _outroTipoCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _tentouSalvar = true);
    final formularioOk = _formKey.currentState?.validate() ?? false;
    final tipo = _tipo;
    final secretariaId = _secretariaId;
    if (!formularioOk || tipo == null || secretariaId == null) return;

    final tipoFinal = tipo == _tipoOutro ? _outroTipoCtrl.text.trim() : tipo;
    final registro = _registroCtrl.text.trim();
    final modelo = _modeloCtrl.text.trim();

    setState(() => _salvando = true);
    try {
      final existente = widget.maquina;
      if (existente == null) {
        await MaquinasRepo.criar(
          numeroRegistro: registro,
          tipoMaquina: tipoFinal,
          modelo: modelo,
          secretariaId: secretariaId,
        );
      } else {
        await MaquinasRepo.atualizar(
          existente.id,
          numeroRegistro: registro,
          tipoMaquina: tipoFinal,
          modelo: modelo,
          secretariaId: secretariaId,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        mostrarMensagem(context, mensagemDeErro(e), erro: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final semTipo = _tentouSalvar && _tipo == null;
    final semSecretaria = _tentouSalvar && _secretariaId == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar máquina' : 'Nova máquina'),
        leading: IconButton(
          tooltip: 'Fechar',
          icon: const Icon(Icons.close),
          onPressed: _salvando ? null : () => Navigator.of(context).pop(false),
        ),
      ),
      body: ConteudoCentralizado(
        larguraMaxima: 600,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TituloDaTela(
                titulo: _editando ? 'Dados do equipamento' : 'Cadastro de equipamento',
                subtitulo: _editando
                    ? 'Altere o campo "Secretaria vinculada" para transferir o equipamento.'
                    : 'Informe tipo, modelo, nº de patrimônio e secretaria vinculada.',
              ),
              Painel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PickerField<String>(
                      rotulo: 'Tipo de máquina',
                      icone: Icons.category_outlined,
                      itens: [
                        for (final tipo in kTiposMaquina)
                          PickerItem<String>(value: tipo, titulo: tipo),
                      ],
                      valor: _tipo,
                      onChanged: (valor) => setState(() => _tipo = valor),
                      erro: semTipo ? 'Escolha o tipo.' : null,
                    ),
                    if (_tipo == _tipoOutro) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _outroTipoCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        decoration: decoracaoCampo('Qual é o tipo?',
                            icone: Icons.edit_outlined),
                        validator: (valor) =>
                            (valor == null || valor.trim().length < 2)
                                ? 'Informe o tipo da máquina.'
                                : null,
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _registroCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: decoracaoCampo(
                        'Número de registro (patrimônio)',
                        icone: Icons.tag,
                      ),
                      validator: (valor) =>
                          (valor == null || valor.trim().isEmpty)
                              ? 'Informe o número de patrimônio.'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modeloCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: decoracaoCampo(
                        'Modelo',
                        icone: Icons.memory_outlined,
                        dica: 'Ex.: Dell OptiPlex 3080',
                      ),
                      validator: (valor) =>
                          (valor == null || valor.trim().isEmpty)
                              ? 'Informe o modelo.'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    PickerField<int>(
                      rotulo: 'Secretaria vinculada',
                      icone: Icons.apartment_outlined,
                      itens: [
                        for (final s in widget.secretarias)
                          PickerItem<int>(value: s.id, titulo: s.nome),
                      ],
                      valor: _secretariaId,
                      onChanged: (valor) =>
                          setState(() => _secretariaId = valor),
                      erro: semSecretaria ? 'Escolha a secretaria.' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _salvando ? null : _salvar,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                icon: _salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_salvando ? 'Salvando…' : 'Salvar'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
