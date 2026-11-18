import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/biblia/livro_model.dart';
import '../../../../data/model/leitura/leitura_agenda_atividade_model.dart';
import '../../../../data/model/leitura/leitura_agenda_model.dart';
import '../../../../data/model/leitura/leitura_model.dart';
import '../use_case/grupo_leitura_atividade_usecase.dart';

/// Estado da aba "Atividades": atividades do item da agenda selecionado, no grupo selecionado.
///
/// - Carrega sob demanda: [abrir] executa [carregarCommand] (grupos, agenda do grupo, atividades do item e livros)
///   na primeira vez que a aba é aberta e depois de [invalidar] (grupos ou agenda mudaram).
/// - [selecionarGrupoCommand] troca o grupo (e o item vira o primeiro da agenda dele); [selecionarItemCommand]
///   troca o item. [selecionar] também serve antes do carregamento ("Atividades" no menu do item da agenda).
/// - [salvarCommand], [concluirCommand] (marca/desmarca) e [excluirCommand] gravam e recarregam as atividades.
class GrupoLeituraAtividadeViewmodel extends ChangeNotifier {
  GrupoLeituraAtividadeViewmodel({required this.grupoLeituraAtividadeUseCase}) {
    Log.print(super.runtimeType);
  }

  final GrupoLeituraAtividadeUseCase grupoLeituraAtividadeUseCase;

  late final Command0<void> carregarCommand = Command0(_carregar);
  late final Command1<void, int> selecionarGrupoCommand = Command1(_selecionarGrupo);
  late final Command1<void, int> selecionarItemCommand = Command1(_selecionarItem);
  late final Command1<LeituraAgendaAtividadeModel, LeituraAgendaAtividadeModel> salvarCommand = Command1(_salvar);
  late final Command1<LeituraAgendaAtividadeModel, LeituraAgendaAtividadeModel> concluirCommand = Command1(_concluir);
  late final Command1<void, LeituraAgendaAtividadeModel> excluirCommand = Command1(_excluir);

  List<LeituraModel>? _grupos;
  List<LeituraModel>? get grupos => _grupos;

  LeituraModel? _grupo;
  LeituraModel? get grupo => _grupo;

  List<LeituraAgendaModel> _agenda = const [];
  List<LeituraAgendaModel> get agenda => _agenda;

  LeituraAgendaModel? _item;
  LeituraAgendaModel? get item => _item;

  List<LeituraAgendaAtividadeModel> _atividades = const [];
  List<LeituraAgendaAtividadeModel> get atividades => _atividades;

  List<LivroModel> _livros = const [];
  List<LivroModel> get livros => _livros;

  int? _leitIdPedido;
  int? _lageIdPedido;
  bool _desatualizado = true;

  bool get ocupado =>
      carregarCommand.running ||
      selecionarGrupoCommand.running ||
      selecionarItemCommand.running ||
      salvarCommand.running ||
      concluirCommand.running ||
      excluirCommand.running;

  bool get podeAlterar => grupoLeituraAtividadeUseCase.podeAlterar(_grupo);

  int get concluidas => GrupoLeituraAtividadeUseCase.concluidas(_atividades);

  String? validar(LeituraAgendaAtividadeModel atividade) => grupoLeituraAtividadeUseCase.validar(atividade);

  String? nomeLivro(LeituraAgendaAtividadeModel atividade) =>
      GrupoLeituraAtividadeUseCase.nomeLivro(atividade, _livros);

  void abrir() {
    if (_desatualizado && !carregarCommand.running) carregarCommand.execute();
  }

  void invalidar() => _desatualizado = true;

  /// Seleciona o grupo [leitId] e, se informado, o item [lageId] dele.
  void selecionar(int leitId, {int? lageId}) {
    _leitIdPedido = leitId;
    _lageIdPedido = lageId;
    if (_grupos != null && !_desatualizado && !carregarCommand.running) {
      _desatualizado = true;
      carregarCommand.execute();
    }
  }

  Future<Result<void>> _carregar() async {
    notifyListeners();
    final result = await grupoLeituraAtividadeUseCase.grupos();
    switch (result) {
      case Ok<List<LeituraModel>>(value: final grupos):
        final grupo = grupoLeituraAtividadeUseCase.selecionado(grupos, _leitIdPedido ?? _grupo?.leitId);
        final mesmoGrupo = grupo?.leitId == _grupo?.leitId;
        final conteudo = await _conteudoDe(grupo, _lageIdPedido ?? (mesmoGrupo ? _item?.lageId : null));
        if (conteudo case Error(error: final error)) {
          notifyListeners();
          return Result.error(error);
        }
        final valor = (conteudo as Ok<_Conteudo>).value;
        _livros = await grupoLeituraAtividadeUseCase.livros();
        _grupos = grupos;
        _grupo = grupo;
        _agenda = valor.agenda;
        _item = valor.item;
        _atividades = valor.atividades;
        _leitIdPedido = null;
        _lageIdPedido = null;
        _desatualizado = false;
        notifyListeners();
        return const Result.ok(null);
      case Error<List<LeituraModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
        notifyListeners();
        return Result.error(error);
    }
  }

  Future<Result<void>> _selecionarGrupo(int leitId) async {
    final grupo = grupoLeituraAtividadeUseCase.selecionado(_grupos ?? const [], leitId);
    if (grupo?.leitId == _grupo?.leitId) return const Result.ok(null);
    notifyListeners();
    final result = await _conteudoDe(grupo, null);
    if (result case Ok(value: final valor)) {
      _grupo = grupo;
      _agenda = valor.agenda;
      _item = valor.item;
      _atividades = valor.atividades;
    }
    notifyListeners();
    return result;
  }

  Future<Result<void>> _selecionarItem(int lageId) async {
    final item = GrupoLeituraAtividadeUseCase.itemSelecionado(_agenda, lageId);
    if (item?.lageId == _item?.lageId) return const Result.ok(null);
    notifyListeners();
    final result = await _atividadesDe(item);
    if (result case Ok(value: final atividades)) {
      _item = item;
      _atividades = atividades;
    }
    notifyListeners();
    return result;
  }

  Future<Result<LeituraAgendaAtividadeModel>> _salvar(LeituraAgendaAtividadeModel atividade) async {
    notifyListeners();
    final result = await grupoLeituraAtividadeUseCase.salvar(_grupo, _item, atividade, _atividades);
    await _depoisDeGravar(result);
    return result;
  }

  Future<Result<LeituraAgendaAtividadeModel>> _concluir(LeituraAgendaAtividadeModel atividade) async {
    notifyListeners();
    final result = await grupoLeituraAtividadeUseCase.alternarConcluida(_grupo, atividade);
    await _depoisDeGravar(result);
    return result;
  }

  Future<Result<void>> _excluir(LeituraAgendaAtividadeModel atividade) async {
    notifyListeners();
    final result = await grupoLeituraAtividadeUseCase.excluir(_grupo, atividade);
    await _depoisDeGravar(result);
    return result;
  }

  /// Sucesso recarrega as atividades do item (falha na recarga mantém a lista); erro vai para o log.
  Future<void> _depoisDeGravar(Result result) async {
    switch (result) {
      case Ok():
        final atividades = await _atividadesDe(_item);
        if (atividades case Ok(value: final lista)) _atividades = lista;
      case Error(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
  }

  /// Agenda do [grupo], o item selecionado ([lageId] ou o primeiro) e as atividades dele.
  Future<Result<_Conteudo>> _conteudoDe(LeituraModel? grupo, int? lageId) async {
    final leitId = grupo?.leitId;
    if (leitId == null) return const Result.ok((agenda: [], item: null, atividades: []));
    final agenda = await grupoLeituraAtividadeUseCase.agenda(leitId);
    switch (agenda) {
      case Ok<List<LeituraAgendaModel>>(value: final lista):
        final item = GrupoLeituraAtividadeUseCase.itemSelecionado(lista, lageId);
        final atividades = await _atividadesDe(item);
        return switch (atividades) {
          Ok(value: final valor) => Result.ok((agenda: lista, item: item, atividades: valor)),
          Error(error: final error) => Result.error(error),
        };
      case Error<List<LeituraAgendaModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
        return Result.error(error);
    }
  }

  Future<Result<List<LeituraAgendaAtividadeModel>>> _atividadesDe(LeituraAgendaModel? item) async {
    final lageId = item?.lageId;
    if (lageId == null) return const Result.ok([]);
    final result = await grupoLeituraAtividadeUseCase.atividades(lageId);
    if (result case Error(error: final error)) Log.print(error.toString(), name: kApp, title: 'Erro');
    return result;
  }

  @override
  void dispose() {
    carregarCommand.dispose();
    selecionarGrupoCommand.dispose();
    selecionarItemCommand.dispose();
    salvarCommand.dispose();
    concluirCommand.dispose();
    excluirCommand.dispose();
    super.dispose();
  }
}

/// Agenda do grupo selecionado, o item selecionado e as atividades dele.
typedef _Conteudo = ({
  List<LeituraAgendaModel> agenda,
  LeituraAgendaModel? item,
  List<LeituraAgendaAtividadeModel> atividades,
});
