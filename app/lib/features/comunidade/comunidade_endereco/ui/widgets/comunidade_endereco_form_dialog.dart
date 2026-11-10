import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../data/model/comunidade/comunidade_endereco_model.dart';
import '../../../../../data/model/localidade/estado_model.dart';
import '../../../../../data/model/localidade/municipio_model.dart';
import '../../../../admin/configuracao/ui/widgets/configuracao_dialog_layout.dart';
import '../../use_case/comunidade_endereco_usecase.dart' show EnderecoLimites;
import '../comunidade_endereco_view.dart';

/// Formulário de inclusão/alteração do endereço da comunidade [comuId] ([comunidadeNome] aparece no topo):
/// CEP, logradouro, número (só dígitos), complemento, bairro, estado e município, com os tamanhos de [limites].
///
/// Estados e municípios vêm de [estados] e [municipios] (do viewmodel, com cache no use case); os municípios são
/// carregados ao escolher o estado. Ao salvar, [validar] (regra do use case) devolve a chave do problema, mostrada
/// no formulário; sem problema, retorna o [ComunidadeEnderecoModel] preenchido. `null` quando cancelado.
class ComunidadeEnderecoFormDialog extends StatefulWidget {
  const ComunidadeEnderecoFormDialog({
    super.key,
    required this.comuId,
    required this.comunidadeNome,
    required this.estados,
    required this.municipios,
    required this.validar,
    required this.limites,
    this.endereco,
  });

  final int comuId;
  final String comunidadeNome;
  final Future<Result<List<EstadoModel>>> Function() estados;
  final Future<Result<List<MunicipioModel>>> Function(int estaId) municipios;
  final String? Function(ComunidadeEnderecoModel) validar;

  /// Tamanhos máximos dos campos (regra do use case).
  final EnderecoLimites limites;

  /// Endereço em alteração; nulo na inclusão.
  final ComunidadeEnderecoModel? endereco;

  static Future<ComunidadeEnderecoModel?> show(
    BuildContext context, {
    required int comuId,
    required String comunidadeNome,
    required Future<Result<List<EstadoModel>>> Function() estados,
    required Future<Result<List<MunicipioModel>>> Function(int estaId) municipios,
    required String? Function(ComunidadeEnderecoModel) validar,
    required EnderecoLimites limites,
    ComunidadeEnderecoModel? endereco,
  }) => showDialog<ComunidadeEnderecoModel>(
    context: context,
    builder: (context) => ComunidadeEnderecoFormDialog(
      comuId: comuId,
      comunidadeNome: comunidadeNome,
      estados: estados,
      municipios: municipios,
      validar: validar,
      limites: limites,
      endereco: endereco,
    ),
  );

  @override
  State<ComunidadeEnderecoFormDialog> createState() => _ComunidadeEnderecoFormDialogState();
}

class _ComunidadeEnderecoFormDialogState extends State<ComunidadeEnderecoFormDialog> {
  late final _cep = TextEditingController(text: widget.endereco?.cendCep.replaceAll(RegExp(r'\D'), ''));
  late final _logradouro = TextEditingController(text: widget.endereco?.cendLogradouro);
  late final _numero = TextEditingController(text: widget.endereco?.cendNumero);
  late final _complemento = TextEditingController(text: widget.endereco?.cendComplemento);
  late final _bairro = TextEditingController(text: widget.endereco?.cendBairro);

  List<EstadoModel>? _estados;
  List<MunicipioModel>? _municipios;
  late int? _estaId = widget.endereco?.estaId;
  late int? _muniId = widget.endereco?.muniId;
  bool _carregandoMunicipios = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarEstados();
  }

  @override
  void dispose() {
    for (final controller in [_cep, _logradouro, _numero, _complemento, _bairro]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _carregarEstados() async {
    final result = await widget.estados();
    if (!mounted) return;
    switch (result) {
      case Ok(value: final estados):
        setState(() {
          _estados = estados;
          // Sem estaId (API antiga), tenta pela sigla do endereço.
          _estaId ??= estados.where((e) => e.estaSigla == widget.endereco?.estaSigla).firstOrNull?.estaId;
          if (!estados.any((e) => e.estaId == _estaId)) _estaId = null;
        });
        final estaId = _estaId;
        if (estaId != null) await _carregarMunicipios(estaId, manterSelecao: true);
      case Error(error: final error):
        setState(() {
          _estados = const [];
          _erro = error is HandledException ? error.message : 'erroApi';
        });
    }
  }

  Future<void> _carregarMunicipios(int estaId, {bool manterSelecao = false}) async {
    setState(() {
      _estaId = estaId;
      _municipios = null;
      _carregandoMunicipios = true;
      if (!manterSelecao) _muniId = null;
    });
    final result = await widget.municipios(estaId);
    if (!mounted || _estaId != estaId) return;
    setState(() {
      _carregandoMunicipios = false;
      switch (result) {
        case Ok(value: final municipios):
          _municipios = municipios;
          if (!municipios.any((m) => m.muniId == _muniId)) _muniId = null;
        case Error(error: final error):
          _municipios = const [];
          _erro = error is HandledException ? error.message : 'erroApi';
      }
    });
  }

  void _confirmar() {
    final endereco = ComunidadeEnderecoModel(
      cendId: widget.endereco?.cendId,
      comuId: widget.comuId,
      cendCep: _cep.text,
      cendLogradouro: _logradouro.text,
      cendNumero: _numero.text,
      cendComplemento: _complemento.text,
      cendBairro: _bairro.text,
      muniId: _muniId ?? 0,
    );
    final erro = widget.validar(endereco);
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    Navigator.of(context).pop(endereco);
  }

  TextField _campo(
    TextEditingController controller,
    String rotulo, {
    TextInputType? teclado,
    List<TextInputFormatter>? formatadores,
    int? maxLength,
    bool autofocus = false,
    Widget? prefixo,
  }) => TextField(
    controller: controller,
    autofocus: autofocus,
    keyboardType: teclado,
    inputFormatters: formatadores,
    maxLength: maxLength,
    textInputAction: TextInputAction.next,
    textCapitalization: teclado == null ? TextCapitalization.words : TextCapitalization.none,
    decoration: InputDecoration(labelText: AppLocalizations.of(context).translate(rotulo), prefixIcon: prefixo),
  );

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final novo = widget.endereco?.cendId == null;
    final estados = _estados;
    final municipios = _municipios;
    final erro = _erro;

    return ConfiguracaoDialogLayout(
      title: strings.translate(novo ? 'novoEndereco' : 'editarEndereco'),
      onSave: _confirmar,
      fields: [
        Text(widget.comunidadeNome, style: Theme.of(context).textTheme.titleSmall),
        _campo(
          _cep,
          'cep',
          teclado: TextInputType.number,
          formatadores: [FilteringTextInputFormatter.digitsOnly],
          maxLength: widget.limites.cep,
          autofocus: novo,
          prefixo: ComunidadeEnderecoView.icone(ComunidadeEnderecoView.iconeEndereco, Icons.place_outlined),
        ),
        _campo(_logradouro, 'logradouro', maxLength: widget.limites.logradouro),
        Row(
          children: [
            SizedBox(
              width: 110,
              child: _campo(
                _numero,
                'numero',
                teclado: TextInputType.number,
                formatadores: [FilteringTextInputFormatter.digitsOnly],
                maxLength: widget.limites.numero,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _campo(_complemento, 'complemento', maxLength: widget.limites.complemento)),
          ],
        ),
        _campo(_bairro, 'bairro', maxLength: widget.limites.bairro),
        DropdownButtonFormField<int>(
          key: ValueKey('estado-${estados?.length}'),
          initialValue: _estaId,
          isExpanded: true,
          decoration: InputDecoration(labelText: strings.translate('estado')),
          items: [
            for (final estado in estados ?? const <EstadoModel>[])
              DropdownMenuItem(value: estado.estaId, child: Text('${estado.estaSigla} · ${estado.estaNome}')),
          ],
          onChanged: estados == null ? null : (estaId) => estaId == null ? null : _carregarMunicipios(estaId),
        ),
        DropdownButtonFormField<int>(
          key: ValueKey('municipio-$_estaId-${municipios?.length}'),
          initialValue: _muniId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: strings.translate('municipio'),
            suffixIcon: _carregandoMunicipios
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
          ),
          items: [
            for (final municipio in municipios ?? const <MunicipioModel>[])
              DropdownMenuItem(
                value: municipio.muniId,
                child: Text(municipio.muniNome, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: municipios == null || municipios.isEmpty ? null : (muniId) => setState(() => _muniId = muniId),
        ),
        if (erro != null) Text(strings.translate(erro), style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ],
    );
  }
}
