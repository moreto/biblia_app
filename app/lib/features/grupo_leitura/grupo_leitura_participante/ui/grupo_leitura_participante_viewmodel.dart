import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/leitura/leitura_model.dart';
import '../../../../data/model/leitura/leitura_participante_model.dart';
import '../../../../data/model/usuario/usuario_resumo_model.dart';
import '../use_case/grupo_leitura_participante_usecase.dart';

/// Estado da aba "Participantes": participantes do grupo selecionado.
///
/// - Carrega sob demanda: [abrir] executa [carregarCommand] (grupos e participantes do selecionado) na primeira vez
///   que a aba é aberta e depois de [invalidar] (chamado quando os grupos mudam).
/// - [selecionarCommand] troca o grupo; [selecionar] também serve antes do carregamento (ex.: "Participantes" no
///   menu do grupo), guardando a escolha para quando carregar.
/// - [buscar] procura usuários para adicionar (só a resposta da busca mais recente vale); [adicionarCommand] e
///   [removerCommand] gravam e recarregam os participantes. Quando o usuário sai do grupo, [saiuDoGrupo] fica
///   verdadeiro até a tela consumir com [confirmarSaida] (a lista de grupos precisa ser recarregada).
class GrupoLeituraParticipanteViewmodel extends ChangeNotifier {
  GrupoLeituraParticipanteViewmodel({required this.grupoLeituraParticipanteUseCase}) {
    Log.print(super.runtimeType);
  }

  final GrupoLeituraParticipanteUseCase grupoLeituraParticipanteUseCase;

  late final Command0<void> carregarCommand = Command0(_carregar);
  late final Command1<void, int> selecionarCommand = Command1(_selecionar);
  late final Command1<LeituraParticipanteModel, UsuarioResumoModel> adicionarCommand = Command1(_adicionar);
  late final Command1<void, LeituraParticipanteModel> removerCommand = Command1(_remover);

  List<LeituraModel>? _grupos;

  /// Grupos selecionáveis; nula até o primeiro carregamento concluir.
  List<LeituraModel>? get grupos => _grupos;

  LeituraModel? _selecionado;
  LeituraModel? get selecionado => _selecionado;

  int? _leitIdPedido;

  List<LeituraParticipanteModel> _participantes = const [];
  List<LeituraParticipanteModel> get participantes => _participantes;

  bool _desatualizado = true;
  bool _saiuDoGrupo = false;

  /// O usuário acabou de sair de um grupo (remover a si mesmo).
  bool get saiuDoGrupo => _saiuDoGrupo;

  bool get ocupado =>
      carregarCommand.running || selecionarCommand.running || adicionarCommand.running || removerCommand.running;

  bool get podeAdicionar => grupoLeituraParticipanteUseCase.podeAdicionar(_selecionado);
  bool podeRemover(LeituraParticipanteModel participante) =>
      grupoLeituraParticipanteUseCase.podeRemover(_selecionado, participante);
  bool ehUsuarioLogado(LeituraParticipanteModel participante) =>
      grupoLeituraParticipanteUseCase.ehUsuarioLogado(participante);

  // busca de usuários para adicionar

  int _buscaSequencia = 0;
  bool _buscando = false;
  bool _buscou = false;
  String? _erroBusca;
  List<UsuarioResumoModel> _encontrados = const [];

  bool get buscando => _buscando;
  bool get buscou => _buscou;
  String? get erroBusca => _erroBusca;
  List<UsuarioResumoModel> get encontrados => _encontrados;

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

  /// A tela tratou a saída do grupo.
  void confirmarSaida() => _saiuDoGrupo = false;

  Future<void> buscar(String texto) async {
    final sequencia = ++_buscaSequencia;
    _buscando = true;
    _erroBusca = null;
    notifyListeners();

    final result = await grupoLeituraParticipanteUseCase.buscar(texto, _selecionado, _participantes);
    if (sequencia != _buscaSequencia) return;
    switch (result) {
      case Ok<List<UsuarioResumoModel>>(value: final value):
        _encontrados = value;
      case Error<List<UsuarioResumoModel>>(error: final error):
        _encontrados = const [];
        _erroBusca = GrupoLeituraParticipanteUseCase.mensagemErro(error);
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    _buscou = texto.trim().length >= GrupoLeituraParticipanteUseCase.buscaMinimo;
    _buscando = false;
    notifyListeners();
  }

  void limparBusca() {
    _buscaSequencia++;
    _buscando = false;
    _buscou = false;
    _erroBusca = null;
    _encontrados = const [];
  }

  String? nomeExibicao({String? udetNome, String? udetUsuario}) =>
      GrupoLeituraParticipanteUseCase.nomeExibicao(udetNome: udetNome, udetUsuario: udetUsuario);

  String iniciais({String? udetNome, String? udetUsuario}) =>
      GrupoLeituraParticipanteUseCase.iniciais(udetNome: udetNome, udetUsuario: udetUsuario);

  Future<Result<void>> _carregar() async {
    notifyListeners();
    final result = await grupoLeituraParticipanteUseCase.grupos();
    switch (result) {
      case Ok<List<LeituraModel>>(value: final grupos):
        final selecionado = grupoLeituraParticipanteUseCase.selecionado(grupos, _leitIdPedido ?? _selecionado?.leitId);
        final participantes = await _participantesDe(selecionado);
        if (participantes case Error(error: final error)) {
          notifyListeners();
          return Result.error(error);
        }
        _grupos = grupos;
        _selecionado = selecionado;
        _participantes = (participantes as Ok<List<LeituraParticipanteModel>>).value;
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
    final selecionado = grupoLeituraParticipanteUseCase.selecionado(_grupos ?? const [], leitId);
    if (selecionado?.leitId == _selecionado?.leitId) return const Result.ok(null);
    notifyListeners();
    final result = await _participantesDe(selecionado);
    if (result case Ok(value: final participantes)) {
      _selecionado = selecionado;
      _participantes = participantes;
    }
    notifyListeners();
    return result;
  }

  Future<Result<LeituraParticipanteModel>> _adicionar(UsuarioResumoModel usuario) async {
    notifyListeners();
    final result = await grupoLeituraParticipanteUseCase.adicionar(_selecionado, usuario, _participantes);
    if (result is Ok) {
      await _recarregarParticipantes();
      _encontrados = _encontrados.where((u) => u.usuaId != usuario.usuaId).toList(growable: false);
    }
    notifyListeners();
    return result;
  }

  Future<Result<void>> _remover(LeituraParticipanteModel participante) async {
    notifyListeners();
    final saindo = grupoLeituraParticipanteUseCase.ehUsuarioLogado(participante);
    final result = await grupoLeituraParticipanteUseCase.remover(_selecionado, participante);
    if (result is Ok) {
      if (saindo) {
        _saiuDoGrupo = true;
        _desatualizado = true;
        _leitIdPedido = null;
        await _carregar();
      } else {
        await _recarregarParticipantes();
      }
    }
    notifyListeners();
    return result;
  }

  Future<void> _recarregarParticipantes() async {
    final result = await _participantesDe(_selecionado);
    if (result case Ok(value: final participantes)) _participantes = participantes;
  }

  Future<Result<List<LeituraParticipanteModel>>> _participantesDe(LeituraModel? grupo) async {
    final leitId = grupo?.leitId;
    if (leitId == null) return const Result.ok([]);
    final result = await grupoLeituraParticipanteUseCase.participantes(leitId);
    if (result case Error(error: final error)) Log.print(error.toString(), name: kApp, title: 'Erro');
    return result;
  }

  @override
  void dispose() {
    carregarCommand.dispose();
    selecionarCommand.dispose();
    adicionarCommand.dispose();
    removerCommand.dispose();
    super.dispose();
  }
}
