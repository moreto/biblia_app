import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../data/model/comunidade/comunidade_contato_model.dart';
import '../../../../admin/configuracao/ui/widgets/configuracao_dialog_layout.dart';
import '../../use_case/comunidade_contato_usecase.dart';
import '../comunidade_contato_view.dart';

/// Formulário de inclusão/alteração do contato da comunidade [comuId] ([comunidadeNome] aparece no topo): um
/// campo para cada [ContatoCampo] (telefones, WhatsApp, e-mail, site e redes sociais), com o tamanho da coluna.
///
/// Ao salvar, [validarCampo] (regra do use case) marca cada campo com problema e [validar] devolve a chave do
/// problema geral (ex.: nenhum campo preenchido), mostrada no formulário; sem problema, retorna o
/// [ComunidadeContatoModel] preenchido. `null` quando cancelado.
class ComunidadeContatoFormDialog extends StatefulWidget {
  const ComunidadeContatoFormDialog({
    super.key,
    required this.comuId,
    required this.comunidadeNome,
    required this.validar,
    required this.validarCampo,
    this.contato,
  });

  final int comuId;
  final String comunidadeNome;
  final String? Function(ComunidadeContatoModel) validar;
  final String? Function(ContatoCampo campo, String? valor) validarCampo;

  /// Contato em alteração; nulo na inclusão.
  final ComunidadeContatoModel? contato;

  static Future<ComunidadeContatoModel?> show(
    BuildContext context, {
    required int comuId,
    required String comunidadeNome,
    required String? Function(ComunidadeContatoModel) validar,
    required String? Function(ContatoCampo campo, String? valor) validarCampo,
    ComunidadeContatoModel? contato,
  }) => ConfiguracaoDialogLayout.show<ComunidadeContatoModel>(
    context,
    titulo: AppLocalizations.of(context).translate(contato?.cconId == null ? 'novoContato' : 'editarContato'),
    form: ComunidadeContatoFormDialog(
      comuId: comuId,
      comunidadeNome: comunidadeNome,
      validar: validar,
      validarCampo: validarCampo,
      contato: contato,
    ),
  );

  @override
  State<ComunidadeContatoFormDialog> createState() => _ComunidadeContatoFormDialogState();
}

class _ComunidadeContatoFormDialogState extends State<ComunidadeContatoFormDialog> {
  late final Map<ContatoCampo, TextEditingController> _campos = {
    for (final campo in ContatoCampo.values) campo: TextEditingController(text: widget.contato?.campo(campo.chave)),
  };

  Map<ContatoCampo, String> _erros = const {};
  String? _erro;

  @override
  void dispose() {
    for (final controller in _campos.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _confirmar() {
    final contato = ComunidadeContatoModel.comCampos(
      cconId: widget.contato?.cconId,
      comuId: widget.comuId,
      campos: {for (final MapEntry(:key, :value) in _campos.entries) key.chave: value.text},
    );
    final erros = {for (final MapEntry(:key, :value) in _campos.entries) key: ?widget.validarCampo(key, value.text)};
    final erro = widget.validar(contato);
    if (erros.isNotEmpty || erro != null) {
      setState(() {
        _erros = erros;
        // O erro de um campo já aparece nele; aqui só o geral.
        _erro = erros.containsValue(erro) ? null : erro;
      });
      return;
    }
    Navigator.of(context).pop(contato);
  }

  Widget _campo(AppLocalizations strings, ContatoCampo campo) {
    final (teclado, formatadores) = switch (campo.tipo) {
      ContatoTipo.telefone => (TextInputType.phone, [FilteringTextInputFormatter.allow(RegExp(r'[\d\s()+.-]'))]),
      ContatoTipo.email => (TextInputType.emailAddress, null),
      ContatoTipo.link => (TextInputType.url, null),
    };
    final erro = _erros[campo];
    return TextField(
      controller: _campos[campo],
      autofocus: widget.contato == null && campo == ContatoCampo.values.first,
      keyboardType: teclado,
      inputFormatters: formatadores,
      // Telefone aceita a pontuação digitada (gravado só com os dígitos).
      maxLength: campo.tipo == ContatoTipo.telefone ? campo.maximo + 5 : campo.maximo,
      textInputAction: campo == ContatoCampo.values.last ? TextInputAction.done : TextInputAction.next,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: strings.translate(campo.rotulo),
        prefixIcon: ComunidadeContatoView.icone(campo.icone, Icons.contact_page_outlined),
        errorText: erro == null ? null : strings.translate(erro),
        counterText: '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final erro = _erro;

    return ConfiguracaoDialogLayout(
      onSave: _confirmar,
      fields: [
        Text(widget.comunidadeNome, style: Theme.of(context).textTheme.titleSmall),
        for (final campo in ContatoCampo.values) _campo(strings, campo),
        if (erro != null) Text(strings.translate(erro), style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ],
    );
  }
}
