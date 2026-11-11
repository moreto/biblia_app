import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/mensagem/mensagem_tipo_model.dart';
import '../../../../data/model/usuario/usuario_resumo_model.dart';
import '../repository/mensagem_envio_repository.dart';

/// Mensagem a enviar: tipo, título, texto e destinatários.
typedef MensagemRascunho = ({int? mtipId, String titulo, String texto, List<UsuarioResumoModel> destinatarios});

/// Resultado do envio: quantos destinatários receberam e quantos falharam (a mensagem já foi gravada).
typedef MensagemEnviada = ({int mensId, int enviados, int falhas});

/// Regras do envio de mensagem:
/// - os tipos vêm de `/v1/mensagem-tipo`, **sem o de sistema** ([kTipoSistema], 0: só a API gera essas mensagens);
///   o primeiro tipo restante é o padrão ([tipoPadrao]);
/// - destinatários: busca por nome ou nome de usuário com ao menos [buscaMinimo] caracteres (abaixo disso não chama a
///   API), sem quem já foi escolhido; o mesmo usuário não entra duas vezes ([adicionar]);
/// - [validar]: tipo (diferente do de sistema), ao menos um destinatário, título obrigatório até [tituloMaximo] e
///   texto obrigatório até [textoMaximo] (limites da API);
/// - [enviar]: grava a mensagem (`POST /v1/mensagem`, título e texto aparados) e inclui cada destinatário
///   (`POST /v1/mensagem-usuario`); se algum falhar, devolve quantos falharam (`mensagemEnviadaParcialmente`).
class MensagemEnvioUseCase {
  MensagemEnvioUseCase({required this.mensagemEnvioRepository}) {
    Log.print(super.runtimeType);
  }

  final MensagemEnvioRepository mensagemEnvioRepository;

  /// Tipo das mensagens de sistema, fora do envio.
  static const kTipoSistema = 0;
  static const buscaMinimo = 2;
  static const tituloMaximo = 100;
  static const textoMaximo = 4000;

  /// Tipos que o usuário pode escolher (sem o de sistema), na ordem da API.
  Future<Result<List<MensagemTipoModel>>> tipos() async {
    final result = await mensagemEnvioRepository.tipos();
    return switch (result) {
      Ok<List<MensagemTipoModel>>(value: final lista) => Result.ok([
        for (final t in lista)
          if (t.mtipId != kTipoSistema) t,
      ]),
      Error<List<MensagemTipoModel>>(error: final error) => Result.error(error),
    };
  }

  /// Tipo inicial: o primeiro da lista; nulo sem tipos.
  static int? tipoPadrao(List<MensagemTipoModel> tipos) => tipos.firstOrNull?.mtipId;

  /// Usuários para adicionar: [texto] com ao menos [buscaMinimo] caracteres, sem os já [escolhidos].
  Future<Result<List<UsuarioResumoModel>>> buscar(String texto, List<UsuarioResumoModel> escolhidos) async {
    final termo = texto.trim();
    if (termo.length < buscaMinimo) return const Result.ok([]);
    final result = await mensagemEnvioRepository.buscarUsuarios(termo);
    switch (result) {
      case Ok<List<UsuarioResumoModel>>(value: final lista):
        final ja = escolhidos.map((u) => u.usuaId).toSet();
        return Result.ok(lista.where((u) => !ja.contains(u.usuaId)).toList(growable: false));
      case Error<List<UsuarioResumoModel>>(error: final error):
        return Result.error(error);
    }
  }

  /// [escolhidos] com [usuario] no fim (sem repetir).
  static List<UsuarioResumoModel> adicionar(List<UsuarioResumoModel> escolhidos, UsuarioResumoModel usuario) =>
      escolhidos.any((u) => u.usuaId == usuario.usuaId) ? escolhidos : [...escolhidos, usuario];

  static List<UsuarioResumoModel> remover(List<UsuarioResumoModel> escolhidos, UsuarioResumoModel usuario) => [
    for (final u in escolhidos)
      if (u.usuaId != usuario.usuaId) u,
  ];

  /// Chave de tradução do primeiro problema do [rascunho]; nula se ele pode ser enviado.
  static String? validar(MensagemRascunho rascunho) {
    final tipo = rascunho.mtipId;
    if (tipo == null || tipo == kTipoSistema) return 'tipoMensagemObrigatorio';
    if (rascunho.destinatarios.isEmpty) return 'destinatarioObrigatorio';
    final titulo = rascunho.titulo.trim();
    if (titulo.isEmpty) return 'tituloObrigatorio';
    if (titulo.length > tituloMaximo) return 'tituloMuitoLongo';
    final texto = rascunho.texto.trim();
    if (texto.isEmpty) return 'textoObrigatorio';
    if (texto.length > textoMaximo) return 'textoMuitoLongo';
    return null;
  }

  /// Grava a mensagem e inclui os destinatários. Erro de validação ou na gravação da mensagem: nada é enviado.
  /// Algum destinatário falhou: `mensagemEnviadaParcialmente` (a mensagem fica com os que deram certo).
  Future<Result<MensagemEnviada>> enviar(MensagemRascunho rascunho) async {
    final erro = validar(rascunho);
    if (erro != null) return Result.error(HandledException(message: erro));

    final gravada = await mensagemEnvioRepository.gravarMensagem(
      mtipId: rascunho.mtipId!,
      titulo: rascunho.titulo.trim(),
      texto: rascunho.texto.trim(),
    );
    final int mensId;
    switch (gravada) {
      case Ok<int>(value: final value):
        mensId = value;
      case Error<int>(error: final error):
        return Result.error(error);
    }

    var falhas = 0;
    for (final destinatario in rascunho.destinatarios) {
      final result = await mensagemEnvioRepository.incluirDestinatario(mensId: mensId, usuaId: destinatario.usuaId);
      if (result case Error(error: final error)) {
        falhas++;
        Log.print(error.toString(), name: kApp, title: 'Erro');
      }
    }
    if (falhas > 0) return Result.error(HandledException(message: 'mensagemEnviadaParcialmente'));
    return Result.ok((mensId: mensId, enviados: rascunho.destinatarios.length, falhas: 0));
  }

  /// "Nome (@usuario)", só o nome ou só "@usuario"; "?" sem nenhum dos dois.
  static String nomeUsuario(UsuarioResumoModel usuario) {
    final nome = usuario.udetNome?.trim() ?? '';
    final login = usuario.udetUsuario?.trim() ?? '';
    if (nome.isNotEmpty && login.isNotEmpty) return '$nome (@$login)';
    if (nome.isNotEmpty) return nome;
    return login.isNotEmpty ? '@$login' : '?';
  }

  static String mensagemErro(Exception error) => switch (error) {
    HandledException(message: final message) => message,
    HttpServiceException(message: final message?) => message,
    _ => kDefaultAppError,
  };
}
