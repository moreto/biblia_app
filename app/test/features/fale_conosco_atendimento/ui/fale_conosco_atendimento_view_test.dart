import 'package:app/data/model/configuracao/configuracao_item_model.dart';
import 'package:app/data/model/configuracao/configuracao_model.dart';
import 'package:app/data/model/fale_conosco/fale_conosco_atendimento_model.dart';
import 'package:app/features/fale_conosco_atendimento/repository/fale_conosco_atendimento_repository.dart';
import 'package:app/features/fale_conosco_atendimento/ui/fale_conosco_atendimento_view.dart';
import 'package:app/features/fale_conosco_atendimento/ui/fale_conosco_atendimento_viewmodel.dart';
import 'package:app/features/fale_conosco_atendimento/use_case/fale_conosco_atendimento_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart' show DialogBottomSheetMainBody;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service/service.dart';

const _eu = 50;

ConfiguracaoItemModel _item(int confId, int chave, String valor) => ConfiguracaoItemModel(
  citeId: confId * 100 + chave,
  confId: confId,
  citeChave: '$chave',
  citeValor: valor,
  citeSequencia: chave,
);

FaleConoscoAtendimentoModel _chamado(
  int id, {
  String assunto = 'Assunto',
  int prioridade = 2,
  int status = 1,
  int? responsavelId,
  String? responsavelNome,
  DateTime? fechadoEm,
  int? tempo,
}) => FaleConoscoAtendimentoModel(
  fconId: id,
  fconProtocolo: '2026111700000$id',
  usuaId: 7,
  fconNome: 'Ana Souza',
  fconEmail: 'ana@exemplo.com',
  fconTelefone: '11 99999-0000',
  fconAssunto: assunto,
  fconMensagem: 'Mensagem original $id',
  fconCategoria: 1,
  fconPrioridade: prioridade,
  fconStatus: status,
  fconOrigem: 2,
  fconResponsavelId: responsavelId,
  fconResponsavelNome: responsavelNome,
  fconFechadoEm: fechadoEm,
  fconIp: '189.10.20.30',
  createdAt: DateTime(2026, 11, 17, 9, 0),
  fconTempoResposta: tempo,
);

/// Chamados e interações em memória, com as regras da API: o PUT grava todos os campos; a interação do atendente
/// troca a situação (se informada), marca a primeira resposta (não interna) e o torna responsável se não houver.
class _FakeAtendimentoRepository implements FaleConoscoAtendimentoRepository {
  List<FaleConoscoAtendimentoModel> chamados = [
    _chamado(1, assunto: 'App não abre', prioridade: 4),
    _chamado(2, assunto: 'Sugestão', responsavelId: _eu, responsavelNome: 'Marcelo', status: 4, tempo: 5400),
  ];
  final interacoesPorChamado = <int, List<FaleConoscoAtendimentoInteracaoModel>>{
    2: [
      FaleConoscoAtendimentoInteracaoModel(fcinId: 1, usuaId: _eu, fcinTexto: 'Obrigado!', udetNome: 'Marcelo'),
      FaleConoscoAtendimentoInteracaoModel(
        fcinId: 2,
        usuaId: _eu,
        fcinTexto: 'Ver com o time',
        fcinInterna: true,
        udetNome: 'Marcelo',
      ),
    ],
  };
  final filtros = <FaleConoscoAtendimentoFiltroModel>[];
  final respostas = <FaleConoscoAtendimentoInteracaoBodyModel>[];
  final atualizacoes = <FaleConoscoAtendimentoBodyModel>[];
  final excluidos = <int>[];
  Exception? erroFila;

  @override
  Future<Result<List<FaleConoscoAtendimentoModel>>> fila(FaleConoscoAtendimentoFiltroModel filtro) async {
    filtros.add(filtro);
    final e = erroFila;
    if (e != null) return Result.error(e);
    return Result.ok([
      for (final c in chamados)
        if ((filtro.fconStatus == null || c.fconStatus == filtro.fconStatus) &&
            (filtro.fconResponsavelId == null || c.fconResponsavelId == filtro.fconResponsavelId))
          c,
    ]);
  }

  @override
  Future<Result<FaleConoscoAtendimentoModel>> chamado(int fconId) async {
    final c = chamados.where((c) => c.fconId == fconId).firstOrNull;
    return c == null ? Result.error(HttpServiceException(message: 'registroNaoEncontrado', code: 404)) : Result.ok(c);
  }

  @override
  Future<Result<List<FaleConoscoAtendimentoInteracaoModel>>> interacoes(int fconId) async =>
      Result.ok(List.of(interacoesPorChamado[fconId] ?? const []));

  @override
  Future<Result<void>> responder(FaleConoscoAtendimentoInteracaoBodyModel body) async {
    respostas.add(body);
    final c = chamados.firstWhere((c) => c.fconId == body.fconId);
    _trocar(
      _copia(
        c,
        status: body.fconStatus ?? c.fconStatus,
        responsavelId: c.fconResponsavelId ?? _eu,
        responsavelNome: c.fconResponsavelNome ?? 'Marcelo',
      ),
    );
    (interacoesPorChamado[body.fconId] ??= []).add(
      FaleConoscoAtendimentoInteracaoModel(
        fcinId: 100 + respostas.length,
        usuaId: _eu,
        fcinTexto: body.fcinTexto,
        fcinInterna: body.fcinInterna,
        udetNome: 'Marcelo',
      ),
    );
    return const Result.ok(null);
  }

  @override
  Future<Result<FaleConoscoAtendimentoModel>> atualizar(FaleConoscoAtendimentoBodyModel body) async {
    atualizacoes.add(body);
    final c = chamados.firstWhere((c) => c.fconId == body.fconId);
    final novo = FaleConoscoAtendimentoModel(
      fconId: c.fconId,
      fconProtocolo: c.fconProtocolo,
      usuaId: c.usuaId,
      fconNome: c.fconNome,
      fconEmail: c.fconEmail,
      fconAssunto: c.fconAssunto,
      fconMensagem: c.fconMensagem,
      fconCategoria: body.fconCategoria,
      fconPrioridade: body.fconPrioridade,
      fconStatus: body.fconStatus,
      fconResponsavelId: body.fconResponsavelId,
      fconResponsavelNome: body.fconResponsavelId == null ? null : 'Marcelo',
      fconFechadoEm: switch (body.fconFechado) {
        null => c.fconFechadoEm,
        true => c.fconFechadoEm ?? DateTime(2026, 11, 17, 15, 0),
        false => null,
      },
      createdAt: c.createdAt,
      updatedAt: DateTime(2026, 11, 17, 15, atualizacoes.length),
    );
    _trocar(novo);
    return Result.ok(novo);
  }

  @override
  Future<Result<void>> excluir(int fconId) async {
    excluidos.add(fconId);
    chamados = [
      for (final c in chamados)
        if (c.fconId != fconId) c,
    ];
    return const Result.ok(null);
  }

  @override
  Future<Result<List<ConfiguracaoModel>>> configuracoes() async => Result.ok(const [
    ConfiguracaoModel(confId: 10, confNome: 'Fale Conosco - Categoria', confCodigo: 'faleConoscoCategoria'),
    ConfiguracaoModel(confId: 11, confNome: 'Fale Conosco - Prioridade', confCodigo: 'faleConoscoPrioridade'),
    ConfiguracaoModel(confId: 12, confNome: 'Fale Conosco - Situação', confCodigo: 'faleConoscoStatus'),
    ConfiguracaoModel(confId: 13, confNome: 'Fale Conosco - Origem', confCodigo: 'faleConoscoOrigem'),
  ]);

  @override
  Future<Result<List<ConfiguracaoItemModel>>> itens(int confId) async => Result.ok(switch (confId) {
    10 => [_item(10, 1, 'duvida'), _item(10, 4, 'erroTecnico')],
    11 => [_item(11, 1, 'baixa'), _item(11, 2, 'media'), _item(11, 3, 'alta'), _item(11, 4, 'urgente')],
    12 => [_item(12, 1, 'novo'), _item(12, 3, 'emAtendimento'), _item(12, 4, 'respondido'), _item(12, 5, 'fechado')],
    13 => [_item(13, 1, 'site'), _item(13, 2, 'app')],
    _ => const [],
  });

  void _trocar(FaleConoscoAtendimentoModel novo) =>
      chamados = [for (final c in chamados) c.fconId == novo.fconId ? novo : c];

  FaleConoscoAtendimentoModel _copia(
    FaleConoscoAtendimentoModel c, {
    required int status,
    int? responsavelId,
    String? responsavelNome,
  }) => FaleConoscoAtendimentoModel(
    fconId: c.fconId,
    fconProtocolo: c.fconProtocolo,
    usuaId: c.usuaId,
    fconNome: c.fconNome,
    fconEmail: c.fconEmail,
    fconAssunto: c.fconAssunto,
    fconMensagem: c.fconMensagem,
    fconCategoria: c.fconCategoria,
    fconPrioridade: c.fconPrioridade,
    fconStatus: status,
    fconResponsavelId: responsavelId,
    fconResponsavelNome: responsavelNome,
    fconFechadoEm: c.fconFechadoEm,
    createdAt: c.createdAt,
  );
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
  late _FakeAtendimentoRepository repository;

  setUp(() => repository = _FakeAtendimentoRepository());

  FaleConoscoAtendimentoUseCase criarUseCase() =>
      FaleConoscoAtendimentoUseCase(faleConoscoAtendimentoRepository: repository, usuarioId: () => _eu);

  FaleConoscoAtendimentoViewmodel criar() =>
      FaleConoscoAtendimentoViewmodel(faleConoscoAtendimentoUseCase: criarUseCase());

  Future<FaleConoscoAtendimentoOpcoes> opcoes() async =>
      (await criarUseCase().opcoes() as Ok<FaleConoscoAtendimentoOpcoes>).value;

  Future<void> montar(WidgetTester tester, FaleConoscoAtendimentoViewmodel viewModel) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        home: FaleConoscoAtendimentoView(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> abrir(WidgetTester tester, String assunto) async {
    await tester.tap(find.text(assunto));
    await tester.pumpAndSettle();
  }

  /// Toca no texto dentro do detalhe, rolando até ele.
  Future<void> tocarNoDetalhe(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('modelos', () {
    test('fromJson lê o chamado do atendimento (ids bigint como texto) e a interação interna', () {
      final c = FaleConoscoAtendimentoModel.fromJson({
        'fconId': '12',
        'fconProtocolo': 'P',
        'usuaId': '7',
        'fconNome': 'Ana',
        'fconEmail': 'a@b.co',
        'fconAssunto': 'A',
        'fconMensagem': 'M',
        'fconCategoria': 1,
        'fconPrioridade': 3,
        'fconStatus': 2,
        'fconResponsavelId': '50',
        'fconResponsavelNome': 'Marcelo',
        'fconTempoResposta': 3600,
        'createdAt': '2026-11-17T09:00:00Z',
      });
      expect((c.fconId, c.usuaId, c.fconResponsavelId, c.fconTempoResposta, c.fechado), (12, 7, 50, 3600, false));
      final i = FaleConoscoAtendimentoInteracaoModel.fromJson({
        'fcin_id': 1,
        'fcin_texto': 'x',
        'fcin_interna': true,
        'udet_nome': 'M',
      });
      expect((i.fcinInterna, i.udetNome), (true, 'M'));
      expect(
        () => FaleConoscoAtendimentoInteracaoModel.fromJson({'fcinId': 1, 'fcinTexto': 'x', 'fcinInterna': 1}),
        throwsFormatException,
      );
    });

    test('corpos: PUT manda o responsável sempre (nulo = sem responsável) e o fechamento só se informado', () {
      const put = FaleConoscoAtendimentoBodyModel(fconId: 1, fconCategoria: 1, fconPrioridade: 2, fconStatus: 3);
      expect(put.toJson(), {
        'fconId': 1,
        'fconCategoria': 1,
        'fconPrioridade': 2,
        'fconStatus': 3,
        'fconResponsavelId': null,
      });
      expect(const FaleConoscoAtendimentoInteracaoBodyModel(fconId: 1, fcinTexto: 't').toJson(), {
        'fconId': 1,
        'fcinTexto': 't',
        'fcinInterna': false,
      });
      expect(const FaleConoscoAtendimentoFiltroModel(fconStatus: 2).toQuery(), {'fconStatus': 2});
    });
  });

  group('FaleConoscoAtendimentoUseCase', () {
    test('opções das quatro configurações; filtro "meus" usa o usuário logado', () async {
      final o = await opcoes();
      expect(o.prioridades.map((p) => p.rotulo), ['baixa', 'media', 'alta', 'urgente']);
      expect(o.origens, hasLength(2));
      final useCase = criarUseCase();
      expect(useCase.filtroApi((situacao: 3, meus: true)).toQuery(), {'fconStatus': 3, 'fconResponsavelId': _eu});
      expect(useCase.filtroApi((situacao: null, meus: false)).vazio, isTrue);
    });

    test('assumir e liberar mantêm a classificação; fechar e reabrir trocam a situação', () async {
      final useCase = criarUseCase();
      final o = await opcoes();
      final chamado = repository.chamados.first;

      await useCase.assumir(chamado);
      expect(repository.atualizacoes.last.toJson(), {
        'fconId': 1,
        'fconCategoria': 1,
        'fconPrioridade': 4,
        'fconStatus': 1,
        'fconResponsavelId': _eu,
      });
      final assumido = repository.chamados.first;
      await useCase.liberar(assumido);
      expect(repository.atualizacoes.last.fconResponsavelId, isNull);

      await useCase.fechar(repository.chamados.first, o);
      expect((repository.atualizacoes.last.fconFechado, repository.atualizacoes.last.fconStatus), (true, 5));
      await useCase.reabrir(repository.chamados.first, o);
      expect((repository.atualizacoes.last.fconFechado, repository.atualizacoes.last.fconStatus), (false, 3));

      final semUsuario = FaleConoscoAtendimentoUseCase(faleConoscoAtendimentoRepository: repository);
      expect(await semUsuario.assumir(chamado), isA<Error>());
    });

    test('responder valida, não manda situação igual à atual e recarrega o detalhe', () async {
      final useCase = criarUseCase();
      final chamado = repository.chamados.first;
      expect(FaleConoscoAtendimentoUseCase.validarResposta('  '), 'informeMensagem');
      expect(await useCase.responder(chamado, (texto: ' ', interna: false, situacao: null)), isA<Error>());

      final detalhe = (await useCase.responder(chamado, (
        texto: ' Já vamos ver ',
        interna: false,
        situacao: 1,
      )) as Ok<FaleConoscoAtendimentoDetalhe>).value;
      expect((repository.respostas.last.fcinTexto, repository.respostas.last.fconStatus), ('Já vamos ver', null));
      expect(detalhe.interacoes.single.fcinTexto, 'Já vamos ver');
      expect(detalhe.chamado.fconResponsavelId, _eu, reason: 'a API torna o atendente responsável');

      await useCase.responder(detalhe.chamado, (texto: 'nota', interna: true, situacao: 3));
      expect((repository.respostas.last.fcinInterna, repository.respostas.last.fconStatus), (true, 3));
    });

    test('textos: duração do tempo de resposta e nível da prioridade', () async {
      expect(FaleConoscoAtendimentoUseCase.duracao(null), isNull);
      expect(FaleConoscoAtendimentoUseCase.duracao(30), '<1min');
      expect(FaleConoscoAtendimentoUseCase.duracao(12 * 60), '12min');
      expect(FaleConoscoAtendimentoUseCase.duracao(5400), '1h 30min');
      expect(FaleConoscoAtendimentoUseCase.duracao(2 * 86400 + 3 * 3600), '2d 3h');
      final o = await opcoes();
      expect(FaleConoscoAtendimentoUseCase.nivelPrioridade(o.prioridades, 1), 0);
      expect(FaleConoscoAtendimentoUseCase.nivelPrioridade(o.prioridades, 4), 1);
      expect(FaleConoscoAtendimentoUseCase.nivelPrioridade(o.prioridades, 9), isNull);
    });
  });

  group('FaleConoscoAtendimentoViewmodel', () {
    test('filtros recarregam a fila; gravação troca o detalhe e recarrega a fila', () async {
      final vm = criar();
      await pumpEventQueue();
      expect(vm.fila?.map((c) => c.fconId), [1, 2]);

      vm.alternarMeus();
      await pumpEventQueue();
      expect(vm.fila?.map((c) => c.fconId), [2]);
      vm.selecionarSituacao(1);
      await pumpEventQueue();
      expect(vm.fila, isEmpty);
      expect(repository.filtros.last.toQuery(), {'fconStatus': 1, 'fconResponsavelId': _eu});

      vm.alternarMeus();
      await pumpEventQueue();
      await vm.detalheCommand.execute(1);
      expect(vm.meuChamado, isFalse);
      await vm.acaoCommand.execute(FaleConoscoAtendimentoAcao.assumir);
      expect(vm.meuChamado, isTrue);
      await vm.acaoCommand.execute(FaleConoscoAtendimentoAcao.fechar);
      expect(vm.detalhe?.chamado.fechado, isTrue);
      expect(vm.fila, isEmpty, reason: 'saiu do filtro "novo"');

      await vm.excluirCommand.execute();
      expect(vm.detalhe, isNull);
      expect(repository.excluidos, [1]);
    });
  });

  group('FaleConoscoAtendimentoView', () {
    testWidgets('fila com contato, prioridade, situação, responsável e tempo de resposta', (tester) async {
      await montar(tester, criar());
      expect(find.text('atendimentoFaleConosco'), findsOneWidget);
      expect(find.text('App não abre'), findsOneWidget);
      expect(find.text('Ana Souza · ana@exemplo.com'), findsNWidgets(2));
      expect(find.text('urgente'), findsOneWidget);
      expect(find.text('semResponsavel'), findsOneWidget);
      expect(find.text('Marcelo'), findsOneWidget);
      expect(find.text('primeiraResposta: 1h 30min'), findsOneWidget);
      expect(find.text('semResposta'), findsOneWidget);

      await tester.tap(find.text('meusChamados'));
      await tester.pumpAndSettle();
      expect(find.text('App não abre'), findsNothing);
    });

    testWidgets('sem perfil de administrador: mostra acessoNegado', (tester) async {
      repository.erroFila = HttpServiceException(message: 'acessoNegado', code: 403);
      await montar(tester, criar());
      expect(find.text('acessoNegado'), findsOneWidget);
      expect(find.text('tentarNovamente'), findsOneWidget);
    });

    testWidgets('detalhe mostra a conversa com a nota interna; responder como nota grava', (tester) async {
      await montar(tester, criar());
      await abrir(tester, 'Sugestão');

      expect(find.byType(DialogBottomSheetMainBody), findsOneWidget);
      expect(find.text('Mensagem original 2'), findsOneWidget);
      expect(find.text('Obrigado!'), findsOneWidget);
      expect(find.textContaining('notaInterna · Marcelo'), findsOneWidget);
      expect(find.text('responsavel: Marcelo'), findsOneWidget);
      expect(find.text('assumir'), findsNothing, reason: 'já é meu');

      await tester.enterText(find.widgetWithText(TextField, 'responder'), 'Lembrar de revisar');
      await tocarNoDetalhe(tester, find.byType(Switch));
      await tocarNoDetalhe(tester, find.text('enviar'));
      expect(
        (repository.respostas.single.fcinInterna, repository.respostas.single.fcinTexto),
        (true, 'Lembrar de revisar'),
      );
      expect(find.text('notaInternaGravada'), findsOneWidget);
    });

    testWidgets('assumir, classificar e fechar gravam o chamado', (tester) async {
      await montar(tester, criar());
      await abrir(tester, 'App não abre');
      expect(find.text('responsavel: semResponsavel'), findsOneWidget);

      await tocarNoDetalhe(tester, find.text('assumir'));
      expect(repository.atualizacoes.last.fconResponsavelId, _eu);
      expect(find.text('chamadoAtualizado'), findsOneWidget);
      expect(find.text('liberar'), findsOneWidget);

      await tocarNoDetalhe(tester, find.text('urgente').last);
      await tester.tap(find.text('alta').last);
      await tester.pumpAndSettle();
      await tocarNoDetalhe(tester, find.text('salvar'));
      expect(repository.atualizacoes.last.fconPrioridade, 3);

      await tocarNoDetalhe(tester, find.text('fecharChamado'));
      expect(repository.atualizacoes.last.fconFechado, isTrue);
      expect(find.text('reabrirChamado'), findsOneWidget);
    });

    testWidgets('excluir pede confirmação, fecha o detalhe e avisa', (tester) async {
      await montar(tester, criar());
      await abrir(tester, 'App não abre');
      await tocarNoDetalhe(tester, find.text('excluir'));
      expect(find.text('confirmarExclusao'), findsOneWidget);

      // o botão do aviso mostra o texto em maiúsculas
      await tester.tap(find.text('EXCLUIR'));
      await tester.pumpAndSettle();
      expect(repository.excluidos, [1]);
      expect(find.byType(DialogBottomSheetMainBody), findsNothing);
      expect(find.widgetWithText(SnackBar, 'chamadoExcluido'), findsOneWidget);
      expect(find.text('App não abre'), findsNothing);
    });
  });
}
