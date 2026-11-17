import 'package:app/data/model/configuracao/configuracao_item_model.dart';
import 'package:app/data/model/configuracao/configuracao_model.dart';
import 'package:app/data/model/fale_conosco/fale_conosco_model.dart';
import 'package:app/data/model/usuario/usuario_detalhe_model.dart';
import 'package:app/features/fale_conosco/repository/fale_conosco_repository.dart';
import 'package:app/features/fale_conosco/ui/fale_conosco_view.dart';
import 'package:app/features/fale_conosco/ui/fale_conosco_viewmodel.dart';
import 'package:app/features/fale_conosco/use_case/fale_conosco_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart' show DialogBottomSheetMainBody;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service/service.dart';

ConfiguracaoItemModel _item(int confId, int chave, String valor, {bool ativo = true, int? sequencia}) =>
    ConfiguracaoItemModel(
      citeId: confId * 100 + chave,
      confId: confId,
      citeChave: '$chave',
      citeValor: valor,
      citeSequencia: sequencia ?? chave,
      citeAtivo: ativo,
    );

final _aberto = FaleConoscoModel(
  fconId: 7,
  fconProtocolo: '20261117000007',
  fconAssunto: 'Erro na leitura',
  fconMensagem: 'O capítulo não abre.',
  fconCategoria: 4,
  fconStatus: 4,
  fconPrimeiraRespostaEm: DateTime(2026, 11, 17, 11, 0),
  createdAt: DateTime(2026, 11, 17, 10, 0),
);

final _fechado = FaleConoscoModel(
  fconId: 3,
  fconProtocolo: '20261101000003',
  fconAssunto: 'Sugestão de tema',
  fconMensagem: 'Tema sépia.',
  fconCategoria: 2,
  fconStatus: 5,
  fconFechadoEm: DateTime(2026, 11, 5, 9, 0),
  createdAt: DateTime(2026, 11, 1, 8, 0),
);

/// Chamados e configurações em memória, com as regras da API: só o solicitante vê os próprios chamados; chamado
/// fechado não aceita mensagem (404).
class _FakeFaleConoscoRepository implements FaleConoscoRepository {
  List<FaleConoscoModel> chamados = [_fechado, _aberto];
  final interacoes = <int, List<FaleConoscoInteracaoModel>>{
    7: [
      FaleConoscoInteracaoModel(
        fcinId: 1,
        fcinTexto: 'Já corrigimos, tente de novo.',
        createdAt: DateTime(2026, 11, 17, 11, 0),
      ),
    ],
  };
  final enviados = <FaleConoscoBodyModel>[];
  final respostas = <(int, String)>[];

  /// Sem `confCodigo`, a configuração é achada pelo nome.
  bool comCodigo = true;
  bool semOrigemApp = false;
  Exception? erroMeus;
  Exception? erroEnviar;

  @override
  Future<Result<List<FaleConoscoModel>>> meus() async {
    final e = erroMeus;
    return e != null ? Result.error(e) : Result.ok(List.of(chamados));
  }

  @override
  Future<Result<FaleConoscoModel>> meu(int fconId) async {
    final c = chamados.where((c) => c.fconId == fconId).firstOrNull;
    if (c == null) return Result.error(HttpServiceException(message: 'registroNaoEncontrado', code: 404));
    return Result.ok(
      FaleConoscoModel(
        fconId: c.fconId,
        fconProtocolo: c.fconProtocolo,
        fconAssunto: c.fconAssunto,
        fconMensagem: c.fconMensagem,
        fconCategoria: c.fconCategoria,
        fconStatus: c.fconStatus,
        fconPrimeiraRespostaEm: c.fconPrimeiraRespostaEm,
        fconFechadoEm: c.fconFechadoEm,
        createdAt: c.createdAt,
        interacoes: List.of(interacoes[fconId] ?? const []),
      ),
    );
  }

  @override
  Future<Result<FaleConoscoEnvioModel>> enviar(FaleConoscoBodyModel body) async {
    enviados.add(body);
    final e = erroEnviar;
    if (e != null) return Result.error(e);
    final novo = FaleConoscoModel(
      fconId: 9,
      fconProtocolo: '20261117000009',
      fconAssunto: body.fconAssunto,
      fconMensagem: body.fconMensagem,
      fconCategoria: body.fconCategoria,
      fconStatus: 1,
      createdAt: DateTime(2026, 11, 17, 12, 0),
    );
    chamados = [...chamados, novo];
    return Result.ok(FaleConoscoEnvioModel(fconId: novo.fconId, fconProtocolo: novo.fconProtocolo));
  }

  @override
  Future<Result<void>> responder({required int fconId, required String texto}) async {
    respostas.add((fconId, texto));
    final c = chamados.where((c) => c.fconId == fconId).firstOrNull;
    if (c == null || c.fechado) {
      return Result.error(HttpServiceException(message: 'registroNaoEncontrado', code: 404));
    }
    (interacoes[fconId] ??= []).add(
      FaleConoscoInteracaoModel(
        fcinId: 99,
        fcinTexto: texto,
        fcinSolicitante: true,
        createdAt: DateTime(2026, 11, 17, 13, 0),
      ),
    );
    return const Result.ok(null);
  }

  @override
  Future<Result<List<ConfiguracaoModel>>> configuracoes() async => Result.ok([
    ConfiguracaoModel(confId: 1, confNome: 'Níveis de Acesso do Perfil', confCodigo: comCodigo ? 'perfilNivel' : null),
    ConfiguracaoModel(
      confId: 10,
      confNome: 'Fale Conosco - Categoria',
      confCodigo: comCodigo ? 'faleConoscoCategoria' : null,
    ),
    ConfiguracaoModel(
      confId: 12,
      confNome: 'Fale Conosco - Situação',
      confCodigo: comCodigo ? 'faleConoscoStatus' : null,
    ),
    ConfiguracaoModel(
      confId: 13,
      confNome: 'Fale Conosco - Origem',
      confCodigo: comCodigo ? 'faleConoscoOrigem' : null,
    ),
  ]);

  @override
  Future<Result<List<ConfiguracaoItemModel>>> itens(int confId) async => Result.ok(switch (confId) {
    10 => [
      _item(10, 4, 'erroTecnico'),
      _item(10, 1, 'duvida'),
      _item(10, 2, 'sugestao'),
      _item(10, 6, 'outros', ativo: false),
    ],
    12 => [_item(12, 1, 'novo'), _item(12, 4, 'respondido'), _item(12, 5, 'fechado')],
    13 => [_item(13, 1, 'site'), if (!semOrigemApp) _item(13, 2, 'app')],
    _ => const [],
  });
}

final _usuario = UsuarioDetalheModel(
  usuaId: 1,
  usuaUuid: 'u',
  usuaEmail: 'ana@exemplo.com',
  usuaAtivo: true,
  udetNome: 'Ana Souza',
  udetUsuario: 'ana',
  emprId: 1,
  emprNome: 'E',
);

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

const FaleConoscoFormulario _valido = (
  nome: ' Ana Souza ',
  email: 'ana@exemplo.com',
  telefone: ' ',
  assunto: ' Dúvida sobre versões ',
  mensagem: ' Quais versões existem? ',
  categoria: 1,
);

void main() {
  late _FakeFaleConoscoRepository repository;

  setUp(() => repository = _FakeFaleConoscoRepository());

  FaleConoscoUseCase criarUseCase() => FaleConoscoUseCase(faleConoscoRepository: repository, usuario: () => _usuario);

  FaleConoscoViewmodel criar() => FaleConoscoViewmodel(faleConoscoUseCase: criarUseCase());

  Future<void> montar(WidgetTester tester, FaleConoscoViewmodel viewModel) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        home: FaleConoscoView(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('FaleConoscoModel', () {
    test('fromJson lê o chamado (ids bigint como texto) e as interações; datas em hora local', () {
      final chamado = FaleConoscoModel.fromJson({
        'fconId': '7',
        'fconProtocolo': '20261117000007',
        'fconAssunto': 'A',
        'fconMensagem': 'M',
        'fconCategoria': 4,
        'fconStatus': 4,
        'fconOrigem': 2,
        'fconFechadoEm': null,
        'createdAt': '2026-11-17T10:00:00.000Z',
        'interacoes': [
          {'fcinId': '1', 'fcinTexto': 'R', 'fcinStatus': 4, 'fcinSolicitante': false},
          {'fcin_id': 2, 'fcin_texto': 'Obrigado', 'fcin_solicitante': true},
        ],
      });
      expect((chamado.fconId, chamado.fechado, chamado.fconOrigem), (7, false, 2));
      expect(chamado.createdAt, DateTime.utc(2026, 11, 17, 10).toLocal());
      expect(chamado.interacoes.map((i) => (i.fcinId, i.fcinSolicitante)), [(1, false), (2, true)]);
      final snake = FaleConoscoModel.fromJson({
        'fcon_id': 1,
        'fcon_protocolo': 'P',
        'fcon_assunto': 'A',
        'fcon_mensagem': 'M',
        'fcon_categoria': 1,
        'fcon_status': 5,
        'fcon_fechado_em': '2026-11-05T09:00:00Z',
      });
      expect(snake.fechado, isTrue);
      expect(snake.interacoes, isEmpty);
    });

    test('formato inválido lança FormatException; corpo do envio', () {
      expect(() => FaleConoscoModel.fromJson({'fconId': 1}), throwsFormatException);
      expect(
        () => FaleConoscoInteracaoModel.fromJson({'fcinId': 1, 'fcinTexto': 'x', 'fcinSolicitante': 'sim'}),
        throwsFormatException,
      );
      expect(
        const FaleConoscoBodyModel(
          fconNome: 'N',
          fconEmail: 'e@x.co',
          fconAssunto: 'A',
          fconMensagem: 'M',
          fconCategoria: 1,
          fconOrigem: 2,
        ).toJson(),
        {
          'fconNome': 'N',
          'fconEmail': 'e@x.co',
          'fconTelefone': null,
          'fconAssunto': 'A',
          'fconMensagem': 'M',
          'fconCategoria': 1,
          'fconOrigem': 2,
        },
      );
    });
  });

  group('FaleConoscoUseCase', () {
    test(
      'carrega chamados (mais recentes primeiro) e opções ativas em ordem; acha a configuração pelo código',
      () async {
        final dados = (await criarUseCase().carregar() as Ok<FaleConoscoDados>).value;
        expect(dados.chamados.map((c) => c.fconId), [7, 3]);
        expect(dados.opcoes.categorias.map((c) => c.rotulo), [
          'duvida',
          'sugestao',
          'erroTecnico',
        ], reason: 'sem inativo');
        expect(dados.opcoes.origemApp, 2);
        expect(FaleConoscoUseCase.rotulo(dados.opcoes.situacoes, 5), 'fechado');
        expect(FaleConoscoUseCase.rotulo(dados.opcoes.situacoes, 42), '?');
      },
    );

    test('sem confCodigo na resposta da API, acha a configuração pelo nome', () async {
      repository.comCodigo = false;
      final dados = (await criarUseCase().carregar() as Ok<FaleConoscoDados>).value;
      expect(dados.opcoes.categorias, hasLength(3));
      expect(dados.opcoes.origemApp, 2);
    });

    test('validar confere os limites da API', () {
      FaleConoscoFormulario com({
        String? nome,
        String? email,
        String? telefone,
        String? assunto,
        String? mensagem,
        int? categoria = 1,
      }) => (
        nome: nome ?? _valido.nome,
        email: email ?? _valido.email,
        telefone: telefone ?? _valido.telefone,
        assunto: assunto ?? _valido.assunto,
        mensagem: mensagem ?? _valido.mensagem,
        categoria: categoria,
      );
      expect(FaleConoscoUseCase.validar(_valido), isNull);
      expect(FaleConoscoUseCase.validar(com(nome: '  ')), 'informeNome');
      expect(FaleConoscoUseCase.validar(com(nome: 'n' * 151)), 'nomeMuitoLongo');
      expect(FaleConoscoUseCase.validar(com(email: '')), 'informeEmail');
      expect(FaleConoscoUseCase.validar(com(email: 'ana@exemplo')), 'emailInvalido');
      expect(FaleConoscoUseCase.validar(com(telefone: '1' * 21)), 'telefoneMuitoLongo');
      expect(FaleConoscoUseCase.validar(com(categoria: null)), 'informeCategoria');
      expect(FaleConoscoUseCase.validar(com(assunto: '')), 'informeAssunto');
      expect(FaleConoscoUseCase.validar(com(mensagem: 'm' * 4001)), 'mensagemMuitoLonga');
    });

    test('enviar tira os espaços, usa a origem "app" e omite telefone vazio; sem origem "app" não envia', () async {
      final useCase = criarUseCase();
      final opcoes = (await useCase.carregar() as Ok<FaleConoscoDados>).value.opcoes;
      final envio = (await useCase.enviar(_valido, opcoes) as Ok<FaleConoscoEnvioModel>).value;
      expect(envio.fconProtocolo, '20261117000009');
      final body = repository.enviados.single;
      expect(
        (body.fconNome, body.fconAssunto, body.fconMensagem, body.fconTelefone, body.fconOrigem),
        ('Ana Souza', 'Dúvida sobre versões', 'Quais versões existem?', null, 2),
      );

      final sem = await useCase.enviar(_valido, const FaleConoscoOpcoes());
      expect(FaleConoscoUseCase.mensagemErro((sem as Error).error), FaleConoscoUseCase.kIndisponivel);
      expect(repository.enviados, hasLength(1));
      expect((useCase.prefixoNome, useCase.prefixoEmail), ('Ana Souza', 'ana@exemplo.com'));
    });

    test('responder grava e devolve o chamado atualizado; fechado (ou 404) vira chamadoFechado', () async {
      final useCase = criarUseCase();
      final atualizado = (await useCase.responder(_aberto, '  Funcionou!  ') as Ok<FaleConoscoModel>).value;
      expect(repository.respostas, [(7, 'Funcionou!')]);
      expect(atualizado.interacoes.last.fcinSolicitante, isTrue);

      final fechado = await useCase.responder(_fechado, 'oi');
      expect(FaleConoscoUseCase.mensagemErro((fechado as Error).error), FaleConoscoUseCase.kChamadoFechado);
      expect(repository.respostas, hasLength(1), reason: 'fechado não chama a API');

      repository.chamados = [for (final c in repository.chamados) c.fconId == 7 ? _fechado : c];
      final fechouDepois = await useCase.responder(_aberto, 'oi');
      expect(FaleConoscoUseCase.mensagemErro((fechouDepois as Error).error), FaleConoscoUseCase.kChamadoFechado);
      expect(
        FaleConoscoUseCase.mensagemErro((await useCase.responder(_aberto, ' ') as Error).error),
        'informeMensagem',
      );
    });
  });

  group('FaleConoscoViewmodel', () {
    test('carrega ao criar; enviar recarrega a lista; responder troca o detalhe e o chamado da lista', () async {
      final viewModel = criar();
      await pumpEventQueue();
      expect(viewModel.chamados.map((c) => c.fconId), [7, 3]);
      expect(viewModel.categoria(4), 'erroTecnico');

      await viewModel.enviarCommand.execute(_valido);
      expect(viewModel.chamados.map((c) => c.fconId), [9, 7, 3]);

      await viewModel.detalheCommand.execute(7);
      expect(viewModel.detalhe?.interacoes, hasLength(1));
      await viewModel.responderCommand.execute('Funcionou!');
      expect(viewModel.detalhe?.interacoes, hasLength(2));
      expect(viewModel.chamados.firstWhere((c) => c.fconId == 7).interacoes, hasLength(2));
    });
  });

  group('FaleConoscoView', () {
    testWidgets('lista os chamados com protocolo, data, situação e categoria', (tester) async {
      await montar(tester, criar());
      expect(find.text('faleConosco'), findsOneWidget);
      expect(find.text('Erro na leitura'), findsOneWidget);
      expect(find.text('protocolo 20261117000007 · 17/11/2026 10:00'), findsOneWidget);
      expect(find.text('respondido'), findsOneWidget);
      expect(find.text('erroTecnico'), findsOneWidget);
      expect(find.text('fechado'), findsOneWidget);
      expect(find.text('novaMensagem'), findsOneWidget);
    });

    testWidgets('nova mensagem: valida, envia e avisa o protocolo', (tester) async {
      await montar(tester, criar());
      await tester.tap(find.text('novaMensagem'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Ana Souza'), findsOneWidget, reason: 'nome do usuário logado');
      expect(find.widgetWithText(TextField, 'ana@exemplo.com'), findsOneWidget);

      await tester.tap(find.text('enviar'));
      await tester.pumpAndSettle();
      expect(find.text('informeCategoria'), findsOneWidget);
      expect(repository.enviados, isEmpty);

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('duvida').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'assunto'), 'Versões');
      await tester.enterText(find.widgetWithText(TextField, 'mensagem'), 'Quais existem?');
      await tester.ensureVisible(find.text('enviar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('enviar'));
      await tester.pumpAndSettle();

      expect(repository.enviados.single.fconCategoria, 1);
      expect(find.byType(DialogBottomSheetMainBody), findsNothing);
      expect(find.widgetWithText(SnackBar, 'chamadoEnviado: 20261117000009'), findsOneWidget);
      expect(find.text('Versões'), findsOneWidget, reason: 'lista recarregada');
    });

    testWidgets('detalhe mostra a conversa e grava a resposta', (tester) async {
      await montar(tester, criar());
      await tester.tap(find.text('Erro na leitura'));
      await tester.pumpAndSettle();

      expect(find.byType(DialogBottomSheetMainBody), findsOneWidget);
      expect(find.text('O capítulo não abre.'), findsOneWidget);
      expect(find.text('Já corrigimos, tente de novo.'), findsOneWidget);
      expect(find.text('atendimento · 17/11/2026 11:00'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'responder'), 'Funcionou!');
      await tester.tap(find.text('enviar'));
      await tester.pumpAndSettle();
      expect(repository.respostas, [(7, 'Funcionou!')]);
      expect(find.text('Funcionou!'), findsOneWidget);
    });

    testWidgets('chamado fechado não tem campo de resposta', (tester) async {
      await montar(tester, criar());
      await tester.tap(find.text('Sugestão de tema'));
      await tester.pumpAndSettle();
      expect(find.text('chamadoFechadoAviso'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'responder'), findsNothing);
      expect(find.text('aguardandoResposta'), findsOneWidget);
    });

    testWidgets('erro no primeiro carregamento: tentar novamente; vazio', (tester) async {
      repository.erroMeus = HttpServiceException(message: 'erroGeralApi', code: 500);
      await montar(tester, criar());
      expect(find.text('erroGeralApi'), findsOneWidget);

      repository
        ..erroMeus = null
        ..chamados = [];
      await tester.tap(find.text('tentarNovamente'));
      await tester.pumpAndSettle();
      expect(find.text('nenhumChamado'), findsOneWidget);
    });
  });
}
