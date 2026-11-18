import 'package:commons/commons.dart';
import 'package:intl/intl.dart';

import '../../../../data/model/configuracao/configuracao_item_model.dart';
import '../../../../data/model/configuracao/configuracao_model.dart';
import '../../../../data/model/leitura/leitura_agenda_model.dart';
import '../../../../data/model/leitura/leitura_model.dart';
import '../../grupo_leitura/use_case/grupo_leitura_usecase.dart';
import '../repository/grupo_leitura_agenda_repository.dart';

/// Opção de uma configuração da agenda: [chave] (`cite_chave`, gravada no item) e [rotulo] (`cite_valor`, chave de
/// tradução).
typedef AgendaOpcao = ({int chave, String rotulo});

/// Opções do formulário da agenda, vindas das configurações `agendaRepeticao`, `agendaFimRepeticao` e
/// `agendaLembrete`.
class AgendaOpcoes {
  const AgendaOpcoes({this.repeticoes = const [], this.fimRepeticoes = const [], this.lembretes = const []});

  final List<AgendaOpcao> repeticoes;
  final List<AgendaOpcao> fimRepeticoes;
  final List<AgendaOpcao> lembretes;
}

/// Regras da aba "Agenda" (itens da agenda do grupo selecionado):
/// - os grupos selecionáveis são os de "Meus grupos" (via [GrupoLeituraUseCase]);
/// - [agenda] vem de `/v1/leitura-agenda/:leitId`, por data e hora, os sem data por último, e por id ([ordenar]);
///   404 vira lista vazia;
/// - gravação ([salvar]): só o dono; título obrigatório (sem espaços nas pontas, até [kTituloMax]) e texto opcional
///   (até [kTextoMax]; vazio vira nulo) ([validar]); data e hora opcionais. Sem `lageId` inclui, com `lageId`
///   altera. A hora da atividade, que a tela não edita, é mantida;
/// - repetição, fim da repetição e lembrete são opcionais e escolhidos entre os itens ativos das configurações
///   `agendaRepeticao`, `agendaFimRepeticao` e `agendaLembrete` ([opcoes], em cache; achadas pelo `confCodigo` ou,
///   se a API não o devolver, pelo nome). Valor fora das opções: `opcaoAgendaInvalida`. Repetição e lembrete exigem
///   data (`repeticaoExigeData`, `lembreteExigeData`); sem repetição, o fim da repetição é descartado. Falha ao ler
///   as configurações não impede a agenda: as opções ficam vazias;
/// - [excluir] remove o item e, na API, as atividades dele; só o dono.
class GrupoLeituraAgendaUseCase {
  GrupoLeituraAgendaUseCase({required this.grupoLeituraAgendaRepository, required this.grupoLeituraUseCase}) {
    Log.print(super.runtimeType);
  }

  final GrupoLeituraAgendaRepository grupoLeituraAgendaRepository;

  /// Grupos do usuário logado (mesmas regras da aba "Meus grupos").
  final GrupoLeituraUseCase grupoLeituraUseCase;

  /// Tamanhos máximos de `lage_titulo` e `lage_texto` (também `laat_texto`).
  static const kTituloMax = 128;
  static const kTextoMax = 4000;

  /// Configurações das opções, pelo código (e o nome, para as gravadas sem código).
  static const kConfigRepeticao = (codigo: 'agendaRepeticao', nome: 'Agenda - Repetição');
  static const kConfigFimRepeticao = (codigo: 'agendaFimRepeticao', nome: 'Agenda - Fim Repetição');
  static const kConfigLembrete = (codigo: 'agendaLembrete', nome: 'Agenda - Lembrete');

  static const kOpcaoInvalida = 'opcaoAgendaInvalida';

  AgendaOpcoes? _opcoes;

  static final _data = DateFormat('dd/MM/yyyy');
  static final _dataHora = DateFormat('dd/MM/yyyy HH:mm');

  Future<Result<List<LeituraModel>>> grupos() => grupoLeituraUseCase.meusGrupos();

  LeituraModel? selecionado(List<LeituraModel> grupos, int? leitId) => GrupoLeituraUseCase.selecionado(grupos, leitId);

  /// Só o dono do [grupo] inclui, altera e exclui itens.
  bool podeAlterar(LeituraModel? grupo) => grupo?.leitDono ?? false;

  Future<Result<List<LeituraAgendaModel>>> agenda(int leitId) async {
    final result = await grupoLeituraAgendaRepository.agenda(leitId);
    switch (result) {
      case Ok<List<LeituraAgendaModel>>(value: final lista):
        return Result.ok(ordenar(lista));
      case Error<List<LeituraAgendaModel>>(error: final error):
        if (GrupoLeituraUseCase.semRegistros(error)) return const Result.ok([]);
        return result;
    }
  }

  /// Opções de repetição, fim da repetição e lembrete (em cache depois da primeira leitura com sucesso). Falha
  /// devolve opções vazias, sem guardar em cache.
  Future<AgendaOpcoes> opcoes() async {
    final cache = _opcoes;
    if (cache != null) return cache;

    final configuracoes = await grupoLeituraAgendaRepository.configuracoes();
    final List<ConfiguracaoModel> lista;
    switch (configuracoes) {
      case Ok(value: final value):
        lista = value;
      case Error(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
        return const AgendaOpcoes();
    }

    final (repeticoes, fimRepeticoes, lembretes) = await (
      _itens(lista, kConfigRepeticao),
      _itens(lista, kConfigFimRepeticao),
      _itens(lista, kConfigLembrete),
    ).wait;
    if (repeticoes == null || fimRepeticoes == null || lembretes == null) return const AgendaOpcoes();
    return _opcoes = AgendaOpcoes(repeticoes: repeticoes, fimRepeticoes: fimRepeticoes, lembretes: lembretes);
  }

  /// Itens ativos da configuração, em ordem; lista vazia se ela não existir; nulo se a consulta falhar.
  Future<List<AgendaOpcao>?> _itens(
    List<ConfiguracaoModel> configuracoes,
    ({String codigo, String nome}) config,
  ) async {
    final confId = configuracao(configuracoes, codigo: config.codigo, nome: config.nome)?.confId;
    if (confId == null) return const [];
    switch (await grupoLeituraAgendaRepository.itens(confId)) {
      case Ok(value: final itens):
        return opcoesDe(itens);
      case Error(error: final error):
        if (GrupoLeituraUseCase.semRegistros(error)) return const [];
        Log.print(error.toString(), name: kApp, title: 'Erro');
        return null;
    }
  }

  /// Configuração pelo [codigo]; se a API não devolver códigos, pelo [nome].
  static ConfiguracaoModel? configuracao(
    List<ConfiguracaoModel> configuracoes, {
    required String codigo,
    required String nome,
  }) =>
      configuracoes.where((c) => c.confCodigo == codigo).firstOrNull ??
      configuracoes.where((c) => c.confCodigo == null && c.confNome.trim() == nome).firstOrNull;

  /// Itens ativos com chave inteira e rótulo, na ordem de `cite_sequencia` (sem sequência por último).
  static List<AgendaOpcao> opcoesDe(List<ConfiguracaoItemModel> itens) {
    final ativos = [
      for (final item in itens)
        if (item.citeAtivo && int.tryParse(item.citeChave?.trim() ?? '') != null && (item.citeValor ?? '').trim() != '')
          item,
    ]..sort((a, b) => (a.citeSequencia ?? 1 << 30).compareTo(b.citeSequencia ?? 1 << 30));
    return List.unmodifiable([
      for (final i in ativos) (chave: int.parse(i.citeChave!.trim()), rotulo: i.citeValor!.trim()),
    ]);
  }

  /// Rótulo (chave de tradução) da opção [chave] em [opcoes]; nulo sem chave ou se ela não estiver na lista.
  static String? rotulo(int? chave, List<AgendaOpcao> opcoes) {
    if (chave == null) return null;
    for (final opcao in opcoes) {
      if (opcao.chave == chave) return opcao.rotulo;
    }
    return null;
  }

  /// Por data e hora (sem data por último) e id, como a API.
  static List<LeituraAgendaModel> ordenar(List<LeituraAgendaModel> lista) => List.unmodifiable(
    [...lista]..sort((a, b) {
      final da = a.lageDataHora;
      final db = b.lageDataHora;
      if (da != null && db != null && da != db) return da.compareTo(db);
      if (da == null && db != null) return 1;
      if (da != null && db == null) return -1;
      return (a.lageId ?? 0).compareTo(b.lageId ?? 0);
    }),
  );

  /// Chave de tradução do primeiro problema do [item] a gravar; nula se ele pode ser gravado.
  String? validar(LeituraAgendaModel item) {
    final titulo = item.lageTitulo?.trim() ?? '';
    if (titulo.isEmpty) return 'informeTituloAgenda';
    if (titulo.length > kTituloMax) return 'tituloAgendaMuitoLongo';
    if ((item.lageTexto?.trim().length ?? 0) > kTextoMax) return 'textoAgendaMuitoLongo';
    if (item.lageDataHora == null && item.lageRepete != null) return 'repeticaoExigeData';
    if (item.lageDataHora == null && item.lageLembrete != null) return 'lembreteExigeData';
    final opcoes = _opcoes ?? const AgendaOpcoes();
    for (final (chave, lista) in [
      (item.lageRepete, opcoes.repeticoes),
      (item.lageRepete == null ? null : item.lageFimRepete, opcoes.fimRepeticoes),
      (item.lageLembrete, opcoes.lembretes),
    ]) {
      if (chave != null && rotulo(chave, lista) == null) return kOpcaoInvalida;
    }
    return null;
  }

  /// Inclui (sem `lageId`) ou altera o [item] do [grupo], depois de [validar].
  Future<Result<LeituraAgendaModel>> salvar(LeituraModel? grupo, LeituraAgendaModel item) async {
    if (grupo?.leitId == null) return Result.error(HandledException(message: GrupoLeituraUseCase.kGrupoObrigatorio));
    if (!podeAlterar(grupo)) return Result.error(HandledException(message: GrupoLeituraUseCase.kSomenteDonoAltera));
    final erro = validar(item);
    if (erro != null) return Result.error(HandledException(message: erro));

    final texto = item.lageTexto?.trim();
    final registro = LeituraAgendaModel(
      lageId: item.lageId,
      leitId: grupo!.leitId!,
      lageTitulo: item.lageTitulo!.trim(),
      lageTexto: (texto?.isEmpty ?? true) ? null : texto,
      lageDataHora: item.lageDataHora,
      lageHoraAtividade: item.lageHoraAtividade,
      lageRepete: item.lageRepete,
      lageFimRepete: item.lageRepete == null ? null : item.lageFimRepete,
      lageLembrete: item.lageLembrete,
    );
    return registro.lageId == null
        ? grupoLeituraAgendaRepository.incluir(registro)
        : grupoLeituraAgendaRepository.alterar(registro);
  }

  /// Exclui o [item] (e as atividades dele); só o dono do [grupo].
  Future<Result<void>> excluir(LeituraModel? grupo, LeituraAgendaModel item) async {
    final lageId = item.lageId;
    if (lageId == null) return Result.error(HandledException(message: GrupoLeituraUseCase.kRegistroNaoEncontrado));
    if (!podeAlterar(grupo)) return Result.error(HandledException(message: GrupoLeituraUseCase.kSomenteDonoAltera));
    return grupoLeituraAgendaRepository.excluir(lageId);
  }

  // ---------- textos ----------

  /// Data e hora como "dd/MM/yyyy HH:mm"; nula sem data.
  static String? dataHora(DateTime? quando) => quando == null ? null : _dataHora.format(quando);

  /// Só a data, "dd/MM/yyyy"; nula sem data.
  static String? data(DateTime? quando) => quando == null ? null : _data.format(quando);

  /// Hora da API (`HH:MM[:SS]`) como "HH:mm"; nula se vazia ou fora do formato.
  static String? hora(String? valor) {
    final partes = horaMinuto(valor);
    if (partes == null) return null;
    return '${partes.hora.toString().padLeft(2, '0')}:${partes.minuto.toString().padLeft(2, '0')}';
  }

  /// Hora e minuto de um valor `HH:MM[:SS]`; nulo se vazio ou fora do formato.
  static ({int hora, int minuto})? horaMinuto(String? valor) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})(:\d{2})?$').firstMatch(valor?.trim() ?? '');
    if (match == null) return null;
    final hora = int.parse(match.group(1)!);
    final minuto = int.parse(match.group(2)!);
    if (hora > 23 || minuto > 59) return null;
    return (hora: hora, minuto: minuto);
  }

  /// Hora no formato gravado pela API, `HH:MM:00`.
  static String horaApi(int hora, int minuto) =>
      '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}:00';

  /// Data e hora juntas (a hora sem data fica nula: a API grava data e hora num campo só).
  static DateTime? juntar(DateTime? data, ({int hora, int minuto})? hora) =>
      data == null ? null : DateTime(data.year, data.month, data.day, hora?.hora ?? 0, hora?.minuto ?? 0);
}
