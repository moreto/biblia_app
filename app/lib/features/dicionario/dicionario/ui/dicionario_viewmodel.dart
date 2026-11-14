import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/dicionario/dicionario_busca_model.dart';
import '../../../../data/model/dicionario/dicionario_verbete_model.dart';
import '../use_case/dicionario_usecase.dart';

/// O que a tela "Dicionário" mostra abaixo do campo de busca.
enum DicionarioExibicao {
  /// Nada buscado ainda (ou campo limpo).
  inicio,

  /// Palavras encontradas enquanto digita.
  sugestoes,

  /// Verbetes da palavra consultada (ou "não encontrada" com as semelhantes).
  consulta,
}

/// Estado da tela "Dicionário": busca enquanto digita e consulta da palavra, na mesma página.
///
/// - [buscar] traz as palavras que começam pelo texto ou são semelhantes ([sugestoes]); só a resposta mais recente
///   vale e ela descarta a consulta exibida.
/// - [consultarCommand] traz os verbetes da palavra ([consulta]) ou o erro ([erroConsulta]); [repetirConsulta] refaz
///   a última. Uma consulta ainda em andamento quando o usuário volta a digitar é descartada.
/// - [limpar] volta ao início.
class DicionarioViewmodel extends ChangeNotifier {
  DicionarioViewmodel({required this.dicionarioUseCase}) {
    Log.print(super.runtimeType);
  }

  final DicionarioUseCase dicionarioUseCase;

  late final Command1<DicionarioConsulta, String> consultarCommand = Command1(_consultar);

  /// Incrementada a cada busca, consulta ou limpeza: respostas antigas são descartadas.
  int _sequencia = 0;

  DicionarioExibicao _exibicao = DicionarioExibicao.inicio;
  bool _buscando = false;
  String? _erroBusca;
  String? _erroConsulta;
  List<DicionarioBuscaModel>? _sugestoes;
  DicionarioConsulta? _consulta;
  String? _ultimoTermo;

  bool get buscando => _buscando;

  /// Erro da busca enquanto digita (chave de tradução).
  String? get erroBusca => _erroBusca;

  /// Palavras da busca; nula se não houve busca (texto curto ou campo limpo).
  List<DicionarioBuscaModel>? get sugestoes => _sugestoes;

  /// Última consulta concluída; nula enquanto digita ou no início.
  DicionarioConsulta? get consulta => _consulta;

  /// Texto da última consulta (para "Tentar novamente").
  String? get ultimoTermo => _ultimoTermo;

  /// Erro da consulta exibida (chave de tradução).
  String? get erroConsulta => _erroConsulta;

  /// Consulta em andamento (a exibida; uma descartada pela digitação não conta).
  bool get consultando => _exibicao == DicionarioExibicao.consulta && _consulta == null && _erroConsulta == null;

  bool get ocupado => _buscando || consultando;

  DicionarioExibicao get exibicao => _exibicao;

  int get textoMaximo => DicionarioUseCase.textoMaximo;

  Future<void> buscar(String texto) async {
    final sequencia = ++_sequencia;
    _consulta = null;
    _erroConsulta = null;
    _erroBusca = null;
    if (DicionarioUseCase.normalizar(texto).length < DicionarioUseCase.buscaMinimo) {
      _exibicao = DicionarioExibicao.inicio;
      _buscando = false;
      _sugestoes = null;
      notifyListeners();
      return;
    }
    _exibicao = DicionarioExibicao.sugestoes;
    _buscando = true;
    notifyListeners();

    final result = await dicionarioUseCase.buscar(texto);
    if (sequencia != _sequencia) return;
    switch (result) {
      case Ok<List<DicionarioBuscaModel>>(value: final value):
        _sugestoes = value;
      case Error<List<DicionarioBuscaModel>>(error: final error):
        _sugestoes = const [];
        _erroBusca = DicionarioUseCase.mensagemErro(error);
    }
    _buscando = false;
    notifyListeners();
  }

  /// Refaz a última consulta (após erro).
  Future<void> repetirConsulta() async {
    final termo = _ultimoTermo;
    if (termo != null) await consultarCommand.execute(termo);
  }

  void limpar() {
    _sequencia++;
    _exibicao = DicionarioExibicao.inicio;
    _buscando = false;
    _erroConsulta = null;
    _erroBusca = null;
    _sugestoes = null;
    _consulta = null;
    _ultimoTermo = null;
    notifyListeners();
  }

  String titulo(String palavra, int? homonimo) => DicionarioUseCase.titulo(palavra, homonimo);

  List<DicionarioTrecho> trechos(String texto) => DicionarioUseCase.trechos(texto);

  String? resumo(String? definicao) => DicionarioUseCase.resumo(definicao);

  List<DicionarioAcepcaoModel> acepcoes(DicionarioVerbeteModel verbete) => DicionarioUseCase.acepcoes(verbete);

  List<String> usos(DicionarioAcepcaoModel acepcao) => DicionarioUseCase.usos(acepcao);

  List<({String termo, bool navegavel})> remissoes(DicionarioAcepcaoModel acepcao) =>
      DicionarioUseCase.remissoes(acepcao);

  Future<Result<DicionarioConsulta>> _consultar(String texto) async {
    final sequencia = ++_sequencia;
    _ultimoTermo = DicionarioUseCase.normalizar(texto);
    _exibicao = DicionarioExibicao.consulta;
    _buscando = false;
    _erroBusca = null;
    _erroConsulta = null;
    _consulta = null;
    notifyListeners();

    final result = await dicionarioUseCase.consultar(texto);
    if (sequencia != _sequencia) return result;
    switch (result) {
      case Ok<DicionarioConsulta>(value: final value):
        _consulta = value;
        _sugestoes = null;
      case Error<DicionarioConsulta>(error: final error):
        _erroConsulta = DicionarioUseCase.mensagemErro(error);
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    consultarCommand.dispose();
    super.dispose();
  }
}
