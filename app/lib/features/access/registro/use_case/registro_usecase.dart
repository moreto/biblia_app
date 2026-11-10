import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/registro_model.dart';
import '../../configuracao_app/use_case/configuracao_app_usecase.dart';
import '../repository/registro_repository.dart';

/// Regras de negócio do cadastro de usuário. As validações devolvem a chave de tradução do erro, ou null se o
/// valor é válido.
///
/// - o cadastro exige e-mail válido, senha com ao menos [senhaMinimo] caracteres e a confirmação igual à senha;
/// - a senha vai criptografada com a chave compartilhada com a API (a mesma do login);
/// - a API cria o usuário inativo e envia um código de 6 dígitos ao e-mail; a conta só é ativada ao confirmar
///   esse código, junto com o nome completo (até [nomeMaximo] caracteres) e o nome de usuário ([usuarioMinimo] a
///   [usuarioMaximo] letras sem acento, números, `.`, `-` ou `_`), gravados no detalhe do usuário.
class RegistroUseCase {
  RegistroUseCase({required this.registroRepository, required this.configuracaoAppUseCase}) {
    Log.print(super.runtimeType);
  }

  final RegistroRepository registroRepository;

  /// Fornece a chave de criptografia da senha, lida de `GET /v1/configuracao-app`.
  final ConfiguracaoAppUseCase configuracaoAppUseCase;
  final Encrypt _encrypt = Encrypt();

  /// Tamanho mínimo da senha no cadastro.
  static const senhaMinimo = 6;

  /// Tamanho máximo do nome completo (`udet_nome`).
  static const nomeMaximo = 70;

  /// Tamanho mínimo e máximo do nome de usuário (`udet_usuario`).
  static const usuarioMinimo = 3;
  static const usuarioMaximo = 30;

  static final _usuarioRegex = RegExp('^[A-Za-z0-9._-]{$usuarioMinimo,$usuarioMaximo}\$');
  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _codigoRegex = RegExp(r'^\d{6}$');

  // ---------- validações ----------

  String? validateEmail(String? email) {
    final value = email?.trim() ?? kVazio;
    if (value.isEmpty) return 'emailObrigatorio';
    if (!_emailRegex.hasMatch(value)) return 'emailInvalido';
    return null;
  }

  String? validateSenha(String? senha) {
    if (senha == null || senha.isEmpty) return 'informeSenha';
    if (senha.length < senhaMinimo) return 'senhaMinimo6';
    return null;
  }

  String? validateConfirmacao(String? senha, String? confirmacao) {
    if (confirmacao == null || confirmacao.isEmpty) return 'informeConfirmacaoSenha';
    if (confirmacao != senha) return 'senhasDiferentes';
    return null;
  }

  String? validateCodigo(String? codigo) {
    if (!_codigoRegex.hasMatch(codigo?.trim() ?? kVazio)) return 'informeCodigo6Digitos';
    return null;
  }

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

  /// Chave de tradução da mensagem de um erro devolvido pelas operações de cadastro.
  String errorMessage(Exception error) => switch (error) {
    HandledException(message: final message) => message,
    HttpServiceException(message: final message?) => message,
    _ => kDefaultAppError,
  };

  // ---------- operações ----------

  /// Valida os dados, criptografa a senha e cria o usuário (inativo). A API envia o código de ativação ao e-mail.
  Future<Result<RegistroModel>> registrar({
    required String email,
    required String senha,
    required String confirmacao,
  }) async {
    final invalid = validateEmail(email) ?? validateSenha(senha) ?? validateConfirmacao(senha, confirmacao);
    if (invalid != null) return Result.error(HandledException(message: invalid));

    final String chave;
    switch (await configuracaoAppUseCase.cryptKeyB64()) {
      case Ok<String>(value: final value):
        chave = value;
      case Error<String>(error: final error):
        return Result.error(error);
    }

    final String senhaCriptografada;
    try {
      senhaCriptografada = await _encrypt.encryptString(senha, chave);
    } catch (_) {
      return Result.error(HandledException(message: kDefaultAppError));
    }

    return registroRepository.registrar(email: email.trim(), senha: senhaCriptografada);
  }

  /// Confirma o código de ativação enviado ao e-mail, grava o nome completo e o nome de usuário e ativa a conta.
  Future<Result<void>> ativar({
    required String email,
    required String codigo,
    required String nome,
    required String usuario,
  }) async {
    final invalid = validateEmail(email) ?? validateCodigo(codigo) ?? validateNome(nome) ?? validateUsuario(usuario);
    if (invalid != null) return Result.error(HandledException(message: invalid));

    return registroRepository.ativar(
      email: email.trim(),
      codigo: codigo.trim(),
      nome: nome.trim(),
      usuario: usuario.trim(),
    );
  }
}
