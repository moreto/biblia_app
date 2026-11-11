import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/mensagem/mensagem_recebida_model.dart';
import '../use_case/mensagem_lista_usecase.dart';

/// Estado da tela "Mensagens": mensagens recebidas, filtro e ações de situação.
///
/// - [carregarCommand] (executado ao criar) busca as mensagens; uma atualização que falha mantém a última lista.
/// - [selecionarFiltro] troca entre entrada, não lidas e arquivadas ([filtradas]).
/// - [abrirCommand] marca a mensagem como lida ao abrir; [lidaCommand] e [arquivarCommand] invertem lida/arquivada.
///   O registro gravado substitui a mensagem na lista.
class MensagemListaViewmodel extends ChangeNotifier {
  MensagemListaViewmodel({required this.mensagemListaUseCase}) {
    Log.print(super.runtimeType);
    carregarCommand.execute();
  }

  final MensagemListaUseCase mensagemListaUseCase;

  late final Command0<void> carregarCommand = Command0(_carregar);
  late final Command1<MensagemRecebidaModel, MensagemRecebidaModel> abrirCommand = Command1(
    (m) => _aplicar(mensagemListaUseCase.abrir(m)),
  );
  late final Command1<MensagemRecebidaModel, MensagemRecebidaModel> lidaCommand = Command1(
    (m) => _aplicar(mensagemListaUseCase.marcarLida(m, !m.musuLida)),
  );
  late final Command1<MensagemRecebidaModel, MensagemRecebidaModel> arquivarCommand = Command1(
    (m) => _aplicar(mensagemListaUseCase.arquivar(m, !m.musuArquivada)),
  );

  List<MensagemRecebidaModel>? _mensagens;

  /// Todas as mensagens recebidas; nula até o primeiro carregamento concluir.
  List<MensagemRecebidaModel>? get mensagens => _mensagens;

  MensagemFiltro _filtro = MensagemFiltro.entrada;
  MensagemFiltro get filtro => _filtro;

  /// Mensagens do filtro atual.
  List<MensagemRecebidaModel> get filtradas => MensagemListaUseCase.filtrar(_mensagens ?? const [], _filtro);

  /// Não lidas da entrada.
  int get naoLidas => MensagemListaUseCase.naoLidas(_mensagens ?? const []);

  bool get gravando => abrirCommand.running || lidaCommand.running || arquivarCommand.running;

  void selecionarFiltro(MensagemFiltro filtro) {
    if (filtro == _filtro) return;
    _filtro = filtro;
    notifyListeners();
  }

  /// Versão atual (da lista) da mensagem [musuId]; nula se não estiver mais na lista.
  MensagemRecebidaModel? mensagem(int musuId) => _mensagens?.where((m) => m.musuId == musuId).firstOrNull;

  String? remetente(MensagemRecebidaModel m) => MensagemListaUseCase.remetente(m);

  String resumo(MensagemRecebidaModel m) => MensagemListaUseCase.resumo(m);

  String? data(DateTime? quando) => MensagemListaUseCase.data(quando);

  String? resposta(MensagemRecebidaModel m) => MensagemListaUseCase.resposta(m);

  Future<Result<void>> _carregar() async {
    notifyListeners();
    final result = await mensagemListaUseCase.recebidas();
    switch (result) {
      case Ok<List<MensagemRecebidaModel>>(value: final value):
        _mensagens = value;
      case Error<List<MensagemRecebidaModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  /// Executa a gravação e troca a mensagem da lista pela devolvida.
  Future<Result<MensagemRecebidaModel>> _aplicar(Future<Result<MensagemRecebidaModel>> gravacao) async {
    notifyListeners();
    final result = await gravacao;
    if (result case Ok(value: final atualizada)) {
      _mensagens = [
        for (final m in _mensagens ?? const <MensagemRecebidaModel>[]) m.musuId == atualizada.musuId ? atualizada : m,
      ];
    } else if (result case Error(error: final error)) {
      Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    carregarCommand.dispose();
    abrirCommand.dispose();
    lidaCommand.dispose();
    arquivarCommand.dispose();
    super.dispose();
  }
}
