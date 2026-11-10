import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/comunidade/comunidade_endereco_model.dart';
import '../../../../data/model/localidade/estado_model.dart';
import '../../../../data/model/localidade/municipio_model.dart';
import '../../use_case/comunidade_usecase.dart';
import '../repository/comunidade_endereco_repository.dart';

/// Regras da aba "Endereços" (endereços da comunidade selecionada):
/// - as comunidades selecionáveis são as do usuário, na ordem de "Minhas comunidades" (via [ComunidadeUseCase]);
///   a seleção ([selecionada]) mantém a atual se ela ainda existir, senão a primeira;
/// - os endereços da comunidade vêm de `/v1/comunidade-endereco/:comuId`, na ordem da API; 404
///   `registroNaoEncontrado` vira lista vazia;
/// - gravação ([salvar]): comunidade, CEP com 8 dígitos (gravado só com os dígitos), logradouro e município
///   obrigatórios ([validar]); textos sem espaços nas pontas e opcionais em branco viram nulos; sem `cendId` inclui,
///   com `cendId` altera; exclusão ([excluir]) pelo `cendId`;
/// - estados e municípios do formulário ficam em cache (municípios por estado);
/// - textos do card: [linhaPrincipal], [linhaLocal] e [cepFormatado].
class ComunidadeEnderecoUseCase {
  ComunidadeEnderecoUseCase({required this.comunidadeEnderecoRepository, required this.comunidadeUseCase}) {
    Log.print(super.runtimeType);
  }

  final ComunidadeEnderecoRepository comunidadeEnderecoRepository;

  /// Comunidades do usuário logado (mesmas regras da aba "Minhas comunidades").
  final ComunidadeUseCase comunidadeUseCase;

  List<EstadoModel>? _estados;
  final Map<int, List<MunicipioModel>> _municipios = {};

  /// Comunidades que podem ser selecionadas na aba.
  Future<Result<List<ComunidadeResumo>>> comunidades() async {
    final result = await comunidadeUseCase.minhasComunidades();
    return switch (result) {
      Ok<MinhasComunidades>(value: final value) => Result.ok(value.comunidades),
      Error<MinhasComunidades>(error: final error) => Result.error(error),
    };
  }

  /// Comunidade selecionada: a de [comuId], se estiver na lista; senão a primeira. Nula se a lista está vazia.
  ComunidadeResumo? selecionada(List<ComunidadeResumo> comunidades, int? comuId) {
    for (final resumo in comunidades) {
      if (resumo.comunidade.comuId == comuId) return resumo;
    }
    return comunidades.firstOrNull;
  }

  Future<Result<List<ComunidadeEnderecoModel>>> enderecos(int comuId) async {
    final result = await comunidadeEnderecoRepository.enderecos(comuId);
    if (result case Error(error: final error) when _semRegistros(error)) return const Result.ok([]);
    return result;
  }

  Future<Result<List<EstadoModel>>> estados() async {
    final cache = _estados;
    if (cache != null) return Result.ok(cache);
    final result = await comunidadeEnderecoRepository.estados();
    if (result case Ok(value: final value)) _estados = value;
    return result;
  }

  Future<Result<List<MunicipioModel>>> municipios(int estaId) async {
    final cache = _municipios[estaId];
    if (cache != null) return Result.ok(cache);
    final result = await comunidadeEnderecoRepository.municipios(estaId);
    if (result case Ok(value: final value)) _municipios[estaId] = value;
    return result;
  }

  /// Chave de tradução do primeiro problema do [endereco] a gravar; nula se ele pode ser gravado.
  String? validar(ComunidadeEnderecoModel endereco) {
    if (endereco.comuId < 1) return 'comunidadeObrigatoria';
    if (_digitos(endereco.cendCep).length != 8) return 'cepInvalido';
    if (endereco.cendLogradouro.trim().isEmpty) return 'logradouroObrigatorio';
    if (endereco.muniId < 1) return 'municipioObrigatorio';
    return null;
  }

  /// Inclui (sem `cendId`) ou altera o [endereco], depois de [validar].
  Future<Result<ComunidadeEnderecoModel>> salvar(ComunidadeEnderecoModel endereco) async {
    final erro = validar(endereco);
    if (erro != null) return Result.error(HandledException(message: erro));

    final registro = ComunidadeEnderecoModel(
      cendId: endereco.cendId,
      comuId: endereco.comuId,
      cendCep: _digitos(endereco.cendCep),
      cendLogradouro: endereco.cendLogradouro.trim(),
      cendNumero: _texto(endereco.cendNumero),
      cendComplemento: _texto(endereco.cendComplemento),
      cendBairro: _texto(endereco.cendBairro),
      muniId: endereco.muniId,
    );
    return registro.cendId == null
        ? comunidadeEnderecoRepository.incluir(registro)
        : comunidadeEnderecoRepository.alterar(registro);
  }

  Future<Result<void>> excluir(ComunidadeEnderecoModel endereco) async {
    final cendId = endereco.cendId;
    if (cendId == null) return Result.error(HandledException(message: 'registroNaoEncontrado'));
    return comunidadeEnderecoRepository.excluir(cendId);
  }

  /// "Logradouro, Número - Complemento", só com o que houver.
  static String linhaPrincipal(ComunidadeEnderecoModel endereco) {
    final numero = _texto(endereco.cendNumero);
    final complemento = _texto(endereco.cendComplemento);
    final base = [endereco.cendLogradouro.trim(), ?numero].join(', ');
    return complemento == null ? base : '$base - $complemento';
  }

  /// "Bairro · Município - UF", só com o que houver; nula se nada.
  static String? linhaLocal(ComunidadeEnderecoModel endereco) {
    final municipio = [?_texto(endereco.muniNome), ?_texto(endereco.estaSigla)].join(' - ');
    final partes = [?_texto(endereco.cendBairro), if (municipio.isNotEmpty) municipio];
    return partes.isEmpty ? null : partes.join(' · ');
  }

  /// CEP como "00000-000" quando tem 8 dígitos; senão como veio.
  static String cepFormatado(String cep) {
    final digitos = _digitos(cep);
    return digitos.length == 8 ? '${digitos.substring(0, 5)}-${digitos.substring(5)}' : cep.trim();
  }

  static String _digitos(String valor) => valor.replaceAll(RegExp(r'\D'), '');

  static String? _texto(String? valor) {
    final texto = valor?.trim();
    return (texto?.isEmpty ?? true) ? null : texto;
  }

  static bool _semRegistros(Exception error) =>
      (error is HttpServiceException && error.message == kRegistroNaoEncontrado) ||
      (error is HandledException && error.message == kRegistroNaoEncontrado);

  static const kRegistroNaoEncontrado = 'registroNaoEncontrado';
}
