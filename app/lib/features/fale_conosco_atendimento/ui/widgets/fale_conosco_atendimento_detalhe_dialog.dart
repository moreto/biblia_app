import 'package:app/config/command.dart';
import 'package:app/config/dialog_sheet.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:components/components.dart'
    show DialogBottomSheetWarning, DialogWarning, DialogBottomSheetTypeButtons, DialogBottomSheetStatus;
import 'package:flutter/material.dart';

import '../../../../data/model/fale_conosco/fale_conosco_atendimento_model.dart';
import '../../use_case/fale_conosco_atendimento_usecase.dart';
import '../fale_conosco_atendimento_view.dart';
import '../fale_conosco_atendimento_viewmodel.dart';

/// Chamado aberto no atendimento ([show], no `DialogBottomSheet`, com o assunto no topo):
///
/// - Contato: nome, e-mail, telefone, origem, protocolo, envio, primeira resposta e fechamento; "Dados técnicos"
///   (página de origem, IP e navegador) recolhidos.
/// - Classificação: categoria, prioridade e situação, com "Salvar" quando algo muda.
/// - Responsável: nome (ou "Sem responsável"), "Assumir" (se não for o usuário logado) e "Liberar".
/// - Conversa: a mensagem original e as interações; as do solicitante à direita, as do atendimento à esquerda e as
///   notas internas destacadas ("Nota interna", não vistas pelo solicitante).
/// - Responder: texto, "Nota interna" e a situação depois de responder (começa na atual).
/// - Ações: "Fechar chamado" ou "Reabrir", "Excluir" (com confirmação; fecha o detalhe e avisa na tela) e "Fechar".
/// - Gravações concluídas e erros aparecem num aviso dentro do detalhe.
///
/// Ícones: os de [FaleConoscoAtendimentoView] e [iconeContato], [iconeTelefone], [iconeClassificar], [iconeAssumir],
/// [iconeLiberar], [iconeNotaInterna], [iconeSolicitante], [iconeAtendente], [iconeEnviar], [iconeFecharChamado],
/// [iconeReabrir], [iconeExcluir] e [iconeTecnico].
class FaleConoscoAtendimentoDetalheDialog extends StatefulWidget {
  const FaleConoscoAtendimentoDetalheDialog({
    super.key,
    required this.viewModel,
    required this.chamado,
    this.onExcluido,
  });

  final FaleConoscoAtendimentoViewmodel viewModel;

  /// Chamado da fila (para o cabeçalho enquanto o detalhe carrega).
  final FaleConoscoAtendimentoModel chamado;

  /// Chamado depois de excluir e fechar o detalhe.
  final VoidCallback? onExcluido;

  static const iconeContato = 'email-outline';
  static const iconeTelefone = 'phone-outline';
  static const iconeClassificar = 'tag-edit-outline';
  static const iconeAssumir = 'account-arrow-right-outline';
  static const iconeLiberar = 'account-remove-outline';
  static const iconeNotaInterna = 'message-lock-outline';
  static const iconeSolicitante = 'account-outline';
  static const iconeAtendente = 'face-agent';
  static const iconeEnviar = 'send';
  static const iconeFecharChamado = 'lock-outline';
  static const iconeReabrir = 'lock-open-variant-outline';
  static const iconeExcluir = 'delete-outline';
  static const iconeTecnico = 'web-box';

  static Future<void> show(
    BuildContext context, {
    required FaleConoscoAtendimentoViewmodel viewModel,
    required FaleConoscoAtendimentoModel chamado,
  }) {
    viewModel.fecharDetalhe();
    viewModel.detalheCommand.execute(chamado.fconId);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final strings = AppLocalizations.of(context);
    return DialogSheet.show<void>(
      context,
      titulo: chamado.fconAssunto,
      conteudo: FaleConoscoAtendimentoDetalheDialog(
        viewModel: viewModel,
        chamado: chamado,
        onExcluido: () => messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(strings.translate(FaleConoscoAtendimentoUseCase.kExcluido)))),
      ),
    );
  }

  @override
  State<FaleConoscoAtendimentoDetalheDialog> createState() => _FaleConoscoAtendimentoDetalheDialogState();
}

class _FaleConoscoAtendimentoDetalheDialogState extends State<FaleConoscoAtendimentoDetalheDialog> {
  final _resposta = TextEditingController();

  /// Classificação editada; nulo = valor atual do chamado.
  int? _categoria;
  int? _prioridade;
  int? _situacao;

  /// Resposta: nota interna e situação depois de responder (nula = atual).
  bool _interna = false;
  int? _situacaoResposta;

  /// Aviso dentro do detalhe (chave de tradução) e se é erro.
  ({String chave, bool erro})? _aviso;

  FaleConoscoAtendimentoViewmodel get _vm => widget.viewModel;

  /// Comandos de gravação; a mensagem de sucesso da resposta depende de ter sido nota interna.
  List<Command> get _gravacoes => [_vm.responderCommand, _vm.classificarCommand, _vm.acaoCommand, _vm.excluirCommand];

  @override
  void initState() {
    super.initState();
    for (final c in _gravacoes) {
      c.addListener(_onGravar);
    }
  }

  @override
  void dispose() {
    for (final c in _gravacoes) {
      c.removeListener(_onGravar);
    }
    _resposta.dispose();
    super.dispose();
  }

  void _onGravar() {
    if (!mounted) return;
    for (final command in _gravacoes) {
      if (command.running) continue;
      if (command.error) {
        final mensagem = FaleConoscoAtendimentoView.mensagemErro(_vm, command.result);
        command.clearResult();
        setState(() => _aviso = (chave: mensagem, erro: true));
      } else if (command.completed) {
        command.clearResult();
        if (command == _vm.excluirCommand) {
          Navigator.of(context).pop();
          widget.onExcluido?.call();
          return;
        }
        setState(() {
          if (command == _vm.responderCommand) {
            _aviso = (
              chave: _interna ? FaleConoscoAtendimentoUseCase.kNotaGravada : FaleConoscoAtendimentoUseCase.kRespondido,
              erro: false,
            );
            _resposta.clear();
            _interna = false;
            _situacaoResposta = null;
          } else {
            _aviso = (chave: FaleConoscoAtendimentoUseCase.kAtualizado, erro: false);
            _categoria = _prioridade = _situacao = null;
          }
        });
      }
    }
  }

  void _responder() {
    final erro = _vm.validarResposta(_resposta.text);
    if (erro != null) {
      setState(() => _aviso = (chave: erro, erro: true));
      return;
    }
    FocusScope.of(context).unfocus();
    _vm.responderCommand.execute((texto: _resposta.text, interna: _interna, situacao: _situacaoResposta));
  }

  void _excluir(FaleConoscoAtendimentoModel chamado) {
    final strings = AppLocalizations.of(context);
    DialogBottomSheetWarning(
      dialogWarning: DialogWarning(
        title: strings.translate('confirmarExclusao'),
        description:
            '${strings.translate('protocolo')} ${chamado.fconProtocolo}\n\n'
            '${strings.translate('confirmarExclusaoChamado')}',
        titleButtonPrimary: strings.translate('excluir'),
        titleButtonSecondary: strings.translate('cancelar'),
        typeButtonsDialog: DialogBottomSheetTypeButtons.horizontalButtons,
        statusDialog: DialogBottomSheetStatus.statusCritical,
        onPressedPrimary: () {
          Navigator.of(context).pop();
          _vm.excluirCommand.execute();
        },
        onPressedSecondary: () => Navigator.of(context).pop(),
      ),
    ).showModal(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final strings = AppLocalizations.of(context);
        final detalhe = _vm.detalhe;
        final command = _vm.detalheCommand;
        final chamado = detalhe?.chamado ?? widget.chamado;
        final aviso = _aviso;
        final scheme = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_vm.gravando) const LinearProgressIndicator(),
            _contato(chamado, strings),
            if (detalhe == null && command.error)
              _erroCarregamento(strings)
            else if (detalhe == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              const Divider(height: 24),
              _classificacao(chamado, strings),
              const SizedBox(height: 8),
              _responsavel(chamado, strings),
              const Divider(height: 24),
              _conversa(detalhe, strings),
              const SizedBox(height: 12),
              _campoResposta(chamado, strings),
            ],
            if (aviso != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  strings.translate(aviso.chave),
                  style: TextStyle(color: aviso.erro ? scheme.error : scheme.primary),
                ),
              ),
            DialogSheet.acoes([
              if (detalhe != null) ...[
                TextButton.icon(
                  onPressed: _vm.gravando ? null : () => _excluir(chamado),
                  style: TextButton.styleFrom(foregroundColor: scheme.error),
                  icon: FaleConoscoAtendimentoView.icone(
                    FaleConoscoAtendimentoDetalheDialog.iconeExcluir,
                    Icons.delete_outline,
                  ),
                  label: Text(strings.translate('excluir')),
                ),
                chamado.fechado
                    ? TextButton.icon(
                        onPressed: _vm.gravando
                            ? null
                            : () => _vm.acaoCommand.execute(FaleConoscoAtendimentoAcao.reabrir),
                        icon: FaleConoscoAtendimentoView.icone(
                          FaleConoscoAtendimentoDetalheDialog.iconeReabrir,
                          Icons.lock_open_outlined,
                        ),
                        label: Text(strings.translate('reabrirChamado')),
                      )
                    : TextButton.icon(
                        onPressed: _vm.gravando
                            ? null
                            : () => _vm.acaoCommand.execute(FaleConoscoAtendimentoAcao.fechar),
                        icon: FaleConoscoAtendimentoView.icone(
                          FaleConoscoAtendimentoDetalheDialog.iconeFecharChamado,
                          Icons.lock_outline,
                        ),
                        label: Text(strings.translate('fecharChamado')),
                      ),
              ],
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(strings.translate('fechar'))),
            ]),
          ],
        );
      },
    );
  }

  Widget _contato(FaleConoscoAtendimentoModel chamado, AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final secundario = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final telefone = chamado.fconTelefone?.trim();
    final linhas = [
      '${strings.translate('protocolo')}: ${chamado.fconProtocolo}',
      if (chamado.fconOrigem != null)
        '${strings.translate('origem')}: ${strings.translate(_vm.origem(chamado.fconOrigem))}',
      if (_vm.data(chamado.createdAt) case final d?) '${strings.translate('enviadoEm')}: $d',
      if (_vm.data(chamado.fconPrimeiraRespostaEm) case final d?)
        '${strings.translate('primeiraResposta')}: $d (${_vm.duracao(chamado.fconTempoResposta) ?? '-'})',
      if (_vm.data(chamado.fconFechadoEm) case final d?) '${strings.translate('fechadoEm')}: $d',
    ];
    final tecnicos = [
      if (chamado.fconPaginaOrigem case final p? when p.trim().isNotEmpty) '${strings.translate('paginaOrigem')}: $p',
      if (chamado.fconIp case final ip? when ip.trim().isNotEmpty) 'IP: $ip',
      if (chamado.fconUserAgent case final ua? when ua.trim().isNotEmpty) '${strings.translate('navegador')}: $ua',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(chamado.fconNome, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Row(
          children: [
            FaleConoscoAtendimentoView.icone(
              FaleConoscoAtendimentoDetalheDialog.iconeContato,
              Icons.mail_outline,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Flexible(child: SelectableText(chamado.fconEmail, style: textTheme.bodyMedium)),
          ],
        ),
        if (telefone != null && telefone.isNotEmpty)
          Row(
            children: [
              FaleConoscoAtendimentoView.icone(
                FaleConoscoAtendimentoDetalheDialog.iconeTelefone,
                Icons.phone_outlined,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Flexible(child: SelectableText(telefone, style: textTheme.bodyMedium)),
            ],
          ),
        const SizedBox(height: 4),
        for (final l in linhas) Text(l, style: secundario),
        if (tecnicos.isNotEmpty)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              dense: true,
              leading: FaleConoscoAtendimentoView.icone(
                FaleConoscoAtendimentoDetalheDialog.iconeTecnico,
                Icons.public,
                size: 18,
              ),
              title: Text(strings.translate('dadosTecnicos'), style: textTheme.bodyMedium),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final t in tecnicos) SelectableText(t, style: secundario)],
            ),
          ),
      ],
    );
  }

  Widget _erroCarregamento(AppLocalizations strings) {
    final command = _vm.detalheCommand;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Text(
            strings.translate(FaleConoscoAtendimentoView.mensagemErro(_vm, command.result)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: command.running ? null : () => command.execute(widget.chamado.fconId),
            icon: FaleConoscoAtendimentoView.icone(FaleConoscoAtendimentoView.iconeAtualizar, Icons.refresh),
            label: Text(strings.translate('tentarNovamente')),
          ),
        ],
      ),
    );
  }

  Widget _classificacao(FaleConoscoAtendimentoModel chamado, AppLocalizations strings) {
    final opcoes = _vm.opcoes;
    final categoria = _categoria ?? chamado.fconCategoria;
    final prioridade = _prioridade ?? chamado.fconPrioridade;
    final situacao = _situacao ?? chamado.fconStatus;
    final mudou =
        categoria != chamado.fconCategoria || prioridade != chamado.fconPrioridade || situacao != chamado.fconStatus;
    final habilitado = !_vm.gravando;

    Widget campo(String rotulo, int valor, List<FaleConoscoAtendimentoOpcao> itens, ValueChanged<int?> onChanged) =>
        DropdownButtonFormField<int>(
          key: ValueKey('$rotulo-${chamado.fconId}-$valor-${chamado.updatedAt}'),
          initialValue: itens.any((o) => o.chave == valor) ? valor : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: strings.translate(rotulo), isDense: true),
          items: [for (final o in itens) DropdownMenuItem(value: o.chave, child: Text(strings.translate(o.rotulo)))],
          onChanged: habilitado ? onChanged : null,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            FaleConoscoAtendimentoView.icone(
              FaleConoscoAtendimentoDetalheDialog.iconeClassificar,
              Icons.sell_outlined,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(strings.translate('classificacao'), style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 8),
        campo('categoria', categoria, opcoes.categorias, (v) => setState(() => _categoria = v)),
        const SizedBox(height: 8),
        campo('prioridade', prioridade, opcoes.prioridades, (v) => setState(() => _prioridade = v)),
        const SizedBox(height: 8),
        campo('situacao', situacao, opcoes.situacoes, (v) => setState(() => _situacao = v)),
        if (mudou)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FilledButton.tonal(
                onPressed: habilitado
                    ? () => _vm.classificarCommand.execute((
                        categoria: categoria,
                        prioridade: prioridade,
                        situacao: situacao,
                      ))
                    : null,
                child: Text(strings.translate('salvar')),
              ),
            ),
          ),
      ],
    );
  }

  Widget _responsavel(FaleConoscoAtendimentoModel chamado, AppLocalizations strings) {
    final nome = chamado.fconResponsavelNome?.trim();
    final temResponsavel = chamado.fconResponsavelId != null;
    final habilitado = !_vm.gravando;
    return Row(
      children: [
        FaleConoscoAtendimentoView.icone(FaleConoscoAtendimentoView.iconeResponsavel, Icons.badge_outlined, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${strings.translate('responsavel')}: '
            '${temResponsavel ? ((nome?.isNotEmpty ?? false) ? nome! : '#${chamado.fconResponsavelId}') : strings.translate('semResponsavel')}',
          ),
        ),
        if (!_vm.meuChamado)
          TextButton.icon(
            onPressed: habilitado ? () => _vm.acaoCommand.execute(FaleConoscoAtendimentoAcao.assumir) : null,
            icon: FaleConoscoAtendimentoView.icone(
              FaleConoscoAtendimentoDetalheDialog.iconeAssumir,
              Icons.assignment_ind_outlined,
              size: 18,
            ),
            label: Text(strings.translate('assumir')),
          ),
        if (temResponsavel)
          TextButton.icon(
            onPressed: habilitado ? () => _vm.acaoCommand.execute(FaleConoscoAtendimentoAcao.liberar) : null,
            icon: FaleConoscoAtendimentoView.icone(
              FaleConoscoAtendimentoDetalheDialog.iconeLiberar,
              Icons.person_remove_outlined,
              size: 18,
            ),
            label: Text(strings.translate('liberar')),
          ),
      ],
    );
  }

  Widget _conversa(FaleConoscoAtendimentoDetalhe detalhe, AppLocalizations strings) {
    final chamado = detalhe.chamado;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _balao(
          texto: chamado.fconMensagem,
          autor: chamado.fconNome,
          quando: chamado.createdAt,
          lado: _Lado.solicitante,
        ),
        for (final i in detalhe.interacoes)
          _balao(
            texto: i.fcinTexto,
            autor: (i.udetNome?.trim().isNotEmpty ?? false) ? i.udetNome!.trim() : strings.translate('atendimento'),
            quando: i.createdAt,
            lado: i.fcinInterna
                ? _Lado.nota
                : (chamado.usuaId != null && i.usuaId == chamado.usuaId)
                ? _Lado.solicitante
                : _Lado.atendimento,
            rotuloNota: strings.translate('notaInterna'),
          ),
      ],
    );
  }

  Widget _balao({
    required String texto,
    required String autor,
    required DateTime? quando,
    required _Lado lado,
    String? rotuloNota,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final (fundo, cor, icone, fallback) = switch (lado) {
      _Lado.solicitante => (
        scheme.surfaceContainerHighest,
        scheme.onSurface,
        FaleConoscoAtendimentoDetalheDialog.iconeSolicitante,
        Icons.person_outline,
      ),
      _Lado.atendimento => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        FaleConoscoAtendimentoDetalheDialog.iconeAtendente,
        Icons.support_agent,
      ),
      _Lado.nota => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        FaleConoscoAtendimentoDetalheDialog.iconeNotaInterna,
        Icons.lock_outline,
      ),
    };
    final direita = lado != _Lado.solicitante;
    final cabecalho = [if (lado == _Lado.nota) ?rotuloNota, autor, ?_vm.data(quando)].join(' · ');
    return Align(
      alignment: direita ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: EdgeInsets.only(top: 8, left: direita ? 32 : 0, right: direita ? 0 : 32),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaleConoscoAtendimentoView.icone(icone, fallback, size: 16, color: cor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    cabecalho,
                    style: textTheme.labelSmall?.copyWith(color: cor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SelectableText(texto.trim(), style: textTheme.bodyMedium?.copyWith(color: cor, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _campoResposta(FaleConoscoAtendimentoModel chamado, AppLocalizations strings) {
    final enviando = _vm.responderCommand.running;
    final situacoes = _vm.opcoes.situacoes;
    final situacao = _situacaoResposta ?? chamado.fconStatus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _resposta,
          enabled: !enviando,
          maxLength: _vm.textoMaximo,
          minLines: 2,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: strings.translate(_interna ? 'notaInterna' : 'responder'),
            alignLabelWithHint: true,
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _interna,
          onChanged: enviando ? null : (v) => setState(() => _interna = v),
          secondary: FaleConoscoAtendimentoView.icone(
            FaleConoscoAtendimentoDetalheDialog.iconeNotaInterna,
            Icons.lock_outline,
          ),
          title: Text(strings.translate('notaInterna')),
          subtitle: Text(strings.translate('notaInternaDica')),
        ),
        if (situacoes.isNotEmpty)
          DropdownButtonFormField<int>(
            key: ValueKey('situacaoResposta-${chamado.fconId}-$situacao-${chamado.updatedAt}'),
            initialValue: situacoes.any((o) => o.chave == situacao) ? situacao : null,
            isExpanded: true,
            decoration: InputDecoration(labelText: strings.translate('situacaoAposResponder'), isDense: true),
            items: [
              for (final o in situacoes) DropdownMenuItem(value: o.chave, child: Text(strings.translate(o.rotulo))),
            ],
            onChanged: enviando ? null : (v) => setState(() => _situacaoResposta = v),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: enviando || _vm.gravando ? null : _responder,
            icon: enviando
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : FaleConoscoAtendimentoView.icone(FaleConoscoAtendimentoDetalheDialog.iconeEnviar, Icons.send),
            label: Text(strings.translate('enviar')),
          ),
        ),
      ],
    );
  }
}

/// Quem escreveu a mensagem da conversa.
enum _Lado { solicitante, atendimento, nota }
