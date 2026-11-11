import 'package:app/data/model/menu/menu_model.dart';
import 'package:app/features/dashboard/repository/dashboard_repository.dart';
import 'package:app/features/dashboard/ui/dashboard_viewmodel.dart';
import 'package:app/features/dashboard/ui/widgets/nao_lidas_badge.dart';
import 'package:app/features/dashboard/use_case/dashboard_usecase.dart';
import 'package:app/routing/routes.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Devolve os resultados de não lidas em ordem (o último se repete); o menu é sempre vazio.
class _FakeDashboardRepository implements DashboardRepository {
  _FakeDashboardRepository(this.naoLidas);

  final List<Result<int>> naoLidas;
  int chamadas = 0;

  @override
  Future<Result<MenuModel>> menu() async => Result.ok(MenuModel(menu: const []));

  @override
  Future<Result<int>> mensagensNaoLidas() async {
    final i = chamadas < naoLidas.length ? chamadas : naoLidas.length - 1;
    chamadas++;
    return naoLidas[i];
  }
}

Menu _menu(int id, {String? rota, List<Menu>? children}) => Menu(
  menuId: id,
  menuNome: 'm$id',
  menuChave: 'm$id',
  menuIcone: 'x',
  menuSequencia: id,
  menuRota: rota,
  children: children,
);

void main() {
  group('DashboardUseCase', () {
    test('contemMensagens: o próprio menu ou um filho em qualquer nível leva a /mensagem-lista', () {
      expect(DashboardUseCase.contemMensagens(_menu(1, rota: Routes.mensagemLista)), isTrue);
      final neto = _menu(3, rota: Routes.mensagemLista);
      expect(
        DashboardUseCase.contemMensagens(
          _menu(
            1,
            children: [
              _menu(2, children: [neto]),
            ],
          ),
        ),
        isTrue,
      );
      expect(DashboardUseCase.contemMensagens(_menu(1, rota: '/outra', children: [_menu(2)])), isFalse);
      expect(DashboardUseCase.contemMensagens(_menu(1)), isFalse);
    });

    test('rotuloBadge: sem badge com 0, número até 99 e "99+" acima', () {
      expect(DashboardUseCase.rotuloBadge(0), isNull);
      expect(DashboardUseCase.rotuloBadge(-1), isNull);
      expect(DashboardUseCase.rotuloBadge(1), '1');
      expect(DashboardUseCase.rotuloBadge(99), '99');
      expect(DashboardUseCase.rotuloBadge(100), '99+');
    });

    test('mensagensNaoLidas: total negativo vira 0; erro passa adiante', () async {
      final negativo = DashboardUseCase(dashboardRepository: _FakeDashboardRepository([const Result.ok(-2)]));
      expect((await negativo.mensagensNaoLidas() as Ok<int>).value, 0);

      final erro = DashboardUseCase(
        dashboardRepository: _FakeDashboardRepository([Result.error(HandledException(message: 'erroApi'))]),
      );
      expect(await erro.mensagensNaoLidas(), isA<Error<int>>());
    });
  });

  group('DashboardViewmodel', () {
    test('carrega as não lidas no construtor e recarrega ao executar o command', () async {
      final repository = _FakeDashboardRepository([const Result.ok(3), const Result.ok(1)]);
      final viewModel = DashboardViewmodel(dashboardUseCase: DashboardUseCase(dashboardRepository: repository));
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.mensagensNaoLidas, 3);
      expect(viewModel.rotuloBadge, '3');

      await viewModel.naoLidasCommand.execute();
      expect(viewModel.mensagensNaoLidas, 1);
      expect(repository.chamadas, 2);
    });

    test('erro ao recarregar mantém o último valor', () async {
      final repository = _FakeDashboardRepository([
        const Result.ok(5),
        Result.error(HandledException(message: 'erroApi')),
      ]);
      final viewModel = DashboardViewmodel(dashboardUseCase: DashboardUseCase(dashboardRepository: repository));
      await Future<void>.delayed(Duration.zero);

      await viewModel.naoLidasCommand.execute();
      expect(viewModel.naoLidasCommand.error, isTrue);
      expect(viewModel.mensagensNaoLidas, 5);
    });

    test('sem não lidas não há badge', () async {
      final viewModel = DashboardViewmodel(
        dashboardUseCase: DashboardUseCase(dashboardRepository: _FakeDashboardRepository([const Result.ok(0)])),
      );
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.rotuloBadge, isNull);
    });
  });

  group('NaoLidasBadge', () {
    Future<void> montar(WidgetTester tester, String? rotulo) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NaoLidasBadge(rotulo: rotulo, child: const Icon(Icons.mail)),
        ),
      ),
    );

    testWidgets('mostra o total sobre o ícone', (tester) async {
      await montar(tester, '3');
      expect(find.byType(Badge), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.mail), findsOneWidget);
    });

    testWidgets('sem rótulo mostra só o ícone', (tester) async {
      await montar(tester, null);
      expect(find.byType(Badge), findsNothing);
      expect(find.byIcon(Icons.mail), findsOneWidget);
    });
  });
}
