import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/dados_service.dart';
import '../theme.dart';
import '../utils/erros.dart';
import '../widgets/comuns.dart';

const List<String> kProblemasComuns = [
  'Sem internet',
  'Não liga',
  'Impressora não responde',
  'Computador lento ou travando',
  'Tela azul ou reinicia sozinho',
  'Monitor sem imagem',
  'Teclado ou mouse não funciona',
  'Sem acesso a sistema ou e-mail',
  'Outro',
];

const String _problemaOutro = 'Outro';

class AbrirChamadoScreen extends StatefulWidget {
  const AbrirChamadoScreen({
    super.key,
    required this.perfil,
    required this.onVerAcompanhamento,
    required this.onIrParaAjuda,
  });

  final Perfil perfil;
  final VoidCallback onVerAcompanhamento;
  final VoidCallback onIrParaAjuda;

  @override
  State<AbrirChamadoScreen> createState() => _AbrirChamadoScreenState();
}

class _AbrirChamadoScreenState extends State<AbrirChamadoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _outroCtrl = TextEditingController();
  final _maquinaLivreCtrl = TextEditingController();

  List<Secretaria> _secretarias = [];
  List<Maquina> _maquinas = [];
  int? _secretariaId;
  int? _maquinaId;
  bool _maquinaNaoListada = false;
  String? _problema;

  bool _carregando = true;
  bool _carregandoMaquinas = false;
  bool _enviando = false;
  bool _tentouEnviar = false;
  String? _erroCarga;
  int _contadorCarga = 0;

  @override
  void initState() {
    super.initState();
    _secretariaId = widget.perfil.secretariaId;
    _carregarInicial();
  }

  @override
  void dispose() {
    _outroCtrl.dispose();
    _maquinaLivreCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarInicial() async {
    setState(() {
      _carregando = true;
      _erroCarga = null;
    });
    try {
      final secretarias = await SecretariasRepo.listar();
      if (!mounted) return;
      setState(() => _secretarias = secretarias);
      await _carregarMaquinas();
    } catch (e) {
      if (mounted) setState(() => _erroCarga = mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _carregarMaquinas() async {
    final secretariaId = _secretariaId;
    final numero = ++_contadorCarga; // descarta respostas de buscas antigas
    if (secretariaId == null) {
      setState(() {
        _maquinas = [];
        _carregandoMaquinas = false;
      });
      return;
    }
    setState(() => _carregandoMaquinas = true);
    try {
      final lista = await MaquinasRepo.listar(secretariaId: secretariaId);
      if (!mounted || numero != _contadorCarga) return;
      setState(() => _maquinas = lista);
    } catch (e) {
      if (mounted && numero == _contadorCarga) {
        mostrarMensagem(context, mensagemDeErro(e), erro: true);
      }
    } finally {
      if (mounted && numero == _contadorCarga) {
        setState(() => _carregandoMaquinas = false);
      }
    }
  }

  void _aoEscolherSecretaria(int id) {
    setState(() {
      _secretariaId = id;
      _maquinaId = null;
      _maquinas = [];
    });
    _carregarMaquinas();
  }

  void _limparFormulario() {
    _outroCtrl.clear();
    _maquinaLivreCtrl.clear();
    setState(() {
      _problema = null;
      _maquinaId = null;
      _maquinaNaoListada = false;
      _tentouEnviar = false;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _enviar() async {
    setState(() => _tentouEnviar = true);

    final formularioOk = _formKey.currentState?.validate() ?? false;
    final secretariaId = _secretariaId;
    final problema = _problema;
    // Exige uma máquina da lista ou a identificação digitada quando ela não está cadastrada
    final maquinaOk = _maquinaNaoListada || _maquinaId != null;
    if (!formularioOk ||
        secretariaId == null ||
        problema == null ||
        !maquinaOk) {
      return;
    }

    // Texto final do chamado; máquina não listada vai identificada no início
    var descricao = problema == _problemaOutro
        ? 'Outro: ${_outroCtrl.text.trim()}'
        : problema;
    if (_maquinaNaoListada) {
      descricao =
          '[Máquina não cadastrada: ${_maquinaLivreCtrl.text.trim()}] $descricao';
    }

    setState(() => _enviando = true);
    try {
      final protocolo = await ChamadosRepo.abrir(
        servidorId: widget.perfil.id,
        maquinaId: _maquinaNaoListada ? null : _maquinaId,
        secretariaId: secretariaId,
        descricao: descricao,
      );
      if (!mounted) return;
      _limparFormulario();
      await _mostrarConfirmacao(protocolo);
    } catch (e) {
      if (mounted) mostrarMensagem(context, mensagemDeErro(e), erro: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _mostrarConfirmacao(int protocolo) async {
    final acompanhar = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Cores.sucesso, size: 40),
        title: Text('Chamado #$protocolo enviado'),
        content: const Text(
          'A equipe de TI foi notificada. Você pode acompanhar o andamento '
          'na aba Acompanhamento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(false),
            child: const Text('Abrir outro'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(true),
            child: const Text('Acompanhar'),
          ),
        ],
      ),
    );
    if (acompanhar == true) widget.onVerAcompanhamento();
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_erroCarga != null) {
      return EstadoErro(
          mensagem: _erroCarga!, onTentarNovamente: _carregarInicial);
    }

    final semSecretaria = _tentouEnviar && _secretariaId == null;
    final semMaquina =
        _tentouEnviar && !_maquinaNaoListada && _maquinaId == null;
    final semProblema = _tentouEnviar && _problema == null;

    return ConteudoCentralizado(
      larguraMaxima: 720,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const TituloDaTela(
              titulo: 'Abertura de chamado',
              subtitulo:
                  'Informe a secretaria, o equipamento (patrimônio) e a categoria da falha. A equipe de TI é notificada no envio.',
            ),
            _DicaAjuda(onIrParaAjuda: widget.onIrParaAjuda),
            const SizedBox(height: 16),
            Painel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PickerField<int>(
                    rotulo: 'Secretaria',
                    icone: Icons.apartment_outlined,
                    itens: [
                      for (final s in _secretarias)
                        PickerItem<int>(value: s.id, titulo: s.nome),
                    ],
                    valor: _secretariaId,
                    onChanged: _aoEscolherSecretaria,
                    erro: semSecretaria ? 'Escolha a secretaria.' : null,
                    dica: 'Onde a máquina está localizada',
                  ),
                  const SizedBox(height: 16),
                  if (!_maquinaNaoListada)
                    PickerField<int>(
                      rotulo: 'Máquina (patrimônio)',
                      icone: Icons.computer_outlined,
                      itens: [
                        for (final m in _maquinas)
                          PickerItem<int>(
                            value: m.id,
                            titulo: m.descricao,
                            subtitulo: 'Patrimônio ${m.numeroRegistro}',
                          ),
                      ],
                      valor: _maquinaId,
                      onChanged: (id) => setState(() => _maquinaId = id),
                      habilitado: _secretariaId != null && !_carregandoMaquinas,
                      erro:
                          semMaquina ? 'Escolha a máquina com defeito.' : null,
                      dica: _carregandoMaquinas
                          ? 'Carregando máquinas…'
                          : (_secretariaId == null
                              ? 'Escolha a secretaria primeiro'
                              : null),
                      textoVazio:
                          'Nenhuma máquina cadastrada nesta secretaria. Marque "Minha máquina não está na lista".',
                    )
                  else
                    TextFormField(
                      controller: _maquinaLivreCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: decoracaoCampo(
                        'Nº de patrimônio ou identificação',
                        icone: Icons.tag,
                        dica: 'Ex.: etiqueta no gabinete, sala, modelo…',
                      ),
                      validator: (valor) => (valor == null ||
                              valor.trim().length < 2)
                          ? 'Informe o patrimônio ou como identificar a máquina.'
                          : null,
                    ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Minha máquina não está na lista'),
                    value: _maquinaNaoListada,
                    onChanged: (valor) => setState(() {
                      _maquinaNaoListada = valor;
                      _maquinaId = null;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Painel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qual é o problema?',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final opcao in kProblemasComuns)
                        ChoiceChip(
                          label: Text(opcao),
                          selected: _problema == opcao,
                          onSelected: (_) => setState(() => _problema = opcao),
                        ),
                    ],
                  ),
                  if (semProblema)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Escolha uma das opções.',
                        style: TextStyle(color: Cores.perigo, fontSize: 12.5),
                      ),
                    ),
                  if (_problema == _problemaOutro) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _outroCtrl,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: decoracaoCampo(
                        'Descreva o problema',
                        dica: 'Explique com detalhes para o técnico entender.',
                      ),
                      validator: (valor) =>
                          (valor == null || valor.trim().length < 10)
                              ? 'Descreva com pelo menos 10 caracteres.'
                              : null,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _enviando ? null : _enviar,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              icon: _enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_enviando ? 'Enviando…' : 'Enviar chamado'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DicaAjuda extends StatelessWidget {
  const _DicaAjuda({required this.onIrParaAjuda});

  final VoidCallback onIrParaAjuda;

  @override
  Widget build(BuildContext context) {
    return Painel(
      cor: Cores.azulClaro,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Cores.azul),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Muitos problemas se resolvem em poucos minutos pela Central de Ajuda.',
              style: TextStyle(height: 1.35),
            ),
          ),
          TextButton(onPressed: onIrParaAjuda, child: const Text('Ver ajuda')),
        ],
      ),
    );
  }
}
