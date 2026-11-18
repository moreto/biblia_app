import 'package:commons/commons.dart';

import '../../../../data/model/biblia/livro_model.dart';
import '../../../../data/model/leitura/leitura_agenda_atividade_model.dart';
import '../../../../data/model/leitura/leitura_agenda_model.dart';
import '../../../../data/model/leitura/leitura_model.dart';
import '../../grupo_leitura/use_case/grupo_leitura_usecase.dart';
import '../../grupo_leitura_agenda/use_case/grupo_leitura_agenda_usecase.dart';
import '../repository/grupo_leitura_atividade_repository.dart';

/// Regras da aba "Atividades" (atividades de um item da agenda do grupo selecionado):
/// - grupos e itens da agenda selecionáveis vêm de [GrupoLeituraAgendaUseCase] (mesmas regras da aba "Agenda");
///   [itemSelecionado] escolhe o pedido, se estiver na lista, senão o primeiro;
/// - [atividades] vêm de `/v1/leitura-agenda-atividade/:lageId` por `laatSeq` e id; 404 vira lista vazia;
/// - [livros] (`/v1/livro`) ficam em cache; falha devolve lista vazia (a atividade fica sem nome do livro);
/// - gravação ([salvar]): só o dono; texto ou livro obrigatório (`informeTextoOuLivro`), texto até
///   [GrupoLeituraAgendaUseCase.kTextoMax] ([validar]). A nova atividade vai para o fim (maior `laatSeq` + 1).
///   Música e oração vinculadas são mantidas (a tela não as edita);
/// - [alternarConcluida] marca/desmarca a atividade (PUT) e [excluir] a remove; só o dono.
class GrupoLeituraAtividadeUseCase {
  GrupoLeituraAtividadeUseCase({
    required this.grupoLeituraAtividadeRepository,
    required this.grupoLeituraAgendaUseCase,
  }) {
    Log.print(super.runtimeType);
  }

  final GrupoLeituraAtividadeRepository grupoLeituraAtividadeRepository;

  /// Grupos e agenda (mesmas regras da aba "Agenda").
  final GrupoLeituraAgendaUseCase grupoLeituraAgendaUseCase;

  List<LivroModel>? _livros;

  Future<Result<List<LeituraModel>>> grupos() => grupoLeituraAgendaUseCase.grupos();

  LeituraModel? selecionado(List<LeituraModel> grupos, int? leitId) => GrupoLeituraUseCase.selecionado(grupos, leitId);

  Future<Result<List<LeituraAgendaModel>>> agenda(int leitId) => grupoLeituraAgendaUseCase.agenda(leitId);

  /// Item da agenda selecionado: o de [lageId], se estiver em [agenda]; senão o primeiro. Nulo com a lista vazia.
  static LeituraAgendaModel? itemSelecionado(List<LeituraAgendaModel> agenda, int? lageId) {
    for (final item in agenda) {
      if (item.lageId == lageId) return item;
    }
    return agenda.firstOrNull;
  }

  /// Só o dono do [grupo] inclui, altera, marca e exclui atividades.
  bool podeAlterar(LeituraModel? grupo) => grupo?.leitDono ?? false;

  Future<Result<List<LeituraAgendaAtividadeModel>>> atividades(int lageId) async {
    final result = await grupoLeituraAtividadeRepository.atividades(lageId);
    switch (result) {
      case Ok<List<LeituraAgendaAtividadeModel>>(value: final lista):
        return Result.ok(ordenar(lista));
      case Error<List<LeituraAgendaAtividadeModel>>(error: final error):
        if (GrupoLeituraUseCase.semRegistros(error)) return const Result.ok([]);
        return result;
    }
  }

  static List<LeituraAgendaAtividadeModel> ordenar(List<LeituraAgendaAtividadeModel> lista) => List.unmodifiable(
    [...lista]..sort((a, b) {
      final seq = a.laatSeq.compareTo(b.laatSeq);
      return seq != 0 ? seq : (a.laatId ?? 0).compareTo(b.laatId ?? 0);
    }),
  );

  /// Livros da Bíblia (em cache depois da primeira leitura com sucesso); falha devolve lista vazia.
  Future<List<LivroModel>> livros() async {
    final cache = _livros;
    if (cache != null) return cache;
    final result = await grupoLeituraAtividadeRepository.livros();
    switch (result) {
      case Ok<List<LivroModel>>(value: final lista):
        return _livros = List.unmodifiable(lista);
      case Error<List<LivroModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
        return const [];
    }
  }

  /// Chave de tradução do primeiro problema da [atividade] a gravar; nula se ela pode ser gravada.
  String? validar(LeituraAgendaAtividadeModel atividade) {
    final texto = atividade.laatTexto?.trim() ?? '';
    if (texto.isEmpty && atividade.livrId == null) return 'informeTextoOuLivro';
    if (texto.length > GrupoLeituraAgendaUseCase.kTextoMax) return 'textoAgendaMuitoLongo';
    return null;
  }

  /// Inclui (sem `laatId`, no fim de [atividades]) ou altera a [atividade] do [item], depois de [validar].
  Future<Result<LeituraAgendaAtividadeModel>> salvar(
    LeituraModel? grupo,
    LeituraAgendaModel? item,
    LeituraAgendaAtividadeModel atividade,
    List<LeituraAgendaAtividadeModel> atividades,
  ) async {
    final lageId = item?.lageId;
    if (lageId == null) return Result.error(HandledException(message: 'itemAgendaObrigatorio'));
    if (!podeAlterar(grupo)) return Result.error(HandledException(message: GrupoLeituraUseCase.kSomenteDonoAltera));
    final erro = validar(atividade);
    if (erro != null) return Result.error(HandledException(message: erro));

    final texto = atividade.laatTexto?.trim();
    final novo = atividade.laatId == null;
    final registro = LeituraAgendaAtividadeModel(
      laatId: atividade.laatId,
      lageId: lageId,
      livrId: atividade.livrId,
      musiId: atividade.musiId,
      oracId: atividade.oracId,
      laatSeq: novo ? proximaSequencia(atividades) : atividade.laatSeq,
      laatTexto: (texto?.isEmpty ?? true) ? null : texto,
      laatConcluida: atividade.laatConcluida,
    );
    return novo ? grupoLeituraAtividadeRepository.incluir(registro) : grupoLeituraAtividadeRepository.alterar(registro);
  }

  /// Marca como concluída a atividade pendente e como pendente a concluída.
  Future<Result<LeituraAgendaAtividadeModel>> alternarConcluida(
    LeituraModel? grupo,
    LeituraAgendaAtividadeModel atividade,
  ) async {
    if (atividade.laatId == null) {
      return Result.error(HandledException(message: GrupoLeituraUseCase.kRegistroNaoEncontrado));
    }
    if (!podeAlterar(grupo)) return Result.error(HandledException(message: GrupoLeituraUseCase.kSomenteDonoAltera));
    return grupoLeituraAtividadeRepository.alterar(atividade.comConcluida(!atividade.laatConcluida));
  }

  Future<Result<void>> excluir(LeituraModel? grupo, LeituraAgendaAtividadeModel atividade) async {
    final laatId = atividade.laatId;
    if (laatId == null) return Result.error(HandledException(message: GrupoLeituraUseCase.kRegistroNaoEncontrado));
    if (!podeAlterar(grupo)) return Result.error(HandledException(message: GrupoLeituraUseCase.kSomenteDonoAltera));
    return grupoLeituraAtividadeRepository.excluir(laatId);
  }

  /// Maior `laatSeq` + 1 (1 sem atividades).
  static int proximaSequencia(List<LeituraAgendaAtividadeModel> atividades) =>
      atividades.fold<int>(0, (maior, a) => a.laatSeq > maior ? a.laatSeq : maior) + 1;

  /// Nome do livro da [atividade] em [livros]; nulo sem livro ou se ele não estiver na lista.
  static String? nomeLivro(LeituraAgendaAtividadeModel atividade, List<LivroModel> livros) {
    final livrId = atividade.livrId;
    if (livrId == null) return null;
    for (final livro in livros) {
      if (livro.livrId == livrId) return livro.livrNome;
    }
    return null;
  }

  /// Quantas atividades estão concluídas.
  static int concluidas(List<LeituraAgendaAtividadeModel> atividades) =>
      atividades.where((a) => a.laatConcluida).length;
}
