import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/comunidade/comunidade_usuario_model.dart';
import '../../../../data/model/usuario/usuario_resumo_model.dart';
import '../../comunidade/use_case/comunidade_usecase.dart';
import '../use_case/comunidade_usuario_usecase.dart';

/// Estado da aba "Usuários": usuários vinculados à comunidade selecionada.
///
/// - Carrega sob demanda: [abrir] executa [carregarCommand] (comunidades e usuários da selecionada) na primeira
///   vez que a aba é aberta e depois de [invalidar] (chamado quando as comunidades mudam).
/// - [selecionarCommand] troca a comunidade e carrega os usuários dela; [selecionar] também serve antes do
///   carregamento (ex.: "Usuários" no menu da comunidade), guardando a escolha para quando carregar.
/// - [buscar] procura usuários para adicionar (só a resposta da busca mais recente vale); [adicionarCommand],
///   [ativarCommand] (ativa/desativa) e [removerCommand] gravam e recarregam os usuários da selecionada.
/// - Uma atualização que falha mantém a última lista.
class ComunidadeUsuarioViewmodel extends ChangeNotifier {
  ComunidadeUsuarioViewmodel({required this.comunidadeUsuarioUseCase}) {
    Log.print(super.runtimeType);
  }

  final ComunidadeUsuarioUseCase comunidadeUsuarioUseCase;

  late final Command0<void> carregarCommand = Command0(_carregar);
  late final Command1<void, int> selecionarCommand = Command1(_selecionar);
  late final Command1<ComunidadeUsuarioModel, UsuarioResumoModel> adicionarCommand = Command1(_adicionar);
  late final Command1<ComunidadeUsuarioModel, ComunidadeUsuarioModel> ativarCommand = Command1(_ativar);
  late final Command1<void, ComunidadeUsuarioModel> removerCommand = Command1(_remover);

  List<ComunidadeResumo>? _comunidades;

  /// Comunidades selecionáveis; nula até o primeiro carregamento concluir.
  List<ComunidadeResumo>? get comunidades => _comunidades;

  ComunidadeResumo? _selecionada;
  ComunidadeResumo? get selecionada => _selecionada;

  /// Comunidade pedida antes (ou durante) o carregamento.
  int? _comuIdPedido;

  List<ComunidadeUsuarioModel> _usuarios = const [];

  /// Usuários da comunidade selecionada (ativos primeiro).
  List<ComunidadeUsuarioModel> get usuarios => _usuarios;

  bool _desatualizado = true;

  /// Carregamento, troca de comunidade ou gravação em andamento.
  bool get ocupado =>
      carregarCommand.running ||
      selecionarCommand.running ||
      adicionarCommand.running ||
      ativarCommand.running ||
      removerCommand.running;

  // busca de usuários para adicionar

  int _buscaSequencia = 0;
  bool _buscando = false;
  bool _buscou = false;
  String? _erroBusca;
  List<UsuarioResumoModel> _encontrados = const [];

  bool get buscando => _buscando;

  /// Já houve busca com texto suficiente (para mostrar "nenhum usuário encontrado").
  bool get buscou => _buscou;
  String? get erroBusca => _erroBusca;
  List<UsuarioResumoModel> get encontrados => _encontrados;

  int get buscaMinimo => ComunidadeUsuarioUseCase.buscaMinimo;

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

  /// Busca usuários para adicionar pelo [texto] (nome ou nome de usuário), sem os que já estão na comunidade.
  Future<void> buscar(String texto) async {
    final sequencia = ++_buscaSequencia;
    _buscando = true;
    _erroBusca = null;
    notifyListeners();

    final result = await comunidadeUsuarioUseCase.buscar(texto, _usuarios);
    if (sequencia != _buscaSequencia) return;
    switch (result) {
      case Ok<List<UsuarioResumoModel>>(value: final value):
        _encontrados = value;
      case Error<List<UsuarioResumoModel>>(error: final error):
        _encontrados = const [];
        _erroBusca = ComunidadeUsuarioUseCase.mensagemErro(error);
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    _buscou = texto.trim().length >= buscaMinimo;
    _buscando = false;
    notifyListeners();
  }

  /// Limpa a busca (ao abrir/fechar o diálogo de adicionar).
  void limparBusca() {
    _buscaSequencia++;
    _buscando = false;
    _buscou = false;
    _erroBusca = null;
    _encontrados = const [];
  }

  String? nomeExibicao({String? udetNome, String? udetUsuario}) =>
      ComunidadeUsuarioUseCase.nomeExibicao(udetNome: udetNome, udetUsuario: udetUsuario);

  String iniciais({String? udetNome, String? udetUsuario}) =>
      ComunidadeUsuarioUseCase.iniciais(udetNome: udetNome, udetUsuario: udetUsuario);

  Future<Result<void>> _carregar() async {
    notifyListeners();

    final result = await comunidadeUsuarioUseCase.comunidades();
    switch (result) {
      case Ok<List<ComunidadeResumo>>(value: final comunidades):
        final selecionada = comunidadeUsuarioUseCase.selecionada(
          comunidades,
          _comuIdPedido ?? _selecionada?.comunidade.comuId,
        );
        final usuarios = await _usuariosDe(selecionada);
        if (usuarios case Error(error: final error)) {
          notifyListeners();
          return Result.error(error);
        }
        _comunidades = comunidades;
        _selecionada = selecionada;
        _usuarios = (usuarios as Ok<List<ComunidadeUsuarioModel>>).value;
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
    final selecionada = comunidadeUsuarioUseCase.selecionada(comunidades, comuId);
    if (selecionada?.comunidade.comuId == _selecionada?.comunidade.comuId) return const Result.ok(null);
    notifyListeners();

    final result = await _usuariosDe(selecionada);
    if (result case Ok(value: final usuarios)) {
      _selecionada = selecionada;
      _usuarios = usuarios;
    }

    notifyListeners();
    return result;
  }

  Future<Result<ComunidadeUsuarioModel>> _adicionar(UsuarioResumoModel usuario) async {
    notifyListeners();
    final result = await comunidadeUsuarioUseCase.adicionar(_selecionada?.comunidade.comuId, usuario, _usuarios);
    if (result is Ok) {
      await _recarregarUsuarios();
      // Quem entrou some do resultado da busca.
      _encontrados = _encontrados.where((u) => u.usuaId != usuario.usuaId).toList(growable: false);
    }
    notifyListeners();
    return result;
  }

  Future<Result<ComunidadeUsuarioModel>> _ativar(ComunidadeUsuarioModel membro) async {
    notifyListeners();
    final result = await comunidadeUsuarioUseCase.alternarAtivo(membro);
    if (result is Ok) await _recarregarUsuarios();
    notifyListeners();
    return result;
  }

  Future<Result<void>> _remover(ComunidadeUsuarioModel membro) async {
    notifyListeners();
    final result = await comunidadeUsuarioUseCase.remover(membro);
    if (result is Ok) await _recarregarUsuarios();
    notifyListeners();
    return result;
  }

  /// Recarrega os usuários da selecionada; falha mantém a lista atual.
  Future<void> _recarregarUsuarios() async {
    final result = await _usuariosDe(_selecionada);
    if (result case Ok(value: final usuarios)) _usuarios = usuarios;
  }

  Future<Result<List<ComunidadeUsuarioModel>>> _usuariosDe(ComunidadeResumo? resumo) async {
    final comuId = resumo?.comunidade.comuId;
    if (comuId == null) return const Result.ok([]);
    final result = await comunidadeUsuarioUseCase.usuarios(comuId);
    if (result case Error(error: final error)) Log.print(error.toString(), name: kApp, title: 'Erro');
    return result;
  }

  @override
  void dispose() {
    carregarCommand.dispose();
    selecionarCommand.dispose();
    adicionarCommand.dispose();
    ativarCommand.dispose();
    removerCommand.dispose();
    super.dispose();
  }
}
