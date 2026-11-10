import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/biblia/versao_model.dart';
import '../../../../data/model/biblia/versiculo_renomado_model.dart';
import '../../biblia_leitura/use_case/biblia_leitura_usecase.dart';
import '../repository/versiculo_renomado_repository.dart';

/// Regras dos versículos de um renomado:
/// - a lista abre na versão escolhida pelo usuário (a mesma da leitura, via [BibliaLeituraUseCase.versaoInicial]) e
///   trocar a versão aqui também a salva para a leitura;
/// - os versículos vêm na versão escolhida, por `vrenSeq` (sem sequência por último), livro, capítulo e número;
/// - 404 `registroNaoEncontrado` vira lista vazia (`nenhumVersiculoRenomado` na tela);
/// - tocar num versículo abre a leitura nele, na mesma versão ([destino]).
class VersiculoRenomadoUseCase {
  VersiculoRenomadoUseCase({required this.versiculoRenomadoRepository, required this.bibliaLeituraUseCase}) {
    Log.print(super.runtimeType);
  }

  final VersiculoRenomadoRepository versiculoRenomadoRepository;

  /// Versões e preferência de versão, compartilhadas com a leitura.
  final BibliaLeituraUseCase bibliaLeituraUseCase;

  Future<Result<List<VersaoModel>>> versoes() => bibliaLeituraUseCase.versoes();

  /// Versão salva pelo usuário, se ainda existir; senão a primeira. Nula se não há versões.
  VersaoModel? versaoInicial(List<VersaoModel> versoes) => bibliaLeituraUseCase.versaoInicial(versoes);

  void salvarVersao(VersaoModel versao) => bibliaLeituraUseCase.salvarVersao(versao);

  Future<Result<List<VersiculoRenomadoModel>>> versiculos(int renoId, int versaId) async {
    final result = await versiculoRenomadoRepository.versiculos(renoId, versaId);
    switch (result) {
      case Ok<List<VersiculoRenomadoModel>>(value: final value):
        return Result.ok(ordenar(value));
      case Error<List<VersiculoRenomadoModel>>(error: final error):
        if (_semRegistros(error)) return const Result.ok([]);
        return Result.error(error);
    }
  }

  static List<VersiculoRenomadoModel> ordenar(Iterable<VersiculoRenomadoModel> versiculos) {
    final lista = versiculos.toList();
    lista.sort((a, b) {
      final seqA = a.vrenSeq;
      final seqB = b.vrenSeq;
      if (seqA != seqB) {
        if (seqA == null) return 1;
        if (seqB == null) return -1;
        return seqA.compareTo(seqB);
      }
      for (final comparacao in [
        a.livrId.compareTo(b.livrId),
        a.capiNumero.compareTo(b.capiNumero),
        a.versNumero.compareTo(b.versNumero),
      ]) {
        if (comparacao != 0) return comparacao;
      }
      return a.vrenId.compareTo(b.vrenId);
    });
    return List.unmodifiable(lista);
  }

  /// Ponto da leitura para abrir o [versiculo], na versão em que ele foi carregado.
  LeituraDestino destino(VersiculoRenomadoModel versiculo) => LeituraDestino(
    versaId: versiculo.versaId,
    livrId: versiculo.livrId,
    capiNumero: versiculo.capiNumero,
    versNumero: versiculo.versNumero,
  );

  static bool _semRegistros(Exception error) =>
      (error is HttpServiceException && error.message == kRegistroNaoEncontrado) ||
      (error is HandledException && error.message == kRegistroNaoEncontrado);

  static const kRegistroNaoEncontrado = 'registroNaoEncontrado';
}
