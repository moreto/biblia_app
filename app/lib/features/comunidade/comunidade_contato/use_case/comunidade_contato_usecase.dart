import 'package:commons/commons.dart';
import 'package:service/service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/model/comunidade/comunidade_contato_model.dart';
import '../../../dashboard/widgets/musica/use_case/musica_usecase.dart' show AbrirUrl;
import '../../comunidade/use_case/comunidade_usecase.dart';
import '../repository/comunidade_contato_repository.dart';

Future<bool> _abrirExterno(Uri url) => launchUrl(url, mode: LaunchMode.externalApplication);

/// Tipo de um [ContatoCampo]: define validação, gravação, exibição e link.
enum ContatoTipo { telefone, email, link }

/// Campos de contato de `biblia.comunidade_contato`, na ordem do formulário e do card: chave JSON, rótulo (chave
/// de tradução), ícone (em `IconsMap.mdiIcons`), tipo e tamanho máximo da coluna.
enum ContatoCampo {
  telefonePrincipal('cconTelefonePrincipal', 'telefonePrincipal', 'phone-outline', ContatoTipo.telefone, 15),
  telefoneSecundario('cconTelefoneSecundario', 'telefoneSecundario', 'phone-classic', ContatoTipo.telefone, 15),
  celular('cconCelular', 'celular', 'cellphone', ContatoTipo.telefone, 15),
  whatsapp('cconWhatsapp', 'whatsapp', 'chat-outline', ContatoTipo.telefone, 15),
  email('cconEmail', 'email', 'email-outline', ContatoTipo.email, 90),
  site('cconSite', 'site', 'web', ContatoTipo.link, 128),
  facebook('cconFacebook', 'facebook', 'thumb-up-outline', ContatoTipo.link, 128),
  instagram('cconInstagram', 'instagram', 'camera-outline', ContatoTipo.link, 128),
  youtube('cconYoutube', 'youtube', 'play-box-outline', ContatoTipo.link, 128),
  telegram('cconTelegram', 'telegram', 'send', ContatoTipo.link, 128);

  const ContatoCampo(this.chave, this.rotulo, this.icone, this.tipo, this.maximo);

  final String chave;
  final String rotulo;
  final String icone;
  final ContatoTipo tipo;
  final int maximo;
}

/// Regras da aba "Contatos" (contatos da comunidade selecionada):
/// - as comunidades selecionáveis são as do usuário, na ordem de "Minhas comunidades" (via [ComunidadeUseCase]);
///   a seleção ([selecionada]) mantém a atual se ela ainda existir, senão a primeira;
/// - os contatos da comunidade vêm de `/v1/comunidade-contato/:comuId`, na ordem da API; 404
///   `registroNaoEncontrado` vira lista vazia;
/// - gravação ([salvar]): comunidade obrigatória e pelo menos um campo preenchido ([validar]); cada campo segue
///   [validarCampo] — telefone com 8 a 15 dígitos (gravado só com os dígitos), e-mail válido até 90 caracteres,
///   link/usuário sem espaços até 128 caracteres; textos sem espaços nas pontas e em branco viram nulos; sem
///   `cconId` inclui, com `cconId` altera; exclusão ([excluir]) pelo `cconId`;
/// - card: [preenchidos] (campos com valor, na ordem de [ContatoCampo]), [exibicao] (telefone formatado) e [uri]
///   (ligação, e-mail, WhatsApp ou página), aberto fora do app por [abrir].
class ComunidadeContatoUseCase {
  ComunidadeContatoUseCase({
    required this.comunidadeContatoRepository,
    required this.comunidadeUseCase,
    AbrirUrl? abrirUrl,
  }) : _abrirUrl = abrirUrl ?? _abrirExterno {
    Log.print(super.runtimeType);
  }

  final AbrirUrl _abrirUrl;

  final ComunidadeContatoRepository comunidadeContatoRepository;

  /// Comunidades do usuário logado (mesmas regras da aba "Minhas comunidades").
  final ComunidadeUseCase comunidadeUseCase;

  /// Mínimo de dígitos de um telefone (o máximo é o [ContatoCampo.maximo]).
  static const kTelefoneMinimo = 8;

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

  Future<Result<List<ComunidadeContatoModel>>> contatos(int comuId) async {
    final result = await comunidadeContatoRepository.contatos(comuId);
    if (result case Error(error: final error) when _semRegistros(error)) return const Result.ok([]);
    return result;
  }

  /// Chave de tradução do problema do [valor] do [campo]; nula se ele pode ser gravado (vazio também pode).
  static String? validarCampo(ContatoCampo campo, String? valor) {
    final texto = _texto(valor);
    if (texto == null) return null;
    switch (campo.tipo) {
      case ContatoTipo.telefone:
        final digitos = _digitos(texto);
        final valido =
            RegExp(r'^[\d\s()+.-]+$').hasMatch(texto) &&
            digitos.length >= kTelefoneMinimo &&
            digitos.length <= campo.maximo;
        return valido ? null : 'telefoneInvalido';
      case ContatoTipo.email:
        final valido = texto.length <= campo.maximo && RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto);
        return valido ? null : 'emailInvalido';
      case ContatoTipo.link:
        return texto.length <= campo.maximo && !RegExp(r'\s').hasMatch(texto) ? null : 'linkInvalido';
    }
  }

  /// Chave de tradução do primeiro problema do [contato] a gravar; nula se ele pode ser gravado.
  String? validar(ComunidadeContatoModel contato) {
    if (contato.comuId < 1) return 'comunidadeObrigatoria';
    if (preenchidos(contato).isEmpty) return 'contatoObrigatorio';
    for (final campo in ContatoCampo.values) {
      final erro = validarCampo(campo, contato.campo(campo.chave));
      if (erro != null) return erro;
    }
    return null;
  }

  /// Inclui (sem `cconId`) ou altera o [contato], depois de [validar].
  Future<Result<ComunidadeContatoModel>> salvar(ComunidadeContatoModel contato) async {
    final erro = validar(contato);
    if (erro != null) return Result.error(HandledException(message: erro));

    final registro = ComunidadeContatoModel.comCampos(
      cconId: contato.cconId,
      comuId: contato.comuId,
      campos: {for (final campo in ContatoCampo.values) campo.chave: _gravado(campo, contato.campo(campo.chave))},
    );
    return registro.cconId == null
        ? comunidadeContatoRepository.incluir(registro)
        : comunidadeContatoRepository.alterar(registro);
  }

  Future<Result<void>> excluir(ComunidadeContatoModel contato) async {
    final cconId = contato.cconId;
    if (cconId == null) return Result.error(HandledException(message: 'registroNaoEncontrado'));
    return comunidadeContatoRepository.excluir(cconId);
  }

  /// Campos preenchidos do [contato], na ordem de [ContatoCampo], com o valor sem espaços nas pontas.
  static List<(ContatoCampo, String)> preenchidos(ComunidadeContatoModel contato) => [
    for (final campo in ContatoCampo.values)
      if (_texto(contato.campo(campo.chave)) case final valor?) (campo, valor),
  ];

  /// Valor para exibir: telefone com 10 ou 11 dígitos como "(61) 3333-4444" / "(61) 99999-4444"; o resto como veio.
  static String exibicao(ContatoCampo campo, String valor) {
    final texto = valor.trim();
    if (campo.tipo != ContatoTipo.telefone) return texto;
    final d = _digitos(texto);
    return switch (d.length) {
      10 => '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}',
      11 => '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}',
      _ => texto,
    };
  }

  /// Endereço para abrir o contato: ligação (`tel:`), WhatsApp (`https://wa.me/`, com 55 quando o número tem DDD
  /// sem código do país), e-mail (`mailto:`) ou página. Usuário (`@nome` ou só o nome) vira a página da rede.
  /// Nulo se não houver como abrir.
  static Uri? uri(ContatoCampo campo, String valor) {
    final texto = valor.trim();
    if (texto.isEmpty) return null;
    switch (campo.tipo) {
      case ContatoTipo.telefone:
        final digitos = _digitos(texto);
        if (digitos.isEmpty) return null;
        if (campo != ContatoCampo.whatsapp) return Uri(scheme: 'tel', path: digitos);
        final internacional = texto.startsWith('+') || digitos.length > 11 ? digitos : '55$digitos';
        return Uri.https('wa.me', '/$internacional');
      case ContatoTipo.email:
        return Uri(scheme: 'mailto', path: texto);
      case ContatoTipo.link:
        if (RegExp(r'^https?://', caseSensitive: false).hasMatch(texto)) return Uri.tryParse(texto);
        if (texto.contains('.') && !texto.startsWith('@')) return Uri.tryParse('https://$texto');
        final usuario = texto.replaceFirst('@', '');
        if (usuario.isEmpty) return null;
        return switch (campo) {
          ContatoCampo.facebook => Uri.https('facebook.com', '/$usuario'),
          ContatoCampo.instagram => Uri.https('instagram.com', '/$usuario'),
          ContatoCampo.youtube => Uri.https('youtube.com', '/@$usuario'),
          ContatoCampo.telegram => Uri.https('t.me', '/$usuario'),
          _ => Uri.tryParse('https://$usuario'),
        };
    }
  }

  /// Abre o contato fora do app (discador, WhatsApp, e-mail ou navegador); `naoFoiPossivelAbrirLink` se não der.
  Future<Result<void>> abrir(ContatoCampo campo, String valor) async {
    final destino = uri(campo, valor);
    try {
      if (destino != null && await _abrirUrl(destino)) return const Result.ok(null);
    } catch (error) {
      Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    return Result.error(HandledException(message: 'naoFoiPossivelAbrirLink'));
  }

  /// Valor gravado: nulo se em branco; telefone só com os dígitos; o resto sem espaços nas pontas.
  static String? _gravado(ContatoCampo campo, String? valor) {
    final texto = _texto(valor);
    if (texto == null) return null;
    return campo.tipo == ContatoTipo.telefone ? _digitos(texto) : texto;
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
