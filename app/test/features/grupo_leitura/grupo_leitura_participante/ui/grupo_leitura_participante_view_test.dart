import 'package:app/data/model/leitura/leitura_participante_model.dart';
import 'package:app/data/model/usuario/usuario_resumo_model.dart';
import 'package:app/features/grupo_leitura/grupo_leitura/use_case/grupo_leitura_usecase.dart';
import 'package:app/features/grupo_leitura/grupo_leitura_participante/ui/grupo_leitura_participante_view.dart';
import 'package:app/features/grupo_leitura/grupo_leitura_participante/ui/grupo_leitura_participante_viewmodel.dart';
import 'package:app/features/grupo_leitura/grupo_leitura_participante/use_case/grupo_leitura_participante_usecase.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../grupo_leitura_fakes.dart';

void main() {
  late FakeGrupoLeituraParticipanteRepository repository;

  setUp(() => repository = FakeGrupoLeituraParticipanteRepository());

  GrupoLeituraParticipanteUseCase criarUseCase() => GrupoLeituraParticipanteUseCase(
    grupoLeituraParticipanteRepository: repository,
    grupoLeituraUseCase: criarGrupoLeituraUseCase(),
  );

  test('LeituraParticipanteModel.fromJson lê nome e @usuario; toJson não os envia', () {
    final model = LeituraParticipanteModel.fromJson({
      'lpar_id': 1,
      'leit_id': 2,
      'usua_id': 3,
      'udet_nome': 'Ana',
      'udet_usuario': 'ana',
    });
    expect(model.udetNome, 'Ana');
    expect(model.toJson(), {'lparId': 1, 'leitId': 2, 'usuaId': 3});
  });

  group('GrupoLeituraParticipanteUseCase', () {
    test('busca exige 2 caracteres e tira o dono e quem já participa', () async {
      final useCase = criarUseCase();
      expect((await useCase.buscar(' o ', grupoOutro, const []) as Ok).value, isEmpty);
      expect(repository.buscas, isEmpty, reason: 'um caractere (depois do trim) não chama a API');

      // "ou" acha a Ana (já participa) e o dono do grupo (usuaId 3): os dois ficam de fora.
      final semNinguem = await useCase.buscar('ou', grupoOutro, const [ana]);
      expect(repository.buscas, ['ou']);
      expect((semNinguem as Ok).value, isEmpty);

      final carlaEncontrada = await useCase.buscar('ar', grupoOutro, const [ana]);
      expect((carlaEncontrada as Ok<List<UsuarioResumoModel>>).value.map((u) => u.usuaId), [5]);
    });

    test('só o dono adiciona; o mesmo usuário não entra duas vezes', () async {
      final useCase = criarUseCase();
      final naoDono = await useCase.adicionar(grupoOutro, carla, const []);
      expect(((naoDono as Error).error as HandledException).message, GrupoLeituraUseCase.kSomenteDonoAltera);

      const anaResumo = UsuarioResumoModel(usuaId: 4, udetNome: 'Ana Souza');
      final repetido = await useCase.adicionar(grupoMeu, anaResumo, const [ana]);
      expect(((repetido as Error).error as HandledException).message, 'usuarioJaNoGrupo');

      final ok = await useCase.adicionar(grupoMeu, carla, const [ana]);
      expect((ok as Ok<LeituraParticipanteModel>).value.udetNome, 'Carla Dias');
      expect(repository.incluidos.single.toJson(), {'lparId': null, 'leitId': 1, 'usuaId': 5});
    });

    test('dono remove qualquer um; participante só a si mesmo', () async {
      final useCase = criarUseCase();
      expect(useCase.podeRemover(grupoMeu, ana), isTrue);
      expect(useCase.podeRemover(grupoOutro, eu), isTrue);
      const outro = LeituraParticipanteModel(lparId: 12, leitId: 2, usuaId: 8);
      expect(useCase.podeRemover(grupoOutro, outro), isFalse);

      final negado = await useCase.remover(grupoOutro, outro);
      expect(((negado as Error).error as HandledException).message, GrupoLeituraUseCase.kSomenteDonoAltera);
      expect(await useCase.remover(grupoOutro, eu), isA<Ok>());
      expect(repository.excluidos, [11]);
    });

    test('iniciais e nome de exibição', () {
      expect(GrupoLeituraParticipanteUseCase.iniciais(udetNome: 'Ana Maria Souza'), 'AS');
      expect(GrupoLeituraParticipanteUseCase.iniciais(udetUsuario: 'bia'), 'B');
      expect(GrupoLeituraParticipanteUseCase.nomeExibicao(udetNome: ' ', udetUsuario: 'bia'), 'bia');
      expect(GrupoLeituraParticipanteUseCase.iniciais(), '?');
    });
  });

  test('sair do grupo marca saiuDoGrupo e recarrega os grupos', () async {
    final viewModel = GrupoLeituraParticipanteViewmodel(grupoLeituraParticipanteUseCase: criarUseCase())..selecionar(2);
    viewModel.abrir();
    await pumpEventQueue();
    expect(viewModel.selecionado, grupoOutro);
    expect(viewModel.participantes, [eu]);

    await viewModel.removerCommand.execute(eu);
    expect(viewModel.removerCommand.completed, isTrue);
    expect(viewModel.saiuDoGrupo, isTrue);
    viewModel.confirmarSaida();
    expect(viewModel.saiuDoGrupo, isFalse);
  });

  group('GrupoLeituraParticipanteView', () {
    Future<GrupoLeituraParticipanteViewmodel> pump(WidgetTester tester, {int leitId = 1}) async {
      final viewModel = GrupoLeituraParticipanteViewmodel(grupoLeituraParticipanteUseCase: criarUseCase())
        ..selecionar(leitId)
        ..abrir();
      await pumpTela(tester, GrupoLeituraParticipanteView(viewModel: viewModel, onRemover: (_) {}));
      return viewModel;
    }

    testWidgets('no grupo do usuário lista nome, @usuario e o botão de remover', (tester) async {
      await pump(tester);
      expect(find.text('Plano anual'), findsOneWidget);
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('@ana'), findsOneWidget);
      expect(find.text('AS'), findsOneWidget);
      expect(find.byTooltip('remover'), findsOneWidget);
    });

    testWidgets('no grupo de outro, o próprio usuário aparece como "Você" e pode sair', (tester) async {
      await pump(tester, leitId: 2);
      expect(find.text('Evangelhos'), findsOneWidget);
      expect(find.text('voce'), findsOneWidget);
      expect(find.byTooltip('sairDoGrupo'), findsOneWidget);
      expect(find.byTooltip('remover'), findsNothing);
    });

    testWidgets('grupo sem participantes mostra a mensagem', (tester) async {
      repository = FakeGrupoLeituraParticipanteRepository({1: []});
      await pump(tester);
      expect(find.text('nenhumParticipante'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    });
  });
}
