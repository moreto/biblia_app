import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/comunidade/comunidade_local_model.dart';
import '../../../../data/model/localidade/estado_model.dart';
import '../../../../data/model/localidade/municipio_model.dart';
import '../use_case/comunidade_lista_usecase.dart';

/// Estado da tela "Encontrar comunidades": filtro por estado e cidade e as comunidades encontradas.
///
/// - Ao criar, [estadosCommand] carrega os estados.
/// - [selecionarEstado] guarda o estado, limpa a cidade, carrega os municípios dele e busca as comunidades;
///   [selecionarCidade] (nula = todas as cidades) busca de novo. Se o filtro mudar durante uma busca, ela é
///   refeita com o filtro novo (só o resultado do filtro atual é mostrado).
/// - [buscarCommand] busca com o filtro atual (atualizar); [comunidades] é nula até a primeira busca.
class ComunidadeListaViewmodel extends ChangeNotifier {
  ComunidadeListaViewmodel({required this.comunidadeListaUseCase}) {
    Log.print(super.runtimeType);
    estadosCommand.execute();
  }

  final ComunidadeListaUseCase comunidadeListaUseCase;

  late final Command0<void> estadosCommand = Command0(_carregarEstados);
  late final Command0<void> buscarCommand = Command0(_buscar);

  List<EstadoModel>? _estados;

  /// Estados do filtro; nula até carregar.
  List<EstadoModel>? get estados => _estados;

  List<MunicipioModel>? _municipios;

  /// Municípios do estado selecionado; nula sem estado ou enquanto carrega.
  List<MunicipioModel>? get municipios => _municipios;

  bool _carregandoMunicipios = false;
  bool get carregandoMunicipios => _carregandoMunicipios;

  int? _estaId;
  int? get estaId => _estaId;

  int? _muniId;

  /// Cidade selecionada; nula = todas as cidades do estado.
  int? get muniId => _muniId;

  List<ComunidadeLocalModel>? _comunidades;

  /// Comunidades do filtro; nula antes da primeira busca.
  List<ComunidadeLocalModel>? get comunidades => _comunidades;

  bool get ocupado => estadosCommand.running || buscarCommand.running || _carregandoMunicipios;

  /// Seleciona o estado: limpa a cidade, carrega os municípios e busca as comunidades.
  Future<void> selecionarEstado(int estaId) async {
    if (estaId == _estaId) return;
    _estaId = estaId;
    _muniId = null;
    _municipios = null;
    _comunidades = null;
    _carregandoMunicipios = true;
    notifyListeners();

    final busca = buscarCommand.execute();
    final result = await comunidadeListaUseCase.municipios(estaId);
    if (_estaId == estaId) {
      _carregandoMunicipios = false;
      if (result case Ok(value: final municipios)) {
        _municipios = municipios;
      } else if (result case Error(error: final error)) {
        _municipios = const [];
        Log.print(error.toString(), name: kApp, title: 'Erro');
      }
      notifyListeners();
    }
    await busca;
  }

  /// Seleciona a cidade (nula = todas) e busca de novo.
  Future<void> selecionarCidade(int? muniId) async {
    if (muniId == _muniId) return;
    _muniId = muniId;
    notifyListeners();
    await buscarCommand.execute();
  }

  String? descricao(ComunidadeLocalModel comunidade) => ComunidadeListaUseCase.descricao(comunidade);

  String? linhaEndereco(ComunidadeLocalModel comunidade) => ComunidadeListaUseCase.linhaEndereco(comunidade);

  String? linhaLocal(ComunidadeLocalModel comunidade) => ComunidadeListaUseCase.linhaLocal(comunidade);

  String mensagemErro(Exception error) => ComunidadeListaUseCase.mensagemErro(error);

  Future<Result<void>> _carregarEstados() async {
    notifyListeners();
    final result = await comunidadeListaUseCase.estados();
    if (result case Ok(value: final estados)) _estados = estados;
    if (result case Error(error: final error)) Log.print(error.toString(), name: kApp, title: 'Erro');
    notifyListeners();
    return result;
  }

  Future<Result<void>> _buscar() async {
    notifyListeners();
    Result<List<ComunidadeLocalModel>> result;
    (int?, int?) filtro;
    do {
      filtro = (_estaId, _muniId);
      result = await comunidadeListaUseCase.comunidades(
        estaId: filtro.$1,
        muniId: filtro.$2,
        municipiosDoEstado: _municipios,
      );
      // O filtro mudou durante a busca: busca de novo com o atual.
    } while (filtro != (_estaId, _muniId));
    switch (result) {
      case Ok<List<ComunidadeLocalModel>>(value: final value):
        _comunidades = value;
      case Error<List<ComunidadeLocalModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    estadosCommand.dispose();
    buscarCommand.dispose();
    super.dispose();
  }
}
