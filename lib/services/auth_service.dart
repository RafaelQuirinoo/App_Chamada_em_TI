import '../models/models.dart';
import '../utils/erros.dart';
import '../utils/formatos.dart';
import 'supabase_client.dart';

class CadastroResultado {
  const CadastroResultado({
    required this.matricula,
    required this.nome,
    this.secretaria,
  });

  final String matricula;
  final String nome;
  final String? secretaria;
}

class AuthService {
  AuthService._();

  static Future<void> entrar({
    required String matricula,
    required String senha,
  }) async {
    await supabase.auth.signInWithPassword(
      email: emailDaMatricula(matricula),
      password: senha,
    );
  }

  static Future<CadastroResultado> cadastrar({
    required String cpf,
    required String senha,
  }) async {
    final resposta = await supabase.functions.invoke(
      'cadastro-servidor',
      body: {'cpf': somenteDigitos(cpf), 'senha': senha},
    );
    final dados = resposta.data;
    // A função responde {ok: true, ...} ou {erro: "mensagem"}
    if (dados is Map && dados['ok'] == true) {
      return CadastroResultado(
        matricula: dados['matricula'] as String,
        nome: dados['nome'] as String,
        secretaria: dados['secretaria'] as String?,
      );
    }
    if (dados is Map && dados['erro'] is String) {
      throw AppException(dados['erro'] as String);
    }
    throw const AppException(
        'Não foi possível concluir o cadastro. Tente novamente.');
  }

  static Future<void> sair() => supabase.auth.signOut();

  static Future<Perfil> carregarPerfil() async {
    final usuario = supabase.auth.currentUser;
    if (usuario == null) {
      throw const AppException('Sessão não encontrada. Entre novamente.');
    }
    // Traz também o nome da secretaria pelo relacionamento (join do PostgREST)
    final dados = await supabase
        .from('perfis')
        .select(
            'id, nome, matricula, secretaria_id, tipo_usuario, secretarias(nome_secretaria)')
        .eq('id', usuario.id)
        .single();
    return Perfil.fromMap(dados);
  }
}
