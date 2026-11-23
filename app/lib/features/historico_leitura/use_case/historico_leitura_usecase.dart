import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../data/model/biblia/capitulo_lido_model.dart';
import '../../../data/model/biblia/versao_model.dart';
import '../../biblia/biblia_leitura/use_case/biblia_leitura_usecase.dart';
import '../repository/historico_leitura_repository.dart';

/// Filtro da lista do histórico. [chave] é a chave de tradução do rótulo.
enum HistoricoFiltro {
  todos('todos'),
  concluidos('filtroConcluidos'),
  emAndamento('filtroEmAndamento');

  const HistoricoFiltro(this.chave);

  final String chave;
}

/// Período de um grupo do histórico: [hoje], [ontem], um [dia] anterior ou [semData] (leitura sem data gravada).
enum PeriodoHistorico { hoje, ontem, dia, semData }

/// Capítulos lidos no mesmo dia (horário local). [dia] é nulo só em [PeriodoHistorico.semData].
class GrupoHistorico {
  const GrupoHistorico({required this.periodo, this.dia, required this.capitulos});

  final PeriodoHistorico periodo;
  final DateTime? dia;
  final List<CapituloLidoModel> capitulos;

  /// Chave de tradução do título do grupo; nula em [PeriodoHistorico.dia], cujo título é a data formatada na view.
  String? get chave => switch (periodo) {
    PeriodoHistorico.hoje => 'hoje',
    PeriodoHistorico.ontem => 'ontem',
    PeriodoHistorico.semData => 'semData',
    PeriodoHistorico.dia => null,
  };
}

/// Resumo do histórico na versão: capítulos com leitura, concluídos, em andamento e total de versículos lidos.
typedef ResumoHistorico = ({int capitulos, int concluidos, int emAndamento, int versiculos});

/// Regras da tela "Histórico de leitura" (`/historico-leitura`):
/// - a tela abre na versão escolhida pelo usuário (a mesma da leitura, via [BibliaLeituraUseCase.versaoInicial]) e
///   trocar a versão aqui também a salva para a leitura;
/// - o histórico vem de `versiculo-reacao/lidos` (com a leitura offline, também o que está só no aparelho) e é
///   ordenado do mais recente para o mais antigo, como na folha da leitura ([BibliaLeituraUseCase.historico]);
/// - 404 `registroNaoEncontrado` vira histórico vazio;
/// - [filtrar] separa concluídos (todos os versículos lidos) e em andamento (parte dos versículos lidos);
/// - [agrupar] junta os capítulos por dia da última leitura, em horário local: hoje, ontem, os demais dias e, por
///   último, os sem data;
/// - [continuar] é o capítulo em andamento lido mais recentemente;
/// - tocar num capítulo abre a leitura nele, na versão do histórico ([destino]).
class HistoricoLeituraUseCase {
  HistoricoLeituraUseCase({
    required this.historicoLeituraRepository,
    required this.bibliaLeituraUseCase,
    DateTime Function()? relogio,
  }) : _relogio = relogio ?? DateTime.now {
    Log.print(super.runtimeType);
  }

  final HistoricoLeituraRepository historicoLeituraRepository;

  /// Versões, preferência de versão e ordem do histórico, compartilhadas com a leitura.
  final BibliaLeituraUseCase bibliaLeituraUseCase;

  /// Data e hora atuais (injetável nos testes), base de "hoje" e "ontem".
  final DateTime Function() _relogio;

  Future<Result<List<VersaoModel>>> versoes() => bibliaLeituraUseCase.versoes();

  /// Versão salva pelo usuário, se ainda existir; senão a primeira. Nula se não há versões.
  VersaoModel? versaoInicial(List<VersaoModel> versoes) => bibliaLeituraUseCase.versaoInicial(versoes);

  void salvarVersao(VersaoModel versao) => bibliaLeituraUseCase.salvarVersao(versao);

  /// Capítulos com leitura na versão, do mais recente para o mais antigo.
  Future<Result<List<CapituloLidoModel>>> historico(int versaId) async {
    final result = await historicoLeituraRepository.lidos(versaId);
    switch (result) {
      case Ok<List<CapituloLidoModel>>(value: final lidos):
        final comLeitura = lidos.where((c) => c.versLidos > 0);
        return Result.ok(List.unmodifiable(bibliaLeituraUseCase.historico(comLeitura)));
      case Error<List<CapituloLidoModel>>(error: final error):
        if (_semRegistros(error)) return const Result.ok([]);
        return Result.error(error);
    }
  }

  /// Capítulos de [historico] que atendem ao [filtro], na mesma ordem.
  List<CapituloLidoModel> filtrar(List<CapituloLidoModel> historico, HistoricoFiltro filtro) => switch (filtro) {
    HistoricoFiltro.todos => historico,
    HistoricoFiltro.concluidos => historico.where((c) => c.completo).toList(growable: false),
    HistoricoFiltro.emAndamento => historico.where((c) => !c.completo).toList(growable: false),
  };

  /// Quantidade de capítulos de [historico] em cada [filtro] (o rótulo dos filtros mostra a quantidade).
  int quantidade(List<CapituloLidoModel> historico, HistoricoFiltro filtro) => filtrar(historico, filtro).length;

  ResumoHistorico resumo(List<CapituloLidoModel> historico) {
    var concluidos = 0;
    var versiculos = 0;
    for (final capitulo in historico) {
      if (capitulo.completo) concluidos++;
      versiculos += capitulo.versTotal > 0 ? capitulo.versLidos.clamp(0, capitulo.versTotal) : capitulo.versLidos;
    }
    return (
      capitulos: historico.length,
      concluidos: concluidos,
      emAndamento: historico.length - concluidos,
      versiculos: versiculos,
    );
  }

  /// Fração (0 a 1) de versículos lidos no capítulo.
  double fracao(CapituloLidoModel capitulo) =>
      capitulo.versTotal <= 0 ? 0 : (capitulo.versLidos / capitulo.versTotal).clamp(0, 1).toDouble();

  /// Capítulos agrupados pelo dia da última leitura, mantendo a ordem de [capitulos] dentro de cada grupo. Os
  /// grupos vão do dia mais recente para o mais antigo; os sem data ficam no último grupo.
  List<GrupoHistorico> agrupar(List<CapituloLidoModel> capitulos) {
    final agora = _relogio();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final ontem = DateTime(hoje.year, hoje.month, hoje.day - 1);

    final porDia = <DateTime, List<CapituloLidoModel>>{};
    final semData = <CapituloLidoModel>[];
    for (final capitulo in capitulos) {
      final lidoEm = capitulo.lidoEm?.toLocal();
      if (lidoEm == null) {
        semData.add(capitulo);
        continue;
      }
      porDia.putIfAbsent(DateTime(lidoEm.year, lidoEm.month, lidoEm.day), () => []).add(capitulo);
    }

    final dias = porDia.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final dia in dias)
        GrupoHistorico(
          periodo: dia == hoje
              ? PeriodoHistorico.hoje
              : dia == ontem
              ? PeriodoHistorico.ontem
              : PeriodoHistorico.dia,
          dia: dia,
          capitulos: List.unmodifiable(porDia[dia]!),
        ),
      if (semData.isNotEmpty) GrupoHistorico(periodo: PeriodoHistorico.semData, capitulos: List.unmodifiable(semData)),
    ];
  }

  /// Capítulo em andamento lido mais recentemente (para "Continuar leitura"); nulo se todos estão concluídos.
  /// [historico] deve estar na ordem de [historico] (mais recente primeiro).
  CapituloLidoModel? continuar(List<CapituloLidoModel> historico) => historico.where((c) => !c.completo).firstOrNull;

  /// Ponto da leitura para abrir o [capitulo] na versão [versaId].
  LeituraDestino destino(int versaId, CapituloLidoModel capitulo) =>
      LeituraDestino(versaId: versaId, livrId: capitulo.livrId, capiNumero: capitulo.capiNumero);

  static bool _semRegistros(Exception error) =>
      (error is HttpServiceException && error.message == kRegistroNaoEncontrado) ||
      (error is HandledException && error.message == kRegistroNaoEncontrado);

  static const kRegistroNaoEncontrado = 'registroNaoEncontrado';
}
