import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../usuario_view.dart';
import '../usuario_viewmodel.dart';

/// Aba "Senha" da tela "Meus dados": senha atual, nova senha e confirmação, com o botão de exibir/ocultar. Os
/// campos ficam na [UsuarioView], que troca a senha pelo botão inferior ou pelo "concluir" do teclado
/// ([onAlterar]) e limpa os campos depois da troca.
class UsuarioSenhaTab extends StatefulWidget {
  const UsuarioSenhaTab({
    super.key,
    required this.viewModel,
    required this.formKey,
    required this.senhaAtualController,
    required this.novaSenhaController,
    required this.confirmacaoController,
    required this.onAlterar,
  });

  final UsuarioViewmodel viewModel;
  final GlobalKey<FormState> formKey;
  final TextEditingController senhaAtualController;
  final TextEditingController novaSenhaController;
  final TextEditingController confirmacaoController;
  final VoidCallback onAlterar;

  @override
  State<UsuarioSenhaTab> createState() => _UsuarioSenhaTabState();
}

class _UsuarioSenhaTabState extends State<UsuarioSenhaTab> {
  bool _visivel = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final vm = widget.viewModel;
    final habilitado = !vm.ocupado;
    String? traduzir(String? chave) => chave == null ? null : strings.translate(chave);

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UsuarioView.icone(
                UsuarioView.iconeInformacao,
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(strings.translate('alterarSenhaIntro'), style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AutofillGroup(
              child: Form(
                key: widget.formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: widget.senhaAtualController,
                      enabled: habilitado,
                      obscureText: !_visivel,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: strings.translate('senhaAtual'),
                        hintText: strings.translate('informeSenhaAtual'),
                        prefixIcon: UsuarioView.icone(UsuarioView.iconeSenha, Icons.lock_outline),
                        suffixIcon: _visibilidade(strings),
                      ),
                      validator: (valor) => traduzir(vm.validateSenhaAtual(valor)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: widget.novaSenhaController,
                      enabled: habilitado,
                      obscureText: !_visivel,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: strings.translate('novaSenha'),
                        hintText: strings.translate('informeNovaSenha'),
                        helperText: strings.translate('senhaMinimo6'),
                        prefixIcon: UsuarioView.icone(UsuarioView.iconeNovaSenha, Icons.lock_outline),
                      ),
                      validator: (valor) => traduzir(vm.validateNovaSenha(widget.senhaAtualController.text, valor)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: widget.confirmacaoController,
                      enabled: habilitado,
                      obscureText: !_visivel,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => widget.onAlterar(),
                      decoration: InputDecoration(
                        labelText: strings.translate('confirmeNovaSenha'),
                        hintText: strings.translate('informeConfirmacaoSenha'),
                        prefixIcon: UsuarioView.icone(UsuarioView.iconeConfirmacao, Icons.lock_outline),
                      ),
                      validator: (valor) => traduzir(vm.validateConfirmacao(widget.novaSenhaController.text, valor)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _visibilidade(AppLocalizations strings) => IconButton(
    tooltip: strings.translate(_visivel ? 'ocultarSenha' : 'exibirSenha'),
    onPressed: () => setState(() => _visivel = !_visivel),
    icon: _visivel
        ? UsuarioView.icone(UsuarioView.iconeOcultar, Icons.visibility_off_outlined)
        : UsuarioView.icone(UsuarioView.iconeExibir, Icons.visibility_outlined),
  );
}
