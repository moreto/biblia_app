import 'package:commons/commons.dart';
import 'package:intl/intl.dart';
import 'package:service/service.dart';

import '../../../config/usuario_session.dart';
import '../../../data/model/usuario/usuario_configuracao_model.dart';
import '../../../data/model/usuario/usuario_detalhe_model.dart';
import '../../access/configuracao_app/use_case/configuracao_app_usecase.dart';
import '../repository/usuario_repository.dart';

/// Abas da tela "Meus dados", na ordem em que aparecem: rótulo (chave de tradução) e ícone (em `IconsMap.mdiIcons`).
enum UsuarioAba {
  dados(rotulo: 'dadosCadastrais', icone: 'card-account-details-outline'),
  senha(rotulo: 'senha', icone: 'lock-reset'),
  configuracoes(rotulo: 'configuracoes', icone: 'cog-outline');

  const UsuarioAba({required this.rotulo, required this.icone});

  final String rotulo;
  final String icone;
}

/// Opções liga/desliga de `usuario_configuracao`, na ordem da tela: título e descrição (chaves de tradução) e ícone.
enum UsuarioConfiguracaoOpcao {
  emailVersiculo(
    titulo: 'configEmailVersiculo',
    descricao: 'configEmailVersiculoDescricao',
    icone: 'book-open-page-variant',
  ),
  emailComunidade(
    titulo: 'configEmailComunidade',
    descricao: 'configEmailComunidadeDescricao',
    icone: 'account-group-outline',
  ),
  emailLeitura(titulo: 'configEmailLeitura', descricao: 'configEmailLeituraDescricao', icone: 'book-open-variant'),
  emailFaleConosco(titulo: 'configEmailFaleConosco', descricao: 'configEmailFaleConoscoDescricao', icone: 'face-agent'),
  leituraAberto(titulo: 'configLeituraAberto', descricao: 'configLeituraAbertoDescricao', icone: 'eye-outline');

  const UsuarioConfiguracaoOpcao({required this.titulo, required this.descricao, required this.icone});

  final String titulo;
  final String descricao;
  final String icone;

  /// Opções da seção "Avisos por e-mail".
  static const email = [emailVersiculo, emailComunidade, emailLeitura, emailFaleConosco];
}

/// Quantidades de `usuario_configuracao` (registros guardados): título e descrição (chaves de tradução) e ícone.
enum UsuarioConfiguracaoQuantidade {
  logsAcesso(titulo: 'configLogsAcesso', descricao: 'configLogsAcessoDescricao', icone: 'login'),
  logsNotificacao(titulo: 'configLogsNotificacao', descricao: 'configLogsNotificacaoDescricao', icone: 'bell-outline');

  const UsuarioConfiguracaoQuantidade({required this.titulo, required this.descricao, required this.icone});

  final String titulo;
  final String descricao;
  final String icone;
}

/// Conteúdo da tela: o detalhe do usuário e a configuração (a padrão, sem `uconId`, se ele ainda não tiver uma).
typedef UsuarioDados = ({UsuarioDetalheModel detalhe, UsuarioConfiguracaoModel configuracao});

/// Regras da tela "Meus dados" (dados do cadastro inicial: `usuario`, `usuario_detalhe` e `usuario_configuracao`).
/// As validações devolvem a chave de tradução do erro, ou null se o valor é válido.
///
/// - [carregar] busca o detalhe e a configuração juntos. Sem configuração (404 `registroNaoEncontrado`) usa a
///   [configuracaoPadrao], ainda não gravada. O detalhe carregado ou gravado atualiza a [UsuarioSession];
/// - e-mail, identificador e situação da conta são só leitura (o e-mail é o login);
/// - [salvarDados] grava o nome completo (até [nomeMaximo] caracteres) e o nome de usuário ([usuarioMinimo] a
///   [usuarioMaximo] letras sem acento, números, `.`, `-` ou `_`), as mesmas regras da ativação da conta, sem
///   espaços nas pontas. Sem alteração, não chama a API. A API responde 409 `nomeUsuarioDuplicado` se o nome de
///   usuário já for de outro usuário;
/// - [alterarSenha] exige a senha atual, a nova com ao menos [senhaMinimo] caracteres, a confirmação igual e a nova
///   diferente da atual; as duas vão criptografadas como no login. A API confere a senha atual
///   (`senhaAtualInvalida`) e avisa o usuário por e-mail;
/// - [salvarConfiguracao] inclui (POST) a primeira configuração e altera (PUT) a existente. Se o POST responder 409
///   `usuarioConfiguracaoDuplicada` (gravada em outro aparelho), lê a existente e altera. Quantidades de 0 a
///   [quantidadeMaxima], escolhidas entre as [opcoesQuantidade].
class UsuarioUseCase {
  UsuarioUseCase({
    required this.usuarioRepository,
    required this.configuracaoAppUseCase,
    UsuarioSession? session,
    Encrypt? encrypt,
  }) : _session = session ?? UsuarioSession.instance,
       _encrypt = encrypt ?? Encrypt() {
    Log.print(super.runtimeType);
  }

  final UsuarioRepository usuarioRepository;

  /// Fornece a chave de criptografia da senha, lida de `GET /v1/configuracao-app`.
  final ConfiguracaoAppUseCase configuracaoAppUseCase;
  final UsuarioSession _session;
  final Encrypt _encrypt;

  /// Tamanho máximo do nome completo (`udet_nome`).
  static const nomeMaximo = 70;

  /// Tamanho mínimo e máximo do nome de usuário (`udet_usuario`).
  static const usuarioMinimo = 3;
  static const usuarioMaximo = 30;

  /// Tamanho mínimo da nova senha.
  static const senhaMinimo = 6;

  /// Maior quantidade aceita pela API (inteiro do PostgreSQL).
  static const quantidadeMaxima = 2147483647;

  /// Quantidades oferecidas na tela; a atual entra na lista se não for uma delas.
  static const quantidadesSugeridas = [0, 10, 25, 50, 100, 200, 500];

  /// Mensagens (chaves de tradução) de sucesso das gravações.
  static const kDadosSalvos = 'dadosSalvos';
  static const kSenhaAlterada = 'senhaAlterada';
  static const kConfiguracoesSalvas = 'configuracoesSalvas';

  static const kRegistroNaoEncontrado = 'registroNaoEncontrado';
  static const kConfiguracaoDuplicada = 'usuarioConfiguracaoDuplicada';

  /// Valores de quem ainda não tem configuração (os mesmos de `usuario_registros_faltantes.sql` na API).
  static const configuracaoPadrao = UsuarioConfiguracaoModel(
    emailVersiculo: true,
    emailComunidade: true,
    emailLeitura: true,
    emailFaleConosco: true,
    leituraAberto: false,
    quantidadeLogsAcesso: 50,
    quantidadeLogsNotificacao: 50,
  );

  static final _usuarioRegex = RegExp('^[A-Za-z0-9._-]{$usuarioMinimo,$usuarioMaximo}\$');

  // ---------- validações ----------

  String? validateNome(String? nome) {
    final value = nome?.trim() ?? kVazio;
    if (value.isEmpty) return 'informeNomeCompleto';
    if (value.length > nomeMaximo) return 'nomeCompletoMaximo70';
    return null;
  }

  String? validateUsuario(String? usuario) {
    final value = usuario?.trim() ?? kVazio;
    if (value.isEmpty) return 'informeNomeUsuario';
    if (!_usuarioRegex.hasMatch(value)) return 'nomeUsuarioInvalido';
    return null;
  }

  String? validateSenhaAtual(String? senha) => (senha == null || senha.isEmpty) ? 'informeSenhaAtual' : null;

  String? validateNovaSenha(String? senhaAtual, String? novaSenha) {
    if (novaSenha == null || novaSenha.isEmpty) return 'informeNovaSenha';
    if (novaSenha.length < senhaMinimo) return 'senhaMinimo6';
    if (senhaAtual != null && senhaAtual.isNotEmpty && novaSenha == senhaAtual) return 'novaSenhaIgualAtual';
    return null;
  }

  String? validateConfirmacao(String? novaSenha, String? confirmacao) {
    if (confirmacao == null || confirmacao.isEmpty) return 'informeConfirmacaoSenha';
    if (confirmacao != novaSenha) return 'senhasDiferentes';
    return null;
  }

  String? validateQuantidade(int quantidade) =>
      (quantidade < 0 || quantidade > quantidadeMaxima) ? 'quantidadeInvalida' : null;

  /// Nome ou nome de usuário diferente do [detalhe] (sem considerar espaços nas pontas).
  static bool dadosAlterados(UsuarioDetalheModel? detalhe, String nome, String usuario) =>
      detalhe != null && (nome.trim() != detalhe.udetNome || usuario.trim() != detalhe.udetUsuario);

  /// Configuração a gravar: diferente da gravada ou ainda não gravada.
  static bool configuracaoAlterada(UsuarioConfiguracaoModel? gravada, UsuarioConfiguracaoModel? editada) =>
      gravada != null && editada != null && (gravada.uconId == null || !gravada.mesmosValores(editada));

  // ---------- operações ----------

  Future<Result<UsuarioDados>> carregar() async {
    final (detalhe, configuracao) = await (usuarioRepository.detalhe(), usuarioRepository.configuracao()).wait;

    final UsuarioDetalheModel usuario;
    switch (detalhe) {
      case Ok<UsuarioDetalheModel>(value: final value):
        usuario = value;
      case Error<UsuarioDetalheModel>(error: final error):
        return Result.error(error);
    }
    _session.setUsuarioDetalhe(usuario);

    return switch (configuracao) {
      Ok<UsuarioConfiguracaoModel>(value: final value) => Result.ok((detalhe: usuario, configuracao: value)),
      Error<UsuarioConfiguracaoModel>(error: final error) when _mensagem(error) == kRegistroNaoEncontrado => Result.ok((
        detalhe: usuario,
        configuracao: configuracaoPadrao,
      )),
      Error<UsuarioConfiguracaoModel>(error: final error) => Result.error(error),
    };
  }

  /// Valida e grava o nome completo e o nome de usuário; devolve o detalhe atualizado.
  Future<Result<UsuarioDetalheModel>> salvarDados({
    required UsuarioDetalheModel atual,
    required String nome,
    required String usuario,
  }) async {
    final invalid = validateNome(nome) ?? validateUsuario(usuario);
    if (invalid != null) return Result.error(HandledException(message: invalid));
    if (!dadosAlterados(atual, nome, usuario)) return Result.ok(atual);

    final result = await usuarioRepository.alterarDetalhe(
      UsuarioDetalheBodyModel(udetNome: nome.trim(), udetUsuario: usuario.trim()),
    );
    if (result case Ok<UsuarioDetalheModel>(value: final detalhe)) _session.setUsuarioDetalhe(detalhe);
    return result;
  }

  /// Valida, criptografa e troca a senha.
  Future<Result<void>> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
    required String confirmacao,
  }) async {
    final invalid =
        validateSenhaAtual(senhaAtual) ??
        validateNovaSenha(senhaAtual, novaSenha) ??
        validateConfirmacao(novaSenha, confirmacao);
    if (invalid != null) return Result.error(HandledException(message: invalid));

    final String chave;
    switch (await configuracaoAppUseCase.cryptKeyB64()) {
      case Ok<String>(value: final value):
        chave = value;
      case Error<String>(error: final error):
        return Result.error(error);
    }

    final String atualCriptografada;
    final String novaCriptografada;
    try {
      atualCriptografada = await _encrypt.encryptString(senhaAtual, chave);
      novaCriptografada = await _encrypt.encryptString(novaSenha, chave);
    } catch (_) {
      return Result.error(HandledException(message: kDefaultAppError));
    }

    return usuarioRepository.alterarSenha(senhaAtual: atualCriptografada, novaSenha: novaCriptografada);
  }

  /// Inclui ou altera a configuração; devolve a gravada.
  Future<Result<UsuarioConfiguracaoModel>> salvarConfiguracao(UsuarioConfiguracaoModel configuracao) async {
    final invalid =
        validateQuantidade(configuracao.quantidadeLogsAcesso) ??
        validateQuantidade(configuracao.quantidadeLogsNotificacao);
    if (invalid != null) return Result.error(HandledException(message: invalid));

    if (configuracao.uconId != null) return usuarioRepository.alterarConfiguracao(configuracao);

    final incluida = await usuarioRepository.incluirConfiguracao(configuracao);
    if (incluida case Error(error: final error) when _mensagem(error) == kConfiguracaoDuplicada) {
      return switch (await usuarioRepository.configuracao()) {
        Ok<UsuarioConfiguracaoModel>(value: final existente) => usuarioRepository.alterarConfiguracao(
          configuracao.copyWith(uconId: existente.uconId),
        ),
        Error<UsuarioConfiguracaoModel>(error: final error) => Result.error(error),
      };
    }
    return incluida;
  }

  // ---------- textos ----------

  static bool opcao(UsuarioConfiguracaoModel configuracao, UsuarioConfiguracaoOpcao opcao) => switch (opcao) {
    UsuarioConfiguracaoOpcao.emailVersiculo => configuracao.emailVersiculo,
    UsuarioConfiguracaoOpcao.emailComunidade => configuracao.emailComunidade,
    UsuarioConfiguracaoOpcao.emailLeitura => configuracao.emailLeitura,
    UsuarioConfiguracaoOpcao.emailFaleConosco => configuracao.emailFaleConosco,
    UsuarioConfiguracaoOpcao.leituraAberto => configuracao.leituraAberto,
  };

  static UsuarioConfiguracaoModel comOpcao(
    UsuarioConfiguracaoModel configuracao,
    UsuarioConfiguracaoOpcao opcao,
    bool valor,
  ) => switch (opcao) {
    UsuarioConfiguracaoOpcao.emailVersiculo => configuracao.copyWith(emailVersiculo: valor),
    UsuarioConfiguracaoOpcao.emailComunidade => configuracao.copyWith(emailComunidade: valor),
    UsuarioConfiguracaoOpcao.emailLeitura => configuracao.copyWith(emailLeitura: valor),
    UsuarioConfiguracaoOpcao.emailFaleConosco => configuracao.copyWith(emailFaleConosco: valor),
    UsuarioConfiguracaoOpcao.leituraAberto => configuracao.copyWith(leituraAberto: valor),
  };

  static int quantidade(UsuarioConfiguracaoModel configuracao, UsuarioConfiguracaoQuantidade quantidade) =>
      switch (quantidade) {
        UsuarioConfiguracaoQuantidade.logsAcesso => configuracao.quantidadeLogsAcesso,
        UsuarioConfiguracaoQuantidade.logsNotificacao => configuracao.quantidadeLogsNotificacao,
      };

  static UsuarioConfiguracaoModel comQuantidade(
    UsuarioConfiguracaoModel configuracao,
    UsuarioConfiguracaoQuantidade quantidade,
    int valor,
  ) => switch (quantidade) {
    UsuarioConfiguracaoQuantidade.logsAcesso => configuracao.copyWith(quantidadeLogsAcesso: valor),
    UsuarioConfiguracaoQuantidade.logsNotificacao => configuracao.copyWith(quantidadeLogsNotificacao: valor),
  };

  /// [quantidadesSugeridas] mais a [atual], em ordem crescente.
  static List<int> opcoesQuantidade(int atual) => ({...quantidadesSugeridas, atual}.toList()..sort());

  /// Iniciais do avatar: primeira letra do primeiro e do último nome; sem nome, a do nome de usuário ou do e-mail.
  static String iniciais(UsuarioDetalheModel detalhe) {
    final partes = detalhe.udetNome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isNotEmpty) {
      final primeira = partes.first[0];
      final ultima = partes.length > 1 ? partes.last[0] : kVazio;
      return '$primeira$ultima'.toUpperCase();
    }
    final reserva = detalhe.udetUsuario.isNotEmpty ? detalhe.udetUsuario : detalhe.usuaEmail;
    return reserva.isEmpty ? '?' : reserva[0].toUpperCase();
  }

  /// Data e hora como "dd/MM/yyyy HH:mm"; nula sem data.
  static String? data(DateTime? quando) => quando == null ? null : DateFormat('dd/MM/yyyy HH:mm').format(quando);

  static String mensagemErro(Exception error) => _mensagem(error) ?? kDefaultAppError;

  static String? _mensagem(Exception error) => switch (error) {
    HandledException(message: final message) => message,
    HttpServiceException(message: final message?) => message,
    _ => null,
  };
}
