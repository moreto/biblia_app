import 'package:commons/commons.dart';

import '../../../../data/model/biblia/capitulo_lido_model.dart';
import '../../../../data/model/biblia/indice_capitulo_model.dart';
import '../../../../data/model/biblia/livro_model.dart';
import '../../../../data/model/biblia/testamento_model.dart';
import '../../../../data/model/biblia/versao_model.dart';
import '../../../../data/model/biblia/versiculo_texto_model.dart';
import '../repository/biblia_leitura_repository.dart';

/// Referência de um capítulo (livro e número), usada para navegar entre capítulos.
typedef CapituloRef = ({int livrId, int capiNumero});

/// Regras da leitura da Bíblia:
/// - o índice da versão define quais capítulos existem (só os que têm versículos na versão);
/// - o progresso vem de `versiculo-reacao/lidos`: um capítulo está lido quando todos os versículos estão marcados;
/// - marcar o capítulo grava todos os versículos de uma vez; se ele já estava completo, desmarca;
/// - o histórico de leitura lista os capítulos do mais recente para o mais antigo;
/// - o filtro de testamentos mostra o Novo Testamento antes do Antigo.
class BibliaLeituraUseCase {
  BibliaLeituraUseCase({required this.bibliaLeituraRepository}) {
    Log.print(super.runtimeType);
  }

  final BibliaLeituraRepository bibliaLeituraRepository;

  Future<Result<List<VersaoModel>>> versoes() => bibliaLeituraRepository.versoes();

  /// Testamentos na ordem do filtro do índice: Novo antes do Antigo (a API devolve por `test_id` crescente,
  /// então a lista é ordenada por `testId` decrescente).
  Future<Result<List<TestamentoModel>>> testamentos() async {
    final result = await bibliaLeituraRepository.testamentos();
    switch (result) {
      case Ok<List<TestamentoModel>>(value: final testamentos):
        return Result.ok([...testamentos]..sort((a, b) => b.testId.compareTo(a.testId)));
      case Error<List<TestamentoModel>>(error: final error):
        return Result.error(error);
    }
  }

  Future<Result<List<LivroModel>>> livros() => bibliaLeituraRepository.livros();

  Future<Result<List<VersiculoTextoModel>>> capitulo(int versaId, CapituloRef ref) =>
      bibliaLeituraRepository.capitulo(versaId, ref.livrId, ref.capiNumero);

  /// Capítulos da versão agrupados por livro, em ordem; capítulos sem versículos na versão ficam de fora.
  Future<Result<Map<int, List<IndiceCapituloModel>>>> indice(int versaId) async {
    final result = await bibliaLeituraRepository.indice(versaId);
    switch (result) {
      case Ok<List<IndiceCapituloModel>>(value: final capitulos):
        final porLivro = <int, List<IndiceCapituloModel>>{};
        for (final capitulo in capitulos) {
          if (capitulo.versTotal <= 0) continue;
          porLivro.putIfAbsent(capitulo.livrId, () => []).add(capitulo);
        }
        for (final lista in porLivro.values) {
          lista.sort((a, b) => a.capiNumero.compareTo(b.capiNumero));
        }
        return Result.ok(porLivro);
      case Error<List<IndiceCapituloModel>>(error: final error):
        return Result.error(error);
    }
  }

  /// Progresso de leitura do usuário na versão, indexado por [CapituloLidoModel.chave].
  Future<Result<Map<String, CapituloLidoModel>>> lidos(int versaId) async {
    final result = await bibliaLeituraRepository.lidos(versaId);
    switch (result) {
      case Ok<List<CapituloLidoModel>>(value: final lidos):
        return Result.ok({for (final lido in lidos) lido.chave: lido});
      case Error<List<CapituloLidoModel>>(error: final error):
        return Result.error(error);
    }
  }

  /// Capítulos com leitura, do mais recente para o mais antigo (sem data ficam no fim, na ordem da Bíblia).
  List<CapituloLidoModel> historico(Iterable<CapituloLidoModel> lidos) {
    final lista = lidos.toList();
    lista.sort((a, b) {
      final da = a.lidoEm;
      final db = b.lidoEm;
      if (da != null && db != null) return db.compareTo(da);
      if (da != null) return -1;
      if (db != null) return 1;
      final livro = a.livrId.compareTo(b.livrId);
      return livro != 0 ? livro : a.capiNumero.compareTo(b.capiNumero);
    });
    return lista;
  }

  /// Marca o capítulo como lido, ou desmarca se [atual] já estava completo. Devolve o novo progresso do
  /// capítulo, ou nulo quando ele foi desmarcado.
  Future<Result<CapituloLidoModel?>> alternarCapitulo(
    int versaId,
    IndiceCapituloModel capitulo,
    LivroModel? livro,
    CapituloLidoModel? atual,
  ) async {
    final lido = !(atual?.completo ?? false);
    final result = await bibliaLeituraRepository.marcarCapitulo(
      versaId,
      capitulo.livrId,
      capitulo.capiNumero,
      lido: lido,
    );
    switch (result) {
      case Ok<int>(value: final total):
        if (!lido) return const Result.ok(null);
        return Result.ok(
          CapituloLidoModel(
            livrId: capitulo.livrId,
            livrNome: livro?.livrNome ?? capitulo.livrNome,
            livrAbrev: livro?.livrAbrev ?? '',
            capiNumero: capitulo.capiNumero,
            versTotal: total,
            versLidos: total,
            lidoEm: DateTime.now(),
          ),
        );
      case Error<int>(error: final error):
        return Result.error(error);
    }
  }

  /// Capítulo vizinho de [atual] na ordem da Bíblia ([passo] -1 anterior, 1 próximo), passando de um livro para
  /// o outro; nulo no início ou no fim. [livros] define a ordem dos livros.
  CapituloRef? vizinho(
    Map<int, List<IndiceCapituloModel>> indice,
    List<LivroModel> livros,
    CapituloRef atual,
    int passo,
  ) {
    final ordem = <CapituloRef>[
      for (final livro in livros)
        for (final capitulo in indice[livro.livrId] ?? const <IndiceCapituloModel>[])
          (livrId: capitulo.livrId, capiNumero: capitulo.capiNumero),
    ];
    final posicao = ordem.indexOf(atual);
    if (posicao < 0) return null;
    final destino = posicao + passo;
    return destino >= 0 && destino < ordem.length ? ordem[destino] : null;
  }
}
