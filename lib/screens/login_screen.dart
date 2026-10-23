import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../utils/erros.dart';
import '../utils/formatos.dart';
import '../widgets/comuns.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formLogin = GlobalKey<FormState>();
  final _formCadastro = GlobalKey<FormState>();
  final _matriculaCtrl = TextEditingController();
  final _senhaLoginCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _senhaCadastroCtrl = TextEditingController();
  final _confirmaCtrl = TextEditingController();

  bool _modoCadastro = false;
  bool _ocultarSenha = true;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _matriculaCtrl.dispose();
    _senhaLoginCtrl.dispose();
    _cpfCtrl.dispose();
    _senhaCadastroCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  void _trocarModo(bool cadastro) {
    setState(() {
      _modoCadastro = cadastro;
      _erro = null;
    });
  }

  Future<void> _entrar() async {
    final formulario = _formLogin.currentState;
    if (formulario == null || !formulario.validate()) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await AuthService.entrar(
        matricula: _matriculaCtrl.text,
        senha: _senhaLoginCtrl.text,
      );
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _cadastrar() async {
    final formulario = _formCadastro.currentState;
    if (formulario == null || !formulario.validate()) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final resultado = await AuthService.cadastrar(
        cpf: _cpfCtrl.text,
        senha: _senhaCadastroCtrl.text,
      );
      if (!mounted) return;

      final vinculo =
          resultado.secretaria == null ? '' : ' (${resultado.secretaria})';
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (contextoDialogo) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Cores.sucesso, size: 40),
          title: const Text('Cadastro concluído!'),
          content: Text(
            'Olá, ${resultado.nome}.\n\n'
            'Seu CPF foi vinculado à matrícula ${resultado.matricula}$vinculo.\n\n'
            'Nos próximos acessos, entre usando a matrícula e a senha.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(contextoDialogo).pop(),
              child: const Text('Entrar no sistema'),
            ),
          ],
        ),
      );
      if (!mounted) return;

      // Após o cadastro, entra direto com a matrícula devolvida pela função
      await AuthService.entrar(
        matricula: resultado.matricula,
        senha: _senhaCadastroCtrl.text,
      );
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.azul,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Cabecalho(),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<bool>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment<bool>(
                                value: false, label: Text('Entrar')),
                            ButtonSegment<bool>(
                                value: true, label: Text('Primeiro acesso')),
                          ],
                          selected: {_modoCadastro},
                          onSelectionChanged: _carregando
                              ? null
                              : (selecionado) => _trocarModo(selecionado.first),
                        ),
                        const SizedBox(height: 20),
                        if (_erro != null) _Aviso(mensagem: _erro!),
                        if (_modoCadastro)
                          _formularioCadastro()
                        else
                          _formularioLogin(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formularioLogin() {
    return Form(
      key: _formLogin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _matriculaCtrl,
            enabled: !_carregando,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
            decoration:
                decoracaoCampo('Matrícula', icone: Icons.badge_outlined),
            validator: (valor) =>
                (valor == null || normalizarMatricula(valor).isEmpty)
                    ? 'Informe a sua matrícula.'
                    : null,
          ),
          const SizedBox(height: 14),
          _campoSenha(
            controller: _senhaLoginCtrl,
            rotulo: 'Senha',
            acao: TextInputAction.done,
            aoEnviar: _entrar,
            validator: (valor) => (valor == null || valor.isEmpty)
                ? 'Informe a sua senha.'
                : null,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _carregando ? null : _entrar,
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: _carregando ? const _Girando() : const Text('Entrar'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _carregando ? null : () => _trocarModo(true),
            child: const Text('Primeiro acesso? Cadastre-se'),
          ),
        ],
      ),
    );
  }

  Widget _formularioCadastro() {
    return Form(
      key: _formCadastro,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Informe seu CPF e crie uma senha. '
            'Nos próximos acessos você entra só com a matrícula e a senha.',
            style: TextStyle(color: Cores.tintaSuave, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cpfCtrl,
            enabled: !_carregando,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [CpfInputFormatter()],
            decoration: decoracaoCampo('CPF',
                icone: Icons.badge_outlined, dica: '000.000.000-00'),
            validator: (valor) => cpfValido(valor ?? '')
                ? null
                : 'CPF inválido. Confira os 11 números.',
          ),
          const SizedBox(height: 14),
          _campoSenha(
            controller: _senhaCadastroCtrl,
            rotulo: 'Crie uma senha',
            validator: (valor) => (valor == null || valor.length < 6)
                ? 'Use pelo menos 6 caracteres.'
                : null,
          ),
          const SizedBox(height: 14),
          _campoSenha(
            controller: _confirmaCtrl,
            rotulo: 'Repita a senha',
            acao: TextInputAction.done,
            aoEnviar: _cadastrar,
            validator: (valor) => valor != _senhaCadastroCtrl.text
                ? 'As senhas não são iguais.'
                : null,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _carregando ? null : _cadastrar,
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: _carregando
                ? const _Girando()
                : const Text('Cadastrar e entrar'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _carregando ? null : () => _trocarModo(false),
            child: const Text('Já tenho cadastro — Entrar'),
          ),
        ],
      ),
    );
  }

  Widget _campoSenha({
    required TextEditingController controller,
    required String rotulo,
    required String? Function(String?) validator,
    TextInputAction acao = TextInputAction.next,
    VoidCallback? aoEnviar,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_carregando,
      obscureText: _ocultarSenha,
      textInputAction: acao,
      onFieldSubmitted: (_) => aoEnviar?.call(),
      decoration: decoracaoCampo(
        rotulo,
        icone: Icons.lock_outline,
        sufixo: IconButton(
          tooltip: _ocultarSenha ? 'Mostrar senha' : 'Ocultar senha',
          icon: Icon(_ocultarSenha ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
        ),
      ),
      validator: validator,
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Cores.laranja,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.support_agent, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text(
          'Chamados de TI',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Suporte de informática para os servidores do município',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Cores.perigoClaro,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Cores.perigoBorda),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Cores.perigo, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensagem,
              style: const TextStyle(color: Cores.perigo, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _Girando extends StatelessWidget {
  const _Girando();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
    );
  }
}
