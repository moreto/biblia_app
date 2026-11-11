import 'package:app/data/model/mensagem/mensagem_tipo_model.dart';
import 'package:app/data/model/usuario/usuario_resumo_model.dart';
import 'package:app/features/mensagem/mensagem_envio/repository/mensagem_envio_repository.dart';
import 'package:app/features/mensagem/mensagem_envio/ui/mensagem_envio_view.dart';
import 'package:app/features/mensagem/mensagem_envio/ui/mensagem_envio_viewmodel.dart';
import 'package:app/features/mensagem/mensagem_envio/use_case/mensagem_envio_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service/service.dart';

const _ana = UsuarioResumoModel(usuaId: 3, udetNome: 'Ana Souza', udetUsuario: 'ana');
const _bruno = UsuarioResumoModel(usuaId: 4, udetUsuario: 'bruno');

/// Envio em memória: tipos com o de sistema; destinatários em [falhaPara] falham.
class FakeMensagemEnvioRepository implements MensagemEnvioRepository {
  final buscas = <String>[];
  final mensagens = <(int, String, String)>[];
  final destinatarios = <(int, int)>[];
  final falhaPara = <int>{};
  Exception? erroGravar;

  @override
  Future<Result<List<MensagemTipoModel>>> tipos() async => const Result.ok([
    MensagemTipoModel(mtipId: 0, mtipTipo: 'Sistema'),
    MensagemTipoModel(mtipId: 1, mtipTipo: 'Usuário'),
  ]);

  @override
  Future<Result<List<UsuarioResumoModel>>> buscarUsuarios(String texto) async {
    buscas.add(texto);
    return Result.ok([
      for (final u in [_ana, _bruno])
        if ('${u.udetNome} ${u.udetUsuario}'.toLowerCase().contains(texto.toLowerCase())) u,
    ]);
  }

  @override
  Future<Result<int>> gravarMensagem({required int mtipId, required String titulo, required String texto}) async {
    final e = erroGravar;
    if (e != null) return Result.error(e);
    mensagens.add((mtipId, titulo, texto));
    return const Result.ok(99);
  }

  @override
  Future<Result<void>> incluirDestinatario({required int mensId, required int usuaId}) async {
    destinatarios.add((mensId, usuaId));
    return falhaPara.contains(usuaId)
        ? Result.error(HttpServiceException(message: 'erroGeralApi', code: 500))
        : const Result.ok(null);
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
  late FakeMensagemEnvioRepository repository;

  setUp(() => repository = FakeMensagemEnvioRepository());

  MensagemEnvioUseCase criarUseCase() => MensagemEnvioUseCase(mensagemEnvioRepository: repository);

  MensagemEnvioViewmodel criar() => MensagemEnvioViewmodel(mensagemEnvioUseCase: criarUseCase());

  /// Tela com um botão que abre o envio; [concluidos] guarda as mensagens de conclusão.
  Future<void> abrir(WidgetTester tester, MensagemEnvioViewmodel viewModel, List<String> concluidos) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => MensagemEnvioView.show(context, viewModel: viewModel, onConcluido: concluidos.add),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> buscarEAdicionar(WidgetTester tester, String texto, String nome) async {
    await tester.enterText(find.widgetWithText(TextField, 'buscarUsuario'), texto);
    await tester.pump(MensagemEnvioView.esperaBusca);
    await tester.pumpAndSettle();
    await tester.tap(find.text(nome));
    await tester.pumpAndSettle();
  }

  group('MensagemEnvioUseCase', () {
    test('tipos sem o de sistema; padrão é o primeiro restante', () async {
      final tipos = (await criarUseCase().tipos() as Ok<List<MensagemTipoModel>>).value;
      expect(tipos.map((t) => t.mtipId), [1]);
      expect(MensagemEnvioUseCase.tipoPadrao(tipos), 1);
      expect(MensagemEnvioUseCase.tipoPadrao(const []), isNull);
    });

    test('busca: mínimo de 2 caracteres e sem os já escolhidos', () async {
      final useCase = criarUseCase();
      expect((await useCase.buscar(' a ', const []) as Ok).value, isEmpty);
      expect(repository.buscas, isEmpty);
      final lista = (await useCase.buscar('an', const [_ana]) as Ok<List<UsuarioResumoModel>>).value;
      expect(lista, isEmpty, reason: 'Ana já escolhida');
    });

    test('adicionar não repete; remover tira', () {
      final dois = MensagemEnvioUseCase.adicionar(MensagemEnvioUseCase.adicionar(const [_ana], _ana), _bruno);
      expect(dois.map((u) => u.usuaId), [3, 4]);
      expect(MensagemEnvioUseCase.remover(dois, _ana).map((u) => u.usuaId), [4]);
    });

    test('validar: tipo (nunca o de sistema), destinatário, título e texto com limites', () {
      String? v({
        int? tipo = 1,
        List<UsuarioResumoModel> dest = const [_ana],
        String titulo = 'T',
        String texto = 'X',
      }) => MensagemEnvioUseCase.validar((mtipId: tipo, titulo: titulo, texto: texto, destinatarios: dest));
      expect(v(), isNull);
      expect(v(tipo: null), 'tipoMensagemObrigatorio');
      expect(v(tipo: 0), 'tipoMensagemObrigatorio', reason: 'sistema não pode ser enviado');
      expect(v(dest: const []), 'destinatarioObrigatorio');
      expect(v(titulo: '  '), 'tituloObrigatorio');
      expect(v(titulo: 'a' * 101), 'tituloMuitoLongo');
      expect(v(texto: ' '), 'textoObrigatorio');
      expect(v(texto: 'a' * 4001), 'textoMuitoLongo');
    });

    test('enviar grava a mensagem aparada e inclui cada destinatário; falha parcial é avisada', () async {
      final useCase = criarUseCase();
      final ok = await useCase.enviar((mtipId: 1, titulo: ' Oi ', texto: ' Tudo bem? ', destinatarios: const [_ana]));
      expect((ok as Ok<MensagemEnviada>).value.enviados, 1);
      expect(repository.mensagens.single, (1, 'Oi', 'Tudo bem?'));
      expect(repository.destinatarios.single, (99, 3));

      repository.falhaPara.add(4);
      final parcial = await useCase.enviar((mtipId: 1, titulo: 'T', texto: 'X', destinatarios: const [_ana, _bruno]));
      expect(((parcial as Error).error as HandledException).message, 'mensagemEnviadaParcialmente');
    });

    test('enviar inválido ou com erro ao gravar não inclui destinatários', () async {
      final useCase = criarUseCase();
      await useCase.enviar((mtipId: 0, titulo: 'T', texto: 'X', destinatarios: const [_ana]));
      repository.erroGravar = HttpServiceException(message: 'erroGeralApi', code: 500);
      final erro = await useCase.enviar((mtipId: 1, titulo: 'T', texto: 'X', destinatarios: const [_ana]));
      expect(erro, isA<Error<MensagemEnviada>>());
      expect(repository.destinatarios, isEmpty);
    });
  });

  group('MensagemEnvioView', () {
    testWidgets('abre no DialogBottomSheet com tipo padrão (sem Sistema); envia e fecha', (tester) async {
      final concluidos = <String>[];
      await abrir(tester, criar(), concluidos);

      expect(find.text('novaMensagem'), findsOneWidget, reason: 'título do sheet');
      expect(find.text('Usuário'), findsOneWidget, reason: 'tipo padrão');
      await tester.tap(find.text('Usuário'));
      await tester.pumpAndSettle();
      expect(find.text('Sistema'), findsNothing, reason: 'sistema fica de fora');
      await tester.tap(find.text('Usuário').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('enviar'));
      await tester.pumpAndSettle();
      expect(find.text('destinatarioObrigatorio'), findsOneWidget);

      await buscarEAdicionar(tester, 'ana', 'Ana Souza (@ana)');
      expect(find.widgetWithText(InputChip, 'Ana Souza (@ana)'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'titulo'), 'Encontro');
      await tester.enterText(find.widgetWithText(TextField, 'texto'), 'Sábado às 19h');
      await tester.ensureVisible(find.text('enviar'));
      await tester.tap(find.text('enviar'));
      await tester.pumpAndSettle();

      expect(repository.mensagens.single, (1, 'Encontro', 'Sábado às 19h'));
      expect(repository.destinatarios.single, (99, 3));
      expect(concluidos, ['mensagemEnviada']);
      expect(find.text('novaMensagem'), findsNothing, reason: 'fechou');
    });

    testWidgets('erro ao gravar fica no formulário; fechar pelo X não envia', (tester) async {
      repository.erroGravar = HttpServiceException(message: 'erroGeralApi', code: 500);
      final concluidos = <String>[];
      await abrir(tester, criar(), concluidos);
      await buscarEAdicionar(tester, 'bru', '@bruno');
      await tester.enterText(find.widgetWithText(TextField, 'titulo'), 'T');
      await tester.enterText(find.widgetWithText(TextField, 'texto'), 'X');
      await tester.ensureVisible(find.text('enviar'));
      await tester.tap(find.text('enviar'));
      await tester.pumpAndSettle();

      expect(find.text('erroGeralApi'), findsOneWidget);
      expect(concluidos, isEmpty);

      await tester.tap(find.byIcon(Icons.clear).first); // o X do sheet (o do chip vem depois)
      await tester.pumpAndSettle();
      expect(find.text('novaMensagem'), findsNothing);
    });

    testWidgets('abrir de novo começa um rascunho limpo', (tester) async {
      final viewModel = criar();
      await abrir(tester, viewModel, []);
      await buscarEAdicionar(tester, 'ana', 'Ana Souza (@ana)');
      await tester.tap(find.byIcon(Icons.clear).first); // o X do sheet (o do chip vem depois)
      await tester.pumpAndSettle();

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(InputChip), findsNothing);
      expect(viewModel.destinatarios, isEmpty);
    });
  });
}
