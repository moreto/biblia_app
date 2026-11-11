import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/comunidade/comunidade_usuario_model.dart';
import '../../../../data/model/usuario/usuario_resumo_model.dart';
import '../../comunidade/use_case/comunidade_usecase.dart';
import '../repository/comunidade_usuario_repository.dart';

/// Regras da aba "Usuários" (usuários vinculados à comunidade selecionada):
/// - as comunidades selecionáveis são as do usuário, na ordem de "Minhas comunidades" (via [ComunidadeUseCase]);
///   a seleção ([selecionada]) mantém a atual se ela ainda existir, senão a primeira;
/// - os usuários da comunidade vêm de `/v1/comunidade-usuario/:comuId` ([usuarios]): ativos primeiro, depois por
///   nome ([nomeExibicao]); 404 `registroNaoEncontrado` vira lista vazia;
/// - adicionar ([buscar] e [adicionar]): a busca exige ao menos [buscaMinimo] caracteres (abaixo disso não chama a
///   API) e não lista quem já está na comunidade; o mesmo usuário não entra duas vezes (`usuarioJaNaComunidade`; a
///   API também responde 409 `comunidadeUsuarioDuplicado`); o vínculo nasce ativo;
/// - [alternarAtivo] ativa/desativa o vínculo (PUT) e [remover] o exclui (DELETE).
class ComunidadeUsuarioUseCase {
  ComunidadeUsuarioUseCase({required this.comunidadeUsuarioRepository, required this.comunidadeUseCase}) {
    Log.print(super.runtimeType);
  }

  final ComunidadeUsuarioRepository comunidadeUsuarioRepository;

  /// Comunidades do usuário logado (mesmas regras da aba "Minhas comunidades").
  final ComunidadeUseCase comunidadeUseCase;

  /// Tamanho mínimo do texto da busca de usuários.
  static const buscaMinimo = 2;

  /// Comunidades que podem ser selecionadas na aba.
  Future<Result<List<ComunidadeResumo>>> comunidades() async {
    final result = await comunidadeUseCase.minhasComunidades();
    return switch (result) {
      Ok<MinhasComunidades>(value: final value) => Result.ok(value.comunidades),
      Error<MinhasComunidades>(error: final error) => Result.error(error),
    };
  }

  /// Comunidade selecionada: a de [comuId], se estiver na lista; senão a primeira. Nula se a lista está vazia.
  ComunidadeResumo? selecionada(List<ComunidadeResumo> comunidades, int? comuId) {
    for (final resumo in comunidades) {
      if (resumo.comunidade.comuId == comuId) return resumo;
    }
    return comunidades.firstOrNull;
  }

  /// Usuários da comunidade: ativos primeiro, depois por nome (sem diferenciar maiúsculas).
  Future<Result<List<ComunidadeUsuarioModel>>> usuarios(int comuId) async {
    final result = await comunidadeUsuarioRepository.usuarios(comuId);
    switch (result) {
      case Ok<List<ComunidadeUsuarioModel>>(value: final lista):
        return Result.ok(ordenar(lista));
      case Error<List<ComunidadeUsuarioModel>>(error: final error):
        if (_semRegistros(error)) return const Result.ok([]);
        return result;
    }
  }

  static List<ComunidadeUsuarioModel> ordenar(List<ComunidadeUsuarioModel> lista) {
    String chave(ComunidadeUsuarioModel u) =>
        (nomeExibicao(udetNome: u.udetNome, udetUsuario: u.udetUsuario) ?? '').toLowerCase();
    return [...lista]..sort((a, b) {
      if (a.cusuAtivo != b.cusuAtivo) return a.cusuAtivo ? -1 : 1;
      return chave(a).compareTo(chave(b));
    });
  }

  /// Usuários cujo nome ou nome de usuário contém [texto], sem os que já estão em [membros]. Texto com menos de
  /// [buscaMinimo] caracteres devolve lista vazia sem chamar a API.
  Future<Result<List<UsuarioResumoModel>>> buscar(String texto, List<ComunidadeUsuarioModel> membros) async {
    final termo = texto.trim();
    if (termo.length < buscaMinimo) return const Result.ok([]);

    final result = await comunidadeUsuarioRepository.buscarUsuarios(termo);
    switch (result) {
      case Ok<List<UsuarioResumoModel>>(value: final lista):
        final jaMembros = membros.map((m) => m.usuaId).toSet();
        return Result.ok(lista.where((u) => !jaMembros.contains(u.usuaId)).toList(growable: false));
      case Error<List<UsuarioResumoModel>>(error: final error):
        return Result.error(error);
    }
  }

  /// Vincula [usuario] à comunidade [comuId] (ativo). Recusa quem já está em [membros]. Devolve o vínculo com o
  /// nome do usuário.
  Future<Result<ComunidadeUsuarioModel>> adicionar(
    int? comuId,
    UsuarioResumoModel usuario,
    List<ComunidadeUsuarioModel> membros,
  ) async {
    if (comuId == null || comuId < 1) return Result.error(HandledException(message: 'comunidadeObrigatoria'));
    if (membros.any((m) => m.usuaId == usuario.usuaId)) {
      return Result.error(HandledException(message: 'usuarioJaNaComunidade'));
    }

    final result = await comunidadeUsuarioRepository.incluir(
      ComunidadeUsuarioModel(comuId: comuId, usuaId: usuario.usuaId),
    );
    return switch (result) {
      Ok<ComunidadeUsuarioModel>(value: final gravado) => Result.ok(
        gravado.copiar(udetNome: usuario.udetNome, udetUsuario: usuario.udetUsuario),
      ),
      Error<ComunidadeUsuarioModel>(error: final error) => Result.error(error),
    };
  }

  /// Ativa o vínculo inativo e desativa o ativo.
  Future<Result<ComunidadeUsuarioModel>> alternarAtivo(ComunidadeUsuarioModel membro) async {
    if (membro.cusuId == null) return Result.error(HandledException(message: 'registroNaoEncontrado'));
    return comunidadeUsuarioRepository.alterar(membro.copiar(cusuAtivo: !membro.cusuAtivo));
  }

  /// Remove o usuário da comunidade.
  Future<Result<void>> remover(ComunidadeUsuarioModel membro) async {
    final cusuId = membro.cusuId;
    if (cusuId == null) return Result.error(HandledException(message: 'registroNaoEncontrado'));
    return comunidadeUsuarioRepository.excluir(cusuId);
  }

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

  /// Chave de tradução da mensagem de um erro.
  static String mensagemErro(Exception error) => switch (error) {
    HandledException(message: final message) => message,
    HttpServiceException(message: final message?) => message,
    _ => kDefaultAppError,
  };

  static bool _semRegistros(Exception error) =>
      (error is HttpServiceException && error.message == kRegistroNaoEncontrado) ||
      (error is HandledException && error.message == kRegistroNaoEncontrado);

  static const kRegistroNaoEncontrado = 'registroNaoEncontrado';
}
