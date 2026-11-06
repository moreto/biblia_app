import 'package:flutter/material.dart';

class ViewBottomAction {
  const ViewBottomAction({required this.text, this.onPressed, this.icon, this.isVisible = true, this.isEnabled = true});

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isVisible;
  final bool isEnabled;
}

class ViewBottomActions extends StatefulWidget {
  const ViewBottomActions({
    super.key,
    this.optionButton1,
    this.optionButton2,
    this.isVisible = true,
    this.initiallyExpanded = true,
    this.backLabel = 'Voltar',
    this.hideActionsTooltip = 'Ocultar ações inferiores',
    this.showActionsTooltip = 'Exibir ações inferiores',
  });

  final ViewBottomAction? optionButton1;
  final ViewBottomAction? optionButton2;
  final bool isVisible;
  final bool initiallyExpanded;
  final String backLabel;
  final String hideActionsTooltip;
  final String showActionsTooltip;

  @override
  State<ViewBottomActions> createState() => _ViewBottomActionsState();
}

class _ViewBottomActionsState extends State<ViewBottomActions> {
  late bool _isExpanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final actions = [
      if (widget.optionButton1 case final action? when action.isVisible)
        _ActionButton(action: action, style: _ActionButtonStyle.elevated),
      if (widget.optionButton2 case final action? when action.isVisible)
        _ActionButton(action: action, style: _ActionButtonStyle.filled),
    ];

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: _isExpanded ? widget.hideActionsTooltip : widget.showActionsTooltip,
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
              icon: Icon(_isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  for (final action in actions) ...[Expanded(child: action), const SizedBox(width: 8)],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(widget.backLabel),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

enum _ActionButtonStyle { elevated, filled }

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.style});

  final ViewBottomAction action;
  final _ActionButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final onPressed = action.isEnabled ? action.onPressed : null;
    final label = Text(action.text, textAlign: TextAlign.center);
    final icon = action.icon;

    if (style == _ActionButtonStyle.elevated) {
      return icon == null
          ? ElevatedButton(onPressed: onPressed, child: label)
          : ElevatedButton.icon(onPressed: onPressed, icon: Icon(icon), label: label);
    }

    return icon == null
        ? FilledButton(onPressed: onPressed, child: label)
        : FilledButton.icon(onPressed: onPressed, icon: Icon(icon), label: label);
  }
}
