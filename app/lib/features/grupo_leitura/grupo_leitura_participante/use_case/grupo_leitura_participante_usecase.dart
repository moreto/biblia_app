import 'package:commons/commons.dart';

import '../../../../data/model/leitura/leitura_model.dart';
import '../../../../data/model/leitura/leitura_participante_model.dart';
import '../../../../data/model/usuario/usuario_resumo_model.dart';
import '../../grupo_leitura/use_case/grupo_leitura_usecase.dart';
import '../repository/grupo_leitura_participante_repository.dart';

/// Regras da aba "Participantes" (participantes do grupo selecionado):
/// - os grupos selecionáveis são os de "Meus grupos" (via [GrupoLeituraUseCase]);
/// - [participantes] vêm de `/v1/leitura-participante/:leitId` por nome ([nomeExibicao]); 404 vira lista vazia;
/// - só o dono adiciona ([adicionar]); a busca ([buscar]) exige ao menos [buscaMinimo] caracteres (abaixo disso não
///   chama a API) e não lista o dono nem quem já participa; o mesmo usuário não entra duas vezes
///   (`usuarioJaNoGrupo`; a API também responde 409 `leituraParticipanteDuplicado`);
/// - o dono remove qualquer participante; o participante só a si mesmo, saindo do grupo ([podeRemover], [remover]).
class GrupoLeituraParticipanteUseCase {
  GrupoLeituraParticipanteUseCase({
    required this.grupoLeituraParticipanteRepository,
    required this.grupoLeituraUseCase,
  }) {
    Log.print(super.runtimeType);
  }

  final GrupoLeituraParticipanteRepository grupoLeituraParticipanteRepository;

  /// Grupos do usuário logado (mesmas regras da aba "Meus grupos").
  final GrupoLeituraUseCase grupoLeituraUseCase;

  /// Tamanho mínimo do texto da busca de usuários.
  static const buscaMinimo = 2;

  Future<Result<List<LeituraModel>>> grupos() => grupoLeituraUseCase.meusGrupos();

  LeituraModel? selecionado(List<LeituraModel> grupos, int? leitId) => GrupoLeituraUseCase.selecionado(grupos, leitId);

  Future<Result<List<LeituraParticipanteModel>>> participantes(int leitId) async {
    final result = await grupoLeituraParticipanteRepository.participantes(leitId);
    switch (result) {
      case Ok<List<LeituraParticipanteModel>>(value: final lista):
        return Result.ok(ordenar(lista));
      case Error<List<LeituraParticipanteModel>>(error: final error):
        if (GrupoLeituraUseCase.semRegistros(error)) return const Result.ok([]);
        return result;
    }
  }

  static List<LeituraParticipanteModel> ordenar(List<LeituraParticipanteModel> lista) {
    String chave(LeituraParticipanteModel p) =>
        (nomeExibicao(udetNome: p.udetNome, udetUsuario: p.udetUsuario) ?? '').toLowerCase();
    return List.unmodifiable([...lista]..sort((a, b) => chave(a).compareTo(chave(b))));
  }

  /// O usuário logado pode adicionar participantes ao [grupo] (só o dono).
  bool podeAdicionar(LeituraModel? grupo) => grupo?.leitDono ?? false;

  /// O usuário logado pode remover o [participante] do [grupo]: o dono qualquer um; o participante só a si mesmo.
  bool podeRemover(LeituraModel? grupo, LeituraParticipanteModel participante) =>
      grupo != null && (grupo.leitDono || ehUsuarioLogado(participante));

  /// O [participante] é o usuário logado (remover = sair do grupo).
  bool ehUsuarioLogado(LeituraParticipanteModel participante) =>
      participante.usuaId == grupoLeituraUseCase.usuarioLogado;

  /// Usuários cujo nome ou nome de usuário contém [texto], sem o dono do [grupo] e sem quem já está em
  /// [participantes]. Texto com menos de [buscaMinimo] caracteres devolve lista vazia sem chamar a API.
  Future<Result<List<UsuarioResumoModel>>> buscar(
    String texto,
    LeituraModel? grupo,
    List<LeituraParticipanteModel> participantes,
  ) async {
    final termo = texto.trim();
    if (termo.length < buscaMinimo) return const Result.ok([]);

    final result = await grupoLeituraParticipanteRepository.buscarUsuarios(termo);
    switch (result) {
      case Ok<List<UsuarioResumoModel>>(value: final lista):
        final fora = {...participantes.map((p) => p.usuaId), ?grupo?.usuaId};
        return Result.ok(lista.where((u) => !fora.contains(u.usuaId)).toList(growable: false));
      case Error<List<UsuarioResumoModel>>(error: final error):
        return Result.error(error);
    }
  }

  /// Inclui [usuario] no [grupo]. Recusa quem não é dono e quem já está em [participantes]. Devolve o participante
  /// com o nome do usuário.
  Future<Result<LeituraParticipanteModel>> adicionar(
    LeituraModel? grupo,
    UsuarioResumoModel usuario,
    List<LeituraParticipanteModel> participantes,
  ) async {
    final leitId = grupo?.leitId;
    if (grupo == null || leitId == null) {
      return Result.error(HandledException(message: GrupoLeituraUseCase.kGrupoObrigatorio));
    }
    if (!podeAdicionar(grupo)) return Result.error(HandledException(message: GrupoLeituraUseCase.kSomenteDonoAltera));
    if (participantes.any((p) => p.usuaId == usuario.usuaId)) {
      return Result.error(HandledException(message: 'usuarioJaNoGrupo'));
    }

    final result = await grupoLeituraParticipanteRepository.incluir(
      LeituraParticipanteModel(leitId: leitId, usuaId: usuario.usuaId),
    );
    return switch (result) {
      Ok<LeituraParticipanteModel>(value: final gravado) => Result.ok(
        gravado.comNome(udetNome: usuario.udetNome, udetUsuario: usuario.udetUsuario),
      ),
      Error<LeituraParticipanteModel>(error: final error) => Result.error(error),
    };
  }

  /// Remove o [participante] do [grupo] (ou tira o próprio usuário dele), conforme [podeRemover].
  Future<Result<void>> remover(LeituraModel? grupo, LeituraParticipanteModel participante) async {
    final lparId = participante.lparId;
    if (lparId == null) return Result.error(HandledException(message: GrupoLeituraUseCase.kRegistroNaoEncontrado));
    if (!podeRemover(grupo, participante)) {
      return Result.error(HandledException(message: GrupoLeituraUseCase.kSomenteDonoAltera));
    }
    return grupoLeituraParticipanteRepository.excluir(lparId);
  }

  /// Chave de tradução da mensagem de um erro.
  static String mensagemErro(Exception error) => GrupoLeituraUseCase.mensagemErro(error);

  /// Nome mostrado do usuário: o nome completo; sem ele, o nome de usuário; sem os dois, nulo.
  static String? nomeExibicao({String? udetNome, String? udetUsuario}) {
    final nome = udetNome?.trim() ?? '';
    if (nome.isNotEmpty) return nome;
    final usuario = udetUsuario?.trim() ?? '';
    return usuario.isEmpty ? null : usuario;
  }

  /// Iniciais do nome (até duas letras) para o avatar; "?" sem nome.
  static String iniciais({String? udetNome, String? udetUsuario}) {
    final nome = nomeExibicao(udetNome: udetNome, udetUsuario: udetUsuario);
    if (nome == null) return '?';
    final partes = nome.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final letras = partes.length == 1 ? partes.first.substring(0, 1) : '${partes.first[0]}${partes.last[0]}';
    return letras.toUpperCase();
  }
}
