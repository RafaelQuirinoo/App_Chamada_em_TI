import '../models/models.dart';
import '../utils/erros.dart';
import 'supabase_client.dart';

class SecretariasRepo {
  SecretariasRepo._();

  static Future<List<Secretaria>> listar() async {
    final dados = await supabase
        .from('secretarias')
        .select('id, nome_secretaria')
        .order('nome_secretaria');
    return dados.map<Secretaria>((m) => Secretaria.fromMap(m)).toList();
  }
}

class MaquinasRepo {
  MaquinasRepo._();

  static const String _colunas =
      'id, numero_registro, tipo_maquina, modelo, secretaria_id, secretarias(nome_secretaria)';

  static Future<List<Maquina>> listar({int? secretariaId}) async {
    var consulta = supabase.from('maquinas').select(_colunas);
    if (secretariaId != null) {
      consulta = consulta.eq('secretaria_id', secretariaId);
    }
    final dados = await consulta.order('numero_registro');
    return dados.map<Maquina>((m) => Maquina.fromMap(m)).toList();
  }

  static Future<void> criar({
    required String numeroRegistro,
    required String tipoMaquina,
    required String modelo,
    required int secretariaId,
  }) async {
    await supabase.from('maquinas').insert({
      'numero_registro': numeroRegistro,
      'tipo_maquina': tipoMaquina,
      'modelo': modelo,
      'secretaria_id': secretariaId,
    });
  }

  // O select('id') devolve as linhas afetadas; lista vazia = RLS bloqueou
  // ou o registro não existe
  static Future<void> atualizar(
    int id, {
    required String numeroRegistro,
    required String tipoMaquina,
    required String modelo,
    required int secretariaId,
  }) async {
    final alteradas = await supabase
        .from('maquinas')
        .update({
          'numero_registro': numeroRegistro,
          'tipo_maquina': tipoMaquina,
          'modelo': modelo,
          'secretaria_id': secretariaId,
        })
        .eq('id', id)
        .select('id');
    if (alteradas.isEmpty) {
      throw const AppException(
          'Não foi possível atualizar: máquina não encontrada ou sem permissão.');
    }
  }

  static Future<void> transferir(int id, int novaSecretariaId) async {
    final alteradas = await supabase
        .from('maquinas')
        .update({'secretaria_id': novaSecretariaId})
        .eq('id', id)
        .select('id');
    if (alteradas.isEmpty) {
      throw const AppException(
          'Não foi possível transferir: máquina não encontrada ou sem permissão.');
    }
  }

  static Future<void> excluir(int id) async {
    final removidas =
        await supabase.from('maquinas').delete().eq('id', id).select('id');
    if (removidas.isEmpty) {
      throw const AppException(
          'Não foi possível excluir: máquina não encontrada ou sem permissão.');
    }
  }
}

class ChamadosRepo {
  ChamadosRepo._();

  static const String _colunas =
      'id, servidor_id, servidor_nome, maquina_id, secretaria_id, descricao_problema, '
      'status, data_criacao, atualizado_em, '
      'maquinas(numero_registro, tipo_maquina, modelo), secretarias(nome_secretaria)';

  static Future<int> abrir({
    required String servidorId,
    int? maquinaId,
    required int secretariaId,
    required String descricao,
  }) async {
    final criado = await supabase
        .from('chamados')
        .insert({
          'servidor_id': servidorId,
          'maquina_id': maquinaId,
          'secretaria_id': secretariaId,
          'descricao_problema': descricao,
          'status': 'aberto',
        })
        .select('id')
        .single();
    return (criado['id'] as num).toInt();
  }

  static Future<List<Chamado>> listar({
    String? servidorId,
    int? secretariaId,
  }) async {
    var consulta = supabase.from('chamados').select(_colunas);
    if (servidorId != null) {
      consulta = consulta.eq('servidor_id', servidorId);
    }
    if (secretariaId != null) {
      consulta = consulta.eq('secretaria_id', secretariaId);
    }
    // Traz os 300 mais recentes; o que cada perfil enxerga também é limitado pelo RLS
    final dados =
        await consulta.order('data_criacao', ascending: false).limit(300);
    return dados.map<Chamado>((m) => Chamado.fromMap(m)).toList();
  }

  // Mesma checagem: sem linhas alteradas, o RLS bloqueou ou o chamado não existe
  static Future<void> alterarStatus(int id, String novoStatus) async {
    final alterados = await supabase
        .from('chamados')
        .update({'status': novoStatus})
        .eq('id', id)
        .select('id');
    if (alterados.isEmpty) {
      throw const AppException(
          'Não foi possível alterar o status: chamado não encontrado ou sem permissão.');
    }
  }

  static Future<int> contarAbertos() async {
    final dados =
        await supabase.from('chamados').select('id').eq('status', 'aberto');
    return dados.length;
  }
}

class FaqsRepo {
  FaqsRepo._();

  static Future<List<Faq>> listar() async {
    final dados = await supabase
        .from('faqs')
        .select('id, categoria, pergunta, resposta')
        .order('ordem')
        .order('id');
    return dados.map<Faq>((m) => Faq.fromMap(m)).toList();
  }
}
