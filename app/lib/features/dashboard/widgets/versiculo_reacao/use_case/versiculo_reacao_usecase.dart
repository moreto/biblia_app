import 'package:commons/commons.dart';

import '../../../../../data/model/versiculo/versiculo_reacao_model.dart';
import '../repository/versiculo_reacao_repository.dart';

/// Regras da reação de leitura do card de versículo:
/// - o GET da API devolve as reações de todos os usuários; só vale a do usuário logado;
/// - marcar/desmarcar como lido inclui a reação (POST) se o usuário ainda não tem uma, senão a altera (PUT);
/// - ao marcar como lido o comentário informado substitui o anterior (vazio remove); ao desmarcar ele é preservado.
class VersiculoReacaoUseCase {
  VersiculoReacaoUseCase({required this.versiculoReacaoRepository, int? Function()? usuarioLogado})
    : _usuarioLogado = usuarioLogado ?? (() => AuthSession.instance.userId) {
    Log.print(super.runtimeType);
  }

  final VersiculoReacaoRepository versiculoReacaoRepository;

  /// Tamanho máximo do comentário da reação.
  static const comentarioMaximo = 500;

  /// Id do usuário logado; injetável para testes.
  final int? Function() _usuarioLogado;

  /// Reação do usuário logado ao versículo, ou nulo se ele ainda não reagiu. Se houver mais de uma
  /// (registros duplicados), vale a mais recente (maior `vreaId`).
  Future<Result<VersiculoReacaoModel?>> minhaReacao(int versId) async {
    final usuaId = _usuarioLogado();
    if (usuaId == null) {
      return Result.error(HandledException(message: 'headerInvalido'));
    }

    final result = await versiculoReacaoRepository.reacoes(versId);
    switch (result) {
      case Ok<List<VersiculoReacaoModel>>(value: final reacoes):
        VersiculoReacaoModel? minha;
        for (final reacao in reacoes) {
          if (reacao.usuaId != usuaId) continue;
          if (minha == null || (reacao.vreaId ?? 0) > (minha.vreaId ?? 0)) {
            minha = reacao;
          }
        }
        return Result.ok(minha);
      case Error<List<VersiculoReacaoModel>>(error: final error):
        return Result.error(error);
    }
  }

  /// Inverte a reação de leitura a partir de [atual] (a reação exibida no card).
  ///
  /// [comentario] só vale ao marcar como lido: é aparado e, se vazio, remove o comentário. Ao desmarcar, o
  /// comentário gravado é mantido. Acima de [comentarioMaximo] caracteres devolve `comentarioMaximo500`.
  ///
  /// Com [manterComentario] (marcação rápida, sem campo de comentário), o comentário gravado é mantido também
  /// ao marcar como lido e [comentario] é ignorado.
  ///
  /// Sem [atual] — o usuário não reagiu ou a consulta inicial falhou —, a reação é consultada de novo antes de
  /// gravar, para não criar um registro duplicado.
  Future<Result<VersiculoReacaoModel>> alternarLido(
    int versId,
    VersiculoReacaoModel? atual, {
    String? comentario,
    bool manterComentario = false,
  }) async {
    final lido = !(atual?.vreaLido ?? false);

    final texto = comentario?.trim() ?? '';
    if (lido && !manterComentario && texto.length > comentarioMaximo) {
      return Result.error(HandledException(message: 'comentarioMaximo500'));
    }

    var existente = atual;
    if (existente == null) {
      final consulta = await minhaReacao(versId);
      switch (consulta) {
        case Ok<VersiculoReacaoModel?>(value: final value):
          existente = value;
        case Error<VersiculoReacaoModel?>(error: final error):
          return Result.error(error);
      }
    }

    final novoComentario = lido && !manterComentario ? (texto.isEmpty ? null : texto) : existente?.vreaComentario;
    if (existente == null) {
      return versiculoReacaoRepository.incluir(
        VersiculoReacaoModel(versId: versId, vreaLido: lido, vreaComentario: novoComentario),
      );
    }
    return versiculoReacaoRepository.alterar(
      VersiculoReacaoModel(
        vreaId: existente.vreaId,
        versId: existente.versId,
        usuaId: existente.usuaId,
        vreaComentario: novoComentario,
        vreaLido: lido,
      ),
    );
  }
}
