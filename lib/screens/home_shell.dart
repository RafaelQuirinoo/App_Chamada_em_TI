import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/dados_service.dart';
import '../services/supabase_client.dart';
import '../theme.dart';
import 'abrir_chamado_screen.dart';
import 'ajuda_screen.dart';
import 'maquinas_screen.dart';
import 'status_screen.dart';

class _Destino {
  const _Destino({
    required this.titulo,
    required this.rotulo,
    required this.icone,
    required this.iconeAtivo,
  });

  final String titulo;
  final String rotulo;
  final IconData icone;
  final IconData iconeAtivo;
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.perfil});

  final Perfil perfil;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  // Posições das abas; Máquinas (índice 3) só existe para o técnico
  static const int _idxChamado = 0;
  static const int _idxAjuda = 1;
  static const int _idxStatus = 2;

  int _indice = 0;
  late final List<_Destino> _destinos;
  late final List<Widget> _telas;

  RealtimeChannel? _canal;
  Timer? _temporizador;
  int _abertos = 0;

  @override
  void initState() {
    super.initState();
    final perfil = widget.perfil;

    _destinos = [
      const _Destino(
        titulo: 'Abrir chamado',
        rotulo: 'Novo chamado',
        icone: Icons.add_circle_outline,
        iconeAtivo: Icons.add_circle,
      ),
      const _Destino(
        titulo: 'Ajuda e assistente',
        rotulo: 'Ajuda',
        icone: Icons.support_agent_outlined,
        iconeAtivo: Icons.support_agent,
      ),
      const _Destino(
        titulo: 'Acompanhamento',
        rotulo: 'Acompanhamento',
        icone: Icons.build_circle_outlined,
        iconeAtivo: Icons.build_circle,
      ),
      if (perfil.ehTecnico)
        const _Destino(
          titulo: 'Máquinas',
          rotulo: 'Máquinas',
          icone: Icons.computer_outlined,
          iconeAtivo: Icons.computer,
        ),
    ];

    _telas = [
      AbrirChamadoScreen(
        perfil: perfil,
        onVerAcompanhamento: () => _irPara(_idxStatus),
        onIrParaAjuda: () => _irPara(_idxAjuda),
      ),
      AjudaScreen(onAbrirChamado: () => _irPara(_idxChamado)),
      StatusScreen(perfil: perfil),
      if (perfil.ehTecnico) MaquinasScreen(perfil: perfil),
    ];

    // Só a equipe de TI recebe contagem e avisos em tempo real
    if (perfil.ehTecnico) {
      _atualizarContagem();
      _assinarChamados();
    }
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    final canal = _canal;
    if (canal != null) supabase.removeChannel(canal);
    super.dispose();
  }

  void _irPara(int indice) {
    if (indice < 0 || indice >= _telas.length) return;
    setState(() => _indice = indice);
  }

  // Escuta a tabela chamados para avisar novos chamados e atualizar o selo
  void _assinarChamados() {
    _canal = supabase
        .channel('ti-chamados-${widget.perfil.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chamados',
          callback: (payload) {
            if (!mounted) return;
            if (payload.eventType == PostgresChangeEvent.insert) {
              _avisarNovoChamado(payload.newRecord);
            }
            _agendarContagem();
          },
        )
        .subscribe();
  }

  void _avisarNovoChamado(Map<String, dynamic> registro) {
    if (registro['servidor_id'] == widget.perfil.id)
      return; // foi o próprio técnico
    final aviso = ScaffoldMessenger.of(context);
    aviso.hideCurrentSnackBar();
    aviso.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Cores.azulNoite,
        duration: const Duration(seconds: 8),
        content: Text(
          'Novo chamado #${registro['id']}: ${registro['descricao_problema']}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () => _irPara(_idxStatus),
        ),
      ),
    );
  }

  // Evita consultar a contagem a cada evento (500 ms)
  void _agendarContagem() {
    _temporizador?.cancel();
    _temporizador =
        Timer(const Duration(milliseconds: 500), _atualizarContagem);
  }

  Future<void> _atualizarContagem() async {
    try {
      final total = await ChamadosRepo.contarAbertos();
      if (mounted) setState(() => _abertos = total);
    } catch (_) {
      // O selo é só um complemento; falhas aqui não devem incomodar.
    }
  }

  void _abrirConta() {
    final perfil = widget.perfil;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (contextoFolha) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                perfil.nome,
                style: Theme.of(contextoFolha)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text('Matrícula ${perfil.matricula}'),
              Text(perfil.secretariaNome ?? 'Sem secretaria vinculada'),
              const SizedBox(height: 4),
              Text(
                perfil.ehTecnico ? 'Perfil: técnico de TI' : 'Perfil: servidor',
                style: const TextStyle(color: Cores.tintaSuave),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(contextoFolha).pop();
                  AuthService.sair();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sair da conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _icone(int indice, {bool ativo = false}) {
    final destino = _destinos[indice];
    final icone = Icon(ativo ? destino.iconeAtivo : destino.icone);
    final mostrarSelo =
        indice == _idxStatus && widget.perfil.ehTecnico && _abertos > 0;
    if (mostrarSelo) {
      return Badge(label: Text('$_abertos'), child: icone);
    }
    return icone;
  }

  @override
  Widget build(BuildContext context) {
    final perfil = widget.perfil;
    // A partir de 840 px usa menu lateral no lugar da barra inferior
    final telaLarga = MediaQuery.of(context).size.width >= 840;
    // IndexedStack preserva o estado de cada aba ao alternar
    final corpo = IndexedStack(index: _indice, children: _telas);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _destinos[_indice].titulo,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (perfil.ehTecnico)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Cores.laranjaClaro,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Equipe de TI',
                style: TextStyle(
                  color: Cores.laranjaEscuro,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Minha conta',
            onPressed: _abrirConta,
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Cores.laranjaClaro,
              child: Text(
                perfil.iniciais,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Cores.laranjaEscuro,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(3),
          child: Divider(height: 3, thickness: 3, color: Cores.laranja),
        ),
      ),
      body: telaLarga
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _indice,
                  onDestinationSelected: (i) => setState(() => _indice = i),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Colors.white,
                  destinations: [
                    for (var i = 0; i < _destinos.length; i++)
                      NavigationRailDestination(
                        icon: _icone(i),
                        selectedIcon: _icone(i, ativo: true),
                        label: Text(_destinos[i].rotulo),
                      ),
                  ],
                ),
                const VerticalDivider(
                    width: 1, thickness: 1, color: Cores.borda),
                Expanded(child: corpo),
              ],
            )
          : corpo,
      bottomNavigationBar: telaLarga
          ? null
          : NavigationBar(
              selectedIndex: _indice,
              onDestinationSelected: (i) => setState(() => _indice = i),
              destinations: [
                for (var i = 0; i < _destinos.length; i++)
                  NavigationDestination(
                    icon: _icone(i),
                    selectedIcon: _icone(i, ativo: true),
                    label: _destinos[i].rotulo,
                  ),
              ],
            ),
    );
  }
}
