import 'package:commons/commons.dart';
import 'package:service/service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../data/model/musica/musica_model.dart';
import '../repository/musica_repository.dart';

/// Abre [url] fora do app; devolve `false` se nenhum app/navegador aceitar o link.
typedef AbrirUrl = Future<bool> Function(Uri url);

Future<bool> _abrirExterno(Uri url) => launchUrl(url, mode: LaunchMode.externalApplication);

class MusicaUseCase {
  MusicaUseCase({required this.musicaRepository, AbrirUrl? abrirUrl}) : _abrirUrl = abrirUrl ?? _abrirExterno {
    Log.print(super.runtimeType);
  }

  final MusicaRepository musicaRepository;
  final AbrirUrl _abrirUrl;

  /// Sorteia uma música. A API responde 404 `registroNaoEncontrado` quando não há músicas cadastradas;
  /// esse caso vira `nenhumaMusicaCadastrada`, para o card não mostrar uma mensagem genérica.
  Future<Result<MusicaModel>> aleatoria() async {
    final result = await musicaRepository.aleatoria();
    switch (result) {
      case Ok<MusicaModel>():
        return Result.ok(result.value);
      case Error<MusicaModel>(error: final error):
        if (_semMusicas(error)) {
          return Result.error(HandledException(message: 'nenhumaMusicaCadastrada'));
        }
        return Result.error(error);
    }
  }

  /// Links válidos (http/https) da música, na ordem de [MusicaPlataforma]; links nulos, vazios ou
  /// malformados são ignorados.
  List<MusicaLink> links(MusicaModel musica) => [
    for (final (plataforma, link) in [
      (MusicaPlataforma.spotify, musica.musiSpotify),
      (MusicaPlataforma.deezer, musica.musiDeezer),
      (MusicaPlataforma.appleMusic, musica.musiAppleMusic),
    ])
      if (_url(link) case final url?) MusicaLink(plataforma: plataforma, url: url),
  ];

  /// Inspiração da música sem espaços nas pontas; nulo quando não há texto.
  String? inspiracao(MusicaModel musica) {
    final texto = musica.musiInspiracao?.trim();
    return (texto == null || texto.isEmpty) ? null : texto;
  }

  /// Abre o link da plataforma no app correspondente (ou no navegador).
  /// Falha vira `naoFoiPossivelAbrirLink`.
  Future<Result<void>> abrirLink(MusicaLink link) async {
    try {
      if (await _abrirUrl(link.url)) return const Result.ok(null);
    } catch (error) {
      Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    return Result.error(HandledException(message: 'naoFoiPossivelAbrirLink'));
  }

  static Uri? _url(String? link) {
    final texto = link?.trim();
    if (texto == null || texto.isEmpty) return null;
    final url = Uri.tryParse(texto);
    if (url == null || !(url.isScheme('http') || url.isScheme('https')) || url.host.isEmpty) return null;
    return url;
  }

  static bool _semMusicas(Exception error) =>
      (error is HttpServiceException && error.message == kRegistroNaoEncontrado) ||
      (error is HandledException && error.message == kRegistroNaoEncontrado);

  static const kRegistroNaoEncontrado = 'registroNaoEncontrado';
}
