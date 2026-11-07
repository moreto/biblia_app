import 'package:app/data/model/configuracao/configuracao_item_model.dart';
import 'package:app/data/model/configuracao/configuracao_model.dart';
import 'package:app/features/configuracao/repository/configuracao_repository.dart';
import 'package:app/features/configuracao/ui/configuracao_view.dart';
import 'package:app/features/configuracao/ui/configuracao_viewmodel.dart';
import 'package:app/features/configuracao/use_case/configuracao_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConfiguracaoRepository implements ConfiguracaoRepository {
  final List<ConfiguracaoModel> configuracoes = [
    const ConfiguracaoModel(confId: 2, confNome: 'Níveis de Acesso do Perfil', confTipo: 1),
    const ConfiguracaoModel(confId: 1, confNome: 'Tipos de Itens', confTipo: 1, confAtivo: false),
  ];
  final List<ConfiguracaoItemModel> itens = [
    const ConfiguracaoItemModel(
      citeId: 4,
      confId: 2,
      citeCampo: 'perf_nivel',
      citeChave: 1,
      citeValor: 'Administrador',
    ),
    const ConfiguracaoItemModel(citeId: 5, confId: 1, citeCampo: 'conf_tipo', citeChave: 1, citeValor: 'Ativação'),
  ];
  int _nextId = 100;

  @override
  Future<Result<List<ConfiguracaoModel>>> getConfiguracoes() async => Result.ok([...configuracoes]);

  @override
  Future<Result<ConfiguracaoModel>> insertConfiguracao(ConfiguracaoModel configuracao) async {
    final novo = configuracao.copyWith(confId: _nextId++);
    configuracoes.add(novo);
    return Result.ok(novo);
  }

  @override
  Future<Result<ConfiguracaoModel>> updateConfiguracao(ConfiguracaoModel configuracao) async {
    final index = configuracoes.indexWhere((item) => item.confId == configuracao.confId);
    if (index < 0) return Result.error(HandledException(message: 'registroNaoEncontrado'));
    configuracoes[index] = configuracao;
    return Result.ok(configuracao);
  }

  @override
  Future<Result<int>> deleteConfiguracao(int confId) async {
    configuracoes.removeWhere((item) => item.confId == confId);
    itens.removeWhere((item) => item.confId == confId);
    return Result.ok(confId);
  }

  @override
  Future<Result<List<ConfiguracaoItemModel>>> getItens(int confId) async =>
      Result.ok(itens.where((item) => item.confId == confId).toList());

  @override
  Future<Result<ConfiguracaoItemModel>> insertItem(ConfiguracaoItemModel item) async {
    final novo = item.copyWith(citeId: _nextId++);
    itens.add(novo);
    return Result.ok(novo);
  }

  @override
  Future<Result<ConfiguracaoItemModel>> updateItem(ConfiguracaoItemModel item) async {
    final index = itens.indexWhere((element) => element.citeId == item.citeId);
    if (index < 0) return Result.error(HandledException(message: 'registroNaoEncontrado'));
    itens[index] = item;
    return Result.ok(item);
  }

  @override
  Future<Result<int>> deleteItem(int citeId) async {
    itens.removeWhere((item) => item.citeId == citeId);
    return Result.ok(citeId);
  }
}

class _TestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale: locale, translations: const []));

  @override
  bool shouldReload(_TestLocalizationsDelegate old) => false;
}

void main() {
  late _FakeConfiguracaoRepository repository;
  late ConfiguracaoUseCase useCase;

  setUp(() {
    repository = _FakeConfiguracaoRepository();
    useCase = ConfiguracaoUseCase(configuracaoRepository: repository);
  });

  group('ConfiguracaoUseCase', () {
    test('lista configurações ordenadas pelo nome', () async {
      final result = await useCase.getConfiguracoes();
      expect((result as Ok<List<ConfiguracaoModel>>).value.map((item) => item.confId), [2, 1]);
    });

    test('recusa configuração sem nome', () async {
      final result = await useCase.saveConfiguracao(const ConfiguracaoModel(confNome: '   '));
      expect((result as Error).error, HandledException(message: 'nomeObrigatorio'));
    });

    test('recusa nome acima de 60 caracteres', () async {
      final result = await useCase.saveConfiguracao(ConfiguracaoModel(confNome: 'a' * 61));
      expect((result as Error).error, HandledException(message: 'nomeMaximo60'));
    });

    test('insere sem id e grava o nome sem espaços nas pontas', () async {
      final result = await useCase.saveConfiguracao(const ConfiguracaoModel(confNome: '  Nova  '));
      final value = (result as Ok<ConfiguracaoModel>).value;
      expect(value.confId, isNotNull);
      expect(value.confNome, 'Nova');
    });

    test('altera quando tem id', () async {
      await useCase.saveConfiguracao(const ConfiguracaoModel(confId: 1, confNome: 'Alterada'));
      expect(repository.configuracoes.firstWhere((item) => item.confId == 1).confNome, 'Alterada');
    });

    test('recusa item sem campo e valor acima de 128', () async {
      final semCampo = await useCase.saveItem(const ConfiguracaoItemModel(confId: 1, citeCampo: ''));
      expect((semCampo as Error).error, HandledException(message: 'campoObrigatorio'));

      final valorLongo = await useCase.saveItem(ConfiguracaoItemModel(confId: 1, citeCampo: 'x', citeValor: 'v' * 129));
      expect((valorLongo as Error).error, HandledException(message: 'valorMaximo128'));
    });

    test('item com valor vazio é gravado como nulo', () async {
      final result = await useCase.saveItem(const ConfiguracaoItemModel(confId: 1, citeCampo: 'x', citeValor: '  '));
      expect((result as Ok<ConfiguracaoItemModel>).value.citeValor, isNull);
    });
  });

  group('ConfiguracaoViewmodel', () {
    test('carrega configurações e seleciona a primeira com seus itens', () async {
      final viewModel = ConfiguracaoViewmodel(configuracaoUseCase: useCase);
      await pumpEventQueue();

      expect(viewModel.configuracoes, hasLength(2));
      expect(viewModel.selectedConfId, 2);
      expect(viewModel.itens?.map((item) => item.citeId), [4]);
    });

    test('troca de configuração recarrega os itens', () async {
      final viewModel = ConfiguracaoViewmodel(configuracaoUseCase: useCase);
      await pumpEventQueue();

      viewModel.selectConfiguracao(1);
      await pumpEventQueue();
      expect(viewModel.itens?.map((item) => item.citeId), [5]);
    });

    test('excluir a configuração selecionada seleciona outra', () async {
      final viewModel = ConfiguracaoViewmodel(configuracaoUseCase: useCase);
      await pumpEventQueue();

      await viewModel.deleteConfiguracaoCommand.execute(viewModel.configuracoes!.first);
      await pumpEventQueue();

      expect(viewModel.deleteConfiguracaoCommand.completed, isTrue);
      expect(viewModel.configuracoes?.map((item) => item.confId), [1]);
      expect(viewModel.selectedConfId, 1);
      expect(viewModel.itens?.map((item) => item.citeId), [5]);
    });

    test('inclui item e recarrega a lista', () async {
      final viewModel = ConfiguracaoViewmodel(configuracaoUseCase: useCase);
      await pumpEventQueue();

      await viewModel.saveItemCommand.execute(
        const ConfiguracaoItemModel(confId: 2, citeCampo: 'perf_nivel', citeChave: 5, citeValor: 'Convidado'),
      );
      await pumpEventQueue();

      expect(viewModel.itens?.map((item) => item.citeValor), ['Administrador', 'Convidado']);
    });
  });

  testWidgets('mostra as abas de configurações e itens', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          _TestLocalizationsDelegate(),
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: ConfiguracaoView(viewModel: ConfiguracaoViewmodel(configuracaoUseCase: useCase)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Níveis de Acesso do Perfil'), findsOneWidget);
    expect(find.text('Tipos de Itens'), findsOneWidget);

    await tester.tap(find.text('itensConfiguracao'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Administrador'), findsOneWidget);
  });
}
