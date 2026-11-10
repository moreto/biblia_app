import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/comunidade/comunidade_contato_model.dart';
import '../../comunidade/use_case/comunidade_usecase.dart';
import '../use_case/comunidade_contato_usecase.dart';

/// Estado da aba "Contatos": contatos da comunidade selecionada.
///
/// - Carrega sob demanda: [abrir] executa [carregarCommand] (comunidades e contatos da selecionada) na primeira
///   vez que a aba é aberta e depois de [invalidar] (chamado quando as comunidades mudam).
/// - [selecionarCommand] troca a comunidade e carrega os contatos dela; [selecionar] também serve antes do
///   carregamento (ex.: "Contatos" no menu da comunidade), guardando a escolha para quando carregar.
/// - [salvarCommand] e [excluirCommand] gravam e recarregam os contatos da selecionada.
/// - [acessarCommand] abre um contato fora do app (ligação, WhatsApp, e-mail ou página).
/// - Uma atualização que falha mantém a última lista.
class ComunidadeContatoViewmodel extends ChangeNotifier {
  ComunidadeContatoViewmodel({required this.comunidadeContatoUseCase}) {
    Log.print(super.runtimeType);
  }

  final ComunidadeContatoUseCase comunidadeContatoUseCase;

  late final Command0<void> carregarCommand = Command0(_carregar);
  late final Command1<void, int> selecionarCommand = Command1(_selecionar);
  late final Command1<ComunidadeContatoModel, ComunidadeContatoModel> salvarCommand = Command1(_salvar);
  late final Command1<void, ComunidadeContatoModel> excluirCommand = Command1(_excluir);
  late final Command1<void, (ContatoCampo, String)> acessarCommand = Command1(
    (item) => comunidadeContatoUseCase.abrir(item.$1, item.$2),
  );

  List<ComunidadeResumo>? _comunidades;

  /// Comunidades selecionáveis; nula até o primeiro carregamento concluir.
  List<ComunidadeResumo>? get comunidades => _comunidades;

  ComunidadeResumo? _selecionada;
  ComunidadeResumo? get selecionada => _selecionada;

  /// Comunidade pedida antes (ou durante) o carregamento.
  int? _comuIdPedido;

  List<ComunidadeContatoModel> _contatos = const [];

  /// Contatos da comunidade selecionada.
  List<ComunidadeContatoModel> get contatos => _contatos;

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

  String? validar(ComunidadeContatoModel contato) => comunidadeContatoUseCase.validar(contato);

  String? validarCampo(ContatoCampo campo, String? valor) => ComunidadeContatoUseCase.validarCampo(campo, valor);

  List<(ContatoCampo, String)> preenchidos(ComunidadeContatoModel contato) =>
      ComunidadeContatoUseCase.preenchidos(contato);

  String exibicao(ContatoCampo campo, String valor) => ComunidadeContatoUseCase.exibicao(campo, valor);

  /// O contato pode ser aberto fora do app.
  bool acessivel(ContatoCampo campo, String valor) => ComunidadeContatoUseCase.uri(campo, valor) != null;

  Future<Result<void>> _carregar() async {
    notifyListeners();

    final result = await comunidadeContatoUseCase.comunidades();
    switch (result) {
      case Ok<List<ComunidadeResumo>>(value: final comunidades):
        final selecionada = comunidadeContatoUseCase.selecionada(
          comunidades,
          _comuIdPedido ?? _selecionada?.comunidade.comuId,
        );
        final contatos = await _contatosDe(selecionada);
        if (contatos case Error(error: final error)) {
          notifyListeners();
          return Result.error(error);
        }
        _comunidades = comunidades;
        _selecionada = selecionada;
        _contatos = (contatos as Ok<List<ComunidadeContatoModel>>).value;
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
    final selecionada = comunidadeContatoUseCase.selecionada(comunidades, comuId);
    if (selecionada?.comunidade.comuId == _selecionada?.comunidade.comuId) return const Result.ok(null);
    notifyListeners();

    final result = await _contatosDe(selecionada);
    if (result case Ok(value: final contatos)) {
      _selecionada = selecionada;
      _contatos = contatos;
    }

    notifyListeners();
    return result;
  }

  Future<Result<ComunidadeContatoModel>> _salvar(ComunidadeContatoModel contato) async {
    notifyListeners();
    final result = await comunidadeContatoUseCase.salvar(contato);
    if (result is Ok) await _recarregarContatos();
    notifyListeners();
    return result;
  }

  Future<Result<void>> _excluir(ComunidadeContatoModel contato) async {
    notifyListeners();
    final result = await comunidadeContatoUseCase.excluir(contato);
    if (result is Ok) await _recarregarContatos();
    notifyListeners();
    return result;
  }

  /// Recarrega os contatos da selecionada; falha mantém a lista atual.
  Future<void> _recarregarContatos() async {
    final result = await _contatosDe(_selecionada);
    if (result case Ok(value: final contatos)) _contatos = contatos;
  }

  Future<Result<List<ComunidadeContatoModel>>> _contatosDe(ComunidadeResumo? resumo) async {
    final comuId = resumo?.comunidade.comuId;
    if (comuId == null) return const Result.ok([]);
    final result = await comunidadeContatoUseCase.contatos(comuId);
    if (result case Error(error: final error)) Log.print(error.toString(), name: kApp, title: 'Erro');
    return result;
  }

  @override
  void dispose() {
    carregarCommand.dispose();
    selecionarCommand.dispose();
    salvarCommand.dispose();
    excluirCommand.dispose();
    acessarCommand.dispose();
    super.dispose();
  }
}
