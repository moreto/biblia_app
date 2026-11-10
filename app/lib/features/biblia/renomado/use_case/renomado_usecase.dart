import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/biblia/renomado_model.dart';
import '../repository/renomado_repository.dart';

class RenomadoUseCase {
  RenomadoUseCase({required this.renomadoRepository}) {
    Log.print(super.runtimeType);
  }

  final RenomadoRepository renomadoRepository;

  /// Lista todos os renomados, prontos para exibição:
  /// - nome e texto sem espaços nas pontas; texto em branco vira nulo (o item não mostra descrição);
  /// - ordem por `renoSeq` (sem sequência por último), nome (sem diferenciar maiúsculas) e id, a mesma da API;
  /// - 404 `registroNaoEncontrado` vira lista vazia, para a tela mostrar `nenhumRenomadoCadastrado`.
  Future<Result<List<RenomadoModel>>> listar() async {
    final result = await renomadoRepository.getAll();
    switch (result) {
      case Ok<List<RenomadoModel>>():
        return Result.ok(ordenar(result.value.map(normalizar)));
      case Error<List<RenomadoModel>>(error: final error):
        if (_semRegistros(error)) return const Result.ok([]);
        return Result.error(error);
    }
  }

  static RenomadoModel normalizar(RenomadoModel renomado) {
    final texto = renomado.renoTexto?.trim();
    return renomado.copyWith(
      renoNome: renomado.renoNome.trim(),
      renoTexto: () => (texto?.isEmpty ?? true) ? null : texto,
    );
  }

  static List<RenomadoModel> ordenar(Iterable<RenomadoModel> renomados) {
    final lista = renomados.toList();
    lista.sort((a, b) {
      final seqA = a.renoSeq;
      final seqB = b.renoSeq;
      if (seqA != seqB) {
        if (seqA == null) return 1;
        if (seqB == null) return -1;
        return seqA.compareTo(seqB);
      }
      final nome = a.renoNome.toLowerCase().compareTo(b.renoNome.toLowerCase());
      return nome != 0 ? nome : a.renoId.compareTo(b.renoId);
    });
    return List.unmodifiable(lista);
  }

  static bool _semRegistros(Exception error) =>
      (error is HttpServiceException && error.message == kRegistroNaoEncontrado) ||
      (error is HandledException && error.message == kRegistroNaoEncontrado);

  static const kRegistroNaoEncontrado = 'registroNaoEncontrado';
}
