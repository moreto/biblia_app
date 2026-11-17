import 'package:app/config/dialog_sheet.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/fale_conosco/fale_conosco_model.dart';
import '../../use_case/fale_conosco_usecase.dart';
import '../fale_conosco_view.dart';
import '../fale_conosco_viewmodel.dart';

/// Formulário "Nova mensagem" do Fale Conosco, aberto no `DialogBottomSheet` ([show]).
///
/// - Nome e e-mail já vêm com os do usuário logado; telefone é opcional; categoria (opções da configuração
///   `faleConoscoCategoria`), assunto e mensagem são obrigatórios. Os limites de tamanho são os da API.
/// - "Enviar" valida (problema mostrado no formulário) e envia. Sucesso fecha e chama [onEnviado] com o protocolo;
///   erro fica no formulário.
///
/// Ícones: [FaleConoscoView.iconeNova] (título) e [iconeEnviar].
class FaleConoscoFormDialog extends StatefulWidget {
  const FaleConoscoFormDialog({super.key, required this.viewModel, required this.onEnviado});

  final FaleConoscoViewmodel viewModel;
  final ValueChanged<FaleConoscoEnvioModel> onEnviado;

  static const iconeEnviar = 'send';

  static void show(
    BuildContext context, {
    required FaleConoscoViewmodel viewModel,
    required ValueChanged<FaleConoscoEnvioModel> onEnviado,
  }) {
    viewModel.enviarCommand.clearResult();
    final strings = AppLocalizations.of(context);
    DialogSheet.show<void>(
      context,
      isDismissible: false,
      cabecalho: Builder(
        builder: (context) => Row(
          children: [
            FaleConoscoView.icone(
              FaleConoscoView.iconeNova,
              Icons.mail_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
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
      conteudo: FaleConoscoFormDialog(viewModel: viewModel, onEnviado: onEnviado),
    );
  }

  @override
  State<FaleConoscoFormDialog> createState() => _FaleConoscoFormDialogState();
}

class _FaleConoscoFormDialogState extends State<FaleConoscoFormDialog> {
  late final _nome = TextEditingController(text: _vm.prefixoNome);
  late final _email = TextEditingController(text: _vm.prefixoEmail);
  final _telefone = TextEditingController();
  final _assunto = TextEditingController();
  final _mensagem = TextEditingController();
  int? _categoria;
  String? _erro;

  FaleConoscoViewmodel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.enviarCommand.addListener(_onEnviar);
  }

  @override
  void dispose() {
    _vm.enviarCommand.removeListener(_onEnviar);
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    _assunto.dispose();
    _mensagem.dispose();
    super.dispose();
  }

  void _onEnviar() {
    final command = _vm.enviarCommand;
    if (!mounted || command.running) return;
    final result = command.result;
    if (result case Ok(value: final FaleConoscoEnvioModel envio)) {
      command.clearResult();
      FocusScope.of(context).unfocus();
      Navigator.of(context).pop();
      widget.onEnviado(envio);
    } else if (command.error) {
      final mensagem = FaleConoscoView.mensagemErro(_vm, result);
      command.clearResult();
      setState(() => _erro = mensagem);
    }
  }

  FaleConoscoFormulario get _formulario => (
    nome: _nome.text,
    email: _email.text,
    telefone: _telefone.text,
    assunto: _assunto.text,
    mensagem: _mensagem.text,
    categoria: _categoria,
  );

  void _enviar() {
    final formulario = _formulario;
    final erro = _vm.validar(formulario);
    setState(() => _erro = erro);
    if (erro == null) _vm.enviarCommand.execute(formulario);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: _vm.enviarCommand,
      builder: (context, _) {
        final enviando = _vm.enviarCommand.running;
        final erro = _erro;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(strings.translate('faleConoscoIntro'), style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _nome,
              enabled: !enviando,
              maxLength: _vm.nomeMaximo,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: strings.translate('nome')),
            ),
            TextField(
              controller: _email,
              enabled: !enviando,
              maxLength: _vm.emailMaximo,
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: strings.translate('email')),
            ),
            TextField(
              controller: _telefone,
              enabled: !enviando,
              maxLength: _vm.telefoneMaximo,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: strings.translate('telefoneOpcional')),
            ),
            DropdownButtonFormField<int>(
              initialValue: _categoria,
              isExpanded: true,
              decoration: InputDecoration(labelText: strings.translate('categoria')),
              items: [
                for (final c in _vm.opcoes.categorias)
                  DropdownMenuItem(value: c.chave, child: Text(strings.translate(c.rotulo))),
              ],
              onChanged: enviando ? null : (valor) => setState(() => _categoria = valor),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _assunto,
              enabled: !enviando,
              maxLength: _vm.assuntoMaximo,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: strings.translate('assunto')),
            ),
            TextField(
              controller: _mensagem,
              enabled: !enviando,
              maxLength: _vm.textoMaximo,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: strings.translate('mensagem'), alignLabelWithHint: true),
            ),
            if (erro != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(strings.translate(erro), style: TextStyle(color: scheme.error)),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: enviando ? null : _enviar,
              icon: enviando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : FaleConoscoView.icone(FaleConoscoFormDialog.iconeEnviar, Icons.send),
              label: Text(strings.translate('enviar')),
            ),
          ],
        );
      },
    );
  }
}
