import '../utils/erros.dart';
import 'supabase_client.dart';

class MensagemChat {
  const MensagemChat._(
      this.texto, this.doUsuario, this.ehErro, this.ehBoasVindas);

  factory MensagemChat.usuario(String texto) =>
      MensagemChat._(texto, true, false, false);

  factory MensagemChat.assistente(String texto) =>
      MensagemChat._(texto, false, false, false);

  factory MensagemChat.boasVindas(String texto) =>
      MensagemChat._(texto, false, false, true);

  factory MensagemChat.erro(String texto) =>
      MensagemChat._(texto, false, true, false);

  final String texto;
  final bool doUsuario;
  final bool ehErro;
  final bool ehBoasVindas;
}

class IaService {
  IaService._();

  static Future<String> perguntar(List<MensagemChat> historico) async {
    // Envia só a conversa real, sem a mensagem de boas-vindas nem os erros
    final mensagens = historico
        .where((m) => !m.ehErro && !m.ehBoasVindas)
        .map((m) => {
              'role': m.doUsuario ? 'user' : 'assistant',
              'content': m.texto,
            })
        .toList();

    // A chave da IA fica na função do servidor; o app não a conhece
    final resposta = await supabase.functions.invoke(
      'assistente-ia',
      body: {'mensagens': mensagens},
    );
    final dados = resposta.data;
    if (dados is Map && dados['resposta'] is String) {
      return dados['resposta'] as String;
    }
    if (dados is Map && dados['erro'] is String) {
      throw AppException(dados['erro'] as String);
    }
    throw const AppException(
        'O assistente não conseguiu responder agora. Tente novamente.');
  }
}
