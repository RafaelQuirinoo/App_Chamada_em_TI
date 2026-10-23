class StatusChamado {
  StatusChamado._();

  // Valores gravados na coluna chamados.status
  static const String aberto = 'aberto';
  static const String emConserto = 'conserto em andamento';
  static const String pronto = 'pronto para retirada';
  static const String concluido = 'concluido';

  // Ordem do fluxo de atendimento (usada na barra de progresso)
  static const List<String> todos = [aberto, emConserto, pronto, concluido];

  static String rotulo(String status) {
    if (status == aberto) return 'Aberto';
    if (status == emConserto) return 'Conserto em andamento';
    if (status == pronto) return 'Pronto para retirada';
    if (status == concluido) return 'Concluído';
    return status;
  }
}

const List<String> kTiposMaquina = [
  'Desktop',
  'Notebook',
  'Impressora',
  'Monitor',
  'Servidor',
  'Switch/Roteador',
  'Scanner',
  'Projetor',
  'No-break',
  'Tablet',
  'Outro',
];

// Converte número vindo do JSON (int ou double) para int
int _inteiro(dynamic valor) => (valor as num).toInt();

String? _nomeSecretaria(dynamic relacao) {
  if (relacao is Map) {
    final nome = relacao['nome_secretaria'];
    if (nome is String) return nome;
  }
  return null;
}

class Secretaria {
  const Secretaria({required this.id, required this.nome});

  final int id;
  final String nome;

  factory Secretaria.fromMap(Map<String, dynamic> mapa) {
    return Secretaria(
      id: _inteiro(mapa['id']),
      nome: mapa['nome_secretaria'] as String,
    );
  }
}

class Perfil {
  const Perfil({
    required this.id,
    required this.nome,
    required this.matricula,
    required this.tipoUsuario,
    this.secretariaId,
    this.secretariaNome,
  });

  final String id;
  final String nome;
  final String matricula;
  final String tipoUsuario;
  final int? secretariaId;
  final String? secretariaNome;

  // Só controla o que a interface exibe; a permissão real é validada pelo RLS
  bool get ehTecnico => tipoUsuario == 'tecnico';

  String get iniciais {
    final partes =
        nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }

  factory Perfil.fromMap(Map<String, dynamic> mapa) {
    final idSecretaria = mapa['secretaria_id'];
    return Perfil(
      id: mapa['id'] as String,
      nome: mapa['nome'] as String,
      matricula: mapa['matricula'] as String,
      tipoUsuario: mapa['tipo_usuario'] as String,
      secretariaId: idSecretaria == null ? null : _inteiro(idSecretaria),
      secretariaNome: _nomeSecretaria(mapa['secretarias']),
    );
  }
}

class Maquina {
  const Maquina({
    required this.id,
    required this.numeroRegistro,
    required this.tipoMaquina,
    required this.modelo,
    required this.secretariaId,
    this.secretariaNome,
  });

  final int id;
  final String numeroRegistro;
  final String tipoMaquina;
  final String modelo;
  final int secretariaId;
  final String? secretariaNome;

  String get descricao => '$tipoMaquina $modelo';

  factory Maquina.fromMap(Map<String, dynamic> mapa) {
    return Maquina(
      id: _inteiro(mapa['id']),
      numeroRegistro: mapa['numero_registro'] as String,
      tipoMaquina: mapa['tipo_maquina'] as String,
      modelo: mapa['modelo'] as String,
      secretariaId: _inteiro(mapa['secretaria_id']),
      secretariaNome: _nomeSecretaria(mapa['secretarias']),
    );
  }
}

class Chamado {
  const Chamado({
    required this.id,
    required this.secretariaId,
    required this.descricao,
    required this.status,
    required this.dataCriacao,
    required this.atualizadoEm,
    this.servidorId,
    this.servidorNome,
    this.maquinaId,
    this.maquinaTipo,
    this.maquinaModelo,
    this.maquinaRegistro,
    this.secretariaNome,
  });

  final int id;
  final String? servidorId;
  final String? servidorNome;
  final int? maquinaId;
  final int secretariaId;
  final String descricao;
  final String status;
  final DateTime dataCriacao;
  final DateTime atualizadoEm;
  final String? maquinaTipo;
  final String? maquinaModelo;
  final String? maquinaRegistro;
  final String? secretariaNome;

  // O chamado pode não ter máquina (fora da lista ou máquina já excluída)
  String get maquinaTitulo {
    if (maquinaTipo != null && maquinaModelo != null) {
      return '$maquinaTipo $maquinaModelo';
    }
    return 'Máquina não identificada';
  }

  String get maquinaDetalhe {
    final partes = <String>[];
    if (maquinaRegistro != null) partes.add('Patrimônio $maquinaRegistro');
    if (secretariaNome != null) partes.add(secretariaNome!);
    return partes.join(' · ');
  }

  factory Chamado.fromMap(Map<String, dynamic> mapa) {
    final maquina = mapa['maquinas'];
    final criado = DateTime.parse(mapa['data_criacao'] as String);
    final atualizado = mapa['atualizado_em'];
    final idMaquina = mapa['maquina_id'];
    return Chamado(
      id: _inteiro(mapa['id']),
      servidorId: mapa['servidor_id'] as String?,
      servidorNome: mapa['servidor_nome'] as String?,
      maquinaId: idMaquina == null ? null : _inteiro(idMaquina),
      secretariaId: _inteiro(mapa['secretaria_id']),
      descricao: mapa['descricao_problema'] as String,
      status: mapa['status'] as String,
      dataCriacao: criado,
      // Sem atualizado_em, usa a data de criação
      atualizadoEm: atualizado is String ? DateTime.parse(atualizado) : criado,
      maquinaTipo: maquina is Map ? maquina['tipo_maquina'] as String? : null,
      maquinaModelo: maquina is Map ? maquina['modelo'] as String? : null,
      maquinaRegistro:
          maquina is Map ? maquina['numero_registro'] as String? : null,
      secretariaNome: _nomeSecretaria(mapa['secretarias']),
    );
  }
}

class Faq {
  const Faq({
    required this.id,
    required this.categoria,
    required this.pergunta,
    required this.resposta,
  });

  final int id;
  final String categoria;
  final String pergunta;
  final String resposta;

  factory Faq.fromMap(Map<String, dynamic> mapa) {
    return Faq(
      id: _inteiro(mapa['id']),
      categoria: mapa['categoria'] as String,
      pergunta: mapa['pergunta'] as String,
      resposta: mapa['resposta'] as String,
    );
  }
}
