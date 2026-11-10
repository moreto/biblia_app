import 'package:app/data/model/configuracao/configuracao_app_model.dart';
import 'package:app/features/access/configuracao_app/repository/configuracao_app_repository.dart';
import 'package:app/features/access/configuracao_app/use_case/configuracao_app_usecase.dart';
import 'package:commons/commons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service/service.dart';

const _chave = '5oAaa+hIOTQzGUxHYn8o6mHfQqEi9PXb4kBGpCQ+fn0=';

class _FakeRepository implements ConfiguracaoAppRepository {
  _FakeRepository(this.resposta);

  Result<List<ConfiguracaoAppModel>> resposta;
  int chamadas = 0;

  @override
  Future<Result<List<ConfiguracaoAppModel>>> listar() async {
    chamadas++;
    return resposta;
  }
}

List<ConfiguracaoAppModel> _itens({String cryptKeyB64 = _chave, String? accessTokenId = 'tokenApi'}) => [
  const ConfiguracaoAppModel(citeChave: kConfCryptKey, citeValor: 'MmT3xh0'),
  ConfiguracaoAppModel(citeChave: kConfCryptKeyB64, citeValor: cryptKeyB64),
  if (accessTokenId != null) ConfiguracaoAppModel(citeChave: kConfAccessTokenId, citeValor: accessTokenId),
];

void main() {
  setUp(AppSession.instance.clear);
  tearDown(AppSession.instance.clear);

  test('grava as chaves na sessão e o header passa a usar o access token da API', () async {
    final repo = _FakeRepository(Result.ok(_itens()));
    final result = await ConfiguracaoAppUseCase(configuracaoAppRepository: repo).carregar();

    expect(result, isA<Ok<void>>());
    expect(AppSession.instance.cryptKey, 'MmT3xh0');
    expect(AppSession.instance.cryptKeyB64, _chave);
    expect(AppSession.instance.accessTokenId, 'tokenApi');
    expect(Header.buildHeaders()['x-access-token'], 'tokenApi');
  });

  test('sem kAccessTokenId mantém o access token embutido', () async {
    final repo = _FakeRepository(Result.ok(_itens(accessTokenId: null)));
    await ConfiguracaoAppUseCase(configuracaoAppRepository: repo).carregar();

    expect(AppSession.instance.accessTokenId, isNull);
    expect(Header.buildHeaders()['x-access-token'], kAccessTokenId);
  });

  test('lê a API uma vez só', () async {
    final repo = _FakeRepository(Result.ok(_itens()));
    final useCase = ConfiguracaoAppUseCase(configuracaoAppRepository: repo);

    await useCase.carregar();
    final chave = await useCase.cryptKeyB64();

    expect(repo.chamadas, 1);
    expect(chave, isA<Ok<String>>().having((r) => r.value, 'value', _chave));
  });

  for (final invalida in ['', 'nao-e-base64', 'MTIz']) {
    test('recusa kCryptKeyB64 inválida ("$invalida") sem gravar a sessão', () async {
      final repo = _FakeRepository(Result.ok(_itens(cryptKeyB64: invalida)));
      final result = await ConfiguracaoAppUseCase(configuracaoAppRepository: repo).cryptKeyB64();

      expect(result, isA<Error<String>>());
      expect(((result as Error<String>).error as HandledException).message, 'configuracaoAppInvalida');
      expect(AppSession.instance.isLoaded, isFalse);
    });
  }

  test('erro da API é repassado e a próxima chamada tenta de novo', () async {
    final repo = _FakeRepository(Result.error(HttpServiceException(message: 'erroApi', code: 500)));
    final useCase = ConfiguracaoAppUseCase(configuracaoAppRepository: repo);

    expect(await useCase.carregar(), isA<Error<void>>());

    repo.resposta = Result.ok(_itens());
    expect(await useCase.carregar(), isA<Ok<void>>());
    expect(repo.chamadas, 2);
  });
}
