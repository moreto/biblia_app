import 'package:app/config/usuario_session.dart';
import 'package:app/data/model/configuracao/configuracao_app_model.dart';
import 'package:app/data/model/usuario/usuario_configuracao_model.dart';
import 'package:app/data/model/usuario/usuario_detalhe_model.dart';
import 'package:app/features/access/configuracao_app/repository/configuracao_app_repository.dart';
import 'package:app/features/access/configuracao_app/use_case/configuracao_app_usecase.dart';
import 'package:app/features/usuario/repository/usuario_repository.dart';
import 'package:app/features/usuario/ui/usuario_view.dart';
import 'package:app/features/usuario/ui/usuario_viewmodel.dart';
import 'package:app/features/usuario/use_case/usuario_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service/service.dart';

const _chaveTeste = '5oAaa+hIOTQzGUxHYn8o6mHfQqEi9PXb4kBGpCQ+fn0=';

/// Usuário em memória, com as regras da API: nome de usuário de outro usuário dá 409; senha atual errada dá 401;
/// sem configuração o GET dá 404 e o POST com configuração existente dá 409.
class _FakeUsuarioRepository implements UsuarioRepository {
  UsuarioDetalheModel usuario = const UsuarioDetalheModel(
    usuaId: 7,
    usuaUuid: '0b6f-uuid',
    usuaEmail: 'maria@biblia.com',
    usuaAtivo: true,
    udetNome: 'Maria da Silva',
    udetUsuario: 'maria',
  );
  UsuarioConfiguracaoModel? gravada;
  final usuariosDeOutros = <String>{'joao'};
  String senha = 'segredo';

  final detalhesGravados = <UsuarioDetalheBodyModel>[];
  final senhas = <({String atual, String nova})>[];
  final inclusoes = <UsuarioConfiguracaoModel>[];
  final alteracoes = <UsuarioConfiguracaoModel>[];
  Exception? erroDetalhe;

  /// Simula a configuração gravada em outro aparelho depois do carregamento.
  UsuarioConfiguracaoModel? gravadaEmOutroAparelho;

  @override
  Future<Result<UsuarioDetalheModel>> detalhe() async {
    final e = erroDetalhe;
    return e == null ? Result.ok(usuario) : Result.error(e);
  }

  @override
  Future<Result<UsuarioDetalheModel>> alterarDetalhe(UsuarioDetalheBodyModel body) async {
    detalhesGravados.add(body);
    if (usuariosDeOutros.contains(body.udetUsuario.toLowerCase())) {
      return Result.error(HttpServiceException(message: 'nomeUsuarioDuplicado', code: 409));
    }
    usuario = UsuarioDetalheModel(
      usuaId: usuario.usuaId,
      usuaUuid: usuario.usuaUuid,
      usuaEmail: usuario.usuaEmail,
      usuaAtivo: usuario.usuaAtivo,
      udetNome: body.udetNome,
      udetUsuario: body.udetUsuario,
    );
    return Result.ok(usuario);
  }

  @override
  Future<Result<void>> alterarSenha({required String senhaAtual, required String novaSenha}) async {
    final atual = await Encrypt().decryptString(senhaAtual, _chaveTeste);
    final nova = await Encrypt().decryptString(novaSenha, _chaveTeste);
    senhas.add((atual: atual, nova: nova));
    if (atual != senha) return Result.error(HttpServiceException(message: 'senhaAtualInvalida', code: 401));
    senha = nova;
    return const Result.ok(null);
  }

  @override
  Future<Result<UsuarioConfiguracaoModel>> configuracao() async {
    final atual = gravada ?? gravadaEmOutroAparelho;
    if (atual == null) return Result.error(HttpServiceException(message: 'registroNaoEncontrado', code: 404));
    return Result.ok(atual);
  }

  @override
  Future<Result<UsuarioConfiguracaoModel>> incluirConfiguracao(UsuarioConfiguracaoModel configuracao) async {
    inclusoes.add(configuracao);
    if (gravada != null || gravadaEmOutroAparelho != null) {
      return Result.error(HttpServiceException(message: 'usuarioConfiguracaoDuplicada', code: 409));
    }
    gravada = configuracao.copyWith(uconId: 1);
    return Result.ok(gravada!);
  }

  @override
  Future<Result<UsuarioConfiguracaoModel>> alterarConfiguracao(UsuarioConfiguracaoModel configuracao) async {
    alteracoes.add(configuracao);
    gravada = configuracao;
    return Result.ok(configuracao);
  }
}

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
  late _FakeUsuarioRepository repository;

  setUp(() {
    repository = _FakeUsuarioRepository();
    AppSession.instance.clear();
    UsuarioSession.instance.clear();
  });

  UsuarioUseCase criarUseCase() => UsuarioUseCase(
    usuarioRepository: repository,
    configuracaoAppUseCase: ConfiguracaoAppUseCase(configuracaoAppRepository: _FakeConfiguracaoAppRepository()),
  );

  UsuarioViewmodel criar() => UsuarioViewmodel(usuarioUseCase: criarUseCase());

  Future<void> montar(WidgetTester tester, UsuarioViewmodel viewModel) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        home: UsuarioView(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> abrirAba(WidgetTester tester, String rotulo) async {
    await tester.tap(find.text(rotulo));
    await tester.pumpAndSettle();
  }

  group('models', () {
    test('UsuarioDetalheModel.fromJson aceita camelCase e snake_case, sem empresa e sem detalhe', () {
      final camel = UsuarioDetalheModel.fromJson({
        'usuaId': 7,
        'usuaUuid': 'u',
        'usuaEmail': 'a@b.com',
        'usuaAtivo': true,
        'udetNome': 'Ana',
        'udetUsuario': 'ana',
      });
      expect(
        (camel.usuaId, camel.udetNome, camel.udetUsuario, camel.usuaAtivo, camel.emprId),
        (7, 'Ana', 'ana', true, null),
      );

      final snake = UsuarioDetalheModel.fromJson({'usua_id': '8', 'usua_email': 'b@c.com', 'usua_ativo': false});
      expect(
        (snake.usuaId, snake.usuaEmail, snake.udetNome, snake.udetUsuario, snake.usuaAtivo),
        (8, 'b@c.com', '', '', false),
      );
      expect(() => UsuarioDetalheModel.fromJson({'usuaEmail': 'x'}), throwsFormatException);
    });

    test('UsuarioConfiguracaoModel lê e grava o campo com o nome real da API (Notificacacao)', () {
      final json = {
        'uconId': 3,
        'usuaId': 7,
        'uconEmailVersiculo': true,
        'uconEmailComunidade': false,
        'uconEmailLeitura': true,
        'uconLeituraAberto': false,
        'uconQuantidadeLogsAcesso': 50,
        'uconQuantidadeLogsNotificacacao': 20,
        'uconEmailFaleConosco': true,
        'createdAt': '2026-11-17T10:00:00.000Z',
        'updateAt': null,
      };
      final model = UsuarioConfiguracaoModel.fromJson(json);
      expect((model.uconId, model.emailComunidade, model.quantidadeLogsNotificacao), (3, false, 20));
      expect(model.createdAt, DateTime.utc(2026, 11, 17, 10).toLocal());
      expect(model.toJson(), {
        'uconId': 3,
        'uconEmailVersiculo': true,
        'uconEmailComunidade': false,
        'uconEmailLeitura': true,
        'uconLeituraAberto': false,
        'uconQuantidadeLogsAcesso': 50,
        'uconQuantidadeLogsNotificacacao': 20,
        'uconEmailFaleConosco': true,
      });
      expect(UsuarioUseCase.configuracaoPadrao.toJson().containsKey('uconId'), isFalse);
      expect(() => UsuarioConfiguracaoModel.fromJson({...json, 'uconEmailLeitura': 'sim'}), throwsFormatException);
    });
  });

  group('UsuarioUseCase', () {
    test('validações de nome, usuário e senha', () {
      final useCase = criarUseCase();
      expect(useCase.validateNome('  '), 'informeNomeCompleto');
      expect(useCase.validateNome('x' * 71), 'nomeCompletoMaximo70');
      expect(useCase.validateNome('Maria'), isNull);
      expect(useCase.validateUsuario(''), 'informeNomeUsuario');
      expect(useCase.validateUsuario('ma'), 'nomeUsuarioInvalido');
      expect(useCase.validateUsuario('má.ria'), 'nomeUsuarioInvalido');
      expect(useCase.validateUsuario('ma ria'), 'nomeUsuarioInvalido');
      expect(useCase.validateUsuario('maria_2.0-x'), isNull);
      expect(useCase.validateSenhaAtual(''), 'informeSenhaAtual');
      expect(useCase.validateNovaSenha('a', ''), 'informeNovaSenha');
      expect(useCase.validateNovaSenha('a', '12345'), 'senhaMinimo6');
      expect(useCase.validateNovaSenha('segredo', 'segredo'), 'novaSenhaIgualAtual');
      expect(useCase.validateConfirmacao('123456', ''), 'informeConfirmacaoSenha');
      expect(useCase.validateConfirmacao('123456', '123457'), 'senhasDiferentes');
      expect(useCase.validateQuantidade(-1), 'quantidadeInvalida');
      expect(useCase.validateQuantidade(0), isNull);
    });

    test('carregar usa a configuração padrão sem configuração gravada e atualiza a sessão', () async {
      final result = await criarUseCase().carregar();
      final dados = (result as Ok<UsuarioDados>).value;
      expect(dados.detalhe.udetUsuario, 'maria');
      expect(dados.configuracao.uconId, isNull);
      expect(dados.configuracao.mesmosValores(UsuarioUseCase.configuracaoPadrao), isTrue);
      expect(UsuarioSession.instance.usuarioDetalhe?.usuaEmail, 'maria@biblia.com');
    });

    test('carregar devolve o erro do detalhe', () async {
      repository.erroDetalhe = HttpServiceException(message: 'erroGeralApi', code: 500);
      final result = await criarUseCase().carregar();
      expect(UsuarioUseCase.mensagemErro((result as Error).error), 'erroGeralApi');
    });

    test('salvarDados grava sem espaços nas pontas e não chama a API sem alteração', () async {
      final useCase = criarUseCase();
      final atual = repository.usuario;
      final igual = await useCase.salvarDados(atual: atual, nome: ' Maria da Silva ', usuario: 'maria ');
      expect(igual, isA<Ok<UsuarioDetalheModel>>());
      expect(repository.detalhesGravados, isEmpty);

      final result = await useCase.salvarDados(atual: atual, nome: '  Maria Souza ', usuario: ' maria.souza ');
      expect((result as Ok<UsuarioDetalheModel>).value.udetNome, 'Maria Souza');
      expect(repository.detalhesGravados.single.toJson(), {'udetNome': 'Maria Souza', 'udetUsuario': 'maria.souza'});
      expect(UsuarioSession.instance.usuarioDetalhe?.udetUsuario, 'maria.souza');
    });

    test('salvarDados valida antes de chamar a API e repassa o 409', () async {
      final useCase = criarUseCase();
      final invalido = await useCase.salvarDados(atual: repository.usuario, nome: 'Maria', usuario: 'm');
      expect(UsuarioUseCase.mensagemErro((invalido as Error).error), 'nomeUsuarioInvalido');
      expect(repository.detalhesGravados, isEmpty);

      final duplicado = await useCase.salvarDados(atual: repository.usuario, nome: 'Maria', usuario: 'Joao');
      expect(UsuarioUseCase.mensagemErro((duplicado as Error).error), 'nomeUsuarioDuplicado');
    });

    test('alterarSenha valida, criptografa as duas senhas e repassa senha atual inválida', () async {
      final useCase = criarUseCase();
      final igual = await useCase.alterarSenha(senhaAtual: 'segredo', novaSenha: 'segredo', confirmacao: 'segredo');
      expect(UsuarioUseCase.mensagemErro((igual as Error).error), 'novaSenhaIgualAtual');
      expect(repository.senhas, isEmpty);

      final errada = await useCase.alterarSenha(senhaAtual: 'errada', novaSenha: 'nova123', confirmacao: 'nova123');
      expect(UsuarioUseCase.mensagemErro((errada as Error).error), 'senhaAtualInvalida');

      final ok = await useCase.alterarSenha(senhaAtual: 'segredo', novaSenha: 'nova123', confirmacao: 'nova123');
      expect(ok, isA<Ok<void>>());
      expect(repository.senhas.last, (atual: 'segredo', nova: 'nova123'));
      expect(repository.senha, 'nova123');
    });

    test('salvarConfiguracao inclui a primeira e altera a existente', () async {
      final useCase = criarUseCase();
      final incluida = await useCase.salvarConfiguracao(
        UsuarioUseCase.configuracaoPadrao.copyWith(emailLeitura: false),
      );
      expect((incluida as Ok<UsuarioConfiguracaoModel>).value.uconId, 1);
      expect(repository.inclusoes.single.emailLeitura, isFalse);

      await useCase.salvarConfiguracao(incluida.value.copyWith(quantidadeLogsAcesso: 100));
      expect(repository.alteracoes.single.uconId, 1);
      expect(repository.alteracoes.single.quantidadeLogsAcesso, 100);
    });

    test('salvarConfiguracao com 409 (gravada em outro aparelho) lê a existente e altera', () async {
      repository.gravadaEmOutroAparelho = UsuarioUseCase.configuracaoPadrao.copyWith(uconId: 9);
      final result = await criarUseCase().salvarConfiguracao(
        UsuarioUseCase.configuracaoPadrao.copyWith(emailVersiculo: false),
      );
      expect((result as Ok<UsuarioConfiguracaoModel>).value.uconId, 9);
      expect(repository.alteracoes.single.emailVersiculo, isFalse);
    });

    test('textos: iniciais, opções de quantidade e alteração', () {
      expect(UsuarioUseCase.iniciais(repository.usuario), 'MS');
      expect(
        UsuarioUseCase.iniciais(
          const UsuarioDetalheModel(
            usuaId: 1,
            usuaUuid: '',
            usuaEmail: 'ze@x.com',
            usuaAtivo: true,
            udetNome: '',
            udetUsuario: '',
          ),
        ),
        'Z',
      );
      expect(UsuarioUseCase.opcoesQuantidade(30), [0, 10, 25, 30, 50, 100, 200, 500]);
      expect(UsuarioUseCase.opcoesQuantidade(50), UsuarioUseCase.quantidadesSugeridas);
      expect(UsuarioUseCase.dadosAlterados(repository.usuario, 'Maria da Silva ', 'maria'), isFalse);
      expect(UsuarioUseCase.dadosAlterados(repository.usuario, 'Maria', 'maria'), isTrue);
    });
  });

  group('UsuarioViewmodel', () {
    test('carrega ao ser criado e edita a configuração sem gravar', () async {
      final vm = criar();
      await pumpEventQueue();
      expect(vm.detalhe?.usuaEmail, 'maria@biblia.com');
      expect(vm.configuracaoPadrao, isTrue);
      expect(vm.configuracaoAlterada, isTrue, reason: 'configuração padrão ainda não gravada');

      vm.alterarOpcao(UsuarioConfiguracaoOpcao.emailComunidade, false);
      vm.alterarQuantidade(UsuarioConfiguracaoQuantidade.logsNotificacao, 10);
      expect(vm.opcao(UsuarioConfiguracaoOpcao.emailComunidade), isFalse);
      expect(vm.quantidade(UsuarioConfiguracaoQuantidade.logsNotificacao), 10);
      expect(repository.inclusoes, isEmpty);

      await vm.salvarConfiguracaoCommand.execute();
      expect(vm.configuracaoPadrao, isFalse);
      expect(vm.configuracaoAlterada, isFalse);
      expect(repository.gravada?.emailComunidade, isFalse);

      vm.alterarOpcao(UsuarioConfiguracaoOpcao.leituraAberto, true);
      expect(vm.configuracaoAlterada, isTrue);
      vm.descartarConfiguracao();
      expect(vm.configuracaoAlterada, isFalse);
    });
  });

  group('UsuarioView', () {
    testWidgets('mostra as abas e os dados cadastrais, com e-mail só leitura', (tester) async {
      await montar(tester, criar());

      expect(find.text('meusDados'), findsOneWidget);
      expect(find.text('dadosCadastrais'), findsOneWidget);
      expect(find.text('senha'), findsOneWidget);
      expect(find.text('configuracoes'), findsOneWidget);
      expect(find.text('MS'), findsOneWidget);
      expect(find.text('@maria'), findsOneWidget);
      expect(find.text('maria@biblia.com'), findsOneWidget);
      expect(find.text('emailNaoAlteravel'), findsOneWidget);
      expect(find.text('0b6f-uuid'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Maria da Silva'), findsOneWidget);
    });

    testWidgets('salva nome e usuário alterados e avisa dadosSalvos', (tester) async {
      await montar(tester, criar());

      await tester.enterText(find.widgetWithText(TextFormField, 'Maria da Silva'), 'Maria Souza');
      await tester.enterText(find.widgetWithText(TextFormField, 'maria'), 'maria.souza');
      await tester.pump();
      await tester.tap(find.text('salvar'));
      await tester.pumpAndSettle();

      expect(repository.detalhesGravados.single.udetUsuario, 'maria.souza');
      expect(find.text('dadosSalvos'), findsOneWidget);
      expect(find.text('@maria.souza'), findsOneWidget);
    });

    testWidgets('nome de usuário inválido mostra o erro no campo e não grava', (tester) async {
      await montar(tester, criar());

      await tester.enterText(find.widgetWithText(TextFormField, 'maria'), 'ma ria');
      await tester.pump();
      await tester.tap(find.text('salvar'));
      await tester.pumpAndSettle();

      expect(repository.detalhesGravados, isEmpty);
      expect(find.text('nomeUsuarioInvalido'), findsWidgets);
    });

    testWidgets('nome de usuário de outro usuário vira SnackBar', (tester) async {
      await montar(tester, criar());

      await tester.enterText(find.widgetWithText(TextFormField, 'maria'), 'joao');
      await tester.pump();
      await tester.tap(find.text('salvar'));
      await tester.pumpAndSettle();

      expect(find.text('nomeUsuarioDuplicado'), findsOneWidget);
    });

    testWidgets('altera a senha, avisa e limpa os campos', (tester) async {
      await montar(tester, criar());
      await abrirAba(tester, 'senha');

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'segredo');
      await tester.enterText(campos.at(1), 'nova123');
      await tester.enterText(campos.at(2), 'nova123');
      await tester.tap(find.text('alterarSenha'));
      await tester.pumpAndSettle();

      expect(repository.senha, 'nova123');
      expect(find.text('senhaAlterada'), findsOneWidget);
      expect(find.text('segredo'), findsNothing);
    });

    testWidgets('confirmação diferente mostra o erro e não chama a API', (tester) async {
      await montar(tester, criar());
      await abrirAba(tester, 'senha');

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'segredo');
      await tester.enterText(campos.at(1), 'nova123');
      await tester.enterText(campos.at(2), 'outra12');
      await tester.tap(find.text('alterarSenha'));
      await tester.pumpAndSettle();

      expect(repository.senhas, isEmpty);
      expect(find.text('senhasDiferentes'), findsOneWidget);
    });

    testWidgets('configurações: aviso de padrão, troca uma opção e salva', (tester) async {
      await montar(tester, criar());
      await abrirAba(tester, 'configuracoes');

      expect(find.text('configuracaoPadraoAviso'), findsOneWidget);
      expect(find.text('avisosPorEmail'), findsOneWidget);
      await tester.tap(find.text('configEmailVersiculo'));
      await tester.pump();
      await tester.tap(find.text('salvar'));
      await tester.pumpAndSettle();

      expect(repository.inclusoes.single.emailVersiculo, isFalse);
      expect(find.text('configuracoesSalvas'), findsOneWidget);
      expect(find.text('configuracaoPadraoAviso'), findsNothing);
    });

    testWidgets('erro no primeiro carregamento mostra tentar novamente', (tester) async {
      repository.erroDetalhe = HttpServiceException(message: 'erroGeralApi', code: 500);
      await montar(tester, criar());

      expect(find.text('erroGeralApi'), findsOneWidget);
      repository.erroDetalhe = null;
      await tester.tap(find.text('tentarNovamente'));
      await tester.pumpAndSettle();
      expect(find.text('@maria'), findsOneWidget);
    });
  });
}
