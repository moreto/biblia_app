import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../data/model/comunidade/comunidade_denominacao_model.dart';
import '../../../data/model/comunidade/comunidade_model.dart';
import '../../../data/model/comunidade/comunidade_tipo_model.dart';
import '../repository/comunidade_repository.dart';

/// Abas da tela de comunidades, na ordem de exibição. [rotulo] é a chave de tradução e [icone], a chave em
/// `IconsMap.mdiIcons`. Novas abas entram aqui e em [ComunidadeUseCase.abas].
enum ComunidadeAba {
  minhas(rotulo: 'minhasComunidades', icone: 'account-group-outline');

  const ComunidadeAba({required this.rotulo, required this.icone});

  final String rotulo;
  final String icone;
}

/// Comunidade pronta para exibição, com os nomes do tipo e da denominação (nulos se não informados ou não
/// encontrados).
typedef ComunidadeResumo = ({ComunidadeModel comunidade, String? tipo, String? denominacao});

/// Regras da tela de comunidades:
/// - abas disponíveis em [abas];
/// - "Minhas comunidades" lista as comunidades cadastradas pelo usuário logado, por nome (sem diferenciar
///   maiúsculas) e id, com os nomes do tipo e da denominação;
/// - falha ao carregar tipos ou denominações não impede a lista: os nomes ficam de fora;
/// - 404 `registroNaoEncontrado` vira lista vazia (`nenhumaComunidadeCadastrada` na tela);
/// - sem usuário logado, `headerInvalido`.
class ComunidadeUseCase {
  ComunidadeUseCase({required this.comunidadeRepository, int? Function()? usuarioLogado})
    : _usuarioLogado = usuarioLogado ?? (() => AuthSession.instance.userId) {
    Log.print(super.runtimeType);
  }

  final ComunidadeRepository comunidadeRepository;

  /// Id do usuário logado; injetável para testes.
  final int? Function() _usuarioLogado;

  List<ComunidadeAba> get abas => ComunidadeAba.values;

  Future<Result<List<ComunidadeResumo>>> minhasComunidades() async {
    final usuaId = _usuarioLogado();
    if (usuaId == null) {
      return Result.error(HandledException(message: 'headerInvalido'));
    }

    final (comunidades, tipos, denominacoes) = await (
      comunidadeRepository.comunidadesDoUsuario(usuaId),
      comunidadeRepository.tipos(),
      comunidadeRepository.denominacoes(),
    ).wait;

    final List<ComunidadeModel> lista;
    switch (comunidades) {
      case Ok<List<ComunidadeModel>>(value: final value):
        lista = value;
      case Error<List<ComunidadeModel>>(error: final error):
        if (_semRegistros(error)) return const Result.ok([]);
        return Result.error(error);
    }

    final nomesTipo = switch (tipos) {
      Ok<List<ComunidadeTipoModel>>(value: final value) => {for (final t in value) t.ctipId: t.ctipNome},
      Error<List<ComunidadeTipoModel>>() => const <int, String>{},
    };
    final nomesDenominacao = switch (denominacoes) {
      Ok<List<ComunidadeDenominacaoModel>>(value: final value) => {for (final d in value) d.cdenId: d.cdenNome},
      Error<List<ComunidadeDenominacaoModel>>() => const <int, String>{},
    };

    return Result.ok(
      ordenar([
        for (final comunidade in lista)
          (
            comunidade: comunidade,
            tipo: _nome(nomesTipo[comunidade.ctipId]),
            denominacao: _nome(nomesDenominacao[comunidade.cdenId]),
          ),
      ]),
    );
  }

  static List<ComunidadeResumo> ordenar(Iterable<ComunidadeResumo> comunidades) {
    final lista = comunidades.toList();
    lista.sort((a, b) {
      final nome = a.comunidade.comuNome.trim().toLowerCase().compareTo(b.comunidade.comuNome.trim().toLowerCase());
      return nome != 0 ? nome : a.comunidade.comuId.compareTo(b.comunidade.comuId);
    });
    return List.unmodifiable(lista);
  }

  /// Linha de detalhe do card: "Tipo · Denominação", só com o que houver; nula se nenhum dos dois.
  static String? descricao(ComunidadeResumo resumo) {
    final partes = [resumo.tipo, resumo.denominacao].whereType<String>();
    return partes.isEmpty ? null : partes.join(' · ');
  }

  static String? _nome(String? nome) {
    final texto = nome?.trim();
    return (texto?.isEmpty ?? true) ? null : texto;
  }

  static bool _semRegistros(Exception error) =>
      (error is HttpServiceException && error.message == kRegistroNaoEncontrado) ||
      (error is HandledException && error.message == kRegistroNaoEncontrado);

  static const kRegistroNaoEncontrado = 'registroNaoEncontrado';
}
