import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme.dart';

class EstiloStatus {
  const EstiloStatus({
    required this.rotulo,
    required this.fundo,
    required this.texto,
    required this.icone,
  });

  final String rotulo;
  final Color fundo;
  final Color texto;
  final IconData icone;
}

EstiloStatus estiloDoStatus(String status) {
  if (status == StatusChamado.aberto) {
    return const EstiloStatus(
      rotulo: 'Aberto',
      fundo: Cores.azulClaro,
      texto: Cores.azul,
      icone: Icons.schedule,
    );
  }
  if (status == StatusChamado.emConserto) {
    return const EstiloStatus(
      rotulo: 'Conserto em andamento',
      fundo: Cores.laranjaClaro,
      texto: Cores.laranjaEscuro,
      icone: Icons.build_outlined,
    );
  }
  if (status == StatusChamado.pronto) {
    return const EstiloStatus(
      rotulo: 'Pronto para retirada',
      fundo: Color(0xFFDCF3E5),
      texto: Cores.sucesso,
      icone: Icons.check_circle_outline,
    );
  }
  // Qualquer outro valor é tratado como concluído
  return EstiloStatus(
    rotulo: StatusChamado.rotulo(status),
    fundo: const Color(0xFFE8EBF3),
    texto: const Color(0xFF535D78),
    icone: Icons.task_alt,
  );
}

IconData iconeDoTipo(String tipo) {
  switch (tipo) {
    case 'Desktop':
      return Icons.desktop_windows_outlined;
    case 'Notebook':
      return Icons.laptop;
    case 'Impressora':
      return Icons.print_outlined;
    case 'Monitor':
      return Icons.monitor;
    case 'Servidor':
      return Icons.dns_outlined;
    case 'Switch/Roteador':
      return Icons.router_outlined;
    case 'Scanner':
      return Icons.scanner_outlined;
    case 'Projetor':
      return Icons.cast;
    case 'No-break':
      return Icons.battery_charging_full;
    case 'Tablet':
      return Icons.tablet_android;
    // Tipos fora da lista usam ícone genérico
    default:
      return Icons.devices_other_outlined;
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final estilo = estiloDoStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: estilo.fundo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(estilo.icone, size: 16, color: estilo.texto),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              estilo.rotulo,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: estilo.texto,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Painel extends StatelessWidget {
  const Painel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.cor = Colors.white,
    this.margem,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color cor;
  final EdgeInsetsGeometry? margem;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margem,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Cores.borda),
      ),
      child: child,
    );
  }
}

class ConteudoCentralizado extends StatelessWidget {
  const ConteudoCentralizado({
    super.key,
    required this.child,
    this.larguraMaxima = 900,
  });

  final Widget child;
  final double larguraMaxima;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: larguraMaxima),
        child: child,
      ),
    );
  }
}

class TelaCarregando extends StatelessWidget {
  const TelaCarregando({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    this.mensagem,
    this.acao,
  });

  final IconData icone;
  final String titulo;
  final String? mensagem;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 44, color: Cores.tintaSuave),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (mensagem != null) ...[
              const SizedBox(height: 6),
              Text(
                mensagem!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Cores.tintaSuave, height: 1.4),
              ),
            ],
            if (acao != null) ...[
              const SizedBox(height: 16),
              acao!,
            ],
          ],
        ),
      ),
    );
  }
}

class EstadoErro extends StatelessWidget {
  const EstadoErro({
    super.key,
    required this.mensagem,
    required this.onTentarNovamente,
  });

  final String mensagem;
  final VoidCallback onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return EstadoVazio(
      icone: Icons.error_outline,
      titulo: 'Não foi possível carregar',
      mensagem: mensagem,
      acao: OutlinedButton.icon(
        onPressed: onTentarNovamente,
        icon: const Icon(Icons.refresh),
        label: const Text('Tentar novamente'),
      ),
    );
  }
}

class TituloDaTela extends StatelessWidget {
  const TituloDaTela({super.key, required this.titulo, this.subtitulo});

  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Cores.tinta,
                ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitulo!,
              style: const TextStyle(color: Cores.tintaSuave, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

InputDecoration decoracaoCampo(
  String? rotulo, {
  IconData? icone,
  String? dica,
  Widget? sufixo,
}) {
  return InputDecoration(
    labelText: rotulo,
    hintText: dica,
    prefixIcon: icone == null ? null : Icon(icone),
    suffixIcon: sufixo,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Cores.borda),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Cores.azul, width: 2),
    ),
  );
}

class PickerItem<T> {
  const PickerItem({
    required this.value,
    required this.titulo,
    this.subtitulo,
  });

  final T value;
  final String titulo;
  final String? subtitulo;
}

// Abre a folha de seleção; devolve o valor escolhido ou null se for fechada
Future<T?> escolherItem<T>(
  BuildContext context, {
  required String titulo,
  required List<PickerItem<T>> itens,
  T? valor,
  String textoVazio = 'Nenhuma opção disponível.',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _FolhaDeEscolha<T>(
      titulo: titulo,
      itens: itens,
      valor: valor,
      textoVazio: textoVazio,
    ),
  );
}

class PickerField<T> extends StatelessWidget {
  const PickerField({
    super.key,
    required this.rotulo,
    required this.icone,
    required this.itens,
    required this.valor,
    required this.onChanged,
    this.erro,
    this.habilitado = true,
    this.dica,
    this.textoVazio = 'Nenhuma opção disponível.',
  });

  final String rotulo;
  final IconData icone;
  final List<PickerItem<T>> itens;
  final T? valor;
  final ValueChanged<T> onChanged;
  final String? erro;
  final bool habilitado;
  final String? dica;
  final String textoVazio;

  @override
  Widget build(BuildContext context) {
    PickerItem<T>? selecionado;
    for (final item in itens) {
      if (item.value == valor) {
        selecionado = item;
        break;
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: habilitado
          ? () async {
              final escolhido = await escolherItem<T>(
                context,
                titulo: rotulo,
                itens: itens,
                valor: valor,
                textoVazio: textoVazio,
              );
              if (escolhido != null) onChanged(escolhido);
            }
          : null,
      child: InputDecorator(
        isEmpty: selecionado == null,
        decoration: decoracaoCampo(
          rotulo,
          icone: icone,
          sufixo: const Icon(Icons.arrow_drop_down),
        ).copyWith(
          errorText: erro,
          helperText: dica,
          enabled: habilitado,
        ),
        child: Text(
          selecionado?.titulo ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _FolhaDeEscolha<T> extends StatefulWidget {
  const _FolhaDeEscolha({
    required this.titulo,
    required this.itens,
    required this.valor,
    required this.textoVazio,
  });

  final String titulo;
  final List<PickerItem<T>> itens;
  final T? valor;
  final String textoVazio;

  @override
  State<_FolhaDeEscolha<T>> createState() => _FolhaDeEscolhaState<T>();
}

class _FolhaDeEscolhaState<T> extends State<_FolhaDeEscolha<T>> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final termo = _busca.trim().toLowerCase();
    final filtrados = widget.itens.where((item) {
      if (termo.isEmpty) return true;
      return item.titulo.toLowerCase().contains(termo) ||
          (item.subtitulo ?? '').toLowerCase().contains(termo);
    }).toList();

    final altura = MediaQuery.of(context).size.height * 0.75;

    return Padding(
      // Sobe a folha acima do teclado
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: altura),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                widget.titulo,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            // A busca só aparece em listas longas
            if (widget.itens.length > 6)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  onChanged: (valor) => setState(() => _busca = valor),
                  decoration: decoracaoCampo(null,
                      icone: Icons.search, dica: 'Buscar…'),
                ),
              ),
            Flexible(
              child: filtrados.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        widget.itens.isEmpty
                            ? widget.textoVazio
                            : 'Nada encontrado para "$_busca".',
                        style: const TextStyle(color: Cores.tintaSuave),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtrados.length,
                      itemBuilder: (context, indice) {
                        final item = filtrados[indice];
                        final escolhido = item.value == widget.valor;
                        return ListTile(
                          title: Text(item.titulo),
                          subtitle: item.subtitulo == null
                              ? null
                              : Text(item.subtitulo!),
                          trailing: escolhido
                              ? const Icon(Icons.check, color: Cores.azul)
                              : null,
                          selected: escolhido,
                          onTap: () => Navigator.of(context).pop<T>(item.value),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> pedirConfirmacao(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String textoConfirmar = 'Confirmar',
  bool perigo = false,
}) async {
  final resposta = await showDialog<bool>(
    context: context,
    builder: (contextoDialogo) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(contextoDialogo).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: perigo
              ? FilledButton.styleFrom(backgroundColor: Cores.perigo)
              : null,
          onPressed: () => Navigator.of(contextoDialogo).pop(true),
          child: Text(textoConfirmar),
        ),
      ],
    ),
  );
  // Fechar sem escolher conta como não confirmado
  return resposta ?? false;
}

void mostrarMensagem(BuildContext context, String texto, {bool erro = false}) {
  final aviso = ScaffoldMessenger.of(context);
  aviso.hideCurrentSnackBar();
  aviso.showSnackBar(
    SnackBar(
      content: Text(texto),
      behavior: SnackBarBehavior.floating,
      backgroundColor: erro ? Cores.perigo : Cores.azulNoite,
      duration: Duration(seconds: erro ? 6 : 3),
    ),
  );
}
