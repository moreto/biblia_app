import 'package:commons/commons.dart';

import '../../../../data/model/configuracao/configuracao_item_model.dart';
import '../../../../data/model/configuracao/configuracao_model.dart';
import '../repository/configuracao_repository.dart';

class ConfiguracaoUseCase {
  ConfiguracaoUseCase({required this.configuracaoRepository}) {
    Log.print(super.runtimeType);
  }

  static const int kConfNomeMaxLength = 60;
  static const int kCiteValorMaxLength = 128;

  final ConfiguracaoRepository configuracaoRepository;

  // configuracao

  Future<Result<List<ConfiguracaoModel>>> getConfiguracoes() async {
    final result = await configuracaoRepository.getConfiguracoes();
    switch (result) {
      case Ok<List<ConfiguracaoModel>>():
        final configuracoes = [...result.value]
          ..sort((a, b) => a.confNome.toLowerCase().compareTo(b.confNome.toLowerCase()));
        return Result.ok(configuracoes);
      case Error<List<ConfiguracaoModel>>():
        return Result.error(result.error);
    }
  }

  /// Insere quando [ConfiguracaoModel.confId] é nulo, senão altera.
  Future<Result<ConfiguracaoModel>> saveConfiguracao(ConfiguracaoModel configuracao) async {
    final nome = configuracao.confNome.trim();
    if (nome.isEmpty) {
      return Result.error(HandledException(message: 'nomeObrigatorio'));
    }
    if (nome.length > kConfNomeMaxLength) {
      return Result.error(HandledException(message: 'nomeMaximo60'));
    }

    final normalizada = configuracao.copyWith(confNome: nome);
    final result = normalizada.isNovo
        ? await configuracaoRepository.insertConfiguracao(normalizada)
        : await configuracaoRepository.updateConfiguracao(normalizada);
    switch (result) {
      case Ok<ConfiguracaoModel>():
        return Result.ok(result.value);
      case Error<ConfiguracaoModel>():
        return Result.error(result.error);
    }
  }

  Future<Result<int>> deleteConfiguracao(ConfiguracaoModel configuracao) async {
    final confId = configuracao.confId;
    if (confId == null) {
      return Result.error(HandledException(message: 'registroNaoEncontrado'));
    }

    final result = await configuracaoRepository.deleteConfiguracao(confId);
    switch (result) {
      case Ok<int>():
        return Result.ok(result.value);
      case Error<int>():
        return Result.error(result.error);
    }
  }

  // configuracao-item

  Future<Result<List<ConfiguracaoItemModel>>> getItens(int confId) async {
    final result = await configuracaoRepository.getItens(confId);
    switch (result) {
      case Ok<List<ConfiguracaoItemModel>>():
        return Result.ok(result.value);
      case Error<List<ConfiguracaoItemModel>>():
        return Result.error(result.error);
    }
  }

  /// Insere quando [ConfiguracaoItemModel.citeId] é nulo, senão altera.
  Future<Result<ConfiguracaoItemModel>> saveItem(ConfiguracaoItemModel item) async {
    final valor = item.citeValor?.trim();
    if (valor != null && valor.length > kCiteValorMaxLength) {
      return Result.error(HandledException(message: 'valorMaximo128'));
    }

    final normalizado = ConfiguracaoItemModel(
      citeId: item.citeId,
      confId: item.confId,
      citeChave: item.citeChave,
      citeValor: valor == null || valor.isEmpty ? null : valor,
      citeSequencia: item.citeSequencia,
      citeAtivo: item.citeAtivo,
    );
    final result = normalizado.isNovo
        ? await configuracaoRepository.insertItem(normalizado)
        : await configuracaoRepository.updateItem(normalizado);
    switch (result) {
      case Ok<ConfiguracaoItemModel>():
        return Result.ok(result.value);
      case Error<ConfiguracaoItemModel>():
        return Result.error(result.error);
    }
  }

  Future<Result<int>> deleteItem(ConfiguracaoItemModel item) async {
    final citeId = item.citeId;
    if (citeId == null) {
      return Result.error(HandledException(message: 'registroNaoEncontrado'));
    }

    final result = await configuracaoRepository.deleteItem(citeId);
    switch (result) {
      case Ok<int>():
        return Result.ok(result.value);
      case Error<int>():
        return Result.error(result.error);
    }
  }
}
