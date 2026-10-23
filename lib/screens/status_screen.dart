import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../services/dados_service.dart';
import '../services/supabase_client.dart';
import '../theme.dart';
import '../utils/erros.dart';
import '../utils/formatos.dart';
import '../widgets/comuns.dart';

enum FiltroStatus {
  ativos('Em andamento'),
  abertos('Abertos'),
  emConserto('Conserto em andamento'),
  prontos('Pronto para retirada'),
  concluidos('Concluídos'),
  todos('Todos');

  const FiltroStatus(this.rotulo);

  final String rotulo;

  bool aceita(String status) {
    if (this == FiltroStatus.todos) return true;
    if (this == FiltroStatus.ativos) return status != StatusChamado.concluido;
    if (this == FiltroStatus.abertos) return status == StatusChamado.aberto;
    if (this == FiltroStatus.emConserto)
      return status == StatusChamado.emConserto;
    if (this == FiltroStatus.prontos) return status == StatusChamado.pronto;
    return status == StatusChamado.concluido;
  }
}

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key, required this.perfil});

  final Perfil perfil;

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final _buscaCtrl = TextEditingController();

  List<Chamado> _chamados = [];
  bool _carregando = true;
  String? _erro;
  bool _daSecretaria =
      false; // servidor: false = meus chamados | true = da minha secretaria
  FiltroStatus _filtro = FiltroStatus.ativos;
  String _busca = '';

  RealtimeChannel? _canal;
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    _carregar();
    _assinar();
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    final canal = _canal;
    if (canal != null) supabase.removeChannel(canal);
    _buscaCtrl.dispose();
    super.dispose();
  }

  void _assinar() {
    _canal = supabase
        .channel('status-chamados-${widget.perfil.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chamados',
          callback: (payload) => _agendarRecarga(),
        )
        .subscribe();
  }

  // Agrupa várias mudanças seguidas em uma única recarga (400 ms)
  void _agendarRecarga() {
    _temporizador?.cancel();
    _temporizador = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _carregar(silencioso: true);
    });
  }

  Future<void> _carregar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }
    final perfil = widget.perfil;
    // Técnico vê todos; servidor filtra por autor ou pela própria secretaria
    final verTodos = perfil.ehTecnico;
    try {
      final lista = await ChamadosRepo.listar(
        servidorId: (verTodos || _daSecretaria) ? null : perfil.id,
        secretariaId: (!verTodos && _daSecretaria) ? perfil.secretariaId : null,
      );
      if (!mounted) return;
      setState(() {
        _chamados = lista;
        _carregando = false;
        _erro = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        if (!silencioso) _erro = mensagemDeErro(e);
      });
    }
  }

  int _contar(String status) =>
      _chamados.where((c) => c.status == status).length;

  List<Chamado> get _visiveis {
    final termo = _busca.trim().toLowerCase().replaceAll('#', '');
    return _chamados.where((c) {
      if (!_filtro.aceita(c.status)) return false;
      if (termo.isEmpty) return true;
      final texto = '${c.id} ${c.descricao} ${c.maquinaTitulo} '
              '${c.maquinaRegistro ?? ''} ${c.servidorNome ?? ''} ${c.secretariaNome ?? ''}'
          .toLowerCase();
      return texto.contains(termo);
    }).toList();
  }

  Future<void> _alterarStatus(Chamado chamado) async {
    final novo = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (contextoFolha) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Chamado #${chamado.id} — alterar status',
                style: Theme.of(contextoFolha)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            for (final status in StatusChamado.todos)
              ListTile(
                leading: Icon(
                  estiloDoStatus(status).icone,
                  color: estiloDoStatus(status).texto,
                ),
                title: Text(estiloDoStatus(status).rotulo),
                trailing: status == chamado.status
                    ? const Icon(Icons.check, color: Cores.azul)
                    : null,
                onTap: () => Navigator.of(contextoFolha).pop(status),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (novo == null || novo == chamado.status) return;

    try {
      await ChamadosRepo.alterarStatus(chamado.id, novo);
      if (!mounted) return;
      mostrarMensagem(
        context,
        'Chamado #${chamado.id}: ${StatusChamado.rotulo(novo)}.',
      );
      _carregar(silencioso: true);
    } catch (e) {
      if (mounted) mostrarMensagem(context, mensagemDeErro(e), erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_erro != null) {
      return EstadoErro(mensagem: _erro!, onTentarNovamente: _carregar);
    }

    final visiveis = _visiveis;
    final ehTecnico = widget.perfil.ehTecnico;

    return ConteudoCentralizado(
      larguraMaxima: 860,
      child: RefreshIndicator(
        onRefresh: () => _carregar(silencioso: true),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: visiveis.isEmpty ? 2 : visiveis.length + 1,
          itemBuilder: (context, indice) {
            if (indice == 0) return _cabecalho();
            if (visiveis.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: EstadoVazio(
                  icone: Icons.build_circle_outlined,
                  titulo: _chamados.isEmpty
                      ? 'Nenhum chamado por aqui'
                      : 'Nenhum chamado neste filtro',
                  mensagem: _chamados.isEmpty
                      ? (ehTecnico
                          ? 'Quando um servidor abrir um chamado, ele aparece aqui na hora.'
                          : 'Quando você abrir um chamado, o andamento do conserto aparece aqui.')
                      : 'Troque o filtro ou a busca para ver outros chamados.',
                ),
              );
            }
            final chamado = visiveis[indice - 1];
            return _CartaoChamado(
              chamado: chamado,
              ehTecnico: ehTecnico,
              onAlterarStatus: () => _alterarStatus(chamado),
            );
          },
        ),
      ),
    );
  }

  Widget _cabecalho() {
    final ehTecnico = widget.perfil.ehTecnico;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TituloDaTela(
          titulo: ehTecnico ? 'Fila de chamados' : 'Acompanhamento de chamados',
          subtitulo: ehTecnico
              ? 'Atualize o status conforme a evolução do atendimento. A alteração é refletida em tempo real para o solicitante.'
              : 'Consulte o status de cada chamado: aberto, conserto em andamento, pronto para retirada ou concluído.',
        ),
        if (!ehTecnico) ...[
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<bool>(value: false, label: Text('Meus chamados')),
              ButtonSegment<bool>(value: true, label: Text('Minha secretaria')),
            ],
            selected: {_daSecretaria},
            onSelectionChanged: (selecionado) {
              setState(() => _daSecretaria = selecionado.first);
              _carregar();
            },
          ),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Expanded(
              child: _ResumoStatus(
                status: StatusChamado.aberto,
                total: _contar(StatusChamado.aberto),
                selecionado: _filtro == FiltroStatus.abertos,
                onTap: () => setState(() => _filtro = FiltroStatus.abertos),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ResumoStatus(
                status: StatusChamado.emConserto,
                total: _contar(StatusChamado.emConserto),
                selecionado: _filtro == FiltroStatus.emConserto,
                onTap: () => setState(() => _filtro = FiltroStatus.emConserto),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ResumoStatus(
                status: StatusChamado.pronto,
                total: _contar(StatusChamado.pronto),
                selecionado: _filtro == FiltroStatus.prontos,
                onTap: () => setState(() => _filtro = FiltroStatus.prontos),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _buscaCtrl,
          onChanged: (valor) => setState(() => _busca = valor),
          decoration: decoracaoCampo(
            null,
            icone: Icons.search,
            dica: 'Buscar por número, máquina, patrimônio ou problema',
            sufixo: _busca.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpar busca',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _buscaCtrl.clear();
                      setState(() => _busca = '');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filtro in FiltroStatus.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filtro.rotulo),
                    selected: _filtro == filtro,
                    onSelected: (_) => setState(() => _filtro = filtro),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _ResumoStatus extends StatelessWidget {
  const _ResumoStatus({
    required this.status,
    required this.total,
    required this.selecionado,
    required this.onTap,
  });

  final String status;
  final int total;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final estilo = estiloDoStatus(status);
    return Material(
      color: estilo.fundo,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selecionado ? estilo.texto : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(estilo.icone, size: 18, color: estilo.texto),
                  const Spacer(),
                  Text(
                    '$total',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: estilo.texto,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                estilo.rotulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: estilo.texto,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartaoChamado extends StatelessWidget {
  const _CartaoChamado({
    required this.chamado,
    required this.ehTecnico,
    required this.onAlterarStatus,
  });

  final Chamado chamado;
  final bool ehTecnico;
  final VoidCallback onAlterarStatus;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final detalhe = chamado.maquinaDetalhe;

    return Painel(
      margem: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#${chamado.id}',
                style: tema.titleSmall?.copyWith(
                  color: Cores.tintaSuave,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Flexible(child: StatusBadge(status: chamado.status)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            chamado.maquinaTitulo,
            style: tema.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (detalhe.isNotEmpty)
            Text(
              detalhe,
              style: const TextStyle(color: Cores.tintaSuave, fontSize: 13),
            ),
          const SizedBox(height: 8),
          Text(chamado.descricao, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 14),
          _FluxoStatus(status: chamado.status),
          const SizedBox(height: 12),
          Text(
            'Aberto por ${chamado.servidorNome ?? 'servidor'} · ${formatarDataHora(chamado.dataCriacao)}',
            style: const TextStyle(color: Cores.tintaSuave, fontSize: 12.5),
          ),
          Text(
            'Atualizado ${tempoRelativo(chamado.atualizadoEm)}',
            style: const TextStyle(color: Cores.tintaSuave, fontSize: 12.5),
          ),
          if (ehTecnico) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: onAlterarStatus,
                icon: const Icon(Icons.sync_alt, size: 18),
                label: const Text('Alterar status'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FluxoStatus extends StatelessWidget {
  const _FluxoStatus({required this.status});

  final String status;

  // Mesma ordem de StatusChamado.todos
  static const List<String> _rotulos = [
    'Aberto',
    'Conserto',
    'Pronto',
    'Concluído'
  ];

  @override
  Widget build(BuildContext context) {
    final etapas = StatusChamado.todos;
    final atual = etapas.indexOf(status);
    final cor = estiloDoStatus(status).texto;

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < etapas.length; i++)
              Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(right: i < etapas.length - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i <= atual ? cor : Cores.borda,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (var i = 0; i < etapas.length; i++)
              Expanded(
                child: Text(
                  _rotulos[i],
                  style: TextStyle(
                    fontSize: 11,
                    color: i == atual ? cor : Cores.tintaSuave,
                    fontWeight: i == atual ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
