import 'package:app/data/model/comunidade/comunidade_contato_model.dart';
import 'package:app/data/model/comunidade/comunidade_denominacao_model.dart';
import 'package:app/data/model/comunidade/comunidade_model.dart';
import 'package:app/data/model/comunidade/comunidade_tipo_model.dart';
import 'package:app/features/comunidade/comunidade/repository/comunidade_repository.dart';
import 'package:app/features/comunidade/comunidade/use_case/comunidade_usecase.dart';
import 'package:app/features/comunidade/comunidade_contato/repository/comunidade_contato_repository.dart';
import 'package:app/features/comunidade/comunidade_contato/ui/comunidade_contato_view.dart';
import 'package:app/features/comunidade/comunidade_contato/ui/comunidade_contato_viewmodel.dart';
import 'package:app/features/comunidade/comunidade_contato/use_case/comunidade_contato_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service/service.dart';

const _matriz = ComunidadeModel(comuId: 1, comuNome: 'Paróquia Matriz', ctipId: 1, cdenId: 1);
const _capela = ComunidadeModel(comuId: 2, comuNome: 'Capela São José');

const _secretaria = ComunidadeContatoModel(
  cconId: 10,
  comuId: 1,
  cconTelefonePrincipal: '6133334444',
  cconWhatsapp: '61999994444',
  cconEmail: 'secretaria@matriz.org',
  cconInstagram: '@matriz',
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

/// Contatos por comunidade em memória; incluir, alterar e excluir mexem neles como a API.
class _FakeComunidadeContatoRepository implements ComunidadeContatoRepository {
  _FakeComunidadeContatoRepository(Map<int, List<ComunidadeContatoModel>> porComunidade)
    : porComunidade = {
        for (final e in porComunidade.entries) e.key: [...e.value],
      };

  final Map<int, List<ComunidadeContatoModel>> porComunidade;
  final erros = <int, Exception>{};
  final consultas = <int>[];
  final gravados = <(String, ComunidadeContatoModel)>[];
  final excluidos = <int>[];

  @override
  Future<Result<List<ComunidadeContatoModel>>> contatos(int comuId) async {
    consultas.add(comuId);
    final erro = erros[comuId];
    return erro != null ? Result.error(erro) : Result.ok(List.of(porComunidade[comuId] ?? const []));
  }

  @override
  Future<Result<ComunidadeContatoModel>> incluir(ComunidadeContatoModel contato) async {
    gravados.add(('incluir', contato));
    (porComunidade[contato.comuId] ??= []).add(contato);
    return Result.ok(contato);
  }

  @override
  Future<Result<ComunidadeContatoModel>> alterar(ComunidadeContatoModel contato) async {
    gravados.add(('alterar', contato));
    final lista = porComunidade[contato.comuId]!;
    lista[lista.indexWhere((c) => c.cconId == contato.cconId)] = contato;
    return Result.ok(contato);
  }

  @override
  Future<Result<void>> excluir(int cconId) async {
    excluidos.add(cconId);
    for (final lista in porComunidade.values) {
      lista.removeWhere((c) => c.cconId == cconId);
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
  late _FakeComunidadeContatoRepository repository;
  late List<Uri> abertos;
  late bool abrirAceita;

  setUp(() {
    repository = _FakeComunidadeContatoRepository({
      1: [_secretaria],
    });
    abertos = [];
    abrirAceita = true;
  });

  ComunidadeContatoUseCase criarUseCase([List<ComunidadeModel> comunidades = const [_matriz, _capela]]) =>
      ComunidadeContatoUseCase(
        comunidadeContatoRepository: repository,
        comunidadeUseCase: ComunidadeUseCase(
          comunidadeRepository: _FakeComunidadeRepository(comunidades),
          usuarioLogado: () => 7,
        ),
        abrirUrl: (url) async {
          abertos.add(url);
          return abrirAceita;
        },
      );

  ComunidadeContatoViewmodel criar([List<ComunidadeModel> comunidades = const [_matriz, _capela]]) =>
      ComunidadeContatoViewmodel(comunidadeContatoUseCase: criarUseCase(comunidades));

  Future<void> montar(WidgetTester tester, ComunidadeContatoViewmodel viewModel) async {
    viewModel.abrir();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        home: Scaffold(
          body: ComunidadeContatoView(viewModel: viewModel, onEditar: (_) {}, onExcluir: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ComunidadeContatoModel', () {
    test('fromJson aceita camelCase e snake_case; campo() e comCampos() usam a chave JSON', () {
      final camel = ComunidadeContatoModel.fromJson({
        'cconId': 1,
        'comuId': '2',
        'cconEmail': 'a@b.com',
        'cconYoutube': null,
      });
      expect((camel.cconId, camel.comuId, camel.campo('cconEmail'), camel.cconYoutube), (1, 2, 'a@b.com', null));

      final snake = ComunidadeContatoModel.fromJson({
        'ccon_id': 3,
        'comu_id': 4,
        'ccon_telefone_principal': '6133334444',
        'ccon_telegram': 'matriz',
      });
      expect((snake.cconTelefonePrincipal, snake.cconTelegram), ('6133334444', 'matriz'));

      final novo = ComunidadeContatoModel.comCampos(comuId: 1, campos: {'cconSite': 'matriz.org'});
      expect((novo.cconId, novo.cconSite, novo.cconEmail), (null, 'matriz.org', null));
      expect(ComunidadeContatoModel.chaves, ContatoCampo.values.map((c) => c.chave));
    });

    test('fromJson sem comunidade lança FormatException', () {
      expect(() => ComunidadeContatoModel.fromJson({'cconId': 1}), throwsFormatException);
    });
  });

  group('ComunidadeContatoUseCase', () {
    test('validarCampo: telefone, e-mail e link', () {
      String? v(ContatoCampo campo, String valor) => ComunidadeContatoUseCase.validarCampo(campo, valor);

      expect(v(ContatoCampo.celular, '  '), isNull, reason: 'vazio pode');
      expect(v(ContatoCampo.celular, '(61) 99999-4444'), isNull);
      expect(v(ContatoCampo.whatsapp, '+55 61 99999-4444'), isNull);
      expect(v(ContatoCampo.telefonePrincipal, '1234567'), 'telefoneInvalido', reason: 'menos de 8 dígitos');
      expect(v(ContatoCampo.telefonePrincipal, '1234567890123456'), 'telefoneInvalido', reason: 'mais de 15');
      expect(v(ContatoCampo.telefonePrincipal, '61 3333-abcd'), 'telefoneInvalido');
      expect(v(ContatoCampo.email, 'secretaria@matriz.org'), isNull);
      expect(v(ContatoCampo.email, 'secretaria@matriz'), 'emailInvalido');
      expect(v(ContatoCampo.email, '${'a' * 85}@b.com'), 'emailInvalido', reason: 'mais de 90');
      expect(v(ContatoCampo.instagram, '@matriz'), isNull);
      expect(v(ContatoCampo.site, 'matriz org'), 'linkInvalido');
      expect(v(ContatoCampo.site, 'a' * 129), 'linkInvalido');
    });

    test('validar exige comunidade e pelo menos um campo', () {
      final useCase = criarUseCase();
      expect(useCase.validar(_secretaria), isNull);
      expect(useCase.validar(const ComunidadeContatoModel(comuId: 0, cconSite: 'a.org')), 'comunidadeObrigatoria');
      expect(useCase.validar(const ComunidadeContatoModel(comuId: 1, cconSite: ' ')), 'contatoObrigatorio');
      expect(useCase.validar(const ComunidadeContatoModel(comuId: 1, cconCelular: '123')), 'telefoneInvalido');
    });

    test('salvar grava telefones só com dígitos, textos aparados e brancos nulos; com cconId altera', () async {
      final useCase = criarUseCase();
      final result = await useCase.salvar(
        const ComunidadeContatoModel(
          comuId: 2,
          cconCelular: ' (61) 99999-4444 ',
          cconEmail: ' contato@capela.org ',
          cconSite: '  ',
        ),
      );
      expect(result, isA<Ok<ComunidadeContatoModel>>());
      final (acao, gravado) = repository.gravados.single;
      expect(acao, 'incluir');
      expect((gravado.cconCelular, gravado.cconEmail, gravado.cconSite), ('61999994444', 'contato@capela.org', null));

      await useCase.salvar(_secretaria);
      expect(repository.gravados.last.$1, 'alterar');

      final invalido = await useCase.salvar(const ComunidadeContatoModel(comuId: 1));
      expect((invalido as Error).error, isA<HandledException>());
      expect(repository.gravados, hasLength(2));
    });

    test('404 registroNaoEncontrado vira lista vazia', () async {
      repository.erros[2] = HttpServiceException(message: 'registroNaoEncontrado');
      expect(await criarUseCase().contatos(2), isA<Ok<List<ComunidadeContatoModel>>>());
    });

    test('preenchidos, exibição e uri', () {
      final itens = ComunidadeContatoUseCase.preenchidos(_secretaria);
      expect(itens.map((i) => i.$1), [
        ContatoCampo.telefonePrincipal,
        ContatoCampo.whatsapp,
        ContatoCampo.email,
        ContatoCampo.instagram,
      ]);

      expect(ComunidadeContatoUseCase.exibicao(ContatoCampo.telefonePrincipal, '6133334444'), '(61) 3333-4444');
      expect(ComunidadeContatoUseCase.exibicao(ContatoCampo.celular, '61999994444'), '(61) 99999-4444');
      expect(ComunidadeContatoUseCase.exibicao(ContatoCampo.celular, '12345678'), '12345678');
      expect(ComunidadeContatoUseCase.exibicao(ContatoCampo.site, ' a.org '), 'a.org');

      String? uri(ContatoCampo campo, String valor) => ComunidadeContatoUseCase.uri(campo, valor)?.toString();
      expect(uri(ContatoCampo.telefonePrincipal, '(61) 3333-4444'), 'tel:6133334444');
      expect(uri(ContatoCampo.whatsapp, '61999994444'), 'https://wa.me/5561999994444');
      expect(uri(ContatoCampo.whatsapp, '+1 555 123 4567'), 'https://wa.me/15551234567');
      expect(uri(ContatoCampo.email, 'a@b.com'), 'mailto:a@b.com');
      expect(uri(ContatoCampo.site, 'matriz.org'), 'https://matriz.org');
      expect(uri(ContatoCampo.site, 'http://matriz.org/x'), 'http://matriz.org/x');
      expect(uri(ContatoCampo.instagram, '@matriz'), 'https://instagram.com/matriz');
      expect(uri(ContatoCampo.facebook, 'matriz'), 'https://facebook.com/matriz');
      expect(uri(ContatoCampo.youtube, '@matriz'), 'https://youtube.com/@matriz');
      expect(uri(ContatoCampo.telegram, 'matriz'), 'https://t.me/matriz');
      expect(uri(ContatoCampo.site, ' '), isNull);
    });

    test('abrir usa o link do campo; recusa vira naoFoiPossivelAbrirLink', () async {
      final useCase = criarUseCase();
      expect(await useCase.abrir(ContatoCampo.email, 'a@b.com'), isA<Ok<void>>());
      expect(abertos.single.toString(), 'mailto:a@b.com');

      abrirAceita = false;
      final result = await useCase.abrir(ContatoCampo.site, 'a.org');
      expect(((result as Error).error as HandledException).message, 'naoFoiPossivelAbrirLink');
    });
  });

  group('ComunidadeContatoViewmodel', () {
    test('só carrega ao abrir; selecionar antes de carregar vale no carregamento', () async {
      final viewModel = criar();
      expect(repository.consultas, isEmpty);

      viewModel.selecionar(1);
      viewModel.abrir();
      await pumpEventQueue();
      expect(viewModel.selecionada?.comunidade.comuId, 1);
      expect(viewModel.contatos, [_secretaria]);

      viewModel.abrir();
      await pumpEventQueue();
      expect(repository.consultas, [1], reason: 'não recarrega sem invalidar');

      viewModel.invalidar();
      viewModel.abrir();
      await pumpEventQueue();
      expect(repository.consultas, [1, 1]);
    });

    test('a selecionada inicial é a primeira por nome; trocar carrega os contatos dela', () async {
      final viewModel = criar()..abrir();
      await pumpEventQueue();
      expect(viewModel.selecionada?.comunidade.comuId, 2, reason: 'Capela vem antes de Paróquia');
      expect(viewModel.contatos, isEmpty);

      viewModel.selecionar(1);
      await pumpEventQueue();
      expect(viewModel.contatos, [_secretaria]);
    });

    test('salvar e excluir recarregam os contatos da selecionada', () async {
      final viewModel = criar()..selecionar(1);
      viewModel.abrir();
      await pumpEventQueue();

      await viewModel.salvarCommand.execute(const ComunidadeContatoModel(comuId: 1, cconSite: 'matriz.org'));
      expect(viewModel.contatos, hasLength(2));

      await viewModel.excluirCommand.execute(_secretaria);
      expect(repository.excluidos, [10]);
      expect(viewModel.contatos.single.cconSite, 'matriz.org');
    });
  });

  group('ComunidadeContatoView', () {
    testWidgets('mostra os campos preenchidos formatados; tocar num campo abre o contato', (tester) async {
      final viewModel = criar()..selecionar(1);
      await montar(tester, viewModel);

      expect(find.text('Paróquia Matriz'), findsOneWidget);
      expect(find.text('(61) 3333-4444'), findsOneWidget);
      expect(find.text('(61) 99999-4444'), findsOneWidget);
      expect(find.text('secretaria@matriz.org'), findsOneWidget);
      expect(find.text('@matriz'), findsOneWidget);
      expect(find.text('whatsapp'), findsOneWidget, reason: 'rótulo (chave de tradução)');

      await tester.tap(find.text('(61) 99999-4444'));
      await tester.pumpAndSettle();
      expect(abertos.single.toString(), 'https://wa.me/5561999994444');
    });

    testWidgets('sem contatos mostra a mensagem; sem comunidades também', (tester) async {
      await montar(tester, criar());
      expect(find.text('nenhumContatoCadastrado'), findsOneWidget);

      await montar(tester, criar(const []));
      expect(find.text('nenhumaComunidadeCadastrada'), findsOneWidget);
    });

    testWidgets('erro no primeiro carregamento mostra tentar novamente', (tester) async {
      repository.erros[2] = HandledException(message: 'erroGeralApi');
      await montar(tester, criar());

      expect(find.text('erroGeralApi'), findsOneWidget);
      expect(find.text('tentarNovamente'), findsOneWidget);
    });
  });
}
