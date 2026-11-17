import 'package:commons/commons.dart';
import 'package:intl/intl.dart';
import 'package:service/service.dart';

import '../../../../data/model/usuario/usuario_consentimento_model.dart';
import '../repository/usuario_consentimento_repository.dart';

/// Finalidades de consentimento conhecidas pelo app, na ordem da tela: chave da API ([chave]), título e descrição
/// (chaves de tradução) e ícone (em `IconsMap.mdiIcons`).
enum ConsentimentoFinalidade {
  /// Termos de uso do app.
  termosUso(
    chave: 'termosUso',
    titulo: 'consentimentoTermosUso',
    descricao: 'consentimentoTermosUsoDescricao',
    icone: 'file-document-outline',
  ),

  /// Política de privacidade (tratamento de dados pessoais).
  politicaPrivacidade(
    chave: 'politicaPrivacidade',
    titulo: 'consentimentoPoliticaPrivacidade',
    descricao: 'consentimentoPoliticaPrivacidadeDescricao',
    icone: 'shield-lock-outline',
  ),

  /// Dados que revelam convicção religiosa (LGPD art. 11, I): a API exige este aceite para gravá-los.
  dadosReligiosos(
    chave: 'dadosReligiosos',
    titulo: 'consentimentoDadosReligiosos',
    descricao: 'consentimentoDadosReligiososDescricao',
    icone: 'hands-pray',
  );

  const ConsentimentoFinalidade({
    required this.chave,
    required this.titulo,
    required this.descricao,
    required this.icone,
  });

  final String chave;
  final String titulo;
  final String descricao;
  final String icone;

  /// Finalidade da [chave] da API; nula se o app não a conhecer.
  static ConsentimentoFinalidade? daChave(String chave) => values.where((f) => f.chave == chave).firstOrNull;
}

/// Regras da tela "Privacidade e consentimentos" (LGPD), sobre `/v1/usuario-consentimento`:
/// - [carregar] traz os termos (finalidade, versão atual e se está aceito) e o histórico; os termos ficam na ordem de
///   [ConsentimentoFinalidade] (finalidades que o app não conhece vão para o fim, pela chave) e o histórico do mais
///   recente ao mais antigo;
/// - [aceitar] grava o aceite da versão atual do termo e recarrega; termo já aceito não chama a API;
/// - [aceitarPendentes] aceita, em ordem, todos os termos ainda não aceitos e recarrega; para no primeiro erro;
/// - [revogar] revoga o aceite vigente e recarrega; 404 `registroNaoEncontrado` (nada vigente) conta como revogado.
///   Revogar não apaga os dados já gravados, só impede novas gravações que dependem do consentimento;
/// - textos: [titulo], [descricao] e [icone] por finalidade (a desconhecida usa a própria chave como título),
///   [aceite] (registro vigente do termo, para a data do aceite) e [data] ("dd/MM/yyyy HH:mm").
class UsuarioConsentimentoUseCase {
  UsuarioConsentimentoUseCase({required this.usuarioConsentimentoRepository}) {
    Log.print(super.runtimeType);
  }

  final UsuarioConsentimentoRepository usuarioConsentimentoRepository;

  /// Mensagens (chaves de tradução) de sucesso das gravações.
  static const kAceito = 'consentimentoRegistrado';
  static const kAceitosTodos = 'consentimentosRegistrados';
  static const kRevogado = 'consentimentoRevogado';

  /// Ícone de finalidade desconhecida.
  static const kIconePadrao = 'shield-account-outline';

  static const kRegistroNaoEncontrado = 'registroNaoEncontrado';

  Future<Result<UsuarioConsentimentoListaModel>> carregar() async {
    final result = await usuarioConsentimentoRepository.listar();
    return switch (result) {
      Ok<UsuarioConsentimentoListaModel>(value: final lista) => Result.ok(ordenar(lista)),
      Error<UsuarioConsentimentoListaModel>() => result,
    };
  }

  /// Aceita a versão atual do [termo] e devolve a lista atualizada.
  Future<Result<UsuarioConsentimentoListaModel>> aceitar(UsuarioConsentimentoTermoModel termo) async {
    final erro = await _aceitar(termo);
    return erro == null ? carregar() : Result.error(erro);
  }

  /// Aceita os [pendentes] dos [termos], em ordem, e devolve a lista atualizada; para no primeiro erro.
  Future<Result<UsuarioConsentimentoListaModel>> aceitarPendentes(List<UsuarioConsentimentoTermoModel> termos) async {
    for (final termo in pendentes(termos)) {
      final erro = await _aceitar(termo);
      if (erro != null) return Result.error(erro);
    }
    return carregar();
  }

  /// Revoga o aceite vigente do [termo] e devolve a lista atualizada.
  Future<Result<UsuarioConsentimentoListaModel>> revogar(UsuarioConsentimentoTermoModel termo) async {
    final result = await usuarioConsentimentoRepository.revogar(termo.finalidade);
    if (result case Error<int>(error: final error) when !_semRegistros(error)) return Result.error(error);
    return carregar();
  }

  /// Erro do aceite; nulo se gravou (ou se o termo já estava aceito).
  Future<Exception?> _aceitar(UsuarioConsentimentoTermoModel termo) async {
    if (termo.aceito) return null;
    if (termo.finalidade.trim().isEmpty || termo.versao.trim().isEmpty) {
      return HandledException(message: 'dadosInvalidos');
    }
    final result = await usuarioConsentimentoRepository.aceitar(
      UsuarioConsentimentoBodyModel(ucnsFinalidade: termo.finalidade, ucnsVersao: termo.versao),
    );
    return switch (result) {
      Ok<UsuarioConsentimentoModel>() => null,
      Error<UsuarioConsentimentoModel>(error: final error) => error,
    };
  }

  /// Termos na ordem de [ConsentimentoFinalidade] (desconhecidos no fim, pela chave); histórico do mais recente ao
  /// mais antigo.
  static UsuarioConsentimentoListaModel ordenar(UsuarioConsentimentoListaModel lista) => UsuarioConsentimentoListaModel(
    termos: [...lista.termos]
      ..sort((a, b) {
        final ordem = _ordem(a.finalidade).compareTo(_ordem(b.finalidade));
        return ordem != 0 ? ordem : a.finalidade.compareTo(b.finalidade);
      }),
    historico: [...lista.historico]..sort((a, b) => b.ucnsId.compareTo(a.ucnsId)),
  );

  static int _ordem(String finalidade) =>
      ConsentimentoFinalidade.daChave(finalidade)?.index ?? ConsentimentoFinalidade.values.length;

  static List<UsuarioConsentimentoTermoModel> pendentes(List<UsuarioConsentimentoTermoModel> termos) => [
    for (final t in termos)
      if (!t.aceito) t,
  ];

  /// Todos os termos aceitos (falso sem termos).
  static bool todosAceitos(List<UsuarioConsentimentoTermoModel> termos) =>
      termos.isNotEmpty && pendentes(termos).isEmpty;

  /// Registro vigente (não revogado) da versão atual do [termo]; nulo se não aceito.
  static UsuarioConsentimentoModel? aceite(
    UsuarioConsentimentoTermoModel termo,
    List<UsuarioConsentimentoModel> historico,
  ) {
    if (!termo.aceito) return null;
    return historico
        .where((c) => c.ucnsFinalidade == termo.finalidade && c.ucnsVersao == termo.versao && !c.revogado)
        .firstOrNull;
  }

  /// Título (chave de tradução) da finalidade; a desconhecida usa a própria chave.
  static String titulo(String finalidade) => ConsentimentoFinalidade.daChave(finalidade)?.titulo ?? finalidade;

  /// Descrição (chave de tradução) da finalidade; nula se desconhecida.
  static String? descricao(String finalidade) => ConsentimentoFinalidade.daChave(finalidade)?.descricao;

  static String icone(String finalidade) => ConsentimentoFinalidade.daChave(finalidade)?.icone ?? kIconePadrao;

  /// Aviso extra (chave de tradução) ao revogar: sem o consentimento de dados religiosos a API recusa gravá-los.
  static String? avisoRevogacao(String finalidade) =>
      finalidade == ConsentimentoFinalidade.dadosReligiosos.chave ? 'revogarDadosReligiososAviso' : null;

  /// Data e hora como "dd/MM/yyyy HH:mm"; nula sem data.
  static String? data(DateTime? quando) => quando == null ? null : DateFormat('dd/MM/yyyy HH:mm').format(quando);

  static String mensagemErro(Exception error) => switch (error) {
    HandledException(message: final message) => message,
    HttpServiceException(message: final message?) => message,
    _ => kDefaultAppError,
  };

  static bool _semRegistros(Exception error) =>
      (error is HttpServiceException && error.message == kRegistroNaoEncontrado) ||
      (error is HandledException && error.message == kRegistroNaoEncontrado);
}
