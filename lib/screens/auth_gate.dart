import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/supabase_client.dart';
import '../theme.dart';
import '../utils/erros.dart';
import '../widgets/comuns.dart';
import 'home_shell.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _inscricao;
  Session? _sessao;
  Future<Perfil>? _futuroPerfil;

  @override
  void initState() {
    super.initState();
    _sessao = supabase.auth.currentSession;
    _prepararPerfil();
    _inscricao = supabase.auth.onAuthStateChange.listen((dados) {
      if (!mounted) return;
      final novaSessao = dados.session;
      // Recarrega o perfil só se o usuário mudou (ignora renovação de token)
      final mudouUsuario = novaSessao?.user.id != _sessao?.user.id;
      setState(() {
        _sessao = novaSessao;
        if (mudouUsuario) _prepararPerfil();
      });
    });
  }

  @override
  void dispose() {
    _inscricao?.cancel();
    super.dispose();
  }

  void _prepararPerfil() {
    _futuroPerfil = _sessao == null ? null : AuthService.carregarPerfil();
  }

  @override
  Widget build(BuildContext context) {
    if (_sessao == null) return const LoginScreen();

    return FutureBuilder<Perfil>(
      future: _futuroPerfil,
      builder: (context, resultado) {
        if (resultado.connectionState != ConnectionState.done) {
          return const TelaCarregando();
        }
        final perfil = resultado.data;
        if (resultado.hasError || perfil == null) {
          return _PerfilIndisponivel(
            mensagem: resultado.hasError
                ? mensagemDeErro(resultado.error!)
                : 'Não encontramos o seu perfil.',
            onTentarNovamente: () => setState(_prepararPerfil),
          );
        }
        // A key recria a Home ao trocar de usuário e descarta o estado anterior
        return HomeShell(key: ValueKey(perfil.id), perfil: perfil);
      },
    );
  }
}

class _PerfilIndisponivel extends StatelessWidget {
  const _PerfilIndisponivel({
    required this.mensagem,
    required this.onTentarNovamente,
  });

  final String mensagem;
  final VoidCallback onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off_outlined,
                      size: 48, color: Cores.tintaSuave),
                  const SizedBox(height: 12),
                  Text(
                    'Não foi possível abrir sua conta',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$mensagem\nSe o problema continuar, procure a equipe de TI.',
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Cores.tintaSuave, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onTentarNovamente,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => AuthService.sair(),
                    child: const Text('Sair'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
