import 'package:commons/commons.dart';

import '../../../data/model/configuracao/configuracao_item_model.dart';
import '../../../data/model/configuracao/configuracao_model.dart';
import '../../../data/model/fale_conosco/fale_conosco_model.dart';

abstract class FaleConoscoRepository {
  /// Chamados do usuário, mais recentes primeiro (`GET /v1/fale-conosco/meus`).
  Future<Result<List<FaleConoscoModel>>> meus();

  /// Chamado do usuário com as interações não internas (`GET /v1/fale-conosco/meus/:fconId`); 404
  /// `registroNaoEncontrado` se não for dele.
  Future<Result<FaleConoscoModel>> meu(int fconId);

  /// Abre o chamado (`POST /v1/fale-conosco`); 400 `dadosInvalidos` com campo inválido ou categoria/origem fora da
  /// configuração.
  Future<Result<FaleConoscoEnvioModel>> enviar(FaleConoscoBodyModel body);

  /// Mensagem do solicitante no próprio chamado (`POST /v1/fale-conosco-interacao/solicitante`); 404
  /// `registroNaoEncontrado` se o chamado não for dele ou estiver fechado.
  Future<Result<void>> responder({required int fconId, required String texto});

  /// Configurações (`GET /v1/configuracao`), para achar as do Fale Conosco.
  Future<Result<List<ConfiguracaoModel>>> configuracoes();

  /// Itens da configuração [confId] (`GET /v1/configuracao-item/:confId`).
  Future<Result<List<ConfiguracaoItemModel>>> itens(int confId);
}
