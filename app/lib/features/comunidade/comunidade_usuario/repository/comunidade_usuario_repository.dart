import 'package:commons/commons.dart';

import '../../../../data/model/comunidade/comunidade_usuario_model.dart';
import '../../../../data/model/usuario/usuario_resumo_model.dart';

abstract class ComunidadeUsuarioRepository {
  /// Usuários da comunidade, ativos e inativos, com nome (`GET /v1/comunidade-usuario/:comuId`).
  Future<Result<List<ComunidadeUsuarioModel>>> usuarios(int comuId);

  /// Usuários ativos cujo nome ou nome de usuário contém [texto], exceto o logado
  /// (`GET /v1/usuario/busca?texto=`).
  Future<Result<List<UsuarioResumoModel>>> buscarUsuarios(String texto);

  /// Vincula o usuário à comunidade (`POST /v1/comunidade-usuario`).
  Future<Result<ComunidadeUsuarioModel>> incluir(ComunidadeUsuarioModel vinculo);

  /// Altera o vínculo pelo `cusuId` (`PUT /v1/comunidade-usuario`).
  Future<Result<ComunidadeUsuarioModel>> alterar(ComunidadeUsuarioModel vinculo);

  /// Remove o vínculo (`DELETE /v1/comunidade-usuario/:cusuId`).
  Future<Result<void>> excluir(int cusuId);
}
