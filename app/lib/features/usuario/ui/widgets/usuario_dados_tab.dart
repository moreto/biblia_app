import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../use_case/usuario_usecase.dart';
import '../usuario_view.dart';
import '../usuario_viewmodel.dart';

/// Aba "Dados cadastrais" da tela "Meus dados": cabeçalho (iniciais, nome, `@usuario` e situação da conta), e-mail e
/// identificador só leitura, e o formulário de nome completo e nome de usuário. Os campos ficam na
/// [UsuarioView], que grava pelo botão inferior ou pelo "concluir" do teclado ([onSalvar]).
class UsuarioDadosTab extends StatelessWidget {
  const UsuarioDadosTab({
    super.key,
    required this.viewModel,
    required this.formKey,
    required this.nomeController,
    required this.usuarioController,
    required this.onSalvar,
  });

  final UsuarioViewmodel viewModel;
  final GlobalKey<FormState> formKey;
  final TextEditingController nomeController;
  final TextEditingController usuarioController;
  final VoidCallback onSalvar;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final detalhe = viewModel.detalhe;
    if (detalhe == null) return const SizedBox.shrink();

    String? traduzir(String? chave) => chave == null ? null : strings.translate(chave);
    final habilitado = !viewModel.ocupado;

    return RefreshIndicator(
      onRefresh: viewModel.carregarCommand.execute,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _cabecalho(context, strings),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(strings.translate('meusDadosIntro'), style: Theme.of(context).textTheme.bodyMedium),
          ),
          Card(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Column(
              children: [
                _somenteLeitura(
                  context,
                  icone: UsuarioView.iconeEmail,
                  fallback: Icons.email_outlined,
                  titulo: strings.translate('email'),
                  valor: detalhe.usuaEmail,
                  ajuda: strings.translate('emailNaoAlteravel'),
                ),
                if (detalhe.usuaUuid.isNotEmpty)
                  _somenteLeitura(
                    context,
                    icone: UsuarioView.iconeIdentificador,
                    fallback: Icons.fingerprint,
                    titulo: strings.translate('identificadorConta'),
                    valor: detalhe.usuaUuid,
                  ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nomeController,
                      enabled: habilitado,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      maxLength: UsuarioUseCase.nomeMaximo,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: strings.translate('nomeCompleto'),
                        hintText: strings.translate('informeNomeCompleto'),
                        prefixIcon: UsuarioView.icone(UsuarioView.iconeNome, Icons.person_outline),
                      ),
                      validator: (valor) => traduzir(viewModel.validateNome(valor)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: usuarioController,
                      enabled: habilitado,
                      autofillHints: const [AutofillHints.username],
                      autocorrect: false,
                      enableSuggestions: false,
                      maxLength: UsuarioUseCase.usuarioMaximo,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => onSalvar(),
                      decoration: InputDecoration(
                        labelText: strings.translate('nomeUsuario'),
                        hintText: strings.translate('informeNomeUsuario'),
                        helperText: strings.translate('nomeUsuarioInvalido'),
                        helperMaxLines: 2,
                        prefixIcon: UsuarioView.icone(UsuarioView.iconeUsuario, Icons.alternate_email),
                      ),
                      validator: (valor) => traduzir(viewModel.validateUsuario(valor)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cabecalho(BuildContext context, AppLocalizations strings) {
    final detalhe = viewModel.detalhe!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final nome = detalhe.udetNome.isNotEmpty ? detalhe.udetNome : detalhe.usuaEmail;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: scheme.primary,
              child: Text(
                viewModel.iniciais,
                style: textTheme.titleLarge?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (detalhe.udetUsuario.isNotEmpty)
                    Text(
                      '@${detalhe.udetUsuario}',
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
                    ),
                  const SizedBox(height: 6),
                  _situacao(context, strings, detalhe.usuaAtivo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Etiqueta "Ativo" / "Inativo" da conta.
  Widget _situacao(BuildContext context, AppLocalizations strings, bool ativo) {
    final scheme = Theme.of(context).colorScheme;
    final fundo = ativo ? scheme.surface : scheme.errorContainer;
    final cor = ativo ? scheme.primary : scheme.onErrorContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ativo
              ? UsuarioView.icone(UsuarioView.iconeAtivo, Icons.check_circle, size: 16, color: cor)
              : UsuarioView.icone(UsuarioView.iconeInativo, Icons.error_outline, size: 16, color: cor),
          const SizedBox(width: 4),
          Text(
            '${strings.translate('situacao')}: ${strings.translate(ativo ? 'ativo' : 'inativo')}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cor),
          ),
        ],
      ),
    );
  }

  Widget _somenteLeitura(
    BuildContext context, {
    required String icone,
    required IconData fallback,
    required String titulo,
    required String valor,
    String? ajuda,
  }) {
    final secundario = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return ListTile(
      leading: UsuarioView.icone(icone, fallback),
      title: Text(titulo, style: secundario),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(valor, style: Theme.of(context).textTheme.bodyLarge),
          if (ajuda != null) Text(ajuda, style: secundario),
        ],
      ),
      trailing: UsuarioView.icone(
        UsuarioView.iconeSomenteLeitura,
        Icons.lock_outline,
        size: 18,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
