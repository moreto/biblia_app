import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/mensagem/mensagem_tipo_model.dart';
import '../../../../data/model/usuario/usuario_resumo_model.dart';
import '../use_case/mensagem_envio_usecase.dart';

/// Estado do envio de mensagem (sheet "Nova mensagem").
///
/// - [iniciar] limpa o rascunho e carrega os tipos ([tiposCommand], sem o de sistema; o primeiro já vem escolhido).
/// - [buscar] procura destinatários (só a resposta mais recente vale); [adicionar]/[remover] mexem nos escolhidos.
/// - [enviarCommand] valida e envia; [validar] devolve o problema do rascunho (para mostrar no formulário).
class MensagemEnvioViewmodel extends ChangeNotifier {
  MensagemEnvioViewmodel({required this.mensagemEnvioUseCase}) {
    Log.print(super.runtimeType);
  }

  final MensagemEnvioUseCase mensagemEnvioUseCase;

  late final Command0<void> tiposCommand = Command0(_carregarTipos);
  late final Command1<MensagemEnviada, ({String titulo, String texto})> enviarCommand = Command1(_enviar);

  List<MensagemTipoModel>? _tipos;

  /// Tipos que podem ser escolhidos (sem o de sistema); nula até carregar.
  List<MensagemTipoModel>? get tipos => _tipos;

  int? _mtipId;
  int? get mtipId => _mtipId;

  List<UsuarioResumoModel> _destinatarios = const [];
  List<UsuarioResumoModel> get destinatarios => _destinatarios;

  int _buscaSequencia = 0;
  bool _buscando = false;
  bool _buscou = false;
  String? _erroBusca;
  List<UsuarioResumoModel> _encontrados = const [];

  bool get buscando => _buscando;
  bool get buscou => _buscou;
  String? get erroBusca => _erroBusca;
  List<UsuarioResumoModel> get encontrados => _encontrados;

  int get tituloMaximo => MensagemEnvioUseCase.tituloMaximo;
  int get textoMaximo => MensagemEnvioUseCase.textoMaximo;

  /// Começa um rascunho novo: limpa tudo e carrega os tipos (se ainda não carregados).
  void iniciar() {
    _destinatarios = const [];
    _limparBusca();
    _mtipId = MensagemEnvioUseCase.tipoPadrao(_tipos ?? const []);
    enviarCommand.clearResult();
    if (_tipos == null && !tiposCommand.running) tiposCommand.execute();
    notifyListeners();
  }

  void selecionarTipo(int? mtipId) {
    _mtipId = mtipId;
    notifyListeners();
  }

  Future<void> buscar(String texto) async {
    final sequencia = ++_buscaSequencia;
    _buscando = true;
    _erroBusca = null;
    notifyListeners();

    final result = await mensagemEnvioUseCase.buscar(texto, _destinatarios);
    if (sequencia != _buscaSequencia) return;
    switch (result) {
      case Ok<List<UsuarioResumoModel>>(value: final value):
        _encontrados = value;
      case Error<List<UsuarioResumoModel>>(error: final error):
        _encontrados = const [];
        _erroBusca = MensagemEnvioUseCase.mensagemErro(error);
    }
    _buscou = texto.trim().length >= MensagemEnvioUseCase.buscaMinimo;
    _buscando = false;
    notifyListeners();
  }

  void adicionar(UsuarioResumoModel usuario) {
    _destinatarios = MensagemEnvioUseCase.adicionar(_destinatarios, usuario);
    _encontrados = _encontrados.where((u) => u.usuaId != usuario.usuaId).toList(growable: false);
    notifyListeners();
  }

  void remover(UsuarioResumoModel usuario) {
    _destinatarios = MensagemEnvioUseCase.remover(_destinatarios, usuario);
    notifyListeners();
  }

  /// Problema do rascunho (chave de tradução); nulo se pode enviar.
  String? validar({required String titulo, required String texto}) =>
      MensagemEnvioUseCase.validar((mtipId: _mtipId, titulo: titulo, texto: texto, destinatarios: _destinatarios));

  String nomeUsuario(UsuarioResumoModel usuario) => MensagemEnvioUseCase.nomeUsuario(usuario);

  String mensagemErro(Exception error) => MensagemEnvioUseCase.mensagemErro(error);

  void _limparBusca() {
    _buscaSequencia++;
    _buscando = false;
    _buscou = false;
    _erroBusca = null;
    _encontrados = const [];
  }

  Future<Result<void>> _carregarTipos() async {
    notifyListeners();
    final result = await mensagemEnvioUseCase.tipos();
    switch (result) {
      case Ok<List<MensagemTipoModel>>(value: final tipos):
        _tipos = tipos;
        _mtipId ??= MensagemEnvioUseCase.tipoPadrao(tipos);
      case Error<List<MensagemTipoModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  Future<Result<MensagemEnviada>> _enviar(({String titulo, String texto}) conteudo) async {
    notifyListeners();
    final result = await mensagemEnvioUseCase.enviar((
      mtipId: _mtipId,
      titulo: conteudo.titulo,
      texto: conteudo.texto,
      destinatarios: _destinatarios,
    ));
    if (result case Error(error: final error)) Log.print(error.toString(), name: kApp, title: 'Erro');
    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    tiposCommand.dispose();
    enviarCommand.dispose();
    super.dispose();
  }
}
