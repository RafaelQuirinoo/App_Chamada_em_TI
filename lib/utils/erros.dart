import 'package:supabase_flutter/supabase_flutter.dart';

class AppException implements Exception {
  const AppException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

// Detecta falha de conexão pelo texto, pois a exceção muda entre mobile e web
bool _pareceErroDeRede(String texto) {
  final t = texto.toLowerCase();
  return t.contains('socketexception') ||
      t.contains('failed host lookup') ||
      t.contains('clientexception') ||
      t.contains('xmlhttprequest') ||
      t.contains('network') ||
      t.contains('timeout') ||
      t.contains('connection');
}

const String _msgSemConexao =
    'Sem conexão com o servidor. Verifique sua internet e tente novamente.';

String mensagemDeErro(Object erro) {
  if (erro is AppException) return erro.mensagem;

  if (erro is FunctionException) {
    final detalhes = erro.details;
    if (detalhes is Map && detalhes['erro'] is String) {
      return detalhes['erro'] as String;
    }
    if (erro.status == 401) {
      return 'Sua sessão expirou. Saia e entre novamente.';
    }
    if (erro.status == 404) {
      return 'Este recurso ainda não foi publicado no Supabase. Avise a equipe de TI.';
    }
    return 'O serviço não respondeu como esperado (código ${erro.status}). Tente novamente.';
  }

  if (erro is AuthException) {
    final msg = erro.message.toLowerCase();
    if (_pareceErroDeRede(msg)) return _msgSemConexao;
    if (msg.contains('invalid login credentials')) {
      return 'Matrícula ou senha incorretos.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Muitas tentativas. Aguarde alguns minutos e tente de novo.';
    }
    return 'Não foi possível entrar: ${erro.message}';
  }

  if (erro is PostgrestException) {
    // 23505 duplicado | 23503 vínculo com outros dados | 42501 sem permissão (RLS)
    // PGRST116 = nenhum registro encontrado
    final codigo = erro.code;
    if (codigo == '23505') {
      return 'Já existe um registro com esse número de patrimônio.';
    }
    if (codigo == '23503') {
      return 'Esse registro está ligado a outros dados e não pôde ser alterado.';
    }
    if (codigo == '42501') {
      return 'Você não tem permissão para fazer isso.';
    }
    if (codigo == 'PGRST116') {
      return 'Registro não encontrado.';
    }
    if (_pareceErroDeRede(erro.message)) return _msgSemConexao;
    return 'Erro ao acessar os dados: ${erro.message}';
  }

  if (_pareceErroDeRede(erro.toString())) return _msgSemConexao;
  return 'Ocorreu um erro inesperado. Tente novamente.';
}
