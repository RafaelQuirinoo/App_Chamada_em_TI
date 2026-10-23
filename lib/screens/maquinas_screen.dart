import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/dados_service.dart';
import '../theme.dart';
import '../utils/erros.dart';
import '../widgets/comuns.dart';
import 'maquina_form_screen.dart';

enum _AcaoMaquina { editar, transferir, excluir }

class MaquinasScreen extends StatefulWidget {
  const MaquinasScreen({super.key, required this.perfil});

  final Perfil perfil;

  @override
  State<MaquinasScreen> createState() => _MaquinasScreenState();
}

class _MaquinasScreenState extends State<MaquinasScreen> {
  final _buscaCtrl = TextEditingController();

  List<Maquina> _maquinas = [];
  List<Secretaria> _secretarias = [];
  bool _carregando = true;
  String? _erro;
  String _busca = '';
  String? _filtroTipo;
  int? _filtroSecretaria;

  @override
  void initState() {
    super.initState();
    // Servidor não usa esta tela, então não consulta
    if (widget.perfil.ehTecnico) _carregar();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  // silencioso = recarrega sem trocar a tela por indicador de carregamento
  Future<void> _carregar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }
    try {
      final maquinas = await MaquinasRepo.listar();
      final secretarias = await SecretariasRepo.listar();
      if (!mounted) return;
      setState(() {
        _maquinas = maquinas;
        _secretarias = secretarias;
        _erro = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (silencioso) {
        mostrarMensagem(context, mensagemDeErro(e), erro: true);
      } else {
        setState(() => _erro = mensagemDeErro(e));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<String> get _tiposPresentes {
    final tipos = _maquinas.map((m) => m.tipoMaquina).toSet().toList();
    tipos.sort();
    return tipos;
  }

  List<Maquina> get _filtradas {
    final termo = _busca.trim().toLowerCase();
    return _maquinas.where((m) {
      if (_filtroTipo != null && m.tipoMaquina != _filtroTipo) return false;
      if (_filtroSecretaria != null && m.secretariaId != _filtroSecretaria) {
        return false;
      }
      if (termo.isEmpty) return true;
      return m.numeroRegistro.toLowerCase().contains(termo) ||
          m.modelo.toLowerCase().contains(termo) ||
          m.tipoMaquina.toLowerCase().contains(termo) ||
          (m.secretariaNome ?? '').toLowerCase().contains(termo);
    }).toList();
  }

  Future<void> _abrirFormulario({Maquina? maquina}) async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) =>
            MaquinaFormScreen(maquina: maquina, secretarias: _secretarias),
      ),
    );
    if (salvou == true && mounted) {
      await _carregar(silencioso: true);
      if (mounted) {
        mostrarMensagem(
          context,
          maquina == null ? 'Máquina cadastrada.' : 'Máquina atualizada.',
        );
      }
    }
  }

  Future<void> _transferir(Maquina maquina) async {
    final destino = await escolherItem<int>(
      context,
      titulo: 'Transferir para qual secretaria?',
      itens: [
        for (final s in _secretarias)
          PickerItem<int>(value: s.id, titulo: s.nome),
      ],
      valor: maquina.secretariaId,
    );
    if (destino == null || destino == maquina.secretariaId) return;
    try {
      await MaquinasRepo.transferir(maquina.id, destino);
      if (!mounted) return;
      await _carregar(silencioso: true);
      if (mounted) {
        mostrarMensagem(
            context, 'Máquina ${maquina.numeroRegistro} transferida.');
      }
    } catch (e) {
      if (mounted) mostrarMensagem(context, mensagemDeErro(e), erro: true);
    }
  }

  Future<void> _excluir(Maquina maquina) async {
    final confirmou = await pedirConfirmacao(
      context,
      titulo: 'Excluir máquina?',
      mensagem: '${maquina.descricao} (patrimônio ${maquina.numeroRegistro}) '
          'será removida do sistema. Os chamados antigos ligados a ela são '
          'mantidos, mas sem a identificação da máquina.',
      textoConfirmar: 'Excluir',
      perigo: true,
    );
    if (!confirmou) return;
    try {
      await MaquinasRepo.excluir(maquina.id);
      if (!mounted) return;
      await _carregar(silencioso: true);
      if (mounted) mostrarMensagem(context, 'Máquina excluída.');
    } catch (e) {
      if (mounted) mostrarMensagem(context, mensagemDeErro(e), erro: true);
    }
  }

  Future<void> _aoEscolherAcao(Maquina maquina, _AcaoMaquina acao) async {
    switch (acao) {
      case _AcaoMaquina.editar:
        await _abrirFormulario(maquina: maquina);
        break;
      case _AcaoMaquina.transferir:
        await _transferir(maquina);
        break;
      case _AcaoMaquina.excluir:
        await _excluir(maquina);
        break;
    }
  }

  Future<void> _escolherFiltroTipo() async {
    final escolhido = await escolherItem<String>(
      context,
      titulo: 'Filtrar por tipo',
      itens: [
        // '' = sem filtro
        const PickerItem<String>(value: '', titulo: 'Todos os tipos'),
        for (final tipo in _tiposPresentes)
          PickerItem<String>(value: tipo, titulo: tipo),
      ],
      valor: _filtroTipo ?? '',
    );
    if (escolhido != null && mounted) {
      setState(() => _filtroTipo = escolhido.isEmpty ? null : escolhido);
    }
  }

  Future<void> _escolherFiltroSecretaria() async {
    final escolhido = await escolherItem<int>(
      context,
      titulo: 'Filtrar por secretaria',
      itens: [
        // 0 = sem filtro
        const PickerItem<int>(value: 0, titulo: 'Todas as secretarias'),
        for (final s in _secretarias)
          PickerItem<int>(value: s.id, titulo: s.nome),
      ],
      valor: _filtroSecretaria ?? 0,
    );
    if (escolhido != null && mounted) {
      setState(() => _filtroSecretaria = escolhido == 0 ? null : escolhido);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.perfil.ehTecnico) {
      return const EstadoVazio(
        icone: Icons.lock_outline,
        titulo: 'Acesso restrito',
        mensagem: 'Esta tela é exclusiva da equipe de TI.',
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            (_carregando || _erro != null) ? null : () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nova máquina'),
      ),
      body: _corpo(),
    );
  }

  Widget _corpo() {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_erro != null) {
      return EstadoErro(mensagem: _erro!, onTentarNovamente: _carregar);
    }

    final filtradas = _filtradas;
    return ConteudoCentralizado(
      child: RefreshIndicator(
        onRefresh: () => _carregar(silencioso: true),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          // +1 do cabeçalho; sem resultados, mostra cabeçalho + aviso
          itemCount: filtradas.isEmpty ? 2 : filtradas.length + 1,
          itemBuilder: (context, indice) {
            if (indice == 0) return _cabecalho(filtradas.length);
            if (filtradas.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: EstadoVazio(
                  icone: Icons.inventory_2_outlined,
                  titulo: _maquinas.isEmpty
                      ? 'Nenhuma máquina cadastrada'
                      : 'Nenhuma máquina encontrada',
                  mensagem: _maquinas.isEmpty
                      ? 'Use o botão "Nova máquina" para cadastrar a primeira.'
                      : 'Ajuste a busca ou os filtros.',
                ),
              );
            }
            final maquina = filtradas[indice - 1];
            return _CartaoMaquina(
              maquina: maquina,
              onAcao: (acao) => _aoEscolherAcao(maquina, acao),
            );
          },
        ),
      ),
    );
  }

  Widget _cabecalho(int quantidade) {
    String? nomeSecretariaFiltro;
    for (final s in _secretarias) {
      if (s.id == _filtroSecretaria) nomeSecretariaFiltro = s.nome;
    }
    final rotuloQuantidade = quantidade == 1 ? 'máquina' : 'máquinas';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TituloDaTela(
          titulo: 'Inventário de ativos de TI',
          subtitulo:
              'Registro, consulta, edição, transferência e baixa de equipamentos por patrimônio e secretaria.',
        ),
        TextField(
          controller: _buscaCtrl,
          onChanged: (valor) => setState(() => _busca = valor),
          decoration: decoracaoCampo(
            null,
            icone: Icons.search,
            dica: 'Buscar por patrimônio, modelo ou secretaria',
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ActionChip(
              avatar: const Icon(Icons.category_outlined, size: 18),
              label: Text(_filtroTipo ?? 'Todos os tipos'),
              onPressed: _escolherFiltroTipo,
            ),
            ActionChip(
              avatar: const Icon(Icons.apartment_outlined, size: 18),
              label: Text(nomeSecretariaFiltro ?? 'Todas as secretarias'),
              onPressed: _escolherFiltroSecretaria,
            ),
            if (_filtroTipo != null || _filtroSecretaria != null)
              TextButton(
                onPressed: () => setState(() {
                  _filtroTipo = null;
                  _filtroSecretaria = null;
                }),
                child: const Text('Limpar filtros'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '$quantidade $rotuloQuantidade',
          style: const TextStyle(
              color: Cores.tintaSuave, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _CartaoMaquina extends StatelessWidget {
  const _CartaoMaquina({required this.maquina, required this.onAcao});

  final Maquina maquina;
  final ValueChanged<_AcaoMaquina> onAcao;

  PopupMenuItem<_AcaoMaquina> _item(
      _AcaoMaquina valor, IconData icone, String texto,
      {Color? cor}) {
    return PopupMenuItem<_AcaoMaquina>(
      value: valor,
      child: Row(
        children: [
          Icon(icone, size: 20, color: cor),
          const SizedBox(width: 12),
          Text(texto, style: TextStyle(color: cor)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Painel(
      margem: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Cores.azulClaro,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconeDoTipo(maquina.tipoMaquina), color: Cores.azul),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  maquina.modelo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${maquina.tipoMaquina} · Patrimônio ${maquina.numeroRegistro}',
                  style: const TextStyle(color: Cores.tinta),
                ),
                Text(
                  maquina.secretariaNome ?? '—',
                  style: const TextStyle(color: Cores.tintaSuave, fontSize: 13),
                ),
              ],
            ),
          ),
          PopupMenuButton<_AcaoMaquina>(
            tooltip: 'Ações',
            onSelected: onAcao,
            itemBuilder: (context) => [
              _item(_AcaoMaquina.editar, Icons.edit_outlined, 'Editar'),
              _item(_AcaoMaquina.transferir, Icons.swap_horiz,
                  'Transferir de secretaria'),
              _item(_AcaoMaquina.excluir, Icons.delete_outline, 'Excluir',
                  cor: Cores.perigo),
            ],
          ),
        ],
      ),
    );
  }
}
