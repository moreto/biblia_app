import 'package:commons/commons.dart';
import 'package:service/service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/model/comunidade/comunidade_contato_model.dart';
import '../../../../data/model/comunidade/comunidade_endereco_model.dart';
import '../../../../data/model/comunidade/comunidade_humanograma_model.dart';
import '../../../../data/model/comunidade/comunidade_local_model.dart';
import '../../../../data/model/localidade/estado_model.dart';
import '../../../../data/model/localidade/municipio_model.dart';
import '../../../dashboard/widgets/musica/use_case/musica_usecase.dart' show AbrirUrl;
import '../../comunidade_contato/use_case/comunidade_contato_usecase.dart';
import '../../comunidade_endereco/use_case/comunidade_endereco_usecase.dart';
import '../repository/comunidade_lista_repository.dart';

Future<bool> _abrirExterno(Uri url) => launchUrl(url, mode: LaunchMode.externalApplication);

/// Detalhe de uma comunidade da lista. Cada parte é carregada em separado: nula se a consulta falhou (as outras
/// continuam valendo); lista vazia se não houver registros.
/// - [enderecos]: todos os endereços (ordem da API);
/// - [contatos]: registros de contato (campos preenchidos via [ComunidadeContatoUseCase.preenchidos]);
/// - [lideranca]: humanograma (pessoa e cargo), por cargo e nome;
/// - [membrosAtivos]: só a quantidade de usuários ativos (a tela é aberta a qualquer usuário: não lista nomes).
typedef ComunidadeDetalhe = ({
  List<ComunidadeEnderecoModel>? enderecos,
  List<ComunidadeContatoModel>? contatos,
  List<ComunidadeHumanogramaModel>? lideranca,
  int? membrosAtivos,
});

/// Regras da tela "Encontrar comunidades" (todas as comunidades, de qualquer usuário, por estado e cidade):
/// - o estado é obrigatório para buscar (`selecioneEstado`, sem chamar a API); a cidade é opcional (sem ela, todas
///   as cidades do estado); uma cidade de outro estado é ignorada;
/// - as comunidades vêm de `/v1/comunidade?estaId=&muniId=`, uma por comunidade, ordenadas pelo nome (sem
///   diferenciar maiúsculas); 404 `registroNaoEncontrado` vira lista vazia;
/// - estados e municípios ficam em cache (municípios por estado);
/// - textos do card: [descricao] (tipo · denominação), [linhaEndereco] e [linhaLocal];
/// - detalhe ([detalhe]): endereços, contatos, liderança e quantidade de membros ativos, carregados juntos; um
///   contato é aberto fora do app por [abrir] (discador, WhatsApp, e-mail ou navegador).
class ComunidadeListaUseCase {
  ComunidadeListaUseCase({required this.comunidadeListaRepository, AbrirUrl? abrirUrl})
    : _abrirUrl = abrirUrl ?? _abrirExterno {
    Log.print(super.runtimeType);
  }

  final AbrirUrl _abrirUrl;

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

  /// Detalhe da comunidade [comuId]: as quatro consultas em paralelo; cada uma que falhar fica nula (404
  /// `registroNaoEncontrado` vira vazio).
  Future<ComunidadeDetalhe> detalhe(int comuId) async {
    final (enderecos, contatos, lideranca, usuarios) = await (
      comunidadeListaRepository.enderecos(comuId),
      comunidadeListaRepository.contatos(comuId),
      comunidadeListaRepository.humanograma(comuId),
      comunidadeListaRepository.usuarios(comuId),
    ).wait;
    final pessoas = _valor(lideranca);
    final membros = _valor(usuarios);
    return (
      enderecos: _valor(enderecos),
      contatos: _valor(contatos)?.where((c) => ComunidadeContatoUseCase.preenchidos(c).isNotEmpty).toList(),
      lideranca: pessoas == null ? null : ordenarLideranca(pessoas),
      membrosAtivos: membros?.where((m) => m.cusuAtivo).length,
    );
  }

  /// Liderança por cargo (sem cargo por último) e nome, sem diferenciar maiúsculas.
  static List<ComunidadeHumanogramaModel> ordenarLideranca(List<ComunidadeHumanogramaModel> lista) {
    String chave(String? valor) => valor?.trim().toLowerCase() ?? '';
    return [...lista]..sort((a, b) {
      final cargoA = chave(a.chcaCargo);
      final cargoB = chave(b.chcaCargo);
      if (cargoA.isEmpty != cargoB.isEmpty) return cargoA.isEmpty ? 1 : -1;
      final porCargo = cargoA.compareTo(cargoB);
      return porCargo != 0 ? porCargo : chave(a.chumNome).compareTo(chave(b.chumNome));
    });
  }

  /// Abre o contato fora do app; `naoFoiPossivelAbrirLink` se não der.
  Future<Result<void>> abrir(ContatoCampo campo, String valor) async {
    final destino = ComunidadeContatoUseCase.uri(campo, valor);
    try {
      if (destino != null && await _abrirUrl(destino)) return const Result.ok(null);
    } catch (error) {
      Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    return Result.error(HandledException(message: 'naoFoiPossivelAbrirLink'));
  }

  /// Linhas de um endereço do detalhe: principal, local (bairro · cidade - UF) e CEP formatado.
  static ({String principal, String? local, String cep}) linhasDoEndereco(ComunidadeEnderecoModel endereco) => (
    principal: ComunidadeEnderecoUseCase.linhaPrincipal(endereco),
    local: ComunidadeEnderecoUseCase.linhaLocal(endereco),
    cep: ComunidadeEnderecoUseCase.cepFormatado(endereco.cendCep),
  );

  /// Valor de uma consulta: a lista, vazia no 404, nula em outro erro (registrado no log).
  static List<T>? _valor<T>(Result<List<T>> result) {
    switch (result) {
      case Ok<List<T>>(value: final value):
        return value;
      case Error<List<T>>(error: final error):
        if (_semRegistros(error)) return const [];
        Log.print(error.toString(), name: kApp, title: 'Erro');
        return null;
    }
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
