import 'package:flutter/services.dart';

import '../config.dart';

String somenteDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

bool cpfValido(String entrada) {
  final cpf = somenteDigitos(entrada);
  if (cpf.length != 11) return false;
  // Rejeita sequências repetidas (ex.: 111.111.111-11)
  if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;

  // Dígito verificador do CPF (módulo 11)
  int digito(int quantidade) {
    var soma = 0;
    for (var i = 0; i < quantidade; i++) {
      soma += int.parse(cpf[i]) * (quantidade + 1 - i);
    }
    final resto = (soma * 10) % 11;
    return resto == 10 ? 0 : resto;
  }

  return digito(9) == int.parse(cpf[9]) && digito(10) == int.parse(cpf[10]);
}

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue valorAntigo,
    TextEditingValue valorNovo,
  ) {
    var digitos = somenteDigitos(valorNovo.text);
    if (digitos.length > 11) digitos = digitos.substring(0, 11);

    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digitos[i]);
    }
    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

String normalizarMatricula(String matricula) =>
    matricula.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

// Login interno: a matrícula normalizada vira o e-mail usado no Supabase Auth
String emailDaMatricula(String matricula) =>
    '${normalizarMatricula(matricula)}@$kDominioLogin';

String _doisDigitos(int valor) => valor.toString().padLeft(2, '0');

String formatarData(DateTime data) {
  final d = data.toLocal();
  return '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}/${d.year}';
}

String formatarDataHora(DateTime data) {
  final d = data.toLocal();
  return '${formatarData(d)} às ${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';
}

String tempoRelativo(DateTime data) {
  final diferenca = DateTime.now().difference(data);
  if (diferenca.inMinutes < 1) return 'agora há pouco';
  if (diferenca.inMinutes < 60) return 'há ${diferenca.inMinutes} min';
  if (diferenca.inHours < 24) return 'há ${diferenca.inHours} h';
  if (diferenca.inDays < 7) return 'há ${diferenca.inDays} d';
  return 'em ${formatarData(data)}';
}
