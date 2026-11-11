import 'package:commons/commons.dart';
import 'package:intl/intl.dart';
import 'package:service/service.dart';

import '../../../../data/model/biblia/versiculo_indicado_model.dart';
import '../../biblia_leitura/use_case/biblia_leitura_usecase.dart';
import '../repository/versiculo_indicado_repository.dart';

/// Regras da tela "Indicações recebidas" (versículos que outros usuários indicaram ao usuário logado):
/// - a lista vem de `/v1/versiculo-indicacao-usuario/recebidas`, das mais recentes para as mais antigas (sem data
///   por último); 404 `registroNaoEncontrado` vira lista vazia;
/// - quem indicou aparece como "Nome (@usuario)", só o nome ou só "@usuario" ([quemIndicou]);
/// - a referência mostra a versão ([referencia], ex.: "Mateus 6:34 · BLIVRE");
/// - tocar abre o versículo na leitura, na versão em que foi indicado ([destino]);
/// - a data aparece como "dd/MM/yyyy HH:mm" ([data]).
class VersiculoIndicadoUseCase {
  VersiculoIndicadoUseCase({required this.versiculoIndicadoRepository}) {
    Log.print(super.runtimeType);
  }

  final VersiculoIndicadoRepository versiculoIndicadoRepository;

  Future<Result<List<VersiculoIndicadoModel>>> recebidas() async {
    final result = await versiculoIndicadoRepository.recebidas();
    switch (result) {
      case Ok<List<VersiculoIndicadoModel>>(value: final lista):
        return Result.ok(ordenar(lista));
      case Error<List<VersiculoIndicadoModel>>(error: final error):
        if (_semRegistros(error)) return const Result.ok([]);
        return result;
    }
  }

  /// Mais recentes primeiro; sem data por último.
  static List<VersiculoIndicadoModel> ordenar(List<VersiculoIndicadoModel> lista) => [...lista]
    ..sort((a, b) {
      final da = a.indicadoEm;
      final db = b.indicadoEm;
      if (da == null || db == null) return da == null ? (db == null ? 0 : 1) : -1;
      return db.compareTo(da);
    });

  /// Destino na leitura: o versículo, na versão em que foi indicado.
  static LeituraDestino destino(VersiculoIndicadoModel indicacao) => LeituraDestino(
    versaId: indicacao.versaId,
    livrId: indicacao.livrId,
    capiNumero: indicacao.capiNumero,
    versNumero: indicacao.versNumero,
  );

  /// "Livro Cap:Vers · VERSÃO"; sem a referência da API, monta com o nome do livro.
  static String referencia(VersiculoIndicadoModel indicacao) {
    final base =
        _texto(indicacao.versReferencia) ??
        '${_texto(indicacao.livrNome) ?? ''} ${indicacao.capiNumero}:${indicacao.versNumero}'.trim();
    final versao = _texto(indicacao.versaCodigo);
    return versao == null ? base : '$base · $versao';
  }

  /// "Nome (@usuario)", só o nome ou só "@usuario"; nulo sem nenhum dos dois.
  static String? quemIndicou(VersiculoIndicadoModel indicacao) {
    final nome = _texto(indicacao.indicadorNome);
    final usuario = _texto(indicacao.indicadorUsuario);
    if (nome != null && usuario != null) return '$nome (@$usuario)';
    return nome ?? (usuario == null ? null : '@$usuario');
  }

  /// Comentário sem espaços nas pontas; nulo se vazio.
  static String? comentario(VersiculoIndicadoModel indicacao) => _texto(indicacao.vindComentario);

  /// Data e hora como "dd/MM/yyyy HH:mm"; nula sem data.
  static String? data(VersiculoIndicadoModel indicacao) {
    final quando = indicacao.indicadoEm;
    return quando == null ? null : DateFormat('dd/MM/yyyy HH:mm').format(quando);
  }

  static String mensagemErro(Exception error) => switch (error) {
    HandledException(message: final message) => message,
    HttpServiceException(message: final message?) => message,
    _ => kDefaultAppError,
  };

  static String? _texto(String? valor) {
    final texto = valor?.trim();
    return (texto?.isEmpty ?? true) ? null : texto;
  }

  static bool _semRegistros(Exception error) =>
      (error is HttpServiceException && error.message == kRegistroNaoEncontrado) ||
      (error is HandledException && error.message == kRegistroNaoEncontrado);

  static const kRegistroNaoEncontrado = 'registroNaoEncontrado';
}
