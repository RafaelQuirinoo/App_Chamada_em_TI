import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/dados_service.dart';
import '../services/ia_service.dart';
import '../theme.dart';
import '../utils/erros.dart';
import '../widgets/comuns.dart';

class AjudaScreen extends StatelessWidget {
  const AjudaScreen({super.key, required this.onAbrirChamado});

  final VoidCallback onAbrirChamado;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Colors.white,
            child: const TabBar(
              tabs: [
                Tab(
                    icon: Icon(Icons.quiz_outlined),
                    text: 'Perguntas frequentes'),
                Tab(
                    icon: Icon(Icons.smart_toy_outlined),
                    text: 'Assistente de IA'),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Cores.borda),
          Expanded(
            child: TabBarView(
              children: [
                _FaqTab(onAbrirChamado: onAbrirChamado),
                _ChatTab(onAbrirChamado: onAbrirChamado),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTab extends StatefulWidget {
  const _FaqTab({required this.onAbrirChamado});

  final VoidCallback onAbrirChamado;

  @override
  State<_FaqTab> createState() => _FaqTabState();
}

class _FaqTabState extends State<_FaqTab> with AutomaticKeepAliveClientMixin {
  List<Faq> _faqs = [];
  bool _carregando = true;
  String? _erro;
  String _busca = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await FaqsRepo.listar();
      if (mounted) setState(() => _faqs = lista);
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_erro != null) {
      return EstadoErro(mensagem: _erro!, onTentarNovamente: _carregar);
    }

    final termo = _busca.trim().toLowerCase();
    final filtradas = _faqs.where((faq) {
      if (termo.isEmpty) return true;
      return faq.pergunta.toLowerCase().contains(termo) ||
          faq.resposta.toLowerCase().contains(termo) ||
          faq.categoria.toLowerCase().contains(termo);
    }).toList();

    return ConteudoCentralizado(
      larguraMaxima: 720,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const TituloDaTela(
            titulo: 'Base de conhecimento',
            subtitulo:
                'Procedimentos de diagnóstico e resolução para falhas recorrentes. Consulte antes de abrir um chamado.',
          ),
          TextField(
            onChanged: (valor) => setState(() => _busca = valor),
            decoration: decoracaoCampo(null,
                icone: Icons.search,
                dica: 'Buscar por palavra (ex.: impressora)'),
          ),
          const SizedBox(height: 16),
          if (filtradas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: EstadoVazio(
                icone: Icons.search_off,
                titulo: 'Nada encontrado',
                mensagem:
                    'Tente outra palavra ou pergunte ao Assistente de IA.',
              ),
            )
          else
            for (final faq in filtradas)
              Painel(
                margem: const EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedAlignment: Alignment.centerLeft,
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  title: Text(
                    faq.pergunta,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, height: 1.3),
                  ),
                  subtitle: Text(
                    faq.categoria,
                    style: const TextStyle(
                        color: Cores.tintaSuave, fontSize: 12.5),
                  ),
                  children: [
                    SelectableText(
                      faq.resposta,
                      style: const TextStyle(height: 1.5, color: Cores.tinta),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 8),
          Painel(
            cor: Cores.azulClaro,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Não resolveu?',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text('A equipe de TI vai cuidar disso para você.'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: widget.onAbrirChamado,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Abrir um chamado'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const List<String> _sugestoes = [
  'Como configuro a impressora padrão na rede?',
  'Estou sem internet, o que verifico?',
  'Meu computador está muito lento',
];

class _ChatTab extends StatefulWidget {
  const _ChatTab({required this.onAbrirChamado});

  final VoidCallback onAbrirChamado;

  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> with AutomaticKeepAliveClientMixin {
  final _controlador = TextEditingController();
  final _rolagem = ScrollController();
  final _foco = FocusNode();
  final List<MensagemChat> _mensagens = [
    MensagemChat.boasVindas(
      'Olá! Sou o assistente de TI. Descreva o seu problema ou dúvida '
      '(por exemplo: "Como configuro a impressora padrão na rede?") '
      'e eu te guio passo a passo.',
    ),
  ];
  bool _aguardando = false;

  // Mantém a conversa ao alternar entre as abas
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _controlador.dispose();
    _rolagem.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _rolarParaOFim() {
    // Espera o frame atual para rolar já contando a nova mensagem
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_rolagem.hasClients) return;
      _rolagem.animateTo(
        _rolagem.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _enviar([String? textoPronto]) async {
    final texto = (textoPronto ?? _controlador.text).trim();
    // Ignora envio vazio ou enquanto a resposta anterior não chegou
    if (texto.isEmpty || _aguardando) return;

    setState(() {
      _mensagens.add(MensagemChat.usuario(texto));
      _aguardando = true;
    });
    _controlador.clear();
    _rolarParaOFim();

    try {
      final resposta = await IaService.perguntar(_mensagens);
      if (!mounted) return;
      setState(() => _mensagens.add(MensagemChat.assistente(resposta)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _mensagens.add(MensagemChat.erro(mensagemDeErro(e))));
    } finally {
      if (mounted) {
        setState(() => _aguardando = false);
        _rolarParaOFim();
        _foco.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Sugestões só aparecem antes da primeira pergunta
    final soBoasVindas = _mensagens.length == 1;
    final totalItens = _mensagens.length + (_aguardando ? 1 : 0);

    return ConteudoCentralizado(
      larguraMaxima: 720,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _rolagem,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: totalItens + 1, // +1 = rodapé com sugestões/aviso
              itemBuilder: (context, indice) {
                if (indice == totalItens) return _rodape(soBoasVindas);
                if (indice == _mensagens.length) return const _Digitando();
                return _Balao(mensagem: _mensagens[indice]);
              },
            ),
          ),
          _campoDeEnvio(),
        ],
      ),
    );
  }

  Widget _rodape(bool soBoasVindas) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (soBoasVindas)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final sugestao in _sugestoes)
                  ActionChip(
                    label: Text(sugestao),
                    onPressed: () => _enviar(sugestao),
                  ),
              ],
            ),
          if (!soBoasVindas && !_aguardando)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: widget.onAbrirChamado,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Não resolveu? Abrir um chamado'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _campoDeEnvio() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Cores.borda)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controlador,
                    focusNode: _foco,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1000,
                    buildCounter: (context,
                            {required currentLength,
                            required isFocused,
                            maxLength}) =>
                        null,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.send,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _enviar(),
                    decoration:
                        decoracaoCampo(null, dica: 'Descreva sua dúvida…'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Enviar',
                  onPressed: _aguardando ? null : _enviar,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'O assistente pode errar. Em caso de dúvida, abra um chamado.',
              style: TextStyle(color: Cores.tintaSuave, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _Digitando extends StatelessWidget {
  const _Digitando();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Cores.borda),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Pensando…', style: TextStyle(color: Cores.tintaSuave)),
          ],
        ),
      ),
    );
  }
}

class _Balao extends StatelessWidget {
  const _Balao({required this.mensagem});

  final MensagemChat mensagem;

  List<InlineSpan> _trechos(String texto) {
    final limpo = texto
        .replaceAll('`', '')
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '• ');
    final partes = limpo.split('**');
    final trechos = <InlineSpan>[];
    for (var i = 0; i < partes.length; i++) {
      if (partes[i].isEmpty) continue;
      trechos.add(TextSpan(
        text: partes[i],
        style: i.isOdd ? const TextStyle(fontWeight: FontWeight.w700) : null,
      ));
    }
    return trechos;
  }

  @override
  Widget build(BuildContext context) {
    final doUsuario = mensagem.doUsuario;
    final largura = MediaQuery.of(context).size.width;
    final larguraMaxima = largura * 0.85 > 560 ? 560.0 : largura * 0.85;

    final Color fundo;
    final Color corTexto;
    if (doUsuario) {
      fundo = Cores.azul;
      corTexto = Colors.white;
    } else if (mensagem.ehErro) {
      fundo = Cores.perigoClaro;
      corTexto = Cores.perigo;
    } else {
      fundo = Colors.white;
      corTexto = Cores.tinta;
    }

    return Align(
      alignment: doUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: larguraMaxima),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: fundo,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(doUsuario ? 16 : 4),
              bottomRight: Radius.circular(doUsuario ? 4 : 16),
            ),
            border: doUsuario ? null : Border.all(color: Cores.borda),
          ),
          child: SelectableText.rich(
            TextSpan(
              children: _trechos(mensagem.texto),
              style: TextStyle(color: corTexto, fontSize: 15, height: 1.45),
            ),
          ),
        ),
      ),
    );
  }
}
