import 'package:app/config/command.dart';
import 'package:app/config/icons_map.dart';
import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:service/service.dart';

import '../../../../data/model/leitura/leitura_agenda_atividade_model.dart';
import '../../../../data/model/leitura/leitura_agenda_model.dart';
import '../../../../data/model/leitura/leitura_model.dart';
import '../../../../data/model/leitura/leitura_participante_model.dart';
import '../../grupo_leitura_agenda/ui/grupo_leitura_agenda_view.dart';
import '../../grupo_leitura_agenda/ui/grupo_leitura_agenda_viewmodel.dart';
import '../../grupo_leitura_agenda/ui/widgets/grupo_leitura_agenda_form_dialog.dart';
import '../../grupo_leitura_atividade/ui/grupo_leitura_atividade_view.dart';
import '../../grupo_leitura_atividade/ui/grupo_leitura_atividade_viewmodel.dart';
import '../../grupo_leitura_atividade/ui/widgets/grupo_leitura_atividade_form_dialog.dart';
import '../../grupo_leitura_participante/ui/grupo_leitura_participante_view.dart';
import '../../grupo_leitura_participante/ui/grupo_leitura_participante_viewmodel.dart';
import '../../grupo_leitura_participante/ui/widgets/grupo_leitura_participante_adicionar_dialog.dart';
import '../use_case/grupo_leitura_usecase.dart';
import 'grupo_leitura_viewmodel.dart';
import 'widgets/grupo_leitura_form_dialog.dart';
import 'widgets/meus_grupos_leitura_tab.dart';

/// Grupos de leitura (`Routes.grupoLeitura`; tela própria), em abas ([GrupoLeituraAba]):
/// - "Meus grupos" ([MeusGruposLeituraTab]): grupos de que o usuário é dono ou participante (`GET /v1/leitura`).
///   O botão inferior "Novo grupo" abre o [GrupoLeituraFormDialog]; no grupo do usuário, tocar no card ou "Editar"
///   no menu altera e "Excluir" pede confirmação. "Participantes" e "Agenda" no menu abrem a aba com o grupo
///   selecionado.
/// - "Participantes" ([GrupoLeituraParticipanteView]): participantes do grupo selecionado no topo
///   (`/v1/leitura-participante`). O dono adiciona ("Adicionar participante", [GrupoLeituraParticipanteAdicionarDialog],
///   busca em `/v1/usuario/busca`) e remove; o participante pode sair do grupo.
/// - "Agenda" ([GrupoLeituraAgendaView]): itens da agenda do grupo selecionado (`/v1/leitura-agenda`); o dono
///   inclui ("Novo item", [GrupoLeituraAgendaFormDialog]), altera e exclui. "Atividades" no menu do item abre a aba
///   "Atividades" com ele selecionado.
/// - "Atividades" ([GrupoLeituraAtividadeView]): atividades do item da agenda selecionado
///   (`/v1/leitura-agenda-atividade`); o dono inclui ("Nova atividade", [GrupoLeituraAtividadeFormDialog]), altera,
///   marca como concluída e exclui.
///
/// As abas além da primeira carregam na primeira abertura e de novo depois que os grupos (ou a agenda, para
/// "Atividades") mudam. AppBar: tema, orientação e atualizar (recarrega a aba aberta). Erro numa atualização vira
/// SnackBar e mantém a lista; o do primeiro carregamento fica na aba. Gravações: sucesso em SnackBar, erro no aviso
/// de erro (inclusive `consentimentoNecessario`, quando falta o aceite de dados religiosos).
///
/// Ícones (em [IconsMap.mdiIcons]): as constantes `icone*` desta classe e o [GrupoLeituraAba.icone] de cada aba.
class GrupoLeituraView extends StatefulWidget {
  const GrupoLeituraView({
    super.key,
    required this.viewModel,
    required this.participanteViewModel,
    required this.agendaViewModel,
    required this.atividadeViewModel,
  });

  final GrupoLeituraViewmodel viewModel;

  /// Aba "Participantes".
  final GrupoLeituraParticipanteViewmodel participanteViewModel;

  /// Aba "Agenda".
  final GrupoLeituraAgendaViewmodel agendaViewModel;

  /// Aba "Atividades".
  final GrupoLeituraAtividadeViewmodel atividadeViewModel;

  /// Tela, cada grupo e lista vazia (também `func_icone`/`menu_icone` de /grupo-leitura).
  static const iconeGrupo = 'book-account-outline';
  static const iconeDescricao = 'text-long';
  static const iconeDono = 'account-star-outline';
  static const iconeParticipante = 'account-multiple-outline';
  static const iconeAgenda = 'calendar-month-outline';
  static const iconeAtividades = 'format-list-checks';
  static const iconeAtualizar = 'refresh';
  static const iconeAdicionar = 'plus';
  static const iconeAcoes = 'dots-vertical';
  static const iconeEditar = 'pencil-outline';
  static const iconeExcluir = 'delete-outline';

  /// Ícone de [IconsMap.mdiIcons] pela chave; usa [fallback] se a chave não estiver mapeada.
  static Widget icone(String chave, IconData fallback, {Color? color, double? size}) =>
      Icon(IconsMap.mdiIcons[chave] ?? fallback, color: color, size: size);

  /// Mensagem (chave de tradução) do erro do comando.
  static String mensagemErro(Result? result) {
    if (result case Error(error: final exception)) {
      if (exception is HandledException) return exception.message;
      if (exception is HttpServiceException) return exception.message ?? kDefaultAppError;
    }
    return kDefaultAppError;
  }

  @override
  State<GrupoLeituraView> createState() => _GrupoLeituraViewState();
}

class _GrupoLeituraViewState extends State<GrupoLeituraView> with SingleTickerProviderStateMixin {
  GrupoLeituraViewmodel get _vm => widget.viewModel;
  GrupoLeituraParticipanteViewmodel get _participanteVm => widget.participanteViewModel;
  GrupoLeituraAgendaViewmodel get _agendaVm => widget.agendaViewModel;
  GrupoLeituraAtividadeViewmodel get _atividadeVm => widget.atividadeViewModel;

  late final TabController _tabs = TabController(length: _vm.abas.length, vsync: this);

  List<Command> _comandos(GrupoLeituraView view) => [
    view.viewModel.gruposCommand,
    view.viewModel.salvarCommand,
    view.viewModel.excluirCommand,
    view.participanteViewModel.carregarCommand,
    view.participanteViewModel.selecionarCommand,
    view.participanteViewModel.adicionarCommand,
    view.participanteViewModel.removerCommand,
    view.agendaViewModel.carregarCommand,
    view.agendaViewModel.selecionarCommand,
    view.agendaViewModel.salvarCommand,
    view.agendaViewModel.excluirCommand,
    view.atividadeViewModel.carregarCommand,
    view.atividadeViewModel.selecionarGrupoCommand,
    view.atividadeViewModel.selecionarItemCommand,
    view.atividadeViewModel.salvarCommand,
    view.atividadeViewModel.concluirCommand,
    view.atividadeViewModel.excluirCommand,
  ];

  @override
  void initState() {
    super.initState();
    for (final command in _comandos(widget)) {
      command.addListener(_onResult);
    }
    _tabs.addListener(_onAba);
    _onAba();
  }

  @override
  void didUpdateWidget(covariant GrupoLeituraView oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final command in _comandos(oldWidget)) {
      command.removeListener(_onResult);
    }
    for (final command in _comandos(widget)) {
      command.addListener(_onResult);
    }
  }

  @override
  void dispose() {
    for (final command in _comandos(widget)) {
      command.removeListener(_onResult);
    }
    _tabs
      ..removeListener(_onAba)
      ..dispose();
    super.dispose();
  }

  /// Abas com carregamento sob demanda carregam ao serem abertas.
  void _onAba() {
    switch (_vm.abas[_tabs.index]) {
      case GrupoLeituraAba.grupos:
        break;
      case GrupoLeituraAba.participantes:
        _participanteVm.abrir();
      case GrupoLeituraAba.agenda:
        _agendaVm.abrir();
      case GrupoLeituraAba.atividades:
        _atividadeVm.abrir();
    }
  }

  /// Os grupos mudaram: as outras abas recarregam na próxima abertura (a aberta, já).
  void _gruposMudaram() {
    _participanteVm.invalidar();
    _agendaVm.invalidar();
    _atividadeVm.invalidar();
    _onAba();
  }

  void _onResult() {
    if (!mounted) return;

    // Atualizações: só o erro com a lista já carregada vira SnackBar; o do primeiro carregamento fica na aba.
    for (final (command, carregado) in [
      (_vm.gruposCommand, _vm.grupos != null),
      (_participanteVm.carregarCommand, _participanteVm.grupos != null),
      (_participanteVm.selecionarCommand, _participanteVm.grupos != null),
      (_agendaVm.carregarCommand, _agendaVm.grupos != null),
      (_agendaVm.selecionarCommand, _agendaVm.grupos != null),
      (_atividadeVm.carregarCommand, _atividadeVm.grupos != null),
      (_atividadeVm.selecionarGrupoCommand, _atividadeVm.grupos != null),
      (_atividadeVm.selecionarItemCommand, _atividadeVm.grupos != null),
    ]) {
      if (command.error && carregado) {
        final mensagem = GrupoLeituraView.mensagemErro(command.result);
        command.clearResult();
        _mostrarMensagem(mensagem);
      }
    }

    // Gravações: sucesso em SnackBar, erro no aviso de erro. [mudanca] diz quais abas precisam recarregar.
    for (final (command, sucesso, mudanca) in [
      (_vm.salvarCommand, 'registroSalvo', _Mudanca.grupos),
      (_vm.excluirCommand, 'registroExcluido', _Mudanca.grupos),
      (_participanteVm.adicionarCommand, 'registroSalvo', _Mudanca.nenhuma),
      (_participanteVm.removerCommand, 'registroExcluido', _Mudanca.nenhuma),
      (_agendaVm.salvarCommand, 'registroSalvo', _Mudanca.agenda),
      (_agendaVm.excluirCommand, 'registroExcluido', _Mudanca.agenda),
      (_atividadeVm.salvarCommand, 'registroSalvo', _Mudanca.nenhuma),
      (_atividadeVm.concluirCommand, 'registroSalvo', _Mudanca.nenhuma),
      (_atividadeVm.excluirCommand, 'registroExcluido', _Mudanca.nenhuma),
    ]) {
      if (command.error) {
        final mensagem = GrupoLeituraView.mensagemErro(command.result);
        command.clearResult();
        _mostrarErro(mensagem);
      } else if (command.completed) {
        command.clearResult();
        switch (mudanca) {
          case _Mudanca.grupos:
            _gruposMudaram();
          case _Mudanca.agenda:
            _atividadeVm.invalidar();
          case _Mudanca.nenhuma:
            break;
        }
        if (_participanteVm.saiuDoGrupo) {
          _participanteVm.confirmarSaida();
          _vm.gruposCommand.execute();
          _agendaVm.invalidar();
          _atividadeVm.invalidar();
          _mostrarMensagem('voceSaiuDoGrupo');
        } else {
          _mostrarMensagem(sucesso);
        }
      }
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate(mensagem))));
  }

  void _mostrarErro(String mensagem) {
    final strings = AppLocalizations.of(context);
    DialogBottomSheetWarning(
      dialogWarning: DialogWarning(
        title: strings.translate('error'),
        titleButtonPrimary: strings.translate('ok'),
        titleButtonSecondary: strings.translate('ok'),
        isDismissible: false,
        typeButtonsDialog: DialogBottomSheetTypeButtons.horizontalButtons,
        description: strings.translate(mensagem),
        statusDialog: DialogBottomSheetStatus.statusCritical,
        onPressedPrimary: () => Navigator.of(context).pop(),
        onPressedSecondary: () => Navigator.of(context).pop(),
      ),
    ).showModal(context);
  }

  /// Confirmação de exclusão/remoção: [resumo] identifica o registro e [aviso] (chave) explica o efeito.
  void _confirmar({required String resumo, required String aviso, required String botao, required VoidCallback onSim}) {
    final strings = AppLocalizations.of(context);
    DialogBottomSheetWarning(
      dialogWarning: DialogWarning(
        title: strings.translate('confirmarExclusao'),
        description: '$resumo\n\n${strings.translate(aviso)}',
        titleButtonPrimary: strings.translate(botao),
        titleButtonSecondary: strings.translate('cancelar'),
        typeButtonsDialog: DialogBottomSheetTypeButtons.horizontalButtons,
        statusDialog: DialogBottomSheetStatus.statusCritical,
        onPressedPrimary: () {
          Navigator.of(context).pop();
          onSim();
        },
        onPressedSecondary: () => Navigator.of(context).pop(),
      ),
    ).showModal(context);
  }

  // ações: grupos

  Future<void> _editarGrupo([LeituraModel? grupo]) async {
    final result = await GrupoLeituraFormDialog.show(
      context,
      validar: _vm.validar,
      nomeMax: _vm.nomeMax,
      descricaoMax: _vm.descricaoMax,
      grupo: grupo,
    );
    if (result != null) _vm.salvarCommand.execute(result);
  }

  void _excluirGrupo(LeituraModel grupo) => _confirmar(
    resumo: grupo.leitNome,
    aviso: 'confirmarExclusaoGrupoLeitura',
    botao: 'excluir',
    onSim: () => _vm.excluirCommand.execute(grupo),
  );

  void _verParticipantes(LeituraModel grupo) {
    final leitId = grupo.leitId;
    if (leitId == null) return;
    _participanteVm.selecionar(leitId);
    _tabs.animateTo(_vm.abas.indexOf(GrupoLeituraAba.participantes));
  }

  void _verAgenda(LeituraModel grupo) {
    final leitId = grupo.leitId;
    if (leitId == null) return;
    _agendaVm.selecionar(leitId);
    _tabs.animateTo(_vm.abas.indexOf(GrupoLeituraAba.agenda));
  }

  // ações: participantes

  Future<void> _adicionarParticipante() async {
    final grupo = _participanteVm.selecionado;
    if (grupo == null) return;
    await GrupoLeituraParticipanteAdicionarDialog.show(context, viewModel: _participanteVm, grupoNome: grupo.leitNome);
  }

  void _removerParticipante(LeituraParticipanteModel participante) {
    final saindo = _participanteVm.ehUsuarioLogado(participante);
    _confirmar(
      resumo: saindo
          ? (_participanteVm.selecionado?.leitNome ?? '')
          : (_participanteVm.nomeExibicao(udetNome: participante.udetNome, udetUsuario: participante.udetUsuario) ??
                '#${participante.usuaId}'),
      aviso: saindo ? 'confirmarSairDoGrupo' : 'confirmarRemocaoParticipante',
      botao: saindo ? 'sairDoGrupo' : 'remover',
      onSim: () => _participanteVm.removerCommand.execute(participante),
    );
  }

  // ações: agenda

  Future<void> _editarItem([LeituraAgendaModel? item]) async {
    final grupo = _agendaVm.selecionado;
    final leitId = item?.leitId ?? grupo?.leitId;
    if (leitId == null) return;
    final result = await GrupoLeituraAgendaFormDialog.show(
      context,
      viewModel: _agendaVm,
      leitId: leitId,
      grupoNome: grupo?.leitNome ?? '',
      item: item,
    );
    if (result != null) _agendaVm.salvarCommand.execute(result);
  }

  void _excluirItem(LeituraAgendaModel item) => _confirmar(
    resumo: [item.lageTitulo, _agendaVm.dataHora(item.lageDataHora)].whereType<String>().join('\n'),
    aviso: 'confirmarExclusaoItemAgenda',
    botao: 'excluir',
    onSim: () => _agendaVm.excluirCommand.execute(item),
  );

  void _verAtividades(LeituraAgendaModel item) {
    _atividadeVm.selecionar(item.leitId, lageId: item.lageId);
    _tabs.animateTo(_vm.abas.indexOf(GrupoLeituraAba.atividades));
  }

  // ações: atividades

  Future<void> _editarAtividade([LeituraAgendaAtividadeModel? atividade]) async {
    final item = _atividadeVm.item;
    final lageId = atividade?.lageId ?? item?.lageId;
    if (lageId == null) return;
    final result = await GrupoLeituraAtividadeFormDialog.show(
      context,
      viewModel: _atividadeVm,
      lageId: lageId,
      itemTitulo: item?.lageTitulo ?? '',
      atividade: atividade,
    );
    if (result != null) _atividadeVm.salvarCommand.execute(result);
  }

  void _excluirAtividade(LeituraAgendaAtividadeModel atividade) => _confirmar(
    resumo: [atividade.laatTexto, _atividadeVm.nomeLivro(atividade)].whereType<String>().join('\n'),
    aviso: 'confirmarExclusaoAtividade',
    botao: 'excluir',
    onSim: () => _atividadeVm.excluirCommand.execute(atividade),
  );

  // layout

  /// Botão inferior da aba aberta: "Novo grupo", "Adicionar participante", "Novo item" ou "Nova atividade".
  ViewBottomAction _botaoAdicionar(GrupoLeituraAba aba, AppLocalizations strings) {
    final icone = IconsMap.mdiIcons[GrupoLeituraView.iconeAdicionar] ?? Icons.add;
    return switch (aba) {
      GrupoLeituraAba.grupos => ViewBottomAction(
        text: strings.translate('novoGrupoLeitura'),
        icon: icone,
        isEnabled: _vm.grupos != null && !_vm.gravando,
        onPressed: () => _editarGrupo(),
      ),
      GrupoLeituraAba.participantes => ViewBottomAction(
        text: strings.translate('adicionarParticipante'),
        icon:
            IconsMap.mdiIcons[GrupoLeituraParticipanteAdicionarDialog.iconeAdicionar] ?? Icons.person_add_alt_outlined,
        isVisible: _participanteVm.podeAdicionar,
        isEnabled: _participanteVm.selecionado != null && !_participanteVm.ocupado,
        onPressed: _adicionarParticipante,
      ),
      GrupoLeituraAba.agenda => ViewBottomAction(
        text: strings.translate('novoItemAgenda'),
        icon: icone,
        isVisible: _agendaVm.podeAlterar,
        isEnabled: _agendaVm.selecionado != null && !_agendaVm.ocupado,
        onPressed: () => _editarItem(),
      ),
      GrupoLeituraAba.atividades => ViewBottomAction(
        text: strings.translate('novaAtividade'),
        icon: icone,
        isVisible: _atividadeVm.podeAlterar,
        isEnabled: _atividadeVm.item != null && !_atividadeVm.ocupado,
        onPressed: () => _editarAtividade(),
      ),
    };
  }

  Command0 _comandoDa(GrupoLeituraAba aba) => switch (aba) {
    GrupoLeituraAba.grupos => _vm.gruposCommand,
    GrupoLeituraAba.participantes => _participanteVm.carregarCommand,
    GrupoLeituraAba.agenda => _agendaVm.carregarCommand,
    GrupoLeituraAba.atividades => _atividadeVm.carregarCommand,
  };

  Widget _conteudo(GrupoLeituraAba aba) => switch (aba) {
    GrupoLeituraAba.grupos => MeusGruposLeituraTab(
      viewModel: _vm,
      onEditar: _editarGrupo,
      onExcluir: _excluirGrupo,
      onParticipantes: _verParticipantes,
      onAgenda: _verAgenda,
    ),
    GrupoLeituraAba.participantes => GrupoLeituraParticipanteView(
      viewModel: _participanteVm,
      onRemover: _removerParticipante,
    ),
    GrupoLeituraAba.agenda => GrupoLeituraAgendaView(
      viewModel: _agendaVm,
      onEditar: _editarItem,
      onExcluir: _excluirItem,
      onAtividades: _verAtividades,
    ),
    GrupoLeituraAba.atividades => GrupoLeituraAtividadeView(
      viewModel: _atividadeVm,
      onEditar: _editarAtividade,
      onExcluir: _excluirAtividade,
    ),
  };

  Widget _screen() {
    final strings = AppLocalizations.of(context);
    final abas = _vm.abas;
    final aba = abas[_tabs.index];
    final atual = _comandoDa(aba);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.translate('gruposLeitura')),
        elevation: 0,
        actions: [
          const ThemeModeButton(),
          const OrientationButton(),
          IconButton(
            tooltip: strings.translate('atualizar'),
            onPressed: atual.running ? null : atual.execute,
            icon: GrupoLeituraView.icone(GrupoLeituraView.iconeAtualizar, Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            for (final aba in abas)
              Tab(
                icon: GrupoLeituraView.icone(aba.icone, Icons.menu_book_outlined),
                text: strings.translate(aba.rotulo),
              ),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: TabBarView(controller: _tabs, children: [for (final aba in abas) _conteudo(aba)]),
      bottomNavigationBar: ViewBottomActions(
        optionButton2: _botaoAdicionar(aba, strings),
        backLabel: strings.translate('voltar'),
        hideActionsTooltip: strings.translate('ocultarAcoes'),
        showActionsTooltip: strings.translate('exibirAcoes'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, _participanteVm, _agendaVm, _atividadeVm, _tabs]),
      builder: (context, child) => _screen(),
    );
  }
}

/// O que uma gravação muda nas outras abas.
enum _Mudanca { nenhuma, grupos, agenda }
