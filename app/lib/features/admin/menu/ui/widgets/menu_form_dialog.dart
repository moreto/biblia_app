import 'package:app/config/icons_map.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../data/model/menu/menu_item_model.dart';
import '../../../configuracao/ui/widgets/configuracao_dialog_layout.dart';

/// Formulário de inclusão/alteração de item de menu.
/// Retorna o [MenuItemModel] preenchido ou `null` quando cancelado.
class MenuFormDialog extends StatefulWidget {
  const MenuFormDialog({super.key, required this.opcoesPai, this.menu, this.menuParentId});

  /// Menus que podem ser pai (já filtrados pelo use case).
  final List<MenuItemModel> opcoesPai;
  final MenuItemModel? menu;

  /// Pai sugerido na inclusão de submenu.
  final int? menuParentId;

  static Future<MenuItemModel?> show(
    BuildContext context, {
    required List<MenuItemModel> opcoesPai,
    MenuItemModel? menu,
    int? menuParentId,
  }) => showDialog<MenuItemModel>(
    context: context,
    builder: (context) => MenuFormDialog(opcoesPai: opcoesPai, menu: menu, menuParentId: menuParentId),
  );

  @override
  State<MenuFormDialog> createState() => _MenuFormDialogState();
}

class _MenuFormDialogState extends State<MenuFormDialog> {
  late final TextEditingController _nomeController = TextEditingController(text: widget.menu?.menuNome);
  late final TextEditingController _chaveController = TextEditingController(text: widget.menu?.menuChave);
  late final TextEditingController _iconeController = TextEditingController(text: widget.menu?.menuIcone)
    ..addListener(() => setState(() {}));
  late final TextEditingController _rotaController = TextEditingController(text: widget.menu?.menuRota);
  late final TextEditingController _sequenciaController = TextEditingController(
    text: widget.menu?.menuSequencia?.toString(),
  );
  late int? _menuParentId = widget.menu?.menuParentId ?? widget.menuParentId;
  late bool _ativo = widget.menu?.menuAtivo ?? true;

  @override
  void dispose() {
    _nomeController.dispose();
    _chaveController.dispose();
    _iconeController.dispose();
    _rotaController.dispose();
    _sequenciaController.dispose();
    super.dispose();
  }

  void _confirmar() {
    Navigator.of(context).pop(
      MenuItemModel(
        menuId: widget.menu?.menuId,
        menuNome: _nomeController.text,
        menuChave: _chaveController.text,
        menuIcone: _iconeController.text,
        menuSequencia: int.tryParse(_sequenciaController.text),
        menuParentId: _menuParentId,
        menuRota: _rotaController.text,
        menuAtivo: _ativo,
        children: widget.menu?.children ?? const [],
        createdAt: widget.menu?.createdAt,
        updatedAt: widget.menu?.updatedAt,
      ),
    );
  }

  Widget _iconePreview() {
    final chave = _iconeController.text.trim();
    if (chave.isEmpty) return const Icon(Icons.image_outlined);
    final icon = IconsMap.mdiIcons[chave];
    if (icon == null) {
      return Tooltip(
        message: AppLocalizations.of(context).translate('iconeNaoEncontrado'),
        child: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
      );
    }
    return Icon(icon, color: Theme.of(context).colorScheme.primary);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isNovo = widget.menu?.menuId == null;
    // o pai atual pode ter sido filtrado (ex.: inativo); mantém a opção para não perder o vínculo
    final opcoes = [
      ...widget.opcoesPai,
      if (_menuParentId != null && widget.opcoesPai.every((item) => item.menuId != _menuParentId))
        MenuItemModel(menuId: _menuParentId, menuNome: '#$_menuParentId', menuChave: ''),
    ];

    return ConfiguracaoDialogLayout(
      title: strings.translate(isNovo ? 'novoMenu' : 'editarMenu'),
      onSave: _confirmar,
      fields: [
        if (!isNovo) Text('${strings.translate('codigo')}: ${widget.menu!.menuId}'),
        DropdownButtonFormField<int?>(
          initialValue: _menuParentId,
          isExpanded: true,
          decoration: InputDecoration(labelText: strings.translate('menuPai')),
          items: [
            DropdownMenuItem<int?>(value: null, child: Text(strings.translate('menuRaiz'))),
            for (final pai in opcoes)
              DropdownMenuItem<int?>(
                value: pai.menuId,
                child: Text(pai.menuNome, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: opcoes.isEmpty ? null : (value) => setState(() => _menuParentId = value),
        ),
        TextField(
          controller: _nomeController,
          autofocus: isNovo,
          maxLength: 60,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: strings.translate('nome')),
        ),
        TextField(
          controller: _chaveController,
          maxLength: 30,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: strings.translate('chave')),
        ),
        TextField(
          controller: _iconeController,
          maxLength: 90,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: strings.translate('icone'),
            suffixIcon: Padding(padding: const EdgeInsets.all(12), child: _iconePreview()),
          ),
        ),
        // rota e sequência lado a lado
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _rotaController,
                maxLength: 60,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: strings.translate('rota'), hintText: '/rota'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _sequenciaController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: strings.translate('sequencia')),
              ),
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(strings.translate('ativo')),
          subtitle: _ativo ? null : Text(strings.translate('menuInativoOculto')),
          value: _ativo,
          onChanged: (value) => setState(() => _ativo = value),
        ),
      ],
    );
  }
}
