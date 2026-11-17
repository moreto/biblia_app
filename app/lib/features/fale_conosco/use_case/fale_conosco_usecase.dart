import 'package:commons/commons.dart';
import 'package:intl/intl.dart';
import 'package:service/service.dart';

import '../../../data/model/configuracao/configuracao_item_model.dart';
import '../../../data/model/configuracao/configuracao_model.dart';
import '../../../data/model/fale_conosco/fale_conosco_model.dart';
import '../../../data/model/usuario/usuario_detalhe_model.dart';
import '../repository/fale_conosco_repository.dart';

/// Opção de uma configuração do Fale Conosco: [chave] (`cite_chave`, gravada no chamado) e [rotulo] (`cite_valor`,
/// chave de tradução).
typedef FaleConoscoOpcao = ({int chave, String rotulo});

/// Configurações do Fale Conosco usadas pela tela: categorias do formulário, rótulos das situações e a origem "app".
class FaleConoscoOpcoes {
  const FaleConoscoOpcoes({this.categorias = const [], this.situacoes = const [], this.origemApp});

  final List<FaleConoscoOpcao> categorias;
  final List<FaleConoscoOpcao> situacoes;

  /// `cite_chave` da origem `app`; nula se a configuração não tiver.
  final int? origemApp;
}

/// Chamados do usuário e as opções das configurações.
class FaleConoscoDados {
  const FaleConoscoDados({required this.chamados, required this.opcoes});

  final List<FaleConoscoModel> chamados;
  final FaleConoscoOpcoes opcoes;
}

/// Campos do formulário "Nova mensagem".
typedef FaleConoscoFormulario = ({
  String nome,
  String email,
  String telefone,
  String assunto,
  String mensagem,
  int? categoria,
});

/// Regras da tela "Fale conosco" (chamados do usuário logado):
/// - [carregar] traz os chamados (`/v1/fale-conosco/meus`, mais recentes primeiro) e as opções das configurações
///   `faleConoscoCategoria`, `faleConoscoStatus` e `faleConoscoOrigem` (`/v1/configuracao` e
///   `/v1/configuracao-item/:confId`; a configuração é achada pelo `confCodigo` ou, se a API não o devolver, pelo
///   nome). Só itens ativos, na ordem de `cite_sequencia`; o `cite_valor` é a chave de tradução do rótulo;
/// - [validar] confere o formulário com os limites da API (nome até [nomeMaximo], e-mail até [emailMaximo] e no
///   formato texto@dominio.ext, telefone opcional até [telefoneMaximo], assunto até [assuntoMaximo], mensagem até
///   [textoMaximo] e categoria obrigatória); [enviar] valida, tira os espaços das pontas e grava com a origem "app";
/// - [detalhe] traz o chamado com as interações; [responder] grava a mensagem do usuário e devolve o chamado
///   atualizado. Chamado fechado não aceita mensagem (`chamadoFechado`);
/// - o formulário começa com o nome e o e-mail do usuário logado ([prefixoNome], [prefixoEmail]);
/// - textos: [rotulo] (chave de tradução da opção; `?` se o código não estiver na configuração) e [data].
class FaleConoscoUseCase {
  FaleConoscoUseCase({required this.faleConoscoRepository, UsuarioDetalheModel? Function()? usuario})
    : _usuario = usuario ?? (() => null) {
    Log.print(super.runtimeType);
  }

  final FaleConoscoRepository faleConoscoRepository;
  final UsuarioDetalheModel? Function() _usuario;

  static const nomeMaximo = 150;
  static const emailMaximo = 90;
  static const telefoneMaximo = 20;
  static const assuntoMaximo = 150;
  static const textoMaximo = 4000;

  /// Configurações (código e nome, para quando a API não devolver o código).
  static const kConfigCategoria = (codigo: 'faleConoscoCategoria', nome: 'Fale Conosco - Categoria');
  static const kConfigStatus = (codigo: 'faleConoscoStatus', nome: 'Fale Conosco - Situação');
  static const kConfigOrigem = (codigo: 'faleConoscoOrigem', nome: 'Fale Conosco - Origem');

  /// `cite_valor` da origem deste app em `faleConoscoOrigem`.
  static const kOrigemApp = 'app';

  static const kChamadoFechado = 'chamadoFechado';
  static const kIndisponivel = 'faleConoscoIndisponivel';

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  String get prefixoNome => _usuario()?.udetNome.trim() ?? '';

  String get prefixoEmail => _usuario()?.usuaEmail.trim() ?? '';

  Future<Result<FaleConoscoDados>> carregar() async {
    final (chamados, opcoes) = await (faleConoscoRepository.meus(), _opcoes()).wait;
    switch ((chamados, opcoes)) {
      case (Ok(value: final lista), Ok(value: final opcoes)):
        return Result.ok(FaleConoscoDados(chamados: ordenar(lista), opcoes: opcoes));
      case (Error(error: final error), _) || (_, Error(error: final error)):
        return Result.error(error);
    }
  }

  Future<Result<FaleConoscoOpcoes>> _opcoes() async {
    final configuracoes = await faleConoscoRepository.configuracoes();
    final List<ConfiguracaoModel> lista;
    switch (configuracoes) {
      case Ok(value: final value):
        lista = value;
      case Error(error: final error):
        return Result.error(error);
    }

    final (categorias, situacoes, origens) = await (
      _itens(lista, kConfigCategoria),
      _itens(lista, kConfigStatus),
      _itens(lista, kConfigOrigem),
    ).wait;
    switch ((categorias, situacoes, origens)) {
      case (Ok(value: final categorias), Ok(value: final situacoes), Ok(value: final origens)):
        return Result.ok(
          FaleConoscoOpcoes(
            categorias: categorias,
            situacoes: situacoes,
            origemApp: origens.where((o) => o.rotulo == kOrigemApp).firstOrNull?.chave,
          ),
        );
      case (Error(error: final error), _, _) || (_, Error(error: final error), _) || (_, _, Error(error: final error)):
        return Result.error(error);
    }
  }

  /// Itens ativos da configuração, em ordem; lista vazia se a configuração não existir.
  Future<Result<List<FaleConoscoOpcao>>> _itens(
    List<ConfiguracaoModel> configuracoes,
    ({String codigo, String nome}) config,
  ) async {
    final confId = configuracao(configuracoes, codigo: config.codigo, nome: config.nome)?.confId;
    if (confId == null) return const Result.ok([]);
    final result = await faleConoscoRepository.itens(confId);
    return switch (result) {
      Ok(value: final itens) => Result.ok(opcoes(itens)),
      Error(error: final error) => _semRegistros(error) ? const Result.ok([]) : Result.error(error),
    };
  }

  /// Configuração pelo [codigo]; se a API não devolver códigos, pelo [nome].
  static ConfiguracaoModel? configuracao(
    List<ConfiguracaoModel> configuracoes, {
    required String codigo,
    required String nome,
  }) =>
      configuracoes.where((c) => c.confCodigo == codigo).firstOrNull ??
      configuracoes.where((c) => c.confCodigo == null && c.confNome.trim() == nome).firstOrNull;

  /// Itens ativos com chave inteira e rótulo, na ordem de `cite_sequencia` (sem sequência por último).
  static List<FaleConoscoOpcao> opcoes(List<ConfiguracaoItemModel> itens) {
    final ativos = [
      for (final item in itens)
        if (item.citeAtivo && int.tryParse(item.citeChave?.trim() ?? '') != null && (item.citeValor ?? '').trim() != '')
          item,
    ]..sort((a, b) => (a.citeSequencia ?? 1 << 30).compareTo(b.citeSequencia ?? 1 << 30));
    return [for (final i in ativos) (chave: int.parse(i.citeChave!.trim()), rotulo: i.citeValor!.trim())];
  }

  /// Mais recentes primeiro (pela data de envio; sem data, pelo id).
  static List<FaleConoscoModel> ordenar(List<FaleConoscoModel> chamados) => [...chamados]
    ..sort((a, b) {
      final da = a.createdAt;
      final db = b.createdAt;
      if (da != null && db != null && da != db) return db.compareTo(da);
      return b.fconId.compareTo(a.fconId);
    });

  /// Problema do formulário (chave de tradução); nulo se pode enviar.
  static String? validar(FaleConoscoFormulario f) {
    final nome = f.nome.trim();
    final email = f.email.trim();
    final assunto = f.assunto.trim();
    final mensagem = f.mensagem.trim();
    if (nome.isEmpty) return 'informeNome';
    if (nome.length > nomeMaximo) return 'nomeMuitoLongo';
    if (email.isEmpty) return 'informeEmail';
    if (email.length > emailMaximo || !_email.hasMatch(email)) return 'emailInvalido';
    if (f.telefone.trim().length > telefoneMaximo) return 'telefoneMuitoLongo';
    if (f.categoria == null) return 'informeCategoria';
    if (assunto.isEmpty) return 'informeAssunto';
    if (assunto.length > assuntoMaximo) return 'assuntoMuitoLongo';
    if (mensagem.isEmpty) return 'informeMensagem';
    if (mensagem.length > textoMaximo) return 'mensagemMuitoLonga';
    return null;
  }

  /// Valida e abre o chamado com a origem "app" ([FaleConoscoOpcoes.origemApp]).
  Future<Result<FaleConoscoEnvioModel>> enviar(FaleConoscoFormulario f, FaleConoscoOpcoes opcoes) async {
    final erro = validar(f);
    if (erro != null) return Result.error(HandledException(message: erro));
    final origem = opcoes.origemApp;
    if (origem == null) return Result.error(HandledException(message: kIndisponivel));
    final telefone = f.telefone.trim();
    return faleConoscoRepository.enviar(
      FaleConoscoBodyModel(
        fconNome: f.nome.trim(),
        fconEmail: f.email.trim(),
        fconTelefone: telefone.isEmpty ? null : telefone,
        fconAssunto: f.assunto.trim(),
        fconMensagem: f.mensagem.trim(),
        fconCategoria: f.categoria!,
        fconOrigem: origem,
      ),
    );
  }

  Future<Result<FaleConoscoModel>> detalhe(int fconId) => faleConoscoRepository.meu(fconId);

  /// Grava a mensagem do usuário no [chamado] e devolve o chamado atualizado.
  Future<Result<FaleConoscoModel>> responder(FaleConoscoModel chamado, String texto) async {
    if (chamado.fechado) return Result.error(HandledException(message: kChamadoFechado));
    final mensagem = texto.trim();
    if (mensagem.isEmpty) return Result.error(HandledException(message: 'informeMensagem'));
    if (mensagem.length > textoMaximo) return Result.error(HandledException(message: 'mensagemMuitoLonga'));
    final result = await faleConoscoRepository.responder(fconId: chamado.fconId, texto: mensagem);
    if (result case Error(error: final error)) {
      // 404: o chamado foi fechado (ou excluído) depois de aberto na tela.
      return Result.error(_semRegistros(error) ? HandledException(message: kChamadoFechado) : error);
    }
    return detalhe(chamado.fconId);
  }

  /// Rótulo (chave de tradução) do código nas [opcoes]; `?` se não estiver na configuração.
  static String rotulo(List<FaleConoscoOpcao> opcoes, int? chave) =>
      opcoes.where((o) => o.chave == chave).firstOrNull?.rotulo ?? '?';

  /// Data e hora como "dd/MM/yyyy HH:mm"; nula sem data.
  static String? data(DateTime? quando) => quando == null ? null : DateFormat('dd/MM/yyyy HH:mm').format(quando);

  static String mensagemErro(Exception error) => switch (error) {
    HandledException(message: final message) => message,
    HttpServiceException(message: final message?) => message,
    _ => kDefaultAppError,
  };

  static bool _semRegistros(Exception error) =>
      (error is HttpServiceException && error.message == kRegistroNaoEncontrado) ||
      (error is HandledException && error.message == kRegistroNaoEncontrado);

  static const kRegistroNaoEncontrado = 'registroNaoEncontrado';
}
