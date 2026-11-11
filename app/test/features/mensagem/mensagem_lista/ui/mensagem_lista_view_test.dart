import 'package:app/data/model/mensagem/mensagem_recebida_model.dart';
import 'package:app/features/mensagem/mensagem_envio/ui/mensagem_envio_viewmodel.dart';
import 'package:app/features/mensagem/mensagem_envio/use_case/mensagem_envio_usecase.dart';
import 'package:app/features/mensagem/mensagem_lista/repository/mensagem_lista_repository.dart';
import 'package:app/features/mensagem/mensagem_lista/ui/mensagem_lista_view.dart';
import 'package:app/features/mensagem/mensagem_lista/ui/mensagem_lista_viewmodel.dart';
import 'package:app/features/mensagem/mensagem_lista/use_case/mensagem_lista_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service/service.dart';

import '../../mensagem_envio/ui/mensagem_envio_view_test.dart' show FakeMensagemEnvioRepository;

final _aviso = MensagemRecebidaModel(
  musuId: 1,
  mensId: 1,
  recebidaEm: DateTime(2026, 11, 11, 12, 10),
  mtipId: 0,
  mtipTipo: 'Sistema',
  mensTitulo: 'moreto indicou Efésios 3:20 para você',
  mensTexto: 'moreto indicou um versículo.\n\nO que foi indicado:\nEfésios 3:20',
  remetenteId: 2,
  remetenteNome: 'MSN',
  remetenteUsuario: 'msn',
);

final _ana = MensagemRecebidaModel(
  musuId: 2,
  mensId: 2,
  musuLida: true,
  musuLidaEm: DateTime(2026, 11, 10, 9, 0),
  musuRespondida: true,
  musuResposta: 'Obrigado!',
  recebidaEm: DateTime(2026, 11, 10, 8, 30),
  mtipId: 1,
  mensTitulo: 'Encontro de oração',
  mensTexto: 'Sábado às 19h',
  remetenteNome: 'Ana Souza',
  remetenteUsuario: 'ana',
);

final _antiga = MensagemRecebidaModel(
  musuId: 3,
  mensId: 3,
  musuLida: true,
  musuArquivada: true,
  recebidaEm: DateTime(2026, 10, 1),
  mtipId: 1,
  mensTitulo: 'Aviso antigo',
  mensTexto: 'texto',
  remetenteUsuario: 'bruno',
);

/// Mensagens em memória; o PUT devolve só a situação, como a API.
class _FakeMensagemListaRepository implements MensagemListaRepository {
  List<MensagemRecebidaModel> lista = [_antiga, _aviso, _ana];
  final atualizacoes = <(int, bool?, bool?)>[];
  Exception? erroLista;
  Exception? erroAtualizar;

  @override
  Future<Result<List<MensagemRecebidaModel>>> recebidas() async {
    final e = erroLista;
    return e != null ? Result.error(e) : Result.ok(List.of(lista));
  }

  @override
  Future<Result<Map<String, dynamic>>> atualizar({required int musuId, bool? lida, bool? arquivada}) async {
    atualizacoes.add((musuId, lida, arquivada));
    final e = erroAtualizar;
    if (e != null) return Result.error(e);
    final atual = lista.firstWhere((m) => m.musuId == musuId);
    final novaLida = lida ?? atual.musuLida;
    final situacao = <String, dynamic>{
      'musuId': musuId,
      'musuLida': novaLida,
      'musuLidaEm': novaLida ? '2026-11-11T15:00:00.000Z' : null,
      'musuArquivada': arquivada ?? atual.musuArquivada,
      'musuRespondida': atual.musuRespondida,
    };
    lista = [for (final m in lista) m.musuId == musuId ? m.comSituacao(situacao) : m];
    return Result.ok(situacao);
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
  late _FakeMensagemListaRepository repository;

  setUp(() => repository = _FakeMensagemListaRepository());

  MensagemListaUseCase criarUseCase() => MensagemListaUseCase(mensagemListaRepository: repository);

  MensagemListaViewmodel criar() => MensagemListaViewmodel(mensagemListaUseCase: criarUseCase());

  Future<void> montar(WidgetTester tester, MensagemListaViewmodel viewModel) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        home: MensagemListaView(
          viewModel: viewModel,
          envioViewModel: MensagemEnvioViewmodel(
            mensagemEnvioUseCase: MensagemEnvioUseCase(mensagemEnvioRepository: FakeMensagemEnvioRepository()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Toca no filtro [rotulo]; a linha de filtros rola, então ele pode estar fora da tela.
  Future<void> filtrar(WidgetTester tester, String rotulo) async {
    final chip = find.text(rotulo);
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }

  group('MensagemRecebidaModel', () {
    test('fromJson aceita camelCase e snake_case; booleanos ausentes são false', () {
      final camel = MensagemRecebidaModel.fromJson({
        'musuId': 1,
        'mensId': '2',
        'musuLida': true,
        'recebidaEm': '2026-11-11T15:10:34.671Z',
        'mtipId': 0,
        'mtipTipo': 'Sistema',
        'mensTitulo': 'T',
        'mensTexto': 'X',
      });
      expect((camel.mensId, camel.musuLida, camel.musuArquivada, camel.sistema), (2, true, false, true));
      expect(camel.recebidaEm, DateTime.utc(2026, 11, 11, 15, 10, 34, 671).toLocal());

      final snake = MensagemRecebidaModel.fromJson({
        'musu_id': 1,
        'mens_id': 1,
        'musu_arquivada': true,
        'mtip_id': 1,
        'mens_titulo': 'T',
        'mens_texto': 'X',
        'remetente_nome': 'Ana',
      });
      expect((snake.musuArquivada, snake.remetenteNome, snake.sistema), (true, 'Ana', false));
    });

    test('booleano fora do formato lança FormatException; comSituacao mantém o resto', () {
      expect(
        () => MensagemRecebidaModel.fromJson({
          'musuId': 1,
          'mensId': 1,
          'musuLida': 'sim',
          'mtipId': 1,
          'mensTitulo': 'T',
          'mensTexto': 'X',
        }),
        throwsFormatException,
      );
      final arquivada = _ana.comSituacao({'musuArquivada': true});
      expect((arquivada.musuArquivada, arquivada.musuLida, arquivada.mensTitulo), (true, true, 'Encontro de oração'));
    });
  });

  group('MensagemListaUseCase', () {
    test('mais recentes primeiro; 404 vira lista vazia', () async {
      final useCase = criarUseCase();
      final lista = (await useCase.recebidas() as Ok<List<MensagemRecebidaModel>>).value;
      expect(lista.map((m) => m.musuId), [1, 2, 3]);

      repository.erroLista = HttpServiceException(message: 'registroNaoEncontrado');
      expect((await useCase.recebidas() as Ok<List<MensagemRecebidaModel>>).value, isEmpty);
    });

    test('filtros e contagem de não lidas', () {
      final lista = [_aviso, _ana, _antiga];
      expect(MensagemListaUseCase.filtrar(lista, MensagemFiltro.entrada).map((m) => m.musuId), [1, 2]);
      expect(MensagemListaUseCase.filtrar(lista, MensagemFiltro.naoLidas).map((m) => m.musuId), [1]);
      expect(MensagemListaUseCase.filtrar(lista, MensagemFiltro.arquivadas).map((m) => m.musuId), [3]);
      expect(MensagemListaUseCase.naoLidas(lista), 1);
    });

    test('abrir marca como lida só se não lida; marcar e arquivar gravam a situação', () async {
      final useCase = criarUseCase();
      final aberta = (await useCase.abrir(_aviso) as Ok<MensagemRecebidaModel>).value;
      expect(aberta.musuLida, isTrue);
      expect(aberta.musuLidaEm, isNotNull);
      await useCase.abrir(_ana);
      expect(repository.atualizacoes, [(1, true, null)], reason: 'já lida não chama a API');

      await useCase.marcarLida(_ana, false);
      await useCase.arquivar(_ana, true);
      expect(repository.atualizacoes.skip(1), [(2, false, null), (2, null, true)]);
    });

    test('textos: remetente (sistema sem remetente), resumo, data e resposta', () {
      expect(MensagemListaUseCase.remetente(_aviso), isNull, reason: 'sistema');
      expect(MensagemListaUseCase.remetente(_ana), 'Ana Souza (@ana)');
      expect(MensagemListaUseCase.remetente(_antiga), '@bruno');
      expect(MensagemListaUseCase.resumo(_aviso), 'moreto indicou um versículo. O que foi indicado: Efésios 3:20');
      expect(MensagemListaUseCase.data(DateTime(2026, 11, 11, 12, 10)), '11/11/2026 12:10');
      expect(MensagemListaUseCase.resposta(_ana), 'Obrigado!');
      expect(MensagemListaUseCase.resposta(_aviso), isNull);
    });
  });

  group('MensagemListaViewmodel', () {
    test('carrega ao criar; filtro; gravação troca a mensagem na lista', () async {
      final viewModel = criar();
      await pumpEventQueue();
      expect(viewModel.filtradas.map((m) => m.musuId), [1, 2]);
      expect(viewModel.naoLidas, 1);

      await viewModel.arquivarCommand.execute(_ana);
      expect(viewModel.filtradas.map((m) => m.musuId), [1]);
      viewModel.selecionarFiltro(MensagemFiltro.arquivadas);
      expect(viewModel.filtradas.map((m) => m.musuId), [2, 3]);

      await viewModel.abrirCommand.execute(_aviso);
      expect(viewModel.naoLidas, 0);
    });
  });

  group('MensagemListaView', () {
    testWidgets('lista a entrada com remetente, data e resumo; filtro de não lidas com quantidade', (tester) async {
      await montar(tester, criar());

      expect(find.text('mensagens'), findsOneWidget);
      expect(find.text('moreto indicou Efésios 3:20 para você'), findsOneWidget);
      expect(find.text('sistema · 11/11/2026 12:10'), findsOneWidget);
      expect(find.text('Ana Souza (@ana) · 10/11/2026 08:30'), findsOneWidget);
      expect(find.text('Aviso antigo'), findsNothing, reason: 'arquivada não está na entrada');
      expect(find.text('naoLidas (1)'), findsOneWidget);

      await filtrar(tester, 'naoLidas (1)');
      expect(find.text('Encontro de oração'), findsNothing);

      await filtrar(tester, 'arquivadas');
      expect(find.text('Aviso antigo'), findsOneWidget);
    });

    testWidgets('tocar abre a mensagem inteira e marca como lida; arquivar no dialog fecha', (tester) async {
      await montar(tester, criar());
      await tester.tap(find.text('moreto indicou Efésios 3:20 para você'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('de: sistema'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(AlertDialog), matching: find.textContaining('O que foi indicado:')),
        findsOneWidget,
      );
      expect(find.text('lidaEm: 11/11/2026 ${_hora('2026-11-11T15:00:00.000Z')}'), findsOneWidget);
      expect(repository.atualizacoes.first, (1, true, null));
      expect(find.text('naoLidas'), findsOneWidget, reason: 'sem não lidas, sem quantidade');

      await tester.tap(find.text('arquivar'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(repository.atualizacoes.last, (1, null, true));
      expect(find.text('moreto indicou Efésios 3:20 para você'), findsNothing, reason: 'saiu da entrada');
    });

    testWidgets('dialog mostra a resposta do usuário; menu marca como não lida', (tester) async {
      await montar(tester, criar());
      await tester.tap(find.text('Encontro de oração'));
      await tester.pumpAndSettle();
      expect(find.text('suaResposta'), findsOneWidget);
      expect(find.text('Obrigado!'), findsOneWidget);
      await tester.tap(find.text('fechar'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('acoes').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('marcarComoNaoLida'));
      await tester.pumpAndSettle();
      expect(repository.atualizacoes.last, (2, false, null));
      expect(find.text('naoLidas (2)'), findsOneWidget);
    });

    testWidgets('erro no primeiro carregamento: tentar novamente; erro ao gravar: SnackBar', (tester) async {
      repository.erroLista = HttpServiceException(message: 'erroGeralApi', code: 500);
      await montar(tester, criar());
      expect(find.text('erroGeralApi'), findsOneWidget);

      repository.erroLista = null;
      await tester.tap(find.text('tentarNovamente'));
      await tester.pumpAndSettle();
      expect(find.text('Encontro de oração'), findsOneWidget);

      repository.erroAtualizar = HttpServiceException(message: 'registroNaoEncontrado', code: 404);
      await tester.tap(find.byTooltip('acoes').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('arquivar'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(SnackBar, 'registroNaoEncontrado'), findsOneWidget);
      expect(find.text('moreto indicou Efésios 3:20 para você'), findsOneWidget, reason: 'continua na entrada');
    });

    testWidgets('"Nova mensagem" ao lado de voltar abre o envio', (tester) async {
      await montar(tester, criar());
      expect(find.text('voltar'), findsOneWidget);
      await tester.tap(find.text('novaMensagem'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'titulo'), findsOneWidget);
    });

    testWidgets('vazios por filtro', (tester) async {
      repository.lista = [];
      await montar(tester, criar());
      expect(find.text('nenhumaMensagemRecebida'), findsOneWidget);
      await filtrar(tester, 'arquivadas');
      expect(find.text('nenhumaMensagemArquivada'), findsOneWidget);
    });
  });
}

/// "HH:mm" local de uma data UTC.
String _hora(String iso) {
  final d = DateTime.parse(iso).toLocal();
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
