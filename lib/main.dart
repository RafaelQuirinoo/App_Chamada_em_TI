import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/auth_gate.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Impede iniciar o Supabase com credenciais de exemplo
  if (configuracaoPendente) {
    runApp(const ChamadosApp(
      home: _TelaAviso(
        icone: Icons.settings_outlined,
        titulo: 'Falta configurar o Supabase',
        mensagem: 'Abra o arquivo lib/config.dart e preencha kSupabaseUrl e '
            'kSupabaseAnonKey com os dados do seu projeto '
            '(Supabase > Project Settings > API). Depois rode o app novamente.',
      ),
    ));
    return;
  }

  try {
    await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
  } catch (e) {
    runApp(ChamadosApp(
      home: _TelaAviso(
        icone: Icons.error_outline,
        titulo: 'Não foi possível iniciar o aplicativo',
        mensagem:
            'Confira a URL e a chave em lib/config.dart.\n\nDetalhe técnico: $e',
      ),
    ));
    return;
  }

  // O AuthGate escolhe entre login e Home conforme a sessão
  runApp(const ChamadosApp(home: AuthGate()));
}

class ChamadosApp extends StatelessWidget {
  const ChamadosApp({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chamados de TI',
      debugShowCheckedModeBanner: false,
      theme: construirTema(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );
  }
}

class _TelaAviso extends StatelessWidget {
  const _TelaAviso({
    required this.icone,
    required this.titulo,
    required this.mensagem,
  });

  final IconData icone;
  final String titulo;
  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icone, size: 48, color: Cores.azul),
                  const SizedBox(height: 16),
                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    mensagem,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(height: 1.5, color: Cores.tintaSuave),
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
