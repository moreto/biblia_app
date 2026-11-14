import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/dicionario/dicionario_busca_model.dart';
import '../../../../data/model/dicionario/dicionario_verbete_model.dart';
import '../repository/dicionario_repository.dart';

/// Resultado da consulta de uma palavra: os verbetes (um por homônimo) ou, se a palavra não existir, as
/// [sugestoes] semelhantes.
class DicionarioConsulta {
  const DicionarioConsulta({required this.termo, this.verbetes = const [], this.sugestoes = const []});

  /// Texto consultado, já normalizado.
  final String termo;
  final List<DicionarioVerbeteModel> verbetes;

  /// Palavras semelhantes, quando a palavra não foi encontrada.
  final List<DicionarioBuscaModel> sugestoes;

  bool get encontrada => verbetes.isNotEmpty;
}

/// Trecho de um texto do dicionário; [italico] para o que vem entre `_sublinhados_`.
typedef DicionarioTrecho = ({String texto, bool italico});

/// Regras da tela "Dicionário" (busca e consulta na mesma página):
/// - o texto é normalizado ([normalizar]: sem espaços nas pontas e repetidos); vazio não chama a API e mais de
///   [textoMaximo] caracteres vira `textoBuscaMuitoLongo`;
/// - [buscar] (enquanto digita) só chama `/v1/dicionario/busca` a partir de [buscaMinimo] caracteres, com até
///   [buscaLimite] palavras;
/// - [consultar] traz os verbetes de `/v1/dicionario/palavra/:palavra`; se a palavra não existir, traz as
///   semelhantes da busca como sugestões;
/// - textos: [trechos] separa o itálico (`_assim_`), [resumo] deixa a definição numa linha só, sem marcas;
///   [titulo] acrescenta o homônimo sobrescrito (Abegão¹); [usos] junta os rótulos de uso da acepção;
/// - remissões "(V. termo)" só são navegáveis quando o termo existe no dicionário ([remissoes]).
class DicionarioUseCase {
  DicionarioUseCase({required this.dicionarioRepository}) {
    Log.print(super.runtimeType);
  }

  final DicionarioRepository dicionarioRepository;

  /// Mínimo de caracteres para a busca enquanto digita.
  static const buscaMinimo = 2;

  /// Máximo de caracteres aceito pela API (busca e palavra).
  static const textoMaximo = 64;

  /// Palavras trazidas pela busca (e pelas sugestões).
  static const buscaLimite = 20;

  static const kTextoMuitoLongo = 'textoBuscaMuitoLongo';

  /// Palavras que começam pelo [texto] ou são semelhantes; lista vazia abaixo de [buscaMinimo] caracteres.
  Future<Result<List<DicionarioBuscaModel>>> buscar(String texto) async {
    final termo = normalizar(texto);
    if (termo.length < buscaMinimo) return const Result.ok([]);
    final erro = validar(termo);
    if (erro != null) return Result.error(HandledException(message: erro));
    return dicionarioRepository.buscar(termo, limite: buscaLimite);
  }

  /// Verbetes da palavra; se ela não existir, as semelhantes viram [DicionarioConsulta.sugestoes].
  Future<Result<DicionarioConsulta>> consultar(String texto) async {
    final termo = normalizar(texto);
    final erro = validar(termo);
    if (erro != null) return Result.error(HandledException(message: erro));

    final result = await dicionarioRepository.palavra(termo);
    switch (result) {
      case Ok<List<DicionarioVerbeteModel>>(value: final verbetes) when verbetes.isNotEmpty:
        return Result.ok(DicionarioConsulta(termo: termo, verbetes: ordenar(verbetes)));
      case Ok<List<DicionarioVerbeteModel>>():
        final busca = await dicionarioRepository.buscar(termo, limite: buscaLimite);
        return switch (busca) {
          Ok<List<DicionarioBuscaModel>>(value: final sugestoes) => Result.ok(
            DicionarioConsulta(termo: termo, sugestoes: sugestoes),
          ),
          Error<List<DicionarioBuscaModel>>(error: final error) => Result.error(error),
        };
      case Error<List<DicionarioVerbeteModel>>(error: final error):
        return Result.error(error);
    }
  }

  /// Sem espaços nas pontas e com espaços repetidos reduzidos a um.
  static String normalizar(String texto) => texto.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Problema do texto (chave de tradução); nulo se pode consultar. Vazio é inválido.
  static String? validar(String termo) {
    if (termo.isEmpty) return 'dadosInvalidos';
    if (termo.length > textoMaximo) return kTextoMuitoLongo;
    return null;
  }

  /// Homônimos em ordem (sem número primeiro) e acepções na ordem de `daceSeq`.
  static List<DicionarioVerbeteModel> ordenar(List<DicionarioVerbeteModel> verbetes) =>
      [...verbetes]..sort((a, b) => (a.dverHomonimo ?? 0).compareTo(b.dverHomonimo ?? 0));

  /// Acepções do verbete na ordem do original.
  static List<DicionarioAcepcaoModel> acepcoes(DicionarioVerbeteModel verbete) =>
      [...verbete.acepcoes]..sort((a, b) => a.daceSeq.compareTo(b.daceSeq));

  /// Palavra com o homônimo sobrescrito ("Abegão¹"); sem homônimo, só a palavra.
  static String titulo(String palavra, int? homonimo) =>
      homonimo == null ? palavra : '$palavra${sobrescrito(homonimo)}';

  /// Número em algarismos sobrescritos (12 → ¹²).
  static String sobrescrito(int numero) =>
      numero.abs().toString().split('').map((d) => _sobrescritos[int.parse(d)]).join();

  /// Separa o texto em trechos normais e em itálico (`_assim_` no original).
  static List<DicionarioTrecho> trechos(String texto) {
    final trechos = <DicionarioTrecho>[];
    var inicio = 0;
    for (final m in _italico.allMatches(texto)) {
      if (m.start > inicio) trechos.add((texto: texto.substring(inicio, m.start), italico: false));
      trechos.add((texto: m.group(1)!, italico: true));
      inicio = m.end;
    }
    if (inicio < texto.length) trechos.add((texto: texto.substring(inicio), italico: false));
    return trechos;
  }

  /// Texto sem as marcas de itálico.
  static String semMarcas(String texto) => texto.replaceAllMapped(_italico, (m) => m.group(1)!);

  /// Definição numa linha só e sem marcas, para a lista de sugestões; nula se vazia.
  static String? resumo(String? definicao) {
    final texto = semMarcas(definicao ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
    return texto.isEmpty ? null : texto;
  }

  /// Rótulos de uso da acepção ("Prov.", "Bras.", "Med."...), na ordem do original.
  static List<String> usos(DicionarioAcepcaoModel acepcao) => [
    for (final u in acepcao.usos)
      if (u.dusoTexto.trim().isNotEmpty) u.dusoTexto.trim(),
  ];

  /// Remissões "(V. termo)" da acepção; [navegavel] quando o termo existe no dicionário.
  static List<({String termo, bool navegavel})> remissoes(DicionarioAcepcaoModel acepcao) => [
    for (final r in acepcao.remissoes) (termo: r.dremTermo, navegavel: r.dverId != null),
  ];

  static String mensagemErro(Exception error) => switch (error) {
    HandledException(message: final message) => message,
    HttpServiceException(message: final message?) => message,
    _ => kDefaultAppError,
  };

  static final _italico = RegExp(r'_([^_]+)_');
  static const _sobrescritos = ['⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹'];
}
