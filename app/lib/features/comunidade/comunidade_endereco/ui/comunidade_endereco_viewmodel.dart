import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/comunidade/comunidade_endereco_model.dart';
import '../../../../data/model/localidade/estado_model.dart';
import '../../../../data/model/localidade/municipio_model.dart';
import '../../comunidade/use_case/comunidade_usecase.dart';
import '../use_case/comunidade_endereco_usecase.dart';

/// Estado da aba "Endereços": endereços da comunidade selecionada.
///
/// - Carrega sob demanda: [abrir] executa [carregarCommand] (comunidades e endereços da selecionada) na primeira
///   vez que a aba é aberta e depois de [invalidar] (chamado quando as comunidades mudam).
/// - [selecionarCommand] troca a comunidade e carrega os endereços dela; [selecionar] também serve antes do
///   carregamento (ex.: "Endereços" no menu da comunidade), guardando a escolha para quando carregar.
/// - [salvarCommand] e [excluirCommand] gravam e recarregam os endereços da selecionada.
/// - Uma atualização que falha mantém a última lista.
class ComunidadeEnderecoViewmodel extends ChangeNotifier {
  ComunidadeEnderecoViewmodel({required this.comunidadeEnderecoUseCase}) {
    Log.print(super.runtimeType);
  }

  final ComunidadeEnderecoUseCase comunidadeEnderecoUseCase;

  late final Command0<void> carregarCommand = Command0(_carregar);
  late final Command1<void, int> selecionarCommand = Command1(_selecionar);
  late final Command1<ComunidadeEnderecoModel, ComunidadeEnderecoModel> salvarCommand = Command1(_salvar);
  late final Command1<void, ComunidadeEnderecoModel> excluirCommand = Command1(_excluir);

  List<ComunidadeResumo>? _comunidades;

  /// Comunidades selecionáveis; nula até o primeiro carregamento concluir.
  List<ComunidadeResumo>? get comunidades => _comunidades;

  ComunidadeResumo? _selecionada;
  ComunidadeResumo? get selecionada => _selecionada;

  /// Comunidade pedida antes (ou durante) o carregamento.
  int? _comuIdPedido;

  List<ComunidadeEnderecoModel> _enderecos = const [];

  /// Endereços da comunidade selecionada.
  List<ComunidadeEnderecoModel> get enderecos => _enderecos;

  bool _desatualizado = true;

  /// Carregamento, troca de comunidade, gravação ou exclusão em andamento.
  bool get ocupado =>
      carregarCommand.running || selecionarCommand.running || salvarCommand.running || excluirCommand.running;

  /// A aba foi aberta: carrega se ainda não carregou ou se as comunidades mudaram.
  void abrir() {
    if (_desatualizado && !carregarCommand.running) carregarCommand.execute();
  }

  /// As comunidades mudaram (inclusão, alteração ou exclusão): a próxima abertura recarrega.
  void invalidar() => _desatualizado = true;

  /// Seleciona a comunidade [comuId]: se já carregou e não há mudança pendente, troca agora; senão vale no
  /// próximo carregamento.
  void selecionar(int comuId) {
    if (_comunidades != null && !_desatualizado && !carregarCommand.running) {
      selecionarCommand.execute(comuId);
    } else {
      _comuIdPedido = comuId;
    }
  }

  String? validar(ComunidadeEnderecoModel endereco) => comunidadeEnderecoUseCase.validar(endereco);

  /// Tamanhos máximos dos campos do formulário.
  EnderecoLimites get limites => ComunidadeEnderecoUseCase.limites;

  Future<Result<List<EstadoModel>>> estados() => comunidadeEnderecoUseCase.estados();

  Future<Result<List<MunicipioModel>>> municipios(int estaId) => comunidadeEnderecoUseCase.municipios(estaId);

  String linhaPrincipal(ComunidadeEnderecoModel endereco) => ComunidadeEnderecoUseCase.linhaPrincipal(endereco);

  String? linhaLocal(ComunidadeEnderecoModel endereco) => ComunidadeEnderecoUseCase.linhaLocal(endereco);

  String cep(ComunidadeEnderecoModel endereco) => ComunidadeEnderecoUseCase.cepFormatado(endereco.cendCep);

  Future<Result<void>> _carregar() async {
    notifyListeners();

    final result = await comunidadeEnderecoUseCase.comunidades();
    switch (result) {
      case Ok<List<ComunidadeResumo>>(value: final comunidades):
        final selecionada = comunidadeEnderecoUseCase.selecionada(
          comunidades,
          _comuIdPedido ?? _selecionada?.comunidade.comuId,
        );
        final enderecos = await _enderecosDe(selecionada);
        if (enderecos case Error(error: final error)) {
          notifyListeners();
          return Result.error(error);
        }
        _comunidades = comunidades;
        _selecionada = selecionada;
        _enderecos = (enderecos as Ok<List<ComunidadeEnderecoModel>>).value;
        _comuIdPedido = null;
        _desatualizado = false;
        notifyListeners();
        return const Result.ok(null);
      case Error<List<ComunidadeResumo>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
        notifyListeners();
        return Result.error(error);
    }
  }

  Future<Result<void>> _selecionar(int comuId) async {
    final comunidades = _comunidades ?? const [];
    final selecionada = comunidadeEnderecoUseCase.selecionada(comunidades, comuId);
    if (selecionada?.comunidade.comuId == _selecionada?.comunidade.comuId) return const Result.ok(null);
    notifyListeners();

    final result = await _enderecosDe(selecionada);
    if (result case Ok(value: final enderecos)) {
      _selecionada = selecionada;
      _enderecos = enderecos;
    }

    notifyListeners();
    return result;
  }

  Future<Result<ComunidadeEnderecoModel>> _salvar(ComunidadeEnderecoModel endereco) async {
    notifyListeners();
    final result = await comunidadeEnderecoUseCase.salvar(endereco);
    if (result is Ok) await _recarregarEnderecos();
    notifyListeners();
    return result;
  }

  Future<Result<void>> _excluir(ComunidadeEnderecoModel endereco) async {
    notifyListeners();
    final result = await comunidadeEnderecoUseCase.excluir(endereco);
    if (result is Ok) await _recarregarEnderecos();
    notifyListeners();
    return result;
  }

  /// Recarrega os endereços da selecionada; falha mantém a lista atual.
  Future<void> _recarregarEnderecos() async {
    final result = await _enderecosDe(_selecionada);
    if (result case Ok(value: final enderecos)) _enderecos = enderecos;
  }

  Future<Result<List<ComunidadeEnderecoModel>>> _enderecosDe(ComunidadeResumo? resumo) async {
    final comuId = resumo?.comunidade.comuId;
    if (comuId == null) return const Result.ok([]);
    final result = await comunidadeEnderecoUseCase.enderecos(comuId);
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
