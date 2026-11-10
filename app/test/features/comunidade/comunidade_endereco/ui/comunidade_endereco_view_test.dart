import 'package:app/data/model/comunidade/comunidade_denominacao_model.dart';
import 'package:app/data/model/comunidade/comunidade_endereco_model.dart';
import 'package:app/data/model/comunidade/comunidade_model.dart';
import 'package:app/data/model/comunidade/comunidade_tipo_model.dart';
import 'package:app/data/model/localidade/estado_model.dart';
import 'package:app/data/model/localidade/municipio_model.dart';
import 'package:app/features/comunidade/comunidade_endereco/repository/comunidade_endereco_repository.dart';
import 'package:app/features/comunidade/comunidade_endereco/ui/comunidade_endereco_view.dart';
import 'package:app/features/comunidade/comunidade_endereco/ui/comunidade_endereco_viewmodel.dart';
import 'package:app/features/comunidade/comunidade_endereco/use_case/comunidade_endereco_usecase.dart';
import 'package:app/features/comunidade/comunidade/repository/comunidade_repository.dart';
import 'package:app/features/comunidade/comunidade/use_case/comunidade_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service/service.dart';

const _matriz = ComunidadeModel(comuId: 1, comuNome: 'Paróquia Matriz', ctipId: 1, cdenId: 1);
const _capela = ComunidadeModel(comuId: 2, comuNome: 'Capela São José');

const _se = ComunidadeEnderecoModel(
  cendId: 10,
  comuId: 1,
  cendCep: '01001000',
  cendLogradouro: 'Praça da Sé',
  cendNumero: '1',
  cendComplemento: 'Sala 2',
  cendBairro: 'Sé',
  muniId: 3550308,
  muniNome: 'São Paulo',
  estaId: 35,
  estaSigla: 'SP',
);

/// Só a listagem de comunidades é usada por esta aba.
class _FakeComunidadeRepository implements ComunidadeRepository {
  _FakeComunidadeRepository(this.comunidades);

  final List<ComunidadeModel> comunidades;

  @override
  Future<Result<List<ComunidadeModel>>> comunidadesDoUsuario(int usuaId) async => Result.ok(comunidades);

  @override
  Future<Result<List<ComunidadeTipoModel>>> tipos() async => const Result.ok([]);

  @override
  Future<Result<List<ComunidadeDenominacaoModel>>> denominacoes() async => const Result.ok([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Endereços por comunidade em memória; incluir, alterar e excluir mexem neles como a API.
class _FakeComunidadeEnderecoRepository implements ComunidadeEnderecoRepository {
  _FakeComunidadeEnderecoRepository(Map<int, List<ComunidadeEnderecoModel>> porComunidade)
    : porComunidade = {
        for (final e in porComunidade.entries) e.key: [...e.value],
      };

  final Map<int, List<ComunidadeEnderecoModel>> porComunidade;
  final erros = <int, Exception>{};
  final consultas = <int>[];
  final gravados = <(String, ComunidadeEnderecoModel)>[];
  final excluidos = <int>[];
  int chamadasEstados = 0;
  final chamadasMunicipios = <int>[];

  @override
  Future<Result<List<ComunidadeEnderecoModel>>> enderecos(int comuId) async {
    consultas.add(comuId);
    final erro = erros[comuId];
    return erro != null ? Result.error(erro) : Result.ok(List.of(porComunidade[comuId] ?? const []));
  }

  @override
  Future<Result<List<EstadoModel>>> estados() async {
    chamadasEstados++;
    return const Result.ok([
      EstadoModel(estaId: 35, estaNome: 'São Paulo', estaSigla: 'SP'),
      EstadoModel(estaId: 33, estaNome: 'Rio de Janeiro', estaSigla: 'RJ'),
    ]);
  }

  @override
  Future<Result<List<MunicipioModel>>> municipios(int estaId) async {
    chamadasMunicipios.add(estaId);
    return Result.ok([
      if (estaId == 35) const MunicipioModel(muniId: 3550308, muniNome: 'São Paulo', estaId: 35),
      if (estaId == 33) const MunicipioModel(muniId: 3304557, muniNome: 'Rio de Janeiro', estaId: 33),
    ]);
  }

  @override
  Future<Result<ComunidadeEnderecoModel>> incluir(ComunidadeEnderecoModel endereco) async {
    gravados.add(('incluir', endereco));
    (porComunidade[endereco.comuId] ??= []).add(endereco);
    return Result.ok(endereco);
  }

  @override
  Future<Result<ComunidadeEnderecoModel>> alterar(ComunidadeEnderecoModel endereco) async {
    gravados.add(('alterar', endereco));
    final lista = porComunidade[endereco.comuId]!;
    lista[lista.indexWhere((e) => e.cendId == endereco.cendId)] = endereco;
    return Result.ok(endereco);
  }

  @override
  Future<Result<void>> excluir(int cendId) async {
    excluidos.add(cendId);
    for (final lista in porComunidade.values) {
      lista.removeWhere((e) => e.cendId == cendId);
    }
    return const Result.ok(null);
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
  late _FakeComunidadeEnderecoRepository repository;

  setUp(
    () => repository = _FakeComunidadeEnderecoRepository({
      1: [_se],
    }),
  );

  ComunidadeEnderecoUseCase criarUseCase([List<ComunidadeModel> comunidades = const [_matriz, _capela]]) =>
      ComunidadeEnderecoUseCase(
        comunidadeEnderecoRepository: repository,
        comunidadeUseCase: ComunidadeUseCase(
          comunidadeRepository: _FakeComunidadeRepository(comunidades),
          usuarioLogado: () => 7,
        ),
      );

  ComunidadeEnderecoViewmodel criar([List<ComunidadeModel> comunidades = const [_matriz, _capela]]) =>
      ComunidadeEnderecoViewmodel(comunidadeEnderecoUseCase: criarUseCase(comunidades));

  Future<void> montar(WidgetTester tester, ComunidadeEnderecoViewmodel viewModel) async {
    viewModel.abrir();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        home: Scaffold(
          body: ComunidadeEnderecoView(viewModel: viewModel, onEditar: (_) {}, onExcluir: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('modelos', () {
    test('ComunidadeEnderecoModel.fromJson aceita camelCase e snake_case com opcionais nulos', () {
      final camel = ComunidadeEnderecoModel.fromJson({
        'cendId': 1,
        'comuId': 2,
        'cendCep': '01001000',
        'cendLogradouro': 'Rua A',
        'muniId': '3',
        'muniNome': 'Cidade',
        'estaId': 35,
        'estaSigla': 'SP',
      });
      expect((camel.cendId, camel.comuId, camel.muniId, camel.estaId, camel.cendNumero), (1, 2, 3, 35, null));

      final snake = ComunidadeEnderecoModel.fromJson({
        'cend_id': 4,
        'comu_id': 5,
        'cend_cep': '1',
        'cend_logradouro': 'Rua B',
        'cend_bairro': 'Centro',
        'muni_id': 6,
      });
      expect((snake.cendId, snake.cendBairro, snake.estaSigla), (4, 'Centro', null));
    });

    test('ComunidadeEnderecoModel.fromJson aceita cendNumero numérico (coluna integer no banco)', () {
      final endereco = ComunidadeEnderecoModel.fromJson({
        'cendId': 1,
        'comuId': 1,
        'cendCep': '73252200',
        'cendLogradouro': 'Rk',
        'cendNumero': 6,
        'cendComplemento': null,
        'muniId': 5300108,
      });
      expect((endereco.cendNumero, endereco.cendComplemento), ('6', null));
      expect(() => ComunidadeEnderecoModel.fromJson({...endereco.toJson(), 'cendNumero': true}), throwsFormatException);
    });

    test('ComunidadeEnderecoModel.fromJson sem logradouro lança FormatException', () {
      expect(() => ComunidadeEnderecoModel.fromJson({'comuId': 1, 'cendCep': '1', 'muniId': 1}), throwsFormatException);
    });

    test('EstadoModel e MunicipioModel', () {
      final estado = EstadoModel.fromJson({'esta_id': 35, 'esta_nome': 'São Paulo', 'esta_sigla': 'SP'});
      final municipio = MunicipioModel.fromJson({'muniId': 1, 'muniNome': 'Santos', 'estaId': '35'});
      expect((estado.estaId, estado.estaSigla), (35, 'SP'));
      expect((municipio.muniId, municipio.estaId), (1, 35));
    });
  });

  group('ComunidadeEnderecoUseCase', () {
    test('formata as linhas do card e o CEP', () {
      expect(ComunidadeEnderecoUseCase.linhaPrincipal(_se), 'Praça da Sé, 1 - Sala 2');
      expect(ComunidadeEnderecoUseCase.linhaLocal(_se), 'Sé · São Paulo - SP');
      expect(ComunidadeEnderecoUseCase.cepFormatado('01001000'), '01001-000');
      expect(ComunidadeEnderecoUseCase.cepFormatado(' 123 '), '123');

      const minimo = ComunidadeEnderecoModel(
        comuId: 1,
        cendCep: '1',
        cendLogradouro: 'Rua A',
        cendNumero: ' ',
        muniId: 1,
      );
      expect(ComunidadeEnderecoUseCase.linhaPrincipal(minimo), 'Rua A');
      expect(ComunidadeEnderecoUseCase.linhaLocal(minimo), isNull);
    });

    test('a selecionada é a pedida, se existir; senão a primeira', () async {
      final useCase = criarUseCase();
      final comunidades = (await useCase.comunidades() as Ok<List<ComunidadeResumo>>).value;

      expect(comunidades.map((c) => c.comunidade.comuId), [2, 1], reason: 'por nome');
      expect(useCase.selecionada(comunidades, 1)?.comunidade.comuId, 1);
      expect(useCase.selecionada(comunidades, 99)?.comunidade.comuId, 2);
      expect(useCase.selecionada(const [], 1), isNull);
    });

    test('404 registroNaoEncontrado nos endereços vira lista vazia; outros erros são repassados', () async {
      repository.erros[2] = HttpServiceException(message: 'registroNaoEncontrado', code: 404);
      expect((await criarUseCase().enderecos(2) as Ok).value, isEmpty);

      final erro = HttpServiceException(message: 'erroGeralApi', code: 500);
      repository.erros[2] = erro;
      expect((await criarUseCase().enderecos(2) as Error).error, same(erro));
    });

    test('estados e municípios ficam em cache', () async {
      final useCase = criarUseCase();
      await useCase.estados();
      await useCase.estados();
      await useCase.municipios(35);
      await useCase.municipios(35);
      await useCase.municipios(33);

      expect(repository.chamadasEstados, 1);
      expect(repository.chamadasMunicipios, [35, 33]);
    });

    test('validar exige comunidade, CEP com 8 dígitos, logradouro e município', () {
      final useCase = criarUseCase();
      ComunidadeEnderecoModel endereco({
        int comuId = 1,
        String cep = '01001-000',
        String logradouro = 'Rua',
        int muniId = 1,
      }) => ComunidadeEnderecoModel(comuId: comuId, cendCep: cep, cendLogradouro: logradouro, muniId: muniId);

      expect(useCase.validar(endereco()), isNull);
      expect(useCase.validar(endereco(comuId: 0)), 'comunidadeObrigatoria');
      expect(useCase.validar(endereco(cep: '0100100')), 'cepInvalido');
      expect(useCase.validar(endereco(logradouro: '  ')), 'logradouroObrigatorio');
      expect(useCase.validar(endereco(muniId: 0)), 'municipioObrigatorio');
    });

    test('validar: número só com dígitos (até 9) e tamanhos das colunas', () {
      final useCase = criarUseCase();
      ComunidadeEnderecoModel endereco({String? numero, String logradouro = 'Rua', String? bairro}) =>
          ComunidadeEnderecoModel(
            comuId: 1,
            cendCep: '01001000',
            cendLogradouro: logradouro,
            cendNumero: numero,
            cendBairro: bairro,
            muniId: 1,
          );

      expect(useCase.validar(endereco(numero: ' 10 ')), isNull);
      expect(useCase.validar(endereco(numero: '  ')), isNull);
      expect(useCase.validar(endereco(numero: 'S/N')), 'numeroInvalido');
      expect(useCase.validar(endereco(numero: '1234567890')), 'numeroInvalido');
      expect(useCase.validar(endereco(logradouro: 'a' * 257)), 'dadosInvalidos');
      expect(useCase.validar(endereco(bairro: 'b' * 61)), 'dadosInvalidos');
      expect(useCase.validar(endereco(bairro: 'b' * 60)), isNull);
    });

    test(
      'salvar normaliza (CEP só com dígitos, textos sem espaços, opcionais em branco nulos) e escolhe POST/PUT',
      () async {
        final useCase = criarUseCase();
        await useCase.salvar(
          const ComunidadeEnderecoModel(
            comuId: 2,
            cendCep: '01001-000',
            cendLogradouro: '  Rua Nova ',
            cendNumero: ' 10 ',
            cendComplemento: '  ',
            muniId: 3550308,
          ),
        );
        await useCase.salvar(_se);

        final (acao, incluido) = repository.gravados.first;
        expect(acao, 'incluir');
        expect(
          (incluido.cendCep, incluido.cendLogradouro, incluido.cendNumero, incluido.cendComplemento),
          ('01001000', 'Rua Nova', '10', null),
        );
        expect(repository.gravados.last.$1, 'alterar');
      },
    );

    test('salvar inválido não chama a API', () async {
      final result = await criarUseCase().salvar(
        const ComunidadeEnderecoModel(comuId: 1, cendCep: '1', cendLogradouro: 'Rua', muniId: 1),
      );
      expect(((result as Error).error as HandledException).message, 'cepInvalido');
      expect(repository.gravados, isEmpty);
    });
  });

  group('ComunidadeEnderecoViewmodel', () {
    test('só carrega ao abrir: comunidades e endereços da primeira; de novo depois de invalidar', () async {
      final viewModel = criar();
      await pumpEventQueue();
      expect(repository.consultas, isEmpty);

      viewModel.abrir();
      await pumpEventQueue();
      expect(viewModel.selecionada?.comunidade.comuId, 2);
      expect(viewModel.enderecos, isEmpty);
      expect(repository.consultas, [2], reason: 'só a selecionada');

      viewModel.abrir();
      await pumpEventQueue();
      expect(repository.consultas, [2]);

      viewModel.invalidar();
      viewModel.abrir();
      await pumpEventQueue();
      expect(repository.consultas, [2, 2]);
    });

    test('selecionar antes de carregar vale no carregamento; depois troca na hora', () async {
      final viewModel = criar();
      viewModel.selecionar(1);
      viewModel.abrir();
      await pumpEventQueue();
      expect(viewModel.selecionada?.comunidade.comuId, 1);
      expect(viewModel.enderecos.single.cendId, 10);

      viewModel.selecionar(2);
      await pumpEventQueue();
      expect(viewModel.selecionada?.comunidade.comuId, 2);
      expect(viewModel.enderecos, isEmpty);
    });

    test('salvar e excluir recarregam os endereços da selecionada', () async {
      final viewModel = criar();
      viewModel.selecionar(1);
      viewModel.abrir();
      await pumpEventQueue();

      await viewModel.salvarCommand.execute(
        const ComunidadeEnderecoModel(comuId: 1, cendCep: '20000000', cendLogradouro: 'Rua B', muniId: 1),
      );
      expect(viewModel.enderecos, hasLength(2));

      await viewModel.excluirCommand.execute(_se);
      expect(viewModel.enderecos.single.cendLogradouro, 'Rua B');
    });

    test('erro na troca de comunidade mantém a seleção e a lista anteriores', () async {
      final viewModel = criar();
      viewModel.selecionar(1);
      viewModel.abrir();
      await pumpEventQueue();
      repository.erros[2] = HttpServiceException(message: 'erroGeralApi', code: 500);
      await viewModel.selecionarCommand.execute(2);

      expect(viewModel.selecionarCommand.error, isTrue);
      expect(viewModel.selecionada?.comunidade.comuId, 1);
      expect(viewModel.enderecos, hasLength(1));
    });
  });

  group('ComunidadeEnderecoView', () {
    testWidgets('mostra a comunidade selecionada e os endereços dela', (tester) async {
      final viewModel = criar()..selecionar(1);
      await montar(tester, viewModel);

      expect(find.text('Paróquia Matriz'), findsOneWidget);
      expect(find.text('Praça da Sé, 1 - Sala 2'), findsOneWidget);
      expect(find.text('Sé · São Paulo - SP'), findsOneWidget);
      expect(find.text('cep 01001-000'), findsOneWidget);
    });

    testWidgets('trocar a comunidade no topo mostra os endereços dela', (tester) async {
      await montar(tester, criar()..selecionar(1));

      await tester.tap(find.text('Paróquia Matriz'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Capela São José').last);
      await tester.pumpAndSettle();

      expect(find.text('nenhumEnderecoCadastrado'), findsOneWidget);
      expect(find.text('Praça da Sé, 1 - Sala 2'), findsNothing);
    });

    testWidgets('sem comunidades mostra nenhumaComunidadeCadastrada', (tester) async {
      await montar(tester, criar(const []));
      expect(find.text('nenhumaComunidadeCadastrada'), findsOneWidget);
    });

    testWidgets('falha no primeiro carregamento mostra a mensagem e tenta novamente', (tester) async {
      repository.erros[1] = HttpServiceException(message: 'erroGeralApi', code: 500);
      await montar(tester, criar()..selecionar(1));
      expect(find.text('erroGeralApi'), findsOneWidget);

      repository.erros.clear();
      await tester.tap(find.text('tentarNovamente'));
      await tester.pumpAndSettle();
      expect(find.text('Praça da Sé, 1 - Sala 2'), findsOneWidget);
    });
  });
}
