import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../data/model/biblia/capitulo_lido_model.dart';
import '../../../data/model/biblia/versao_model.dart';
import '../../biblia/biblia_leitura/use_case/biblia_leitura_usecase.dart';
import '../use_case/historico_leitura_usecase.dart';

/// Estado da tela "Histórico de leitura".
///
/// Ao ser criado executa [carregarCommand]: versões e, na versão escolhida pelo usuário, o histórico. Executado de
/// novo (atualizar ou puxar para baixo), recarrega só o histórico da versão atual. [versaoCommand] troca (e salva) a
/// versão; uma troca ou atualização que falha mantém a versão e a lista anteriores. [selecionarFiltro] só muda o
/// filtro da lista, sem nova consulta.
class HistoricoLeituraViewmodel extends ChangeNotifier {
  HistoricoLeituraViewmodel({required this.historicoLeituraUseCase}) {
    Log.print(super.runtimeType);
    carregarCommand.execute();
  }

  final HistoricoLeituraUseCase historicoLeituraUseCase;

  late final Command0<void> carregarCommand = Command0(_carregar);
  late final Command1<void, VersaoModel> versaoCommand = Command1(_trocarVersao);

  List<VersaoModel> _versoes = const [];
  List<VersaoModel> get versoes => _versoes;

  VersaoModel? _versao;
  VersaoModel? get versao => _versao;

  /// Histórico da versão, do mais recente para o mais antigo; nulo até o primeiro carregamento concluir.
  List<CapituloLidoModel>? _historico;
  List<CapituloLidoModel>? get historico => _historico;

  HistoricoFiltro _filtro = HistoricoFiltro.todos;
  HistoricoFiltro get filtro => _filtro;

  /// Capítulos do filtro atual.
  List<CapituloLidoModel> get capitulos => historicoLeituraUseCase.filtrar(_historico ?? const [], _filtro);

  /// [capitulos] agrupados por dia da última leitura.
  List<GrupoHistorico> get grupos => historicoLeituraUseCase.agrupar(capitulos);

  ResumoHistorico get resumo => historicoLeituraUseCase.resumo(_historico ?? const []);

  /// Capítulo para "Continuar leitura"; nulo se não há capítulo em andamento.
  CapituloLidoModel? get continuar => historicoLeituraUseCase.continuar(_historico ?? const []);

  int quantidade(HistoricoFiltro filtro) => historicoLeituraUseCase.quantidade(_historico ?? const [], filtro);

  double fracao(CapituloLidoModel capitulo) => historicoLeituraUseCase.fracao(capitulo);

  /// Ponto da leitura do [capitulo], na versão do histórico; nulo antes de haver versão.
  LeituraDestino? destino(CapituloLidoModel capitulo) {
    final versao = _versao;
    return versao == null ? null : historicoLeituraUseCase.destino(versao.versaId, capitulo);
  }

  void selecionarFiltro(HistoricoFiltro filtro) {
    if (filtro == _filtro) return;
    _filtro = filtro;
    notifyListeners();
  }

  Future<Result<void>> _carregar() async {
    notifyListeners();

    if (_versoes.isEmpty) {
      final versoes = await historicoLeituraUseCase.versoes();
      switch (versoes) {
        case Ok<List<VersaoModel>>(value: final value):
          _versoes = value;
        case Error<List<VersaoModel>>(error: final error):
          Log.print(error.toString(), name: kApp, title: 'Erro');
          notifyListeners();
          return Result.error(error);
      }
    }

    final versao = _versao ?? historicoLeituraUseCase.versaoInicial(_versoes);
    if (versao == null) {
      notifyListeners();
      return Result.error(HandledException(message: 'nenhumaVersaoDisponivel'));
    }

    final result = await _carregarHistorico(versao);
    notifyListeners();
    return result;
  }

  Future<Result<void>> _trocarVersao(VersaoModel versao) async {
    if (versao.versaId == _versao?.versaId) return const Result.ok(null);
    notifyListeners();

    final result = await _carregarHistorico(versao);
    if (result is Ok) historicoLeituraUseCase.salvarVersao(versao);

    notifyListeners();
    return result;
  }

  Future<Result<void>> _carregarHistorico(VersaoModel versao) async {
    final result = await historicoLeituraUseCase.historico(versao.versaId);
    switch (result) {
      case Ok<List<CapituloLidoModel>>(value: final value):
        _versao = versao;
        _historico = value;
        return const Result.ok(null);
      case Error<List<CapituloLidoModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
        return Result.error(error);
    }
  }

  @override
  void dispose() {
    carregarCommand.dispose();
    versaoCommand.dispose();
    super.dispose();
  }
}
