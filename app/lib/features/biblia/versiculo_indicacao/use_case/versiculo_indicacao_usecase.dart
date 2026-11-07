import 'package:commons/commons.dart';

import '../../../../data/model/biblia/versiculo_indicacao_model.dart';
import '../repository/versiculo_indicacao_repository.dart';

/// Indicações de um versículo: quantas existem e qual é a do usuário logado.
typedef IndicacoesVersiculo = ({int total, VersiculoIndicacaoModel? minha});

/// Regras da indicação de versículo:
/// - o GET da API devolve as indicações de todos os usuários; o total conta todas e só uma é do usuário logado;
/// - indicar inclui (POST) se o usuário ainda não indicou, senão altera o comentário (PUT);
/// - o comentário é aparado (vazio grava nulo) e tem no máximo [comentarioMaximo] caracteres;
/// - remover exclui a indicação do usuário (DELETE).
class VersiculoIndicacaoUseCase {
  VersiculoIndicacaoUseCase({required this.versiculoIndicacaoRepository, int? Function()? usuarioLogado})
    : _usuarioLogado = usuarioLogado ?? (() => AuthSession.instance.userId) {
    Log.print(super.runtimeType);
  }

  final VersiculoIndicacaoRepository versiculoIndicacaoRepository;

  /// Tamanho máximo do comentário da indicação.
  static const comentarioMaximo = 500;

  /// Id do usuário logado; injetável para testes.
  final int? Function() _usuarioLogado;

  /// Total de indicações do versículo e a do usuário logado (a mais recente, se houver duplicadas).
  Future<Result<IndicacoesVersiculo>> indicacoes(int versId) async {
    final usuaId = _usuarioLogado();
    if (usuaId == null) {
      return Result.error(HandledException(message: 'headerInvalido'));
    }

    final result = await versiculoIndicacaoRepository.indicacoes(versId);
    switch (result) {
      case Ok<List<VersiculoIndicacaoModel>>(value: final lista):
        VersiculoIndicacaoModel? minha;
        for (final indicacao in lista) {
          if (indicacao.usuaId != usuaId) continue;
          if (minha == null || (indicacao.vindId ?? 0) > (minha.vindId ?? 0)) {
            minha = indicacao;
          }
        }
        return Result.ok((total: lista.length, minha: minha));
      case Error<List<VersiculoIndicacaoModel>>(error: final error):
        return Result.error(error);
    }
  }

  /// Grava a indicação do usuário ao versículo: inclui se [atual] for nulo, senão altera o comentário.
  Future<Result<VersiculoIndicacaoModel>> indicar(
    int versId,
    VersiculoIndicacaoModel? atual, {
    String? comentario,
  }) async {
    final texto = comentario?.trim() ?? '';
    if (texto.length > comentarioMaximo) {
      return Result.error(HandledException(message: 'comentarioMaximo500'));
    }
    final novoComentario = texto.isEmpty ? null : texto;

    if (atual?.vindId == null) {
      return versiculoIndicacaoRepository.incluir(
        VersiculoIndicacaoModel(versId: versId, vindComentario: novoComentario),
      );
    }
    return versiculoIndicacaoRepository.alterar(
      VersiculoIndicacaoModel(
        vindId: atual!.vindId,
        versId: atual.versId,
        usuaId: atual.usuaId,
        vindComentario: novoComentario,
      ),
    );
  }

  /// Remove a indicação [atual] do usuário.
  Future<Result<void>> remover(VersiculoIndicacaoModel atual) async {
    final vindId = atual.vindId;
    if (vindId == null) {
      return Result.error(HandledException(message: 'registroNaoEncontrado'));
    }
    return versiculoIndicacaoRepository.excluir(vindId);
  }
}
