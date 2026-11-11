import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/comunidade/comunidade_local_model.dart';
import '../../../../data/model/localidade/estado_model.dart';
import '../../../../data/model/localidade/municipio_model.dart';
import '../repository/comunidade_lista_repository.dart';

/// Regras da tela "Encontrar comunidades" (todas as comunidades, de qualquer usuário, por estado e cidade):
/// - o estado é obrigatório para buscar (`selecioneEstado`, sem chamar a API); a cidade é opcional (sem ela, todas
///   as cidades do estado); uma cidade de outro estado é ignorada;
/// - as comunidades vêm de `/v1/comunidade?estaId=&muniId=`, uma por comunidade, ordenadas pelo nome (sem
///   diferenciar maiúsculas); 404 `registroNaoEncontrado` vira lista vazia;
/// - estados e municípios ficam em cache (municípios por estado);
/// - textos do card: [descricao] (tipo · denominação), [linhaEndereco] e [linhaLocal].
class ComunidadeListaUseCase {
  ComunidadeListaUseCase({required this.comunidadeListaRepository}) {
    Log.print(super.runtimeType);
  }

  final ComunidadeListaRepository comunidadeListaRepository;

  List<EstadoModel>? _estados;
  final Map<int, List<MunicipioModel>> _municipios = {};

  Future<Result<List<EstadoModel>>> estados() async {
    final cache = _estados;
    if (cache != null) return Result.ok(cache);
    final result = await comunidadeListaRepository.estados();
    if (result case Ok(value: final value)) _estados = value;
    return result;
  }

  Future<Result<List<MunicipioModel>>> municipios(int estaId) async {
    final cache = _municipios[estaId];
    if (cache != null) return Result.ok(cache);
    final result = await comunidadeListaRepository.municipios(estaId);
    if (result case Ok(value: final value)) _municipios[estaId] = value;
    return result;
  }

  /// Comunidades do estado [estaId] e, se informada, da cidade [muniId]. Sem estado, `selecioneEstado`.
  /// [municipiosDoEstado] (quando conhecidos) descartam uma cidade que não é do estado.
  Future<Result<List<ComunidadeLocalModel>>> comunidades({
    int? estaId,
    int? muniId,
    List<MunicipioModel>? municipiosDoEstado,
  }) async {
    if (estaId == null || estaId < 1) return Result.error(HandledException(message: 'selecioneEstado'));
    final cidade = municipiosDoEstado == null || municipiosDoEstado.any((m) => m.muniId == muniId) ? muniId : null;

    final result = await comunidadeListaRepository.comunidades(estaId: estaId, muniId: cidade);
    switch (result) {
      case Ok<List<ComunidadeLocalModel>>(value: final lista):
        return Result.ok(ordenar(lista));
      case Error<List<ComunidadeLocalModel>>(error: final error):
        if (_semRegistros(error)) return const Result.ok([]);
        return result;
    }
  }

  static List<ComunidadeLocalModel> ordenar(List<ComunidadeLocalModel> lista) =>
      [...lista]..sort((a, b) => a.comuNome.trim().toLowerCase().compareTo(b.comuNome.trim().toLowerCase()));

  /// "Tipo · Denominação", só com o que houver; nula se nada.
  static String? descricao(ComunidadeLocalModel comunidade) {
    final partes = [?_texto(comunidade.ctipNome), ?_texto(comunidade.cdenNome)];
    return partes.isEmpty ? null : partes.join(' · ');
  }

  /// "Logradouro, Número - Complemento", só com o que houver; nula sem logradouro.
  static String? linhaEndereco(ComunidadeLocalModel comunidade) {
    final logradouro = _texto(comunidade.cendLogradouro);
    if (logradouro == null) return null;
    final base = [logradouro, ?_texto(comunidade.cendNumero)].join(', ');
    final complemento = _texto(comunidade.cendComplemento);
    return complemento == null ? base : '$base - $complemento';
  }

  /// "Bairro · Município - UF", só com o que houver; nula se nada.
  static String? linhaLocal(ComunidadeLocalModel comunidade) {
    final municipio = [?_texto(comunidade.muniNome), ?_texto(comunidade.estaSigla)].join(' - ');
    final partes = [?_texto(comunidade.cendBairro), if (municipio.isNotEmpty) municipio];
    return partes.isEmpty ? null : partes.join(' · ');
  }

  /// Chave de tradução da mensagem de um erro.
  static String mensagemErro(Exception error) => switch (error) {
    HandledException(message: final message) => message,
    HttpServiceException(message: final message?) => message,
    _ => kDefaultAppError,
  };

  static String? _texto(String? valor) {
    final texto = valor?.trim();
    return (texto?.isEmpty ?? true) ? null : texto;
  }

  static bool _semRegistros(Exception error) =>
      (error is HttpServiceException && error.message == kRegistroNaoEncontrado) ||
      (error is HandledException && error.message == kRegistroNaoEncontrado);

  static const kRegistroNaoEncontrado = 'registroNaoEncontrado';
}
