import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/leitura/leitura_agenda_model.dart';
import '../../../../data/model/leitura/leitura_model.dart';
import '../use_case/grupo_leitura_agenda_usecase.dart';

/// Estado da aba "Agenda": itens da agenda do grupo selecionado.
///
/// - Carrega sob demanda: [abrir] executa [carregarCommand] (grupos e agenda do selecionado) na primeira vez que a
///   aba é aberta e depois de [invalidar] (chamado quando os grupos mudam).
/// - [selecionarCommand] troca o grupo; [selecionar] também serve antes do carregamento ("Agenda" no menu do grupo).
/// - [salvarCommand] e [excluirCommand] gravam e recarregam a agenda; uma atualização que falha mantém a lista.
class GrupoLeituraAgendaViewmodel extends ChangeNotifier {
  GrupoLeituraAgendaViewmodel({required this.grupoLeituraAgendaUseCase}) {
    Log.print(super.runtimeType);
  }

  final GrupoLeituraAgendaUseCase grupoLeituraAgendaUseCase;

  late final Command0<void> carregarCommand = Command0(_carregar);
  late final Command1<void, int> selecionarCommand = Command1(_selecionar);
  late final Command1<LeituraAgendaModel, LeituraAgendaModel> salvarCommand = Command1(_salvar);
  late final Command1<void, LeituraAgendaModel> excluirCommand = Command1(_excluir);

  List<LeituraModel>? _grupos;
  List<LeituraModel>? get grupos => _grupos;

  LeituraModel? _selecionado;
  LeituraModel? get selecionado => _selecionado;

  int? _leitIdPedido;

  List<LeituraAgendaModel> _agenda = const [];
  List<LeituraAgendaModel> get agenda => _agenda;

  bool _desatualizado = true;

  bool get ocupado =>
      carregarCommand.running || selecionarCommand.running || salvarCommand.running || excluirCommand.running;

  bool get podeAlterar => grupoLeituraAgendaUseCase.podeAlterar(_selecionado);

  int get tituloMax => GrupoLeituraAgendaUseCase.kTituloMax;
  int get textoMax => GrupoLeituraAgendaUseCase.kTextoMax;

  String? validar(LeituraAgendaModel item) => grupoLeituraAgendaUseCase.validar(item);

  String? dataHora(DateTime? quando) => GrupoLeituraAgendaUseCase.dataHora(quando);
  String? data(DateTime? quando) => GrupoLeituraAgendaUseCase.data(quando);
  String? hora(String? valor) => GrupoLeituraAgendaUseCase.hora(valor);
  ({int hora, int minuto})? horaMinuto(String? valor) => GrupoLeituraAgendaUseCase.horaMinuto(valor);
  String horaApi(int hora, int minuto) => GrupoLeituraAgendaUseCase.horaApi(hora, minuto);
  DateTime? juntar(DateTime? data, ({int hora, int minuto})? hora) => GrupoLeituraAgendaUseCase.juntar(data, hora);

  void abrir() {
    if (_desatualizado && !carregarCommand.running) carregarCommand.execute();
  }

  void invalidar() => _desatualizado = true;

  void selecionar(int leitId) {
    if (_grupos != null && !_desatualizado && !carregarCommand.running) {
      selecionarCommand.execute(leitId);
    } else {
      _leitIdPedido = leitId;
    }
  }

  Future<Result<void>> _carregar() async {
    notifyListeners();
    final result = await grupoLeituraAgendaUseCase.grupos();
    switch (result) {
      case Ok<List<LeituraModel>>(value: final grupos):
        final selecionado = grupoLeituraAgendaUseCase.selecionado(grupos, _leitIdPedido ?? _selecionado?.leitId);
        final agenda = await _agendaDe(selecionado);
        if (agenda case Error(error: final error)) {
          notifyListeners();
          return Result.error(error);
        }
        _grupos = grupos;
        _selecionado = selecionado;
        _agenda = (agenda as Ok<List<LeituraAgendaModel>>).value;
        _leitIdPedido = null;
        _desatualizado = false;
        notifyListeners();
        return const Result.ok(null);
      case Error<List<LeituraModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
        notifyListeners();
        return Result.error(error);
    }
  }

  Future<Result<void>> _selecionar(int leitId) async {
    final selecionado = grupoLeituraAgendaUseCase.selecionado(_grupos ?? const [], leitId);
    if (selecionado?.leitId == _selecionado?.leitId) return const Result.ok(null);
    notifyListeners();
    final result = await _agendaDe(selecionado);
    if (result case Ok(value: final agenda)) {
      _selecionado = selecionado;
      _agenda = agenda;
    }
    notifyListeners();
    return result;
  }

  Future<Result<LeituraAgendaModel>> _salvar(LeituraAgendaModel item) async {
    notifyListeners();
    final result = await grupoLeituraAgendaUseCase.salvar(_selecionado, item);
    if (result is Ok) await _recarregarAgenda();
    if (result case Error(error: final error)) Log.print(error.toString(), name: kApp, title: 'Erro');
    notifyListeners();
    return result;
  }

  Future<Result<void>> _excluir(LeituraAgendaModel item) async {
    notifyListeners();
    final result = await grupoLeituraAgendaUseCase.excluir(_selecionado, item);
    if (result is Ok) await _recarregarAgenda();
    if (result case Error(error: final error)) Log.print(error.toString(), name: kApp, title: 'Erro');
    notifyListeners();
    return result;
  }

  Future<void> _recarregarAgenda() async {
    final result = await _agendaDe(_selecionado);
    if (result case Ok(value: final agenda)) _agenda = agenda;
  }

  Future<Result<List<LeituraAgendaModel>>> _agendaDe(LeituraModel? grupo) async {
    final leitId = grupo?.leitId;
    if (leitId == null) return const Result.ok([]);
    final result = await grupoLeituraAgendaUseCase.agenda(leitId);
    if (result case Error(error: final error)) Log.print(error.toString(), name: kApp, title: 'Erro');
    return result;
  }

  @override
  void dispose() {
    carregarCommand.dispose();
    selecionarCommand.dispose();
    salvarCommand.dispose();
    excluirCommand.dispose();
    super.dispose();
  }
}
