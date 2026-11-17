import 'package:app/data/model/usuario/usuario_consentimento_model.dart';
import 'package:app/features/lgpd/usuario_consentimento/repository/usuario_consentimento_repository.dart';
import 'package:app/features/lgpd/usuario_consentimento/ui/usuario_consentimento_view.dart';
import 'package:app/features/lgpd/usuario_consentimento/ui/usuario_consentimento_viewmodel.dart';
import 'package:app/features/lgpd/usuario_consentimento/use_case/usuario_consentimento_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service/service.dart';

/// Consentimentos em memória, com as regras da API: versão atual "1" de cada finalidade; aceite grava um registro;
/// revogar marca os vigentes e dá 404 se não houver.
class _FakeUsuarioConsentimentoRepository implements UsuarioConsentimentoRepository {
  static const versoes = {'dadosReligiosos': '1', 'termosUso': '1', 'politicaPrivacidade': '1'};

  final historico = <UsuarioConsentimentoModel>[];
  final aceites = <String>[];
  final revogacoes = <String>[];
  Exception? erroListar;
  Exception? erroAceitar;

  /// Finalidade cujo aceite falha (para o "aceitar todos" parar no meio).
  String? falharEm;

  void aceitarDireto(String finalidade) => historico.add(
    UsuarioConsentimentoModel(
      ucnsId: historico.length + 1,
      ucnsFinalidade: finalidade,
      ucnsVersao: versoes[finalidade]!,
      createdAt: DateTime(2026, 11, 16, 10, 0),
    ),
  );

  @override
  Future<Result<UsuarioConsentimentoListaModel>> listar() async {
    final e = erroListar;
    if (e != null) return Result.error(e);
    return Result.ok(
      UsuarioConsentimentoListaModel(
        termos: [
          for (final MapEntry(key: finalidade, value: versao) in versoes.entries)
            UsuarioConsentimentoTermoModel(
              finalidade: finalidade,
              versao: versao,
              aceito: historico.any((c) => c.ucnsFinalidade == finalidade && c.ucnsVersao == versao && !c.revogado),
            ),
        ],
        historico: List.of(historico),
      ),
    );
  }

  @override
  Future<Result<UsuarioConsentimentoModel>> aceitar(UsuarioConsentimentoBodyModel body) async {
    aceites.add(body.ucnsFinalidade);
    final e = erroAceitar;
    if (e != null || body.ucnsFinalidade == falharEm) {
      return Result.error(e ?? HttpServiceException(message: 'erroGeralApi', code: 500));
    }
    if (versoes[body.ucnsFinalidade] != body.ucnsVersao) {
      return Result.error(HttpServiceException(message: 'dadosInvalidos', code: 400));
    }
    aceitarDireto(body.ucnsFinalidade);
    return Result.ok(historico.last);
  }

  @override
  Future<Result<int>> revogar(String finalidade) async {
    revogacoes.add(finalidade);
    var revogados = 0;
    for (final (i, c) in historico.indexed) {
      if (c.ucnsFinalidade == finalidade && !c.revogado) {
        historico[i] = UsuarioConsentimentoModel(
          ucnsId: c.ucnsId,
          ucnsFinalidade: c.ucnsFinalidade,
          ucnsVersao: c.ucnsVersao,
          createdAt: c.createdAt,
          ucnsRevogadoEm: DateTime(2026, 11, 17, 9, 30),
        );
        revogados++;
      }
    }
    if (revogados == 0) return Result.error(HttpServiceException(message: 'registroNaoEncontrado', code: 404));
    return Result.ok(revogados);
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
  late _FakeUsuarioConsentimentoRepository repository;

  setUp(() => repository = _FakeUsuarioConsentimentoRepository());

  UsuarioConsentimentoUseCase criarUseCase() => UsuarioConsentimentoUseCase(usuarioConsentimentoRepository: repository);

  UsuarioConsentimentoViewmodel criar() => UsuarioConsentimentoViewmodel(usuarioConsentimentoUseCase: criarUseCase());

  Future<void> montar(WidgetTester tester, UsuarioConsentimentoViewmodel viewModel) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        home: UsuarioConsentimentoView(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('UsuarioConsentimentoListaModel', () {
    test('fromJson lê termos e histórico (camelCase e snake_case); datas em hora local', () {
      final lista = UsuarioConsentimentoListaModel.fromJson({
        'termos': [
          {'finalidade': 'dadosReligiosos', 'versao': '1', 'aceito': true},
          {'finalidade': 'termosUso', 'versao': 1},
        ],
        'historico': [
          {
            'ucnsId': 3,
            'usuaId': 1,
            'ucnsFinalidade': 'dadosReligiosos',
            'ucnsVersao': '1',
            'ucnsIp': '189.10.20.30',
            'ucnsRevogadoEm': null,
            'createdAt': '2026-11-16T10:00:00.000Z',
          },
          {
            'ucns_id': '2',
            'ucns_finalidade': 'termosUso',
            'ucns_versao': '1',
            'ucns_revogado_em': '2026-11-17T09:30:00Z',
          },
        ],
      });
      expect(lista.termos.map((t) => (t.finalidade, t.versao, t.aceito)), [
        ('dadosReligiosos', '1', true),
        ('termosUso', '1', false),
      ]);
      expect(lista.historico.first.createdAt, DateTime.utc(2026, 11, 16, 10).toLocal());
      expect(
        (lista.historico.first.revogado, lista.historico.last.ucnsId, lista.historico.last.revogado),
        (false, 2, true),
      );
    });

    test('formato inválido lança FormatException; corpo do POST', () {
      expect(() => UsuarioConsentimentoListaModel.fromJson({'termos': 'x'}), throwsFormatException);
      expect(
        () => UsuarioConsentimentoTermoModel.fromJson({'finalidade': 'termosUso', 'versao': '1', 'aceito': 'sim'}),
        throwsFormatException,
      );
      expect(const UsuarioConsentimentoBodyModel(ucnsFinalidade: 'termosUso', ucnsVersao: '1').toJson(), {
        'ucnsFinalidade': 'termosUso',
        'ucnsVersao': '1',
      });
    });
  });

  group('UsuarioConsentimentoUseCase', () {
    test('ordena termos pela finalidade (desconhecida no fim) e histórico do mais recente', () {
      final lista = UsuarioConsentimentoUseCase.ordenar(
        UsuarioConsentimentoListaModel(
          termos: const [
            UsuarioConsentimentoTermoModel(finalidade: 'outra', versao: '1'),
            UsuarioConsentimentoTermoModel(finalidade: 'dadosReligiosos', versao: '1'),
            UsuarioConsentimentoTermoModel(finalidade: 'termosUso', versao: '1'),
            UsuarioConsentimentoTermoModel(finalidade: 'politicaPrivacidade', versao: '1'),
          ],
          historico: const [
            UsuarioConsentimentoModel(ucnsId: 1, ucnsFinalidade: 'termosUso', ucnsVersao: '1'),
            UsuarioConsentimentoModel(ucnsId: 5, ucnsFinalidade: 'termosUso', ucnsVersao: '1'),
          ],
        ),
      );
      expect(lista.termos.map((t) => t.finalidade), ['termosUso', 'politicaPrivacidade', 'dadosReligiosos', 'outra']);
      expect(lista.historico.map((c) => c.ucnsId), [5, 1]);
      expect(UsuarioConsentimentoUseCase.titulo('outra'), 'outra');
      expect(UsuarioConsentimentoUseCase.descricao('outra'), isNull);
      expect(UsuarioConsentimentoUseCase.icone('outra'), UsuarioConsentimentoUseCase.kIconePadrao);
      expect(UsuarioConsentimentoUseCase.avisoRevogacao('dadosReligiosos'), 'revogarDadosReligiososAviso');
      expect(UsuarioConsentimentoUseCase.avisoRevogacao('termosUso'), isNull);
    });

    test('aceitar grava a versão atual e recarrega; termo já aceito não chama a API', () async {
      final useCase = criarUseCase();
      const termo = UsuarioConsentimentoTermoModel(finalidade: 'termosUso', versao: '1');
      final lista = (await useCase.aceitar(termo) as Ok<UsuarioConsentimentoListaModel>).value;
      expect(lista.termos.firstWhere((t) => t.finalidade == 'termosUso').aceito, isTrue);
      expect(lista.historico, hasLength(1));

      await useCase.aceitar(const UsuarioConsentimentoTermoModel(finalidade: 'termosUso', versao: '1', aceito: true));
      expect(repository.aceites, ['termosUso']);

      final invalido = await useCase.aceitar(const UsuarioConsentimentoTermoModel(finalidade: 'termosUso', versao: ''));
      expect(UsuarioConsentimentoUseCase.mensagemErro((invalido as Error).error), 'dadosInvalidos');
    });

    test('aceitarPendentes aceita só os pendentes, em ordem; para no primeiro erro', () async {
      repository.aceitarDireto('termosUso');
      final useCase = criarUseCase();
      final termos = (await useCase.carregar() as Ok<UsuarioConsentimentoListaModel>).value.termos;
      expect(UsuarioConsentimentoUseCase.pendentes(termos).map((t) => t.finalidade), [
        'politicaPrivacidade',
        'dadosReligiosos',
      ]);

      repository.falharEm = 'dadosReligiosos';
      expect(await useCase.aceitarPendentes(termos), isA<Error>());
      expect(repository.aceites, ['politicaPrivacidade', 'dadosReligiosos']);

      repository.falharEm = null;
      final lista = (await useCase.aceitarPendentes(termos) as Ok<UsuarioConsentimentoListaModel>).value;
      expect(UsuarioConsentimentoUseCase.todosAceitos(lista.termos), isTrue);
    });

    test('revogar recarrega; 404 (nada vigente) conta como revogado; aceite vigente traz a data', () async {
      repository.aceitarDireto('dadosReligiosos');
      final useCase = criarUseCase();
      final antes = (await useCase.carregar() as Ok<UsuarioConsentimentoListaModel>).value;
      final termo = antes.termos.firstWhere((t) => t.finalidade == 'dadosReligiosos');
      expect(UsuarioConsentimentoUseCase.aceite(termo, antes.historico)?.ucnsId, 1);

      final depois = (await useCase.revogar(termo) as Ok<UsuarioConsentimentoListaModel>).value;
      final revogado = depois.termos.firstWhere((t) => t.finalidade == 'dadosReligiosos');
      expect(revogado.aceito, isFalse);
      expect(UsuarioConsentimentoUseCase.aceite(revogado, depois.historico), isNull);

      expect(await useCase.revogar(termo), isA<Ok<UsuarioConsentimentoListaModel>>(), reason: '404 vira sucesso');
      expect(UsuarioConsentimentoUseCase.data(DateTime(2026, 11, 16, 10, 0)), '16/11/2026 10:00');
    });
  });

  group('UsuarioConsentimentoViewmodel', () {
    test('carrega ao criar; erro de gravação recarrega a lista (aceite parcial)', () async {
      final viewModel = criar();
      await pumpEventQueue();
      expect(viewModel.pendentes, hasLength(3));
      expect(viewModel.todosAceitos, isFalse);

      repository.falharEm = 'dadosReligiosos';
      await viewModel.aceitarTodosCommand.execute();
      expect(viewModel.aceitarTodosCommand.error, isTrue);
      expect(viewModel.pendentes.map((t) => t.finalidade), ['dadosReligiosos'], reason: 'recarregou');

      repository.falharEm = null;
      await viewModel.aceitarCommand.execute(viewModel.pendentes.single);
      expect(viewModel.todosAceitos, isTrue);
    });
  });

  group('UsuarioConsentimentoView', () {
    testWidgets('mostra os termos pendentes; aceitar um termo grava e avisa', (tester) async {
      await montar(tester, criar());

      expect(find.text('privacidadeConsentimentos'), findsOneWidget);
      expect(find.text('consentimentoIntro'), findsOneWidget);
      expect(find.text('consentimentoTermosUso'), findsOneWidget);
      expect(find.text('consentimentoPoliticaPrivacidade'), findsOneWidget);
      expect(find.text('consentimentoDadosReligiosos'), findsOneWidget);
      expect(find.text('consentimentoPendente'), findsNWidgets(3));
      expect(find.text('aceitarTodos'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'aceitar').first);
      await tester.pumpAndSettle();
      expect(repository.aceites, ['termosUso']);
      expect(find.widgetWithText(SnackBar, 'consentimentoRegistrado'), findsOneWidget);
      expect(find.text('consentimentoAceito'), findsOneWidget);
      expect(find.text('versaoTermo: 1 · aceitoEm: 16/11/2026 10:00'), findsOneWidget);
    });

    testWidgets('"aceitar todos" aceita os pendentes e some; aviso de em dia', (tester) async {
      await montar(tester, criar());
      await tester.tap(find.text('aceitarTodos'));
      await tester.pumpAndSettle();

      expect(repository.aceites, ['termosUso', 'politicaPrivacidade', 'dadosReligiosos']);
      expect(find.text('consentimentosEmDia'), findsOneWidget);
      expect(find.text('consentimentoPendente'), findsNothing);
      expect(find.text('aceitarTodos'), findsNothing);
    });

    testWidgets('revogar pede confirmação (com aviso de dados religiosos) e grava', (tester) async {
      repository.aceitarDireto('dadosReligiosos');
      await montar(tester, criar());

      await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'revogar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'revogar'));
      await tester.pumpAndSettle();
      expect(find.text('revogarConsentimento'), findsOneWidget);
      expect(find.textContaining('revogarDadosReligiososAviso'), findsOneWidget);

      // o botão do aviso mostra o texto em maiúsculas
      await tester.tap(find.text('REVOGAR'));
      await tester.pumpAndSettle();
      expect(repository.revogacoes, ['dadosReligiosos']);
      expect(find.widgetWithText(SnackBar, 'consentimentoRevogado'), findsOneWidget);
      expect(find.text('consentimentoAceito'), findsNothing);
    });

    testWidgets('histórico lista aceites e revogações', (tester) async {
      repository.aceitarDireto('termosUso');
      await repository.revogar('termosUso');
      repository.aceitarDireto('termosUso');
      await montar(tester, criar());

      final lista = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('historicoConsentimentos'), 200, scrollable: lista);
      await tester.pumpAndSettle();
      await tester.tap(find.text('historicoConsentimentos'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.textContaining('revogadoEm'), 200, scrollable: lista);
      await tester.pumpAndSettle();
      expect(find.text('consentimentoTermosUso · versaoTermo 1'), findsNWidgets(2));
      expect(find.text('aceitoEm: 16/11/2026 10:00\nrevogadoEm: 17/11/2026 09:30'), findsOneWidget);
    });

    testWidgets('erro no primeiro carregamento: tentar novamente; erro ao gravar: SnackBar', (tester) async {
      repository.erroListar = HttpServiceException(message: 'erroGeralApi', code: 500);
      await montar(tester, criar());
      expect(find.text('erroGeralApi'), findsOneWidget);

      repository.erroListar = null;
      await tester.tap(find.text('tentarNovamente'));
      await tester.pumpAndSettle();
      expect(find.text('consentimentoTermosUso'), findsOneWidget);

      repository.erroAceitar = HttpServiceException(message: 'dadosInvalidos', code: 400);
      await tester.tap(find.widgetWithText(FilledButton, 'aceitar').first);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(SnackBar, 'dadosInvalidos'), findsOneWidget);
      expect(find.text('consentimentoPendente'), findsNWidgets(3));
    });
  });
}
