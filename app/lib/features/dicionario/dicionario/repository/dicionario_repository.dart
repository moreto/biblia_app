import 'package:commons/commons.dart';

import '../../../../data/model/dicionario/dicionario_busca_model.dart';
import '../../../../data/model/dicionario/dicionario_verbete_model.dart';

abstract class DicionarioRepository {
  /// Verbetes que começam pelo [texto] ou são semelhantes a ele, no máximo [limite]
  /// (`GET /v1/dicionario/busca?texto=&limite=`). Lista vazia se nada for encontrado.
  Future<Result<List<DicionarioBuscaModel>>> buscar(String texto, {required int limite});

  /// Verbetes completos (um por homônimo) cuja palavra é igual a [palavra], sem diferenciar maiúsculas nem acentos
  /// (`GET /v1/dicionario/palavra/:palavra`). Lista vazia se a palavra não existir.
  Future<Result<List<DicionarioVerbeteModel>>> palavra(String palavra);
}
