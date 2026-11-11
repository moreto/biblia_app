import 'dart:async';

import 'package:app/config/icons_map.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart' as componentes;
import 'package:flutter/material.dart';

import '../../../../data/model/usuario/usuario_resumo_model.dart';
import 'mensagem_envio_viewmodel.dart';

/// Tela de envio de mensagem ("Nova mensagem"), aberta pelo componente `DialogBottomSheet` ([show]).
///
/// - Tipo (sem o de sistema; o primeiro já escolhido), destinatários (busca por nome ou nome de usuário, a partir de
///   2 caracteres e [esperaBusca] depois da última tecla; cada escolhido vira um chip removível), título (até 100) e
///   texto (até 4000).
/// - "Enviar" valida (problema mostrado no formulário) e envia. Sucesso fecha e avisa `mensagemEnviada`; falha em
///   algum destinatário fecha e avisa `mensagemEnviadaParcialmente`; outro erro fica no formulário.
/// - O componente tem fundo claro fixo: o conteúdo usa tema claro também no modo escuro, para ficar legível.
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeNova], [iconeEnviar], [iconeBuscar] e [iconeAdicionar].
class MensagemEnvioView extends StatefulWidget {
  const MensagemEnvioView({super.key, required this.viewModel, required this.onConcluido});

  final MensagemEnvioViewmodel viewModel;

  /// Chamado ao fechar depois de enviar, com a chave da mensagem a mostrar.
  final ValueChanged<String> onConcluido;

  static const esperaBusca = Duration(milliseconds: 400);

  /// Botão "Nova mensagem" da lista e título do sheet.
  static const iconeNova = 'email-plus-outline';
  static const iconeEnviar = 'send';
  static const iconeBuscar = 'account-search-outline';
  static const iconeAdicionar = 'account-plus-outline';

  static Widget icone(String chave, IconData fallback, {Color? color, double? size}) =>
      Icon(IconsMap.mdiIcons[chave] ?? fallback, color: color, size: size);

  /// Tema claro com a cor primária do app, para o fundo claro fixo do `DialogBottomSheet`.
  static ThemeData temaDoSheet(BuildContext context) => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Theme.of(context).colorScheme.primary),
    useMaterial3: true,
  );

  /// Abre o envio no `DialogBottomSheet` com um rascunho novo.
  static void show(
    BuildContext context, {
    required MensagemEnvioViewmodel viewModel,
    required ValueChanged<String> onConcluido,
  }) {
    viewModel.iniciar();
    final strings = AppLocalizations.of(context);
    final tema = temaDoSheet(context);
    componentes.DialogBottomSheet(
      componentes.Dialog(
        isDismissible: false,
        bottomSheetTitle: Theme(
          data: tema,
          child: Builder(
            builder: (context) => Row(
              children: [
                icone(iconeNova, Icons.mail_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    strings.translate('novaMensagem'),
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Material transparente: o componente pinta o fundo num Container, e os ListTile/InkWell precisam de um
        // Material para mostrar o toque.
        widget: Theme(
          data: tema,
          child: Material(
            type: MaterialType.transparency,
            child: MensagemEnvioView(viewModel: viewModel, onConcluido: onConcluido),
          ),
        ),
      ),
    ).showModal(context);
  }

  @override
  State<MensagemEnvioView> createState() => _MensagemEnvioViewState();
}

class _MensagemEnvioViewState extends State<MensagemEnvioView> {
  final _titulo = TextEditingController();
  final _texto = TextEditingController();
  final _busca = TextEditingController();
  Timer? _esperaBusca;
  String? _erro;

  MensagemEnvioViewmodel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.enviarCommand.addListener(_onEnviar);
  }

  @override
  void dispose() {
    _vm.enviarCommand.removeListener(_onEnviar);
    _esperaBusca?.cancel();
    _titulo.dispose();
    _texto.dispose();
    _busca.dispose();
    super.dispose();
  }

  void _onEnviar() {
    final command = _vm.enviarCommand;
    if (!mounted || command.running) return;
    if (command.completed) {
      command.clearResult();
      _fechar('mensagemEnviada');
    } else if (command.error) {
      final mensagem = _mensagemComando(command.result);
      command.clearResult();
      if (mensagem == 'mensagemEnviadaParcialmente') {
        _fechar(mensagem);
      } else {
        setState(() => _erro = mensagem);
      }
    }
  }

  void _fechar(String mensagem) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop();
    widget.onConcluido(mensagem);
  }

  void _onBuscaAlterada(String texto) {
    _esperaBusca?.cancel();
    _esperaBusca = Timer(MensagemEnvioView.esperaBusca, () => _vm.buscar(texto));
  }

  void _adicionar(UsuarioResumoModel usuario) {
    _vm.adicionar(usuario);
    _busca.clear();
    setState(() => _erro = null);
  }

  void _enviar() {
    final erro = _vm.validar(titulo: _titulo.text, texto: _texto.text);
    setState(() => _erro = erro);
    if (erro == null) _vm.enviarCommand.execute((titulo: _titulo.text, texto: _texto.text));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final enviando = _vm.enviarCommand.running;
        final tipos = _vm.tipos;
        final erro = _erro;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (tipos == null && _vm.tiposCommand.error)
                Row(
                  children: [
                    Expanded(child: Text(strings.translate(_mensagemComando(_vm.tiposCommand.result)))),
                    TextButton(onPressed: _vm.tiposCommand.execute, child: Text(strings.translate('tentarNovamente'))),
                  ],
                )
              else
                DropdownButtonFormField<int>(
                  key: ValueKey('tipo-${tipos?.length}-${_vm.mtipId}'),
                  initialValue: _vm.mtipId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: strings.translate('tipoMensagem')),
                  items: [
                    for (final t in tipos ?? const []) DropdownMenuItem(value: t.mtipId, child: Text(t.mtipTipo)),
                  ],
                  onChanged: tipos == null || enviando ? null : _vm.selecionarTipo,
                ),
              const SizedBox(height: 12),
              Text(strings.translate('destinatarios'), style: textTheme.labelLarge),
              const SizedBox(height: 4),
              if (_vm.destinatarios.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final u in _vm.destinatarios)
                      InputChip(
                        label: Text(_vm.nomeUsuario(u)),
                        onDeleted: enviando ? null : () => _vm.remover(u),
                        deleteButtonTooltipMessage: strings.translate('remover'),
                      ),
                  ],
                ),
              TextField(
                controller: _busca,
                enabled: !enviando,
                autocorrect: false,
                textInputAction: TextInputAction.search,
                onChanged: _onBuscaAlterada,
                onSubmitted: _vm.buscar,
                decoration: InputDecoration(
                  labelText: strings.translate('buscarUsuario'),
                  hintText: strings.translate('buscarUsuarioDica'),
                  prefixIcon: MensagemEnvioView.icone(MensagemEnvioView.iconeBuscar, Icons.person_search_outlined),
                ),
              ),
              if (_vm.buscando) const LinearProgressIndicator(),
              if (_vm.erroBusca != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    strings.translate(_vm.erroBusca!),
                    style: textTheme.bodySmall?.copyWith(color: scheme.error),
                  ),
                ),
              if (_vm.buscou && !_vm.buscando && _vm.encontrados.isEmpty && _vm.erroBusca == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(strings.translate('nenhumUsuarioEncontrado'), style: textTheme.bodySmall),
                ),
              for (final u in _vm.encontrados)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_vm.nomeUsuario(u)),
                  trailing: IconButton(
                    tooltip: strings.translate('adicionarDestinatario'),
                    onPressed: enviando ? null : () => _adicionar(u),
                    icon: MensagemEnvioView.icone(
                      MensagemEnvioView.iconeAdicionar,
                      Icons.person_add_alt_outlined,
                      color: scheme.primary,
                    ),
                  ),
                  onTap: enviando ? null : () => _adicionar(u),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _titulo,
                enabled: !enviando,
                maxLength: _vm.tituloMaximo,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: strings.translate('titulo')),
              ),
              TextField(
                controller: _texto,
                enabled: !enviando,
                maxLength: _vm.textoMaximo,
                minLines: 4,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: strings.translate('texto'), alignLabelWithHint: true),
              ),
              if (erro != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(strings.translate(erro), style: TextStyle(color: scheme.error)),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: enviando || tipos == null ? null : _enviar,
                icon: enviando
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : MensagemEnvioView.icone(MensagemEnvioView.iconeEnviar, Icons.send),
                label: Text(strings.translate('enviar')),
              ),
            ],
          ),
        );
      },
    );
  }

  String _mensagemComando(Result? result) => switch (result) {
    Error(error: final error) => _vm.mensagemErro(error),
    _ => kDefaultAppError,
  };
}
