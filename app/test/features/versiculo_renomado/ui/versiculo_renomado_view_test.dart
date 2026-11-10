import 'package:app/config/versao_preferencia.dart';
import 'package:app/data/model/biblia/renomado_model.dart';
import 'package:app/data/model/biblia/versao_model.dart';
import 'package:app/data/model/biblia/versiculo_renomado_model.dart';
import 'package:app/features/biblia/biblia_leitura/repository/biblia_leitura_repository.dart';
import 'package:app/features/biblia/biblia_leitura/use_case/biblia_leitura_usecase.dart';
import 'package:app/features/biblia/versiculo_renomado/repository/versiculo_renomado_repository.dart';
import 'package:app/features/biblia/versiculo_renomado/ui/versiculo_renomado_view.dart';
import 'package:app/features/biblia/versiculo_renomado/ui/versiculo_renomado_viewmodel.dart';
import 'package:app/features/biblia/versiculo_renomado/use_case/versiculo_renomado_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/routing/routes.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:service/service.dart';

const _arc = VersaoModel(versaId: 1, versaCodigo: 'ARC', versaNome: 'Almeida Revista e Corrigida');
const _nvi = VersaoModel(versaId: 2, versaCodigo: 'NVI', versaNome: 'Nova Versão Internacional');

const _agostinho = RenomadoModel(renoId: 5, renoNome: 'Santo Agostinho', renoTexto: 'Bispo de Hipona');

VersiculoRenomadoModel _versiculo(
  int vrenId, {
  int? seq,
  int livrId = 43,
  String livrNome = 'João',
  int capiNumero = 3,
  int versNumero = 16,
  int versaId = 1,
}) => VersiculoRenomadoModel(
  vrenId: vrenId,
  renoId: _agostinho.renoId,
  vrenSeq: seq,
  livrId: livrId,
  livrNome: livrNome,
  capiNumero: capiNumero,
  versId: versaId * 100000 + livrId * 1000 + capiNumero * 100 + versNumero,
  versNumero: versNumero,
  versTexto: '$livrNome $capiNumero:$versNumero na versão $versaId',
  versaId: versaId,
);

/// Versículos por versão; registra as chamadas (renoId, versaId). [erros] substitui a resposta de uma versão.
class _FakeVersiculoRenomadoRepository implements VersiculoRenomadoRepository {
  _FakeVersiculoRenomadoRepository(this.porVersao);

  final Map<int, List<VersiculoRenomadoModel>> porVersao;
  final erros = <int, Exception>{};
  final chamadas = <(int, int)>[];

  @override
  Future<Result<List<VersiculoRenomadoModel>>> versiculos(int renoId, int versaId) async {
    chamadas.add((renoId, versaId));
    final erro = erros[versaId];
    return erro != null ? Result.error(erro) : Result.ok(porVersao[versaId] ?? const []);
  }
}

/// Só as versões são usadas por esta tela; os demais métodos da leitura não são chamados.
class _FakeBibliaLeituraRepository implements BibliaLeituraRepository {
  @override
  Future<Result<List<VersaoModel>>> versoes() async => const Result.ok([_arc, _nvi]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeVersaoPreferencia implements VersaoPreferencia {
  @override
  int? versaoId;

  @override
  void setVersaoId(int versaId) => versaoId = versaId;
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
  late _FakeVersiculoRenomadoRepository repository;
  late _FakeVersaoPreferencia preferencia;

  setUp(() {
    repository = _FakeVersiculoRenomadoRepository({
      _arc.versaId: [
        _versiculo(1, versaId: 1),
        _versiculo(2, seq: 1, livrId: 19, livrNome: 'Salmos', capiNumero: 23, versNumero: 1, versaId: 1),
      ],
      _nvi.versaId: [_versiculo(1, versaId: 2)],
    });
    preferencia = _FakeVersaoPreferencia();
  });

  VersiculoRenomadoUseCase criarUseCase() => VersiculoRenomadoUseCase(
    versiculoRenomadoRepository: repository,
    bibliaLeituraUseCase: BibliaLeituraUseCase(
      bibliaLeituraRepository: _FakeBibliaLeituraRepository(),
      versaoPreferencia: preferencia,
    ),
  );

  VersiculoRenomadoViewmodel criar({RenomadoModel? renomado = _agostinho}) => VersiculoRenomadoViewmodel(
    versiculoRenomadoUseCase: criarUseCase(),
    renoId: _agostinho.renoId,
    renomado: renomado,
  );

  group('VersiculoRenomadoUseCase', () {
    test('ordena por sequência (sem sequência por último), livro, capítulo e número', () {
      final ordenados = VersiculoRenomadoUseCase.ordenar([
        _versiculo(1, livrId: 43, capiNumero: 3, versNumero: 17),
        _versiculo(2, livrId: 1, capiNumero: 1, versNumero: 1),
        _versiculo(3, seq: 2),
        _versiculo(4, seq: 1, livrId: 66),
        _versiculo(5, livrId: 43, capiNumero: 3, versNumero: 16),
      ]);
      expect(ordenados.map((v) => v.vrenId), [4, 3, 2, 5, 1]);
    });

    test('404 registroNaoEncontrado vira lista vazia e outros erros são repassados', () async {
      repository.erros[1] = HttpServiceException(message: 'registroNaoEncontrado', code: 404);
      final erro = HttpServiceException(message: 'erroGeralApi', code: 500);
      repository.erros[2] = erro;

      expect((await criarUseCase().versiculos(5, 1) as Ok<List<VersiculoRenomadoModel>>).value, isEmpty);
      expect((await criarUseCase().versiculos(5, 2) as Error).error, same(erro));
    });

    test('o destino abre a leitura no versículo, na versão em que ele foi carregado', () {
      final destino = criarUseCase().destino(_versiculo(1, versaId: 2));
      expect(destino.toQuery(), {'versaId': '2', 'livrId': '43', 'capiNumero': '3', 'versNumero': '16'});
    });
  });

  group('VersiculoRenomadoViewmodel', () {
    test('carrega os versículos na versão salva pelo usuário', () async {
      preferencia.versaoId = _nvi.versaId;
      final viewModel = criar();
      await pumpEventQueue();

      expect(viewModel.versao?.versaId, _nvi.versaId);
      expect(repository.chamadas, [(_agostinho.renoId, _nvi.versaId)]);
      expect(viewModel.versiculos?.single.versaId, _nvi.versaId);
    });

    test('sem versão salva usa a primeira', () async {
      final viewModel = criar();
      await pumpEventQueue();

      expect(viewModel.versao?.versaId, _arc.versaId);
      expect(viewModel.versiculos?.map((v) => v.vrenId), [2, 1]);
    });

    test('trocar a versão recarrega os versículos e salva a preferência', () async {
      final viewModel = criar();
      await pumpEventQueue();
      await viewModel.versaoCommand.execute(_nvi);

      expect(viewModel.versao?.versaId, _nvi.versaId);
      expect(viewModel.versiculos?.single.versaId, _nvi.versaId);
      expect(preferencia.versaoId, _nvi.versaId);
    });

    test('falha ao trocar a versão mantém a versão e a lista anteriores', () async {
      repository.erros[2] = HttpServiceException(message: 'erroGeralApi', code: 500);
      final viewModel = criar();
      await pumpEventQueue();
      await viewModel.versaoCommand.execute(_nvi);

      expect(viewModel.versaoCommand.error, isTrue);
      expect(viewModel.versao?.versaId, _arc.versaId);
      expect(viewModel.versiculos, hasLength(2));
      expect(preferencia.versaoId, isNull);
    });
  });

  group('VersiculoRenomadoView', () {
    /// Monta a tela num GoRouter com a rota da leitura, que mostra a URI recebida.
    Future<void> montar(WidgetTester tester, VersiculoRenomadoViewmodel viewModel) async {
      final router = GoRouter(
        initialLocation: '/teste',
        routes: [
          GoRoute(
            path: '/teste',
            builder: (_, _) => VersiculoRenomadoView(viewModel: viewModel),
          ),
          GoRoute(
            path: Routes.bibliaLeitura,
            builder: (_, state) => Scaffold(body: Text('leitura ${state.uri.query}')),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('mostra o renomado, a versão e os versículos com referência e texto', (tester) async {
      await montar(tester, criar());

      expect(find.text('Santo Agostinho'), findsOneWidget);
      expect(find.text('Bispo de Hipona'), findsOneWidget);
      expect(find.text('ARC · Almeida Revista e Corrigida'), findsOneWidget);
      expect(find.text('Salmos 23:1'), findsOneWidget);
      expect(find.text('João 3:16 na versão 1'), findsOneWidget);
    });

    testWidgets('sem o renomado no extra usa o título padrão', (tester) async {
      await montar(tester, criar(renomado: null));
      expect(find.text('versiculosRenomado'), findsOneWidget);
    });

    testWidgets('sem versículos mostra nenhumVersiculoRenomado', (tester) async {
      repository.porVersao.clear();
      await montar(tester, criar());
      expect(find.text('nenhumVersiculoRenomado'), findsOneWidget);
    });

    testWidgets('tocar no versículo abre a leitura nele, na versão escolhida', (tester) async {
      await montar(tester, criar());

      await tester.tap(find.text('João 3:16'));
      await tester.pumpAndSettle();

      expect(find.text('leitura versaId=1&livrId=43&capiNumero=3&versNumero=16'), findsOneWidget);
    });

    testWidgets('falha no carregamento mostra a mensagem e tenta novamente', (tester) async {
      repository.erros[1] = HttpServiceException(message: 'erroGeralApi', code: 500);
      await montar(tester, criar());
      expect(find.text('erroGeralApi'), findsOneWidget);

      repository.erros.clear();
      await tester.tap(find.text('tentarNovamente'));
      await tester.pumpAndSettle();
      expect(find.text('Salmos 23:1'), findsOneWidget);
    });
  });
}
