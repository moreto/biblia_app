import 'package:app/config/versao_preferencia.dart';
import 'package:app/data/model/biblia/versiculo_texto_model.dart';
import 'package:app/features/biblia/biblia_leitura/offline/biblia_leitura_repository_offline.dart';
import 'package:app/features/biblia/biblia_leitura/offline/leitura_offline_repository.dart';
import 'package:app/features/biblia/biblia_leitura/offline/versiculo_indicacao_repository_offline.dart';
import 'package:app/features/biblia/biblia_leitura/offline/versiculo_reacao_repository_offline.dart';
import 'package:app/features/biblia/biblia_leitura/ui/biblia_leitura_view.dart';
import 'package:app/features/biblia/biblia_leitura/ui/biblia_leitura_viewmodel.dart';
import 'package:app/features/biblia/biblia_leitura/use_case/biblia_leitura_usecase.dart';
import 'package:app/features/biblia/biblia_leitura/use_case/leitura_offline_usecase.dart';
import 'package:app/features/biblia/biblia_leitura/versiculo_indicacao/repository/versiculo_indicacao_usuario_repository.dart';
import 'package:app/features/biblia/biblia_leitura/versiculo_indicacao/use_case/versiculo_indicacao_usecase.dart';
import 'package:app/features/biblia/biblia_leitura/versiculo_indicacao/use_case/versiculo_indicacao_usuario_usecase.dart';
import 'package:app/features/dashboard/widgets/versiculo_reacao/use_case/versiculo_reacao_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'offline_fakes.dart';

class _Preferencia implements VersaoPreferencia {
  @override
  int? versaoId;

  @override
  void setVersaoId(int versaId) => versaoId = versaId;
}

class _SemDestinatarios implements VersiculoIndicacaoUsuarioRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Localizations extends LocalizationsDelegate<AppLocalizations> {
  const _Localizations();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale: locale, translations: const []);
  @override
  bool shouldReload(_Localizations old) => false;
}

void main() {
  late Ambiente amb;
  late List<int> livrosBuscados;

  setUp(() {
    amb = Ambiente();
    livrosBuscados = [];
  });
  tearDown(() => amb.fechar());

  BibliaLeituraViewmodel criar() {
    final biblia = BibliaLeituraRepositoryOffline(
      api: amb.bibliaApi,
      store: amb.store,
      conectividade: amb.conectividade,
      sincronizacao: amb.sincronizacao,
      usuarioLogado: () => usuaId,
    );
    final download = LeituraOfflineRepositoryImpl(
      store: amb.store,
      conectividade: amb.conectividade,
      buscarLivro: (versaId, livrId) async {
        livrosBuscados.add(livrId);
        return Result.ok(<VersiculoTextoModel>[
          if (livrId == 43) ...joao3(),
          if (livrId == 44)
            const VersiculoTextoModel(
              versId: 200,
              versNumero: 1,
              versTexto: 'atos',
              livrId: 44,
              livrNome: 'Atos',
              capiNumero: 1,
            ),
        ]);
      },
    );
    return BibliaLeituraViewmodel(
      bibliaLeituraUseCase: BibliaLeituraUseCase(bibliaLeituraRepository: biblia, versaoPreferencia: _Preferencia()),
      versiculoIndicacaoUseCase: VersiculoIndicacaoUseCase(
        versiculoIndicacaoRepository: VersiculoIndicacaoRepositoryOffline(
          api: amb.indicacaoApi,
          store: amb.store,
          conectividade: amb.conectividade,
          sincronizacao: amb.sincronizacao,
          usuarioLogado: () => usuaId,
        ),
        usuarioLogado: () => usuaId,
      ),
      versiculoReacaoUseCase: VersiculoReacaoUseCase(
        versiculoReacaoRepository: VersiculoReacaoRepositoryOffline(
          api: amb.reacaoApi,
          store: amb.store,
          conectividade: amb.conectividade,
          sincronizacao: amb.sincronizacao,
          usuarioLogado: () => usuaId,
        ),
        usuarioLogado: () => usuaId,
      ),
      versiculoIndicacaoUsuarioUseCase: VersiculoIndicacaoUsuarioUseCase(
        versiculoIndicacaoUsuarioRepository: _SemDestinatarios(),
      ),
      leituraOfflineUseCase: LeituraOfflineUseCase(
        leituraOfflineRepository: download,
        sincronizacao: amb.sincronizacao,
      ),
    );
  }

  Future<void> aguardar(BibliaLeituraViewmodel vm) async {
    while (vm.carregarCommand.running) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  test('baixa a versão livro a livro e passa a abrir os capítulos sem conexão', () async {
    final vm = criar();
    await aguardar(vm);
    expect(vm.versaoBaixada, isFalse);

    final andamentos = <double>[];
    vm.addListener(() {
      if (vm.progressoDownload case final p?) andamentos.add(p);
    });
    await vm.baixarVersaoCommand.execute();

    expect(vm.baixarVersaoCommand.completed, isTrue);
    expect(livrosBuscados, [43, 44]);
    expect(andamentos.last, 1.0);
    expect(vm.versaoBaixada, isTrue);
    expect(vm.progressoDownload, isNull);

    amb.conectividade.online = false;
    await vm.abrirCapituloCommand.execute((livrId: 44, capiNumero: 1));
    expect(vm.versiculos?.single.versTexto, 'atos');
    expect(amb.bibliaApi.chamadas, isNot(contains('capitulo')));
    vm.dispose();
  });

  test('sem conexão: marca o versículo, conta a pendência e sincroniza quando a conexão volta', () async {
    await amb.store.salvarVersiculos(versaId, joao3());
    // Abre com conexão (guarda versões, livros e índice) e depois perde a conexão.
    final vm = criar();
    await aguardar(vm);
    await amb.sincronizacao.iniciar();
    amb.conectividade.mudar(false);
    await pumpEventQueue();
    expect(vm.online, isFalse);

    await vm.abrirCapituloCommand.execute((livrId: 43, capiNumero: 3));
    await vm.marcarVersiculoCommand.execute(vm.versiculos!.first);
    await amb.sincronizacao.sincronizar();

    expect(vm.versiculoLido(100), isTrue);
    expect(vm.lidoAtual?.versLidos, 1);
    expect(vm.pendentesSincronizacao, 1);
    expect(amb.reacaoApi.chamadas, isEmpty);

    amb.conectividade.mudar(true);
    await vm.sincronizarCommand.execute();

    expect(amb.reacaoApi.chamadas, ['incluir:100:true']);
    expect(vm.pendentesSincronizacao, 0);
    vm.dispose();
  });

  test('baixar sem conexão avisa semConexaoParaBaixar', () async {
    final vm = criar();
    await aguardar(vm);
    amb.conectividade.online = false;

    await vm.baixarVersaoCommand.execute();

    expect(((vm.baixarVersaoCommand.result as Error).error as HandledException).message, 'semConexaoParaBaixar');
    vm.dispose();
  });

  testWidgets('sem conexão a AppBar mostra o aviso com as pendências e o download fica desabilitado', (tester) async {
    late BibliaLeituraViewmodel vm;
    await tester.runAsync(() async {
      await amb.store.salvarVersiculos(versaId, joao3());
      vm = criar();
      await aguardar(vm);
      await amb.sincronizacao.iniciar();
      amb.conectividade.mudar(false);
      await amb.store.gravarReacao(usuaId, 100, joao3Coord, lido: true);
      await amb.sincronizacao.atualizarPendentes();
      await pumpEventQueue();
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_Localizations(), DefaultMaterialLocalizations.delegate],
        home: BibliaLeituraView(viewModel: vm),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('semConexaoLeituraOffline'), findsOneWidget);
    expect(find.descendant(of: find.byType(Badge), matching: find.text('1')), findsOneWidget);
    final baixar = tester.widget<TextButton>(
      find.ancestor(of: find.text('baixarVersaoOffline'), matching: find.byWidgetPredicate((w) => w is TextButton)),
    );
    expect(baixar.onPressed, isNull);

    await tester.tap(find.byTooltip('semConexaoLeituraOffline'));
    await tester.pump();
    expect(find.text('alteracoesSeraoSincronizadas'), findsOneWidget);
    vm.dispose();
  });
}
