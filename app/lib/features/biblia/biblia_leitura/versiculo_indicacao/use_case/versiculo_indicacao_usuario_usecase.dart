import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../../data/model/biblia/versiculo_indicacao_model.dart';
import '../../../../../data/model/biblia/versiculo_indicacao_usuario_model.dart';
import '../../../../../data/model/usuario/usuario_resumo_model.dart';
import '../repository/versiculo_indicacao_usuario_repository.dart';

/// Regras dos usuários que recebem a indicação de um versículo:
/// - só há destinatários depois que o usuário grava a própria indicação (é dela o `vindId`);
/// - a busca de usuários exige ao menos [buscaMinimo] caracteres (abaixo disso não chama a API) e não lista quem
///   já é destinatário;
/// - o mesmo usuário não é incluído duas vezes na mesma indicação;
/// - o nome mostrado é o nome completo; sem ele, o nome de usuário.
class VersiculoIndicacaoUsuarioUseCase {
  VersiculoIndicacaoUsuarioUseCase({required this.versiculoIndicacaoUsuarioRepository}) {
    Log.print(super.runtimeType);
  }

  final VersiculoIndicacaoUsuarioRepository versiculoIndicacaoUsuarioRepository;

  /// Tamanho mínimo do texto da busca de usuários.
  static const buscaMinimo = 2;

  /// Destinatários da [indicacao]; lista vazia se ela ainda não foi gravada.
  Future<Result<List<VersiculoIndicacaoUsuarioModel>>> usuarios(VersiculoIndicacaoModel? indicacao) async {
    final vindId = indicacao?.vindId;
    if (vindId == null) return const Result.ok([]);
    return versiculoIndicacaoUsuarioRepository.usuarios(vindId);
  }

  /// Usuários cujo nome ou nome de usuário contém [texto], sem os que já estão em [indicados]. Texto com menos de
  /// [buscaMinimo] caracteres devolve lista vazia sem chamar a API.
  Future<Result<List<UsuarioResumoModel>>> buscar(String texto, List<VersiculoIndicacaoUsuarioModel> indicados) async {
    final termo = texto.trim();
    if (termo.length < buscaMinimo) return const Result.ok([]);

    final result = await versiculoIndicacaoUsuarioRepository.buscarUsuarios(termo);
    switch (result) {
      case Ok<List<UsuarioResumoModel>>(value: final lista):
        final jaIndicados = indicados.map((i) => i.usuaId).toSet();
        return Result.ok(lista.where((u) => !jaIndicados.contains(u.usuaId)).toList(growable: false));
      case Error<List<UsuarioResumoModel>>(error: final error):
        return Result.error(error);
    }
  }

  /// Inclui [usuario] como destinatário da [indicacao]. Exige a indicação gravada e que o usuário ainda não
  /// esteja em [indicados]. Devolve o registro com o nome do usuário.
  Future<Result<VersiculoIndicacaoUsuarioModel>> adicionar(
    VersiculoIndicacaoModel? indicacao,
    UsuarioResumoModel usuario,
    List<VersiculoIndicacaoUsuarioModel> indicados,
  ) async {
    final vindId = indicacao?.vindId;
    if (vindId == null) {
      return Result.error(HandledException(message: 'indiqueAntesDeAdicionarUsuarios'));
    }
    if (indicados.any((i) => i.usuaId == usuario.usuaId)) {
      return Result.error(HandledException(message: 'usuarioJaIndicado'));
    }

    final result = await versiculoIndicacaoUsuarioRepository.incluir(vindId: vindId, usuaId: usuario.usuaId);
    return switch (result) {
      Ok<VersiculoIndicacaoUsuarioModel>(value: final gravado) => Result.ok(
        gravado.comNome(udetNome: usuario.udetNome, udetUsuario: usuario.udetUsuario),
      ),
      Error<VersiculoIndicacaoUsuarioModel>(error: final error) => Result.error(error),
    };
  }

  /// Remove o destinatário [indicado].
  Future<Result<void>> remover(VersiculoIndicacaoUsuarioModel indicado) =>
      versiculoIndicacaoUsuarioRepository.excluir(indicado.viusId);

  /// Chave de tradução da mensagem de um erro devolvido pelas operações de destinatários.
  String errorMessage(Exception error) => switch (error) {
    HandledException(message: final message) => message,
    HttpServiceException(message: final message?) => message,
    _ => kDefaultAppError,
  };

  /// Nome mostrado do usuário: o nome completo; sem ele, o nome de usuário; sem os dois, nulo.
  String? nomeExibicao({String? udetNome, String? udetUsuario}) {
    final nome = udetNome?.trim() ?? '';
    if (nome.isNotEmpty) return nome;
    final usuario = udetUsuario?.trim() ?? '';
    return usuario.isEmpty ? null : usuario;
  }
}
