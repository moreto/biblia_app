import 'package:app/data/model/configuracao/configuracao_app_model.dart';
import 'package:app/data/model/registro_model.dart';
import 'package:app/features/access/configuracao_app/repository/configuracao_app_repository.dart';
import 'package:app/features/access/configuracao_app/use_case/configuracao_app_usecase.dart';
import 'package:app/features/access/registro/repository/registro_repository.dart';
import 'package:app/features/access/registro/ui/registro_view.dart';
import 'package:app/features/access/registro/ui/registro_viewmodel.dart';
import 'package:app/features/access/registro/use_case/registro_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:service/service.dart';

/// Cadastro em memória: [cadastrados] simula e-mails já existentes; o código de ativação válido é [codigoValido].
class _FakeRegistroRepository implements RegistroRepository {
  final cadastrados = <String>{'existe@biblia.com'};
  final registros = <({String email, String senha})>[];
  final ativacoes = <({String email, String codigo})>[];
  static const codigoValido = '123456';

  @override
  Future<Result<RegistroModel>> registrar({required String email, required String senha}) async {
    registros.add((email: email, senha: senha));
    if (cadastrados.contains(email)) {
      return Result.error(HttpServiceException(message: 'emailJaCadastrado', code: 412));
    }
    cadastrados.add(email);
    return Result.ok(RegistroModel(usuaId: 10, usuaEmail: email, usuaUuid: 'uuid'));
  }

  @override
  Future<Result<void>> ativar({required String email, required String codigo}) async {
    ativacoes.add((email: email, codigo: codigo));
    if (codigo != codigoValido) {
      return Result.error(HttpServiceException(message: 'codigoAtivacaoInvalido', code: 400));
    }
    return const Result.ok(null);
  }
}

/// Chave AES-256 de teste devolvida como `kCryptKeyB64` pela configuração do app.
const _chaveTeste = '5oAaa+hIOTQzGUxHYn8o6mHfQqEi9PXb4kBGpCQ+fn0=';

class _FakeConfiguracaoAppRepository implements ConfiguracaoAppRepository {
  @override
  Future<Result<List<ConfiguracaoAppModel>>> listar() async =>
      const Result.ok([ConfiguracaoAppModel(citeChave: kConfCryptKeyB64, citeValor: _chaveTeste)]);
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
  late _FakeRegistroRepository repository;

  setUp(() {
    repository = _FakeRegistroRepository();
    AppSession.instance.clear();
  });

  RegistroUseCase useCase() => RegistroUseCase(
    registroRepository: repository,
    configuracaoAppUseCase: ConfiguracaoAppUseCase(configuracaoAppRepository: _FakeConfiguracaoAppRepository()),
  );

  group('RegistroUseCase', () {
    test('valida e-mail, senha mínima e confirmação', () {
      final uc = useCase();
      expect(uc.validateEmail(''), 'emailObrigatorio');
      expect(uc.validateEmail('x@'), 'emailInvalido');
      expect(uc.validateEmail(' a@b.com '), isNull);
      expect(uc.validateSenha(''), 'informeSenha');
      expect(uc.validateSenha('12345'), 'senhaMinimo6');
      expect(uc.validateSenha('123456'), isNull);
      expect(uc.validateConfirmacao('123456', ''), 'informeConfirmacaoSenha');
      expect(uc.validateConfirmacao('123456', '654321'), 'senhasDiferentes');
      expect(uc.validateConfirmacao('123456', '123456'), isNull);
      expect(uc.validateCodigo('12a456'), 'informeCodigo6Digitos');
    });

    test('criptografa a senha antes de enviar e apara o e-mail', () async {
      final result = await useCase().registrar(email: ' novo@biblia.com ', senha: 'segredo', confirmacao: 'segredo');
      expect(result, isA<Ok<RegistroModel>>());
      expect(repository.registros.single.email, 'novo@biblia.com');
      expect(repository.registros.single.senha, isNot('segredo'));
      expect(await Encrypt().decryptString(repository.registros.single.senha, _chaveTeste), 'segredo');
    });

    test('dados inválidos não chamam a API', () async {
      final result = await useCase().registrar(email: 'novo@biblia.com', senha: 'segredo', confirmacao: 'outra');
      expect(((result as Error).error as HandledException).message, 'senhasDiferentes');
      expect(repository.registros, isEmpty);
    });

    test('erro da API vira a chave de tradução', () async {
      final uc = useCase();
      final result = await uc.registrar(email: 'existe@biblia.com', senha: 'segredo', confirmacao: 'segredo');
      expect(uc.errorMessage((result as Error).error), 'emailJaCadastrado');
    });
  });

  group('RegistroViewmodel', () {
    test('cadastra, passa para a ativação e ativa com o e-mail cadastrado', () async {
      final viewModel = RegistroViewmodel(registroUseCase: useCase());
      expect(viewModel.etapa, RegistroEtapa.dados);

      await viewModel.registrarCommand.execute((email: 'novo@biblia.com', senha: 'segredo', confirmacao: 'segredo'));
      expect(viewModel.etapa, RegistroEtapa.ativacao);
      expect(viewModel.emailCadastrado, 'novo@biblia.com');

      await viewModel.ativarCommand.execute((email: viewModel.emailCadastrado!, codigo: '123456'));
      expect(viewModel.ativarCommand.completed, isTrue);
      expect(repository.ativacoes.single.email, 'novo@biblia.com');
    });

    test('e-mail já cadastrado mantém os dados de acesso', () async {
      final viewModel = RegistroViewmodel(registroUseCase: useCase());
      await viewModel.registrarCommand.execute((email: 'existe@biblia.com', senha: 'segredo', confirmacao: 'segredo'));
      expect(viewModel.etapa, RegistroEtapa.dados);
      expect(viewModel.errorMessage(viewModel.registrarCommand), 'emailJaCadastrado');
    });
  });

  group('RegistroView', () {
    /// Monta o login falso com um botão que abre o cadastro e guarda o e-mail devolvido.
    Future<List<String?>> montar(WidgetTester tester) async {
      // Tela de celular: o diálogo de erro (components) dimensiona os botões pela largura da tela.
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final devolvidos = <String?>[];
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async => devolvidos.add(await context.push<String>('/registro')),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/registro',
            builder: (context, state) => RegistroView(viewModel: RegistroViewmodel(registroUseCase: useCase())),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      return devolvidos;
    }

    Future<void> preencher(WidgetTester tester, {String confirmacao = 'segredo'}) async {
      await tester.enterText(find.widgetWithText(TextFormField, 'email'), 'novo@biblia.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'senha'), 'segredo');
      await tester.enterText(find.widgetWithText(TextFormField, 'confirmeSenha'), confirmacao);
    }

    testWidgets('valida os campos sem chamar a API', (tester) async {
      await montar(tester);
      await preencher(tester, confirmacao: 'outra');
      await tester.tap(find.widgetWithText(FilledButton, 'criarConta'));
      await tester.pumpAndSettle();
      expect(find.text('senhasDiferentes'), findsOneWidget);
      expect(repository.registros, isEmpty);
    });

    testWidgets('cadastra, ativa e volta ao login com o e-mail', (tester) async {
      final devolvidos = await montar(tester);
      await preencher(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'criarConta'));
      await tester.pumpAndSettle();

      expect(find.textContaining('novo@biblia.com'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'codigoAtivacao'), '123456');
      await tester.tap(find.widgetWithText(FilledButton, 'ativarConta'));
      await tester.pumpAndSettle();

      expect(devolvidos, ['novo@biblia.com']);
      expect(find.text('contaAtivadaFacaLogin'), findsOneWidget);
    });

    testWidgets('código inválido mostra o erro e continua na ativação', (tester) async {
      await montar(tester);
      await preencher(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'criarConta'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'codigoAtivacao'), '000000');
      await tester.tap(find.widgetWithText(FilledButton, 'ativarConta'));
      await tester.pumpAndSettle();
      expect(find.text('codigoAtivacaoInvalido'), findsOneWidget);
    });
  });
}
