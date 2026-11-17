import 'package:commons/commons.dart';

import '../../../data/model/configuracao/configuracao_item_model.dart';
import '../../../data/model/configuracao/configuracao_model.dart';
import '../../../data/model/fale_conosco/fale_conosco_atendimento_model.dart';

/// Atendimento do Fale Conosco. Se a API recusar o acesso do usuário, as rotas respondem 403 `acessoNegado`.
abstract class FaleConoscoAtendimentoRepository {
  /// Fila (`GET /v1/fale-conosco`), por prioridade (maior primeiro) e data de envio.
  Future<Result<List<FaleConoscoAtendimentoModel>>> fila(FaleConoscoAtendimentoFiltroModel filtro);

  /// Chamado completo (`GET /v1/fale-conosco/:fconId`); 404 `registroNaoEncontrado` se não existir.
  Future<Result<FaleConoscoAtendimentoModel>> chamado(int fconId);

  /// Todas as interações, inclusive as internas (`GET /v1/fale-conosco-interacao/:fconId`).
  Future<Result<List<FaleConoscoAtendimentoInteracaoModel>>> interacoes(int fconId);

  /// Resposta ou nota interna (`POST /v1/fale-conosco-interacao`); 404 se o chamado não existir.
  Future<Result<void>> responder(FaleConoscoAtendimentoInteracaoBodyModel body);

  /// Classificação, situação, responsável e fechamento (`PUT /v1/fale-conosco`); devolve o chamado gravado.
  Future<Result<FaleConoscoAtendimentoModel>> atualizar(FaleConoscoAtendimentoBodyModel body);

  /// Exclusão lógica (`DELETE /v1/fale-conosco/:fconId`).
  Future<Result<void>> excluir(int fconId);

  /// Configurações (`GET /v1/configuracao`), para achar as do Fale Conosco.
  Future<Result<List<ConfiguracaoModel>>> configuracoes();

  /// Itens da configuração [confId] (`GET /v1/configuracao-item/:confId`).
  Future<Result<List<ConfiguracaoItemModel>>> itens(int confId);
}
