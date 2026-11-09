import 'package:commons/commons.dart';

import '../../../../data/model/registro_model.dart';

abstract class RegistroRepository {
  /// `POST /v1/acesso/registro`. Cria o usuário inativo e envia o código de ativação ao e-mail.
  /// [senha] já deve chegar criptografada (AES-256-GCM).
  Future<Result<RegistroModel>> registrar({required String email, required String senha});

  /// `POST /v1/usuario-ativacao/confirmar`. Ativa o usuário do [email] se o [codigo] bater com o enviado.
  Future<Result<void>> ativar({required String email, required String codigo});
}
