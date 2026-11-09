import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../../data/model/musica/musica_model.dart';
import '../use_case/musica_usecase.dart';

/// Estado do card de música da dashboard: carrega uma música ao ser criado, sorteia outra a cada
/// `aleatoriaCommand.execute()` e abre os links das plataformas com `abrirLinkCommand`.
class MusicaViewmodel extends ChangeNotifier {
  MusicaViewmodel({required this.musicaUseCase}) {
    Log.print(super.runtimeType);
    aleatoriaCommand.execute();
  }

  final MusicaUseCase musicaUseCase;

  late final Command0<MusicaModel> aleatoriaCommand = Command0(_aleatoria);
  late final Command1<void, MusicaLink> abrirLinkCommand = Command1(musicaUseCase.abrirLink);

  /// Última música carregada; continua visível enquanto outra é sorteada ou se o novo sorteio falhar.
  MusicaModel? _musica;
  MusicaModel? get musica => _musica;

  /// Links válidos da [musica] atual (vazio sem música).
  List<MusicaLink> _links = const [];
  List<MusicaLink> get links => _links;

  /// Inspiração da [musica] atual, ou nulo quando não há texto.
  String? _inspiracao;
  String? get inspiracao => _inspiracao;

  Future<Result<MusicaModel>> _aleatoria() async {
    notifyListeners();

    final result = await musicaUseCase.aleatoria();
    switch (result) {
      case Ok<MusicaModel>(value: final musica):
        _musica = musica;
        _links = musicaUseCase.links(musica);
        _inspiracao = musicaUseCase.inspiracao(musica);
      case Error<MusicaModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    aleatoriaCommand.dispose();
    abrirLinkCommand.dispose();
    super.dispose();
  }
}
